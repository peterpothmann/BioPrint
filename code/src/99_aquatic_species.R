## ---------------------------
##
## Script name: 99_aquatic_species.R
##
## Purpose of script: extracts the species that solely life in aquatic habitat types
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

aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv"))

water <- read_csv(paste0(metaPath, "iucn-aquatic-classes.csv"))

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

aquaticSpecies <- aohInfo %>%
  group_by(taxonID) %>%
  filter(all(habitat %in% water$aquatic)) %>%
  distinct(taxonID)

write_csv(aquaticSpecies, paste0(metaPath, "aquatic-species.csv"))
