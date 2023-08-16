## ---------------------------
##
## Script name: 97_pmiss.R
##
## Purpose of script: submit script for 04_pmiss
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

dpFiles <- tibble(dpPaths = list.files(paste0(stage3, "dp"), pattern = ".vrt$", full.names = TRUE)) %>%
  mutate(taxonID = str_extract(str_split(dpPaths, "-")[[1]][2], "[^_]+"),
         paraID = str_extract(str_split(dpPaths, "_")[[1]][6], "[^[.]]+"),
         year = str_split(dpPaths, "_")[[1]][4])

paohFiles <- tibble(paohPaths = list.files(paste0(stage3, "pcaoh"), pattern = ".vrt$", full.names = TRUE)) %>%
  # MUSS MUTATE CHECKEN
  mutate(taxonID = str_extract(str_split(dpPaths, "-")[[1]][2], "[^_]+"),
         paraID = str_extract(str_split(dpPaths, "_")[[1]][6], "[^[.]]+"),
         year = str_split(dpPaths, "_")[[1]][4])

piaohFiles <- tibble(piahPaths = list.files(paste0(stage3, "pcaoh"), pattern = ".vrt$", full.names = TRUE)) %>%
  # MUSS MUTATE CHECKEN
  mutate(taxonID = str_extract(str_split(dpPaths, "-")[[1]][2], "[^_]+"),
         paraID = str_extract(str_split(dpPaths, "_")[[1]][6], "[^[.]]+"),
         year = str_split(dpPaths, "_")[[1]][4])

# was mache ich wenn nicht jeder Eintrag auch einen passenden anderen hat
submit <- left_join(., ., by = c("taxonID", "paraID", "year"))
