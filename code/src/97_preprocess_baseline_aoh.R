## ---------------------------
##
## Script name: 97_preprocess_baseline_aoh.R
##
## Purpose of script: calculate baseline aoh based on range maps (intersected with Brazil)
##
## Author: Peter Pothmann
##
## Date Created: 04-12-2023
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

aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv"))

aohFiles <- list.files(path = paste0(inPath, "aoh"), full.names = TRUE, pattern = ".tif$")

brazilVertebrates <- tibble(taxonID = aohFiles) %>% # only for species with aoh tif
  rowwise() %>%
  mutate(taxonID = as.numeric(str_extract(str_split(taxonID, pattern = "-")[[1]][2], pattern =  "[^_]+")),
         filtervalue = 1) %>%
  select(taxonID, filtervalue) %>%
  distinct(taxonID, .keep_all = TRUE)

aohInfo <- aohInfo %>%
  left_join(., brazilVertebrates, by = "taxonID") %>%
  drop_na(filtervalue) %>%
  select(-filtervalue)

# only for terrestrial species


aohInfoSub <- aohInfo %>%
  distinct(binomial, taxonID) %>%
  rowwise() %>%
  mutate(submit = paste(binomial, taxonID, sep = "_")) %>%
  select(submit)

write_tsv(aohInfoSub, paste0(slmPath, "preprocess_baseline_aoh.txt"), col_names = FALSE) # das brauche ich vllt gar nicht mehr

write_csv(tibble(taxonID = numeric(),
                 binomial = character(),
                 baseline_area = numeric()), paste0(stage1, "aoh/baseline-area.csv"))
