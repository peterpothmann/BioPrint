## ---------------------------
##
## Script name: 97_preprocess_sum_yield_lulc.R
##
## Purpose of script: creates file list for VRT generation in 00_preprocess_vrt_yield.R one vrt for each year
##
## Author: Peter Pothmann
##
## Date Created: 02-22-2023
##
## Copyright (c) Peter Pothmann, 2023
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
##
## Notes:
##
##
## ---------------------------

cli_h1("Initializing the file list generatation for sum yield")

  # for each lulc
  # -------------
  yieldGapList <- list.files(paste0(stage1, "yield/tif/prep"), full.names = TRUE)

  yieldGapFiles <- as_tibble(yieldGapList) %>%
    rowwise() %>%
    mutate(year = paste(str_split(value, "_")[[1]][5], collapse = "_"),
           gridID = str_extract(str_split(value, pattern = "-")[[1]][2], pattern = "[^_]+"),
           lulcID = str_extract(str_split(value, pattern = "_")[[1]][8], pattern = "[^.]+")) %>% # extract year and al2
    group_by(year, gridID, lulcID) %>%
    summarise(paths = paste(value, collapse = " ")) # group by and paste, to summarize them in 00_preprocess_sum_yield_lulc.R

  write_tsv(yieldGapFiles, paste0(slmPath, "preprocess-sum-yield-lulc-setup.txt"), col_names = TRUE)

  # slurm submit file as input is to big
  # ------------------------------------
  yieldGapFilesLen <- seq_len(nrow(yieldGapFiles))
  write_tsv(tibble(yieldGapFilesLen), paste0(slmPath, "preprocess-sum-yield-lulc-slurm.txt"), col_names = FALSE) # use number of rows for slurm

cli_h1("Closing the file list generatation for sum yield")

