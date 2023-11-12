# Script to extract text from camera trap images
# Code covered by License: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)

# README:
# Some Camera traps embed data in the images themselves without putting it into the EXIF data. 
# This is inconvenient, but the data can still be recovered automatically. This script uses OCR 
# from the Tesseract library to do this.
#
# There are parameters in the code that must be edited by the user (location of images, location
# of text within images, etc). See code comments for details.
#
# If the OCR is not working right, the user may have to edit the Tesseract options. Please see this 
# guide to start: 
# https://docs.ropensci.org/tesseract/articles/intro.html#tesseract-control-parameters
#
# The script uses the ImageMagick library for some minimal pre-processing. If the user needs more, see 
# this guide: 
# https://docs.ropensci.org/magick/articles/intro.html


library(tidyverse)
library(tesseract)
library(magick)

library(exifr)
library(lubridate)

## Different configurations for tesseract ocr ##
# Standard configuratrion for English text:
eng <- tesseract("eng") 
# Configuration to read temperature strings:
degrees <- tesseract(options = list(tessedit_char_whitelist = " -°CcF.0123456789",
                                    tessedit_pageseg_mode = 8,
                                    hocr_char_boxes = 1,
                                    lstm_choice_mode = 1))
character <- tesseract(language = "eng", 
                       options = list(tessedit_char_whitelist = " -CF0123456789° ºC℃",
                                      tessedit_pageseg_mode = 13,
                                      hocr_char_boxes = 1,
                                      tessedit_ocr_engine_mode = 1))

debug <- tesseract(language = "deu", 
                       options = list(tessedit_char_whitelist = " -CcF0123456789° ºC℃",
                                      tessedit_pageseg_mode = 7,
                                      # hocr_char_boxes = 1,
                                      lstm_choice_mode = 1))
###################
## USER OPTIONS ##

# test mode:
test_subset = FALSE # If false, will run the script on all images found
# test_subset = 400     # If N, will run on random sample of N images

# Image locations:
#path = "~/Documents/personal/cams/pics/100EK001"  # Change to directory containing images to be processed.
#path = "./pics/100EK001/"
# path = "./pics/WRCOTL/"
path = "./pics/S2BUTL/"
filename_pattern = "JPG"    # Change to match all filenames containing this pattern 

# OCR options: 
ocr_config = character        # Change to specific tesseract configuration you want. 
# text_boundaries = "264x64+900+1233"       # String with the text boundaries, in pixels (Get with an image viewer)
# text_boundaries = "300x120+1800+2468" #
# text_boundaries = "170x60+908+1236"   # wrcotl c only
# text_boundaries = "340x60+782+1236"  # wrcotl f and c
text_boundaries = "770x178+3096+3914"
# See magick::image_crop() for format


# 1. lambing:  June 1-14
# 2. Summer: June 15-Aug 14
# 3. Fall:  Aug 15-Oct 31
# 4. Rut:  Nov 1-Dec 31
# 5. Early Winter:  Jan 1-Feb 28
# 6. Late winter:  Mar 1-15
# 
# seasons <- tibble(season = c("Early Winter", "Late Winter", "Lambing", "Summer", "Fall", "Rut"),
#                   start = c("Jan 1", "Mar 1", "Jun 1", "Jun 15", "Aug 15", "Nov 1"))

# Season start dates. End dates are determined by next start date or end of year
season_cuts <- c("Early Winter" = "Jan 1", 
                 "Late Winter" = "Mar 1", 
                 "Lambing" = "Jun 1", 
                 "Summer" = "Jun 15", 
                 "Fall" = "Aug 15", 
                 "Rut" = "Nov 1") 

###################

###################
## FUNCTIONS ##

