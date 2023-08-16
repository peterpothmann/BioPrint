## ---------------------------
##
## Script name: 97_p_score_calculation.R
##
## Purpose of script: slurm submit for 04_p_score_calculation.R
##
## Author: Peter Pothmann
##
## Date Created: 03-04-2023
##
## Copyright (c) Peter Pothmann, 2023
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes:
##
## ---------------------------

# habe jetzt nur ein 1996 durchlauf
# muss paraID von 2007 fuer die Periode 1996-2007 benutzen !!!!!!!!!!!!!!!!

# list iaohFiles
iaohFiles <- tibble(iaohPaths = list.files(paste0(workPath, "00_data/02_stage/iaoh/tif"), pattern = ".tif$", full.names = TRUE)) %>%
  rowwise() %>%
  mutate(year = str_sub(str_split(iaohPaths, pattern = "_")[[1]][4], 1, 4),
         taxonID = str_extract(str_split(iaohPaths, pattern = "-")[[1]][2], pattern = "[^_]+"),
         paraID = str_extract(str_split(iaohPaths, pattern = "_")[[1]][6], pattern = "[^[.]]+"))

# list aoh files
aohFiles <-  tibble(aohPaths = list.files(paste0(stage1, "aoh/"), pattern = ".vrt$", full.names = TRUE)) %>%
  rowwise() %>%
  mutate(year = str_sub(str_split(aohPaths, pattern = "_")[[1]][4], 1, 4),
         taxonID = str_extract(str_split(aohPaths, pattern = "-")[[1]][2], pattern = "[^_]+"))

# add baseline
area <- read_csv(paste0(stage1, "aoh/baseline-area.csv"), col_type = "ccd") %>%
  select(-binomial)


aohFiles <- aohFiles %>%
  left_join(., area, by = "taxonID")


# iaoh and aoh files for the first year
y1 <- iaohFiles  %>%
  filter(year == years[1]) %>%
  left_join(., aohFiles, by = c("taxonID", "year")) %>%
  select(-paraID)

y2 <- iaohFiles  %>%
  filter(year == years[2]) %>%
  left_join(., aohFiles, by = c("taxonID", "year"))

y3 <- iaohFiles  %>%
  filter(year == years[3]) %>%
  left_join(., aohFiles, by = c("taxonID", "year"))

# 1996 and 2007
p1 <- y1 %>%
  rename(iaohP1 = iaohPaths,
         aohP1 = aohPaths,
         yearP1 = year) %>%
  right_join(., select(y2, iaohPaths, aohPaths, taxonID, year, paraID), by = c("taxonID")) %>%
  mutate(period = years[2]) %>%
  rename(iaohP2 = iaohPaths,
         aohP2 = aohPaths,
         yearP2 = year)

# 2007 and 2018
p2 <- y2 %>%
  rename(iaohP1 = iaohPaths,
         aohP1 = aohPaths,
         yearP1 = year) %>%
  left_join(., select(y3, iaohPaths, aohPaths, taxonID, year, paraID), by = c("taxonID", "paraID")) %>%
  mutate(period = years[3]) %>%
  rename(iaohP2 = iaohPaths,
         aohP2 = aohPaths,
         yearP2 = year)

submit <- bind_rows(p1, p2) %>%
  select(taxonID, period, yearP1, yearP2, paraID, baseline_area, aohP1, aohP2, iaohP1, iaohP2)

num_arrays = 250000

submit <- submit %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(submit)))

# write files
write_tsv(submit, paste0(slmPath, "p_score_calculation-setup.txt"), col_names = TRUE) # for p_score_calculation.R

# create a submit file as the set up file is to long for submiting
submitLen <- unique(submit$submitID)
write_tsv(tibble(submitLen), paste0(slmPath, "p_score_calculation-slurm.txt"), col_names = FALSE) # use number of rows

