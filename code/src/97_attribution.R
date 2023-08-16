## ---------------------------
##
## Script name: 97_caoh_attribution.R
##
## Purpose of script: slurm submit for 04_caoh_attribution.R
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

# read the submit set up file from 03_p_score_calculation.R
submit <- read_tsv(paste0(slmPath, "p_score_calculation-setup.txt"), col_types = "ccccccccc") %>%
  select(-baseline_area)   # remove baseline column

# add one uni contribution
submit <- submit %>%
  right_join(., read_csv(paste0(workPath, "00_data/03_stage/dp/p-contribution-oneUnit-habitat.csv"), col_types = c("cccd")), by = c("period", "paraID", "taxonID")) # hier kann es sein das oneUnitContri 0 ist

# muss alle Arten die eine NA observation haben als oneUnitcontri haben aussortieren
sortOut <- submit %>% filter(is.na(oneUnitContri)) %>%
  distinct(taxonID)

submit <- submit %>%
  anti_join(., sortOut, by = "taxonID")

# add suitable lulc
aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv"), col_types = "ccccccccc") %>%
  distinct(taxonID, habitat)

iucn <- read_csv(paste0(metaPath, "lulc-iucn-translation.csv")) %>%
  select(habitat = iucn, lulcID)

# add aoh info
submit <- left_join(submit, aohInfo, by = "taxonID")

# add suitable lulcID and summarize
submit <- left_join(submit, iucn, by = "habitat") %>%
  drop_na(lulcID) %>%
  select(-habitat, -submitID) %>%
  distinct(lulcID, taxonID, period, paraID, oneUnitContri, .keep_all = TRUE) %>%
  group_by(taxonID, period, paraID, oneUnitContri, aohP1, aohP2, iaohP1, iaohP2) %>%
  summarise(lulcID = paste(lulcID, collapse = "_"))

# submitID
num_arrays = 250000

submit <- submit %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(submit)))

write_tsv(submit, paste0(slmPath, "attribution-setup.txt"))

submitLen <- tibble(len = unique(submit$submitID)) %>%
  write_csv(., paste0(slmPath, "attribution-slurm.txt"), col_names = FALSE)
