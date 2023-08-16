## ---------------------------
##
## Script name: 97_lulc_file_path_incoming_grid.R
##
## Purpose of script: creates the metadata file list for cluster and local processing
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
##
## ---------------------------

cli_h1("Initializing lulc file list generation")


  lulcfiles <- list.files(paste0(inPath, "lulc/grid"), pattern = ".vrt$", full.names = TRUE)

  write_tsv(tibble(lulcfiles), paste0(slmPath, "lulc-files-in-grid.txt"), col_names = FALSE) # 00_preprocess_seg_lulc


cli_h1("Closing lulc file list generation")


