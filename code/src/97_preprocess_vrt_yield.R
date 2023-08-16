## ---------------------------
##
## Script name: 97_preprocess_vrt_yield.R
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

cli_h1("Initializing the file list generatation for VRT creation")

yieldGapFiles <- as_tibble(list.files(paste0(stage1, "yield/tif"), full.names = TRUE, pattern = ".tif$")) %>%
  rowwise() %>%
  mutate(group = paste(str_split(value, "_")[[1]][4], collapse = "_")) %>% # extract year
  group_by(group) %>%
  summarise(paths = paste(value, collapse = " "))

write_tsv(yieldGapFiles, paste0(slmPath, "preprocess-vrt-yield-setup.txt"), col_names = TRUE)

yieldGapFilesLen <- seq_len(nrow(yieldGapFiles))
write_tsv(tibble(yieldGapFilesLen), paste0(slmPath, "preprocess-vrt-yield-slurm.txt"), col_names = FALSE) # use number of rows for slurm

cli_h1("Initializing the file list generatation for VRT creation")
