## ---------------------------
##
## Script name: 97_preprocess_sum_yield_all.R
##
## Purpose of script: creates file list for 00_preprocess_sum_yield_all.R
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
yieldGapFiles <- tibble(paths = list.files(paste0(stage1, "yield/tif/lulc/tif"), full.names = TRUE)) %>%
  rowwise() %>%
  mutate(year = paste(str_split(paths, "_")[[1]][4], collapse = "_"),
         gridID = str_extract(str_split(paths, pattern = "-")[[1]][2], pattern = "[^_]+")) %>% # extract year and gridID
  filter(year == "19960000") %>%
  group_by(year, gridID) %>%
  summarise(paths = paste(paths, collapse = " ")) # group by and paste, to summarize them in 00_preprocess_sum_yield_all.R

write_tsv(yieldGapFiles, paste0(slmPath, "preprocess-sum-yield-all-setup.txt"), col_names = TRUE)

# slurm submit file as input is to big
# ------------------------------------
yieldGapFilesLen <- seq_len(nrow(yieldGapFiles))
write_tsv(tibble(yieldGapFilesLen), paste0(slmPath, "preprocess-sum-yield-all-slurm.txt"), col_names = FALSE) # use number of rows for slurm

cli_h1("Closing the file list generatation for sum yield")
