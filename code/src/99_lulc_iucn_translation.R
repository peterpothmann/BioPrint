## ---------------------------
##
## Script name: 99_lulc_iucn_translation.R
##
## Purpose of script: 
##
## Author: Peter Pothmann
##
## Date Created: 10-05-2022
##
## Copyright (c) Peter Pothmann, 2022
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes:
##
## ---------------------------


# read translation
translation <- read_csv(paste0(metaPath, "lulc-iucn-translation.csv"))

# read lulc information
lulcInfo <- read_tsv(paste0(metaPath, "lulc-info.csv")) %>%
  select(-natural)

translation <- translation %>%
  separate_rows(lulc, sep = "_")

translation <- left_join(translation, lulcInfo, by = "lulc")
