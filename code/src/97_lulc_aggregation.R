## ---------------------------
##
## Script name: 97_lulc_aggregation.R
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

tax <- "class"

submit <- tibble(paths = list.files(paste0(workPath, "00_data/05_stage/lulc/piaoh/", tax), full.names = T), type = "piaoh") %>%
  bind_rows(., tibble(paths = list.files(paste0(workPath, "00_data/05_stage/lulc/pcaoh/", tax), full.names = T), type = "pcaoh")) %>%
  rowwise() %>%
  mutate(taxonID = str_extract(str_split(paths, "-")[[1]][2], "[^_]+"),
         period = str_sub(str_split(paths, "_")[[1]][4], 1, 4),
         lulcID = str_split(paths, "_")[[1]][6],
         stat = str_extract(str_split(paths, "_")[[1]][7], "[^[.]]+"))

# aufteilen in taxonomische klassen
taxInfo <- read_csv(paste0(metaPath, "taxonomic-info.csv"), col_types = "cccccccc")

submit <- submit %>%
  left_join(., taxInfo, by = c("taxonID" = tax)) %>%
  drop_na(kingdom) %>%
  distinct(paths, .keep_all = T) %>%
  group_by(period, type, lulcID, stat, kingdom) %>%
  summarize(paths = paste(paths, collapse = ";")) %>%
  mutate(taxTree = "kingdom") %>%
  rename(taxClass = kingdom)

num_arrays = 250000

submit <- submit %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(submit)))

# write files
write_tsv(submit, paste0(slmPath, "lulc-aggregation-setup.txt"), col_names = TRUE)

# create a submit file as the set up file is to long for submiting
submitLen <- unique(submit$submitID)
write_tsv(tibble(submitLen), paste0(slmPath, "lulc-aggregation-slurm.txt"), col_names = FALSE)
