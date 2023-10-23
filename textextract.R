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
degrees <- tesseract(options = list(tessedit_char_whitelist = "-°CF.0123456789",
                                    tessedit_pageseg_mode = 7))

## USER OPTIONS ##
#path = "~/Documents/personal/cams/pics/100EK001"  # Change to directory containing images to be processed.
path = "./pics/100EK001/"
filename_pattern = "JPG"    # Change to match all filenames containing this pattern 
ocr_config = degrees        # Change to specific tesseract configuration you want. 
# text_boundaries = "264x64+900+1233"       # String with the text boundaries, in pixels (Get with an image viewer)
text_boundaries = "300x120+1800+2468"
# See magick::image_crop() for format
###################

# List files to extract from:
list.files(path, 
           pattern = filename_pattern, 
           full.names = TRUE,
           recursive = TRUE) ->
  filenames

# # For loop to avoid storing multiple images in memory
text_extracts = c()     # empty results
for (f in filenames) {
  f %>% 
    magick::image_read() -> full_image
  full_image %>% 
    magick::image_crop(text_boundaries) -> cropped_image
  magick::image_destroy(full_image)     # Minimize unnecessary image memeory use
  
  cropped_image %>% 
    magick::image_convert(type = 'Grayscale') %>%  # easier OCR in grayscale
    tesseract::ocr(engine = ocr_config) %>%
    stringr::str_replace_all("\n", " ") -> #remove newline characters
    extracted_text
  magick::image_destroy(cropped_image)   # Minimize unnecessary image memeory use
  # print(paste(basename(f), extracted_text)) # <- for progress monitoring, can comment out
  text_extracts <- append(text_extracts, extracted_text)
}

# extract numeric values from text
text_extracts %>% 
  stringr::str_extract("[0-9.-]+") %>%
  as.numeric() ->
  numeric_extracts

# dataframe (tibble) with results
tibble(path = filenames, 
       file = basename(filenames), 
       text = text_extracts, 
       degrees = numeric_extracts) ->
  temps

# get dates from exif
filenames %>% 
  exifr::read_exif(tags=c("DateTimeOriginal")) %>% 
  mutate(datetime = lubridate::as_datetime(DateTimeOriginal)) %>% 
  select(-DateTimeOriginal) ->
  times

temps %>% 
  left_join(times, by = join_by(path == SourceFile)) ->
  image_data
  
 