## ---------------------------
##
## Script name: 99_resample_template.R
##
## Purpose of script: creates raster to align lulc to aoh
##
## Author: Peter Pothmann
##
## Date Created: 10-17-2022
##
## Copyright (c) Peter Pothmann, 2022
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes
##
##
## ---------------------------


template <- rast(paste0(inPath, "aoh/AoH-22712252_20180101_30arcSec.tif"))
template <- ifel(template, 1, 1)
template <- mask(template, al1)
template <- trim(template)
names(template) <- "template"

writeRaster(template, paste0(metaPath, "template.tif"), gdal = c("COMPRESS=DEFLATE"), overwrite = TRUE)
