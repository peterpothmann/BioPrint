## ---------------------------
##
## Script name: 01_species_response_parameter.R
##
## Purpose of script: create the species specific response parameter ranges
##
## Author: Peter Pothmann
##
## Date Created: 02-22-2023
##
## Copyright (c) Peter Pothmann, 2022
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes:
##
## ---------------------------

cli_h1("Intializing creation of species specific response and spill over parameter")

species <- list.files(paste0(stage1, "aoh/tif/"), pattern = ".tif$")

species <- tibble(files = species) %>%
  rowwise() %>%
  mutate(taxonID = as.numeric(str_extract(str_split(files, pattern = "-")[[1]][2], pattern = "[^_]+"))) %>%
  distinct(taxonID)

# read response groups
ResGrp <- read_csv(paste0(metaPath, "species-response-group-classification.csv"))

species <- left_join(species, ResGrp, by = "taxonID")

# add parameter
resRange <- tibble(maxFS = 0.5,
                   minFS = 0.03125,
                   maxNHS = 3,
                   minNHS = 0.125,
                   maxMCU = 8,
                   minMCU = 0.5,
                   maxRCU = 32,
                   minRCU = 1)

set.seed(10)

parameter <- species %>%
  mutate(responseParameter = case_when(response == "FS" ~ paste(runif(nResFunc, min = resRange$minFS, max = resRange$maxFS), collapse = "_"),
                                       response == "NHS" ~ paste(runif(nResFunc, min = resRange$minNHS, max = resRange$maxNHS), collapse = "_"),
                                       response == "MCU" ~ paste(runif(nResFunc, min = resRange$minMCU, max = resRange$maxMCU), collapse = "_"),
                                       response == "RCU" ~ paste(runif(nResFunc, min = resRange$minRCU, max = resRange$maxRCU), collapse = "_")),
         spillParameter = paste(runif(nSpillEf, min = rangeSpill[1], max = rangeSpill[2]), collapse = "_")) %>%
  separate_rows(responseParameter, sep = "_") %>%
  separate_rows(spillParameter, sep = "_") %>%
  mutate(paraID = row_number()) %>%
  select(paraID, everything())

write_csv(parameter, paste0(metaPath, "species-response-spill-over-parameter.csv"))

cli_h1("Closing creation of species specific response and spill over parameter")
