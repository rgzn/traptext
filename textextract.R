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

## Different configurations for tesseract ocr ##
# Standard configuratrion for English text:
eng <- tesseract("eng") 
# Configuration to read temperature strings:
degrees <- tesseract(options = list(tessedit_char_whitelist = "-°CF.0123456789",
                                    tessedit_pageseg_mode = 7))

## USER OPTIONS ##
path = "~/Documents/personal/cams/pics/100EK001"  # Change to directory containing images to be processed.
filename_pattern = "JPG"    # Change to match all filenames containing this pattern 
ocr_config = degrees        # Change to specific tesseract configuration you want. 
# text_boundaries = "264x64+900+1233"       # String with the text boundaries, in pixels (Get with an image viewer)
text_boundaries = "300x120+1800+2468"
# See magick::image_crop() for format
###################

# List files to extract from:
list.files(path, pattern = filename_pattern, full.names = TRUE) ->
  filenames

# # For loop to avoid storing multiple images in memory
text_extracts = c()     # empty results
for (f in filenames) {
  f %>% image_read() %>%
    image_convert(type = 'Grayscale') %>%  # easier OCR in grayscale
    image_crop(text_boundaries) %>%
    tesseract::ocr(engine = ocr_config) %>%
    stringr::str_replace_all("\n", " ") -> #remove newline characters
    extracted_text

  print(paste(basename(f), extracted_text))

  text_extracts <- append(text_extracts, extracted_text)
}

# purely piped version. Is this the same memory use as for loop? Not sure
# filenames %>% 
#   image_read() %>%
#   image_convert(type = 'Grayscale') %>%  # easier OCR in grayscale
#   image_crop(text_boundaries) %>% 
#   tesseract::ocr(engine = ocr_config) %>% 
#   stringr::str_replace_all("\n", " ") -> #remove newline characters
#   text_extracts

# extract numeric values from text
text_extracts %>% 
  stringr::str_extract("[0-9.-]+") %>%
  as.numeric()->
  numeric_extracts

# dataframe (tibble) with results
tibble(path = filenames, 
       file = basename(filenames), 
       text = text_extracts, 
       degrees = numeric_extracts) %>% 
  write_csv("100EK001_temp_c.csv")
 