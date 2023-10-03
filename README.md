# traptext
Get text from camera trap images

Some Camera traps embed data in the images themselves without putting it into the EXIF data.
This is inconvenient, but the data can still be recovered automatically. This script uses OCR
from the Tesseract library to do this.

There are parameters in the code that must be edited by the user (location of images, location
of text within images, etc). See code comments for details.

If the OCR is not working right, the user may have to edit the Tesseract options. Please see this
guide to start:
https://docs.ropensci.org/tesseract/articles/intro.html#tesseract-control-parameters

The script uses the ImageMagick library for some minimal pre-processing. If the user needs more, see
this guide:
https://docs.ropensci.org/magick/articles/intro.html
