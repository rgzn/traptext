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

Shield: [![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]

This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
