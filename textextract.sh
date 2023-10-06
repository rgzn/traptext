#!/bin/bash
# Small bash script to be run in the directory with a bunch of camera trap images
# Extracts text from each around a specific bounding box. 
# requires: bash, imagemagick, tesseract
for I in *.JPG; 
do 
# The pixel coordinates are an argument to "crop"
# These determine the bounding box for the desired text to extract. Adjust as needed
  NAME=$(basename $I .JPG);  # Get image basename
  convert $I -crop 1280x140+2800+2150 cropped_$I;  # crop around text region
  tesseract cropped_${I} ${NAME}_time ; # OCR on text
done
