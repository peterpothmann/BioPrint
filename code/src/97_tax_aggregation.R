## ---------------------------
##
## Script name: 97_overall_aggregation.R
##
## Purpose of script:
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

# Was will ich aggregieren:
  # - lulc, period, type, mean std

submit <- tibble(paths = list.files(paste0(workPath, "00_data/05_stage/lulc/pcaoh/kingdom"), full.names = T)) %>%
  bind_rows(., tibble(paths = list.files(paste0(workPath, "00_data/05_stage/lulc/piaoh/kingdom"), full.names = T))) %>%
  rowwise() %>%
  mutate(taxClass = str_extract(str_split(paths, "-")[[1]][2], "[^_]+"),
         period = str_sub(str_split(paths, "_")[[1]][4], 1, 4),
         lulcID = str_split(paths, "_")[[1]][6],
         type = str_split(paths, "/")[[1]][9],
         taxTree = str_split(paths, "/")[[1]][10],
         stat = str_extract(str_split(paths, "_")[[1]][7], "[^[.]]+"))

# # aufteilen in taxonomische klassen
# taxInfo <- read_csv(paste0(metaPath, "taxonomic-info.csv"), col_types = "cccccccc")

submit <- submit %>%
  group_by(taxClass, taxTree, period, stat) %>%
  summarize(paths = paste(paths, collapse = ";"))

num_arrays = 250000

submit <- submit %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(submit)))

# write files
write_tsv(submit, paste0(slmPath, "tax-aggregation-setup.txt"), col_names = TRUE)

# create a submit file as the set up file is to long for submiting
submitLen <- unique(submit$submitID)
write_tsv(tibble(submitLen), paste0(slmPath, "tax-aggregation-slurm.txt"), col_names = FALSE)

