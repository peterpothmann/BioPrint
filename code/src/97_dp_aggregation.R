## ---------------------------
##
## Script name: 97_dp_aggregation.R
##
## Purpose of script: creates submit file for 05_dp_aggregation
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

submit <- tibble(paths = list.files(paste0(workPath, "00_data/03_stage/dp/tif"), full.names = T)) %>%
  rowwise() %>%
  mutate(period = str_sub(str_split(paths, "_")[[1]][4], 1, 4),
         taxonID = str_extract(str_split(paths, "-")[[1]][2], "[^_]+")) %>%
  group_by(taxonID, period) %>%
  mutate(submitID = cur_group_id())

write_tsv(submit, paste0(slmPath, "dp-aggregation-setup.txt"))

submitLen <- tibble(len = unique(submit$submitID)) %>%
  write_csv(., paste0(slmPath, "dp-aggregation-slurm.txt"), col_names = FALSE)
