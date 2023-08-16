## ---------------------------
##
## Script name: 99_aoh_info_update.R
##
## Purpose of script: updates aoh-info.csv, subsets with intersecting al1. add response group classification
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
## Notes: # muss das nochmal machen nachdem ich auch die Arten herausgefiltert haben die kein caoh haben
##
## ---------------------------

# gerneral
# --------
aohInfo <- read_csv(paste0(metaPath, "aoh-info.csv"), col_types = "ccccccccc")

aohFiles <- tibble(paths = list.files(path = paste0(workPath,  "00_data/04_stage/pcaoh/tif"), pattern = ".tif$")) %>%
  rowwise() %>%
  mutate(taxonID = str_extract(str_split(paths, "-")[[1]][2], "[^_]+")) %>%
  select(-paths) %>%
  distinct()

aoh <- left_join(aohFiles, aohInfo) %>%
  select(-habitat_2, -season, -importance)


# # add response group classification
# # ---------------------------------
# resGrp <- read_csv(paste0(metaPath, "species-response-group-classification.csv"), col_types = "cc") %>%
#   rename(responseClass = response)
#
# aoh <- left_join(aoh, resGrp, by = "taxonID") %>%
#   select(ID, everything())

# write output
# ------------
write_csv(aoh, paste0(keepPath, "species-info.csv"))

para <- read_csv(paste0(metaPath, "species-response-spill-over-parameter.csv"), col_types = "cccdd") %>%
  filter(taxonID %in% aoh$taxonID)

write_csv(para, paste0(keepPath, "species-response-spill-over-parameter-upd.csv"))

