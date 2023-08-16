## ---------------------------
##
## Script name: 97_intensification_adjust_aoh.R
##
## Purpose of script: slurm submit for 01_intensification_adjust_aoh.R
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

# # remove the species with entry in aoh-bigger-baseline.csv file

#

cli_h1("Intializing stage 1 aoh file list creation")

# aoh file paths
aohFilesS1 <- tibble(aohPath = list.files(paste0(stage1, "aoh"), pattern = ".vrt$", full.names = TRUE)) %>%
  rowwise() %>%
  mutate(taxonID = str_extract(str_split(aohPath, pattern = "-")[[1]][2], pattern = "[^_]+"),
         year = substr(str_split(aohPath, pattern = "_")[[1]][4], 1, 4))


# remove rows with null range area
baseline <- read_csv(paste0(stage1, "aoh/baseline-area.csv"), col_types = "ccc") %>%
  select(taxonID)

submit <- semi_join(aohFilesS1, baseline) # remove the rows with no habitat (no data in aoh)

# remove taxons with aoh > baseline area
bigAoh <- read_csv(paste0(metaPath, "aoh-bigger-baseline.csv"), col_types = "c") %>%
  distinct(taxonID)

submit <- anti_join(submit, bigAoh)

# remove taxons where aoh for all years is 0
aohArea <- read_csv(paste0(stage1, "aoh/aoh-area.csv"), col_types = "ccd") %>%
  group_by(taxonID) %>%
  summarise(aoh_area = sum(aoh_area)) %>%
  filter(aoh_area == 0)

submit <- anti_join(submit, aohArea, by = "taxonID")

parameter <- read_csv(paste0(metaPath, "species-response-spill-over-parameter.csv"), col_types = "cccdd")

submit <- left_join(submit, parameter, by = "taxonID")

# add yield paths
yieldFiles <- tibble(yieldPath = list.files(paste0(stage1, "yield"), pattern = ".vrt$", full.names = T)) %>%
  rowwise() %>%
  mutate(year = substr(str_split(yieldPath, pattern = "-")[[1]][2], 1, 4))

submit <- left_join(submit, yieldFiles, by = "year")

num_arrays = 250000

# remove all paraID except 1 for 1996 iaoh, all para results are the same because yield == 0 for the year 1996

par1996 <- submit %>%
  filter(year == "1996") %>%
  distinct(taxonID, .keep_all = T)

submit <- submit %>%
  filter(year != "1996") %>%
  bind_rows(., par1996) %>%
  bind_cols(submitID = rep_len(1:num_arrays, nrow(.)))

write_tsv(submit, paste0(slmPath, "intensification_adjust_aoh-setup.txt"), col_names = TRUE) # for 01_intensification_adjust_aoh.R

# make submit script as setup is to long
submitLen <- unique(submit$submitID)
write_tsv(tibble(submitLen), paste0(slmPath, "intensification_adjust_aoh-slurm.txt"), col_names = FALSE) # use number of rows

cli_h1("Closing stage 1 aoh file list creation")
