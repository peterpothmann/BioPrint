## ---------------------------
##
## Script name: 97_piaoh_aggregation.R
##
## Purpose of script: creates submit file for 05_caoh_aggregation
##
## Author: Peter Pothmann
##
## Date Created: 03-04-2023
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

submit <- tibble(paths = list.files(paste0(workPath, "00_data/03_stage/piaoh/tif"), full.names = T)) %>%
  rowwise() %>%
  mutate(taxonID = str_extract(str_split(paths, "-")[[1]][2], "[^_]+"),
         period = str_sub(str_split(paths, "_")[[1]][4], 1, 4),
         lulcID = str_extract(str_split(paths, "_")[[1]][8], "[^[.]]+")) %>%
  group_by(taxonID, period, lulcID) %>%
  summarize(paths = paste(paths, collapse = ";"))

num_arrays = 250000

submit <- submit %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(submit)))

# write files
write_tsv(submit, paste0(slmPath, "piaoh-aggregation-setup.txt"), col_names = TRUE)

# create a submit file as the set up file is to long for submiting
submitLen <- unique(submit$submitID)
write_tsv(tibble(submitLen), paste0(slmPath, "piaoh-aggregation-slurm.txt"), col_names = FALSE)

