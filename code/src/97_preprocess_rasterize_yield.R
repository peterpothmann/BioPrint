## ---------------------------
##
## Script name: 97_preprocess_rasterize_yield.R
##
## Purpose of script: file paths of data in stage/lulc folder for yield, to create one VRT for year and LULC class
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
## Notes:
##
## ---------------------------

cli_h1("Intializing creation of file lists for lulc stage 1")

  # list files
  # ----------
  lulcFilesS1 <- list.files(paste0(stage1, "lulc/tif"), full.names = TRUE)

  # tsv for yield preprocesss
  # -------------------------
  write_tsv(tibble(lulcFilesS1), paste0(slmPath, "preprocess-rasterize-yield-slurm.txt"), col_names = FALSE)

cli_h1("Closing creation of file lists for lulc stage 1")
