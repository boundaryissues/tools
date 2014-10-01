''' splitter

This program performs two functions: it splits an ogr format file of
boundaries into subfiles based on boundary types, and it also converts
attributes into osm equivalents on the fly. how the split is done and
what tags are converted are controlled by an external configuration file.

'''

import optparse

import gdal
import ogr
import osr

from gdalconst import *

import logging as log
log.basicConfig( level=log.DEBUG, format="%(message)s")

usage = "usage: %prog SRCFILE"
parser = optparse.OptionParser(usage=usage)

(options, args) = parser.parse_args()

sourceFile = args[0]
sourceDataSet = ogr.Open( sourceFile, GA_ReadOnly)
if sourceDataSet is None:
    exit