# extract_text #
# function to OCR temp text from images:
extract_text = function(image_path, bbox, ocr_config, debug= FALSE) {
  full_image = magick::image_read(image_path)
  cropped_image = magick::image_crop(full_image, bbox)
  magick::image_destroy(full_image)
  cropped_image %>%
    magick::image_convert(type = 'Grayscale') %>% 
    #magick::image_trim(fuzz = 1) %>% 
    image_threshold(type = "white", threshold = "50%") %>%
    image_threshold(type = "black", threshold = "50%") ->
    cropped_image
  cropped_image %>%
    tesseract::ocr_data(engine = ocr_config) ->
    extracted_texts
  
  if(debug) {
    plot(cropped_image)

    #error correction:
    extracted_texts %>%
      mutate(corrected_word = str_replace(word, "^8([0-9])","3\\1")) %>% #3/8 confusion
      mutate(corrected_word =
               if_else(str_detect(corrected_word, "[CFcf]"),
                       corrected_word,
                       str_replace(corrected_word, "([0-9])0$","\\1C"))) %>%
      mutate(corrected_word = str_replace(corrected_word, "([2-90][0-9])[0-9]+","\\1")) %>%
      mutate(number = as.numeric(str_extract(corrected_word, "-?[0-9]+"))) %>%
      mutate(scale = str_extract(corrected_word, "[CcFf]")) ->
      extracted_texts



    extracted_texts %>%
      arrange(desc(confidence)) %>%
      filter(str_detect(word, "[0-9]")) %>%
      slice_head(n = 1) %>%
      select(corrected_word) %>%
      as.character() ->
      hi_conf_word


    # for print
    extracted_texts %>%
      select(corrected_word) %>%
      unlist() %>%
      paste(collapse = ' ') ->
      words

    title(main = list(paste(basename(image_path),
                            "       ",
                            words),
                      cex = 1.5,
                      col = "red", font = 3),
          sub = list(hi_conf_word,
                     col = "red",
                     cex = 4,
                     font = 10))
  }
  magick::image_destroy(cropped_image)
  extracted_texts %>% 
    mutate(file = image_path) %>% 
    return()
}

# clean_extract #
# clean extracted OCR text assuming temeprature format
# raise warning flags for suspicious values
clean_extract <- function(extracted_texts) {
  extracted_texts %>% 
    mutate(corrected_word = str_replace(word, "^8([0-9])","3\\1")) %>% #3/8 confusion
    mutate(corrected_word = 
             if_else(str_detect(corrected_word, "[CFcf]"),
                     corrected_word,
                     str_replace(corrected_word, "([0-9])0$","\\1C"))) %>% 
    mutate(corrected_word = str_replace(corrected_word, "([2-90][0-9])[0-9]+","\\1")) %>% 
    mutate(number = as.numeric(str_extract(corrected_word, "-?[0-9]+"))) %>% 
    mutate(scale = str_extract(corrected_word, "[CcFf]")) ->
    extracted_texts
  
  extracted_texts %>% 
    select(file, scale, number) %>% 
    pivot_wider(names_from = scale, values_from = number) %>%
    mutate(difference_c = (F-32)*(5/9) - C) %>% 
    mutate(warning = (abs(difference_c) > 1))
  
}


# get_season
# Arguments:  date - the date to determine a season for
#             season_cuts - chr vector with season names and yearless dates
#
# Function to encapsulate the date conversions for finding season.
# Using the actual year matters due to leap years. 
# This takes a date, and constructs actual dates in that year
# based on the yearless month/day season starts in season_cuts
# With actual season dates 
# 
get_season <- function(date, season_cuts) {
  date = lubridate::as_date(date)
  year = lubridate::year(date)
  season_dates = lubridate::mdy(paste(season_cuts,  year))
  season_index = findInterval(date, season_dates)
  return(names(season_cuts[season_index]))
}

###################

###################
## Main Script ##

# List files to extract from:
list.files(path, 
           pattern = filename_pattern, 
           full.names = TRUE,
           recursive = TRUE) ->
  filenames

# Use only subset of photos for testing:
if(test_subset) {
  sample(filenames, size = test_subset ) -> filenames
}

# Map the extract_text function to all the files:
filenames %>% 
  map(~ extract_text(.x, bbox = text_boundaries, ocr_config = character)) ->
  raw_extracts


raw_extracts %>% 
  map(~ clean_extract(.x)) %>%
  map_dfr(bind_rows) -> 
  temps

# get dates from exif
filenames %>% 
  exifr::read_exif(tags=c("DateTimeOriginal")) %>% 
  mutate(datetime = lubridate::as_datetime(DateTimeOriginal)) %>% 
  select(-DateTimeOriginal) ->
  times

temps %>% 
  left_join(times, by = join_by(file == SourceFile)) ->
  image_data

# Add in season column
image_data %>% 
  rowwise() %>% 
  mutate(season = get_season(datetime, season_cuts)) ->
  image_data

