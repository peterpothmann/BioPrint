## ---------------------------
##
## Script name: 99_taxonomy_information.R
##
## Purpose of script: extracts taxonomic information for every species
##
## Author: Peter Pothmann
##
## Date Created: 10-12-2022
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
library(taxize)
library(tidyverse)

# paths
# -----
mainPath <- "I:/MAS/01_projects/BioPrint/"
dataPath <- "I:/MAS/01_projects/BioPrint/00_data/"
homePath <- "C:/01_projects/bioprint/"
workPath <- dataPath
# code paths
binPath <- paste0(homePath, "03_code/bin/")
srcPath <- paste0(homePath, "03_code/src/")
# data paths
slmPath <- paste0(dataPath, "97_slurm/")
metaPath <- paste0(dataPath, "99_metadata/")
comPath <- paste0(dataPath, "98_computing/")
inPath <- paste0(dataPath, "00_incoming/")
stage1 <- paste0(dataPath, "01_stage/")
stage2 <- paste0(dataPath, "02_stage/")
stage3 <- paste0(dataPath, "03_stage/")
stage4 <- paste0(dataPath, "04_stage/")

# read csv
# --------
aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv"))

# get taxonID with data in stage 1
withAoh <- read_csv(paste0(stage3, "dp/p-scores.csv")) %>%
  distinct(taxonID) %>%
  pull(taxonID)

# filter aoh withAoh
# ------------------
aohInfo <- aohInfo %>%
  filter(taxonID %in% withAoh)

# update names
# ------------
updNames <- read_csv(paste0(metaPath, "update-taxon-names.csv")) %>%
  filter(rangeName != FALSE) %>%
  select(taxonID, rangeName)

aohInfo <- aohInfo %>%
  left_join(., updNames, by = "taxonID") %>%
  mutate(binomial = case_when(!is.na(rangeName) ~ rangeName,
                              TRUE ~ binomial))

# get taxonomic information
speciesName <- unique(aohInfo$binomial)
uids <- get_uid(speciesName)
out <- classification(uids, db = "ncbi") # output is a list, what information do i need? family and class

get_taxa <- function(x){
  if(is.na(x)[[1]]){
    NULL
  } else{
    x <- x %>%
      filter(rank %in% c("kingdom", "phylum", "class", "order", "family", "genus", "species")) %>%
      select(-id) %>%
      pivot_wider(names_from = rank, values_from = name)
  }

}

t <- map(out, get_taxa)
t <- bind_rows(t)

# add taxonID
aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv")) %>%
  select(taxonID, binomial)

t <- t %>%
  left_join(., aohInfo, by = c("species" = "binomial")) %>%
  select(taxonID, everything())

write_csv(t, paste0(metaPath, "taxonomic-info.csv"))
