## ---------------------------
##
## Script name: 97_preprocess_change_lulc.R
##
## Purpose of script: calculate the p score for all model run time steps
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
## ---------------------------


lulcFiles <- tibble(paths = list.files(paste0(stage1, "lulc/"), full.names = TRUE, pattern = ".vrt$")) %>%
  rowwise() %>%
  mutate(lulcID = str_extract(str_split(paths, pattern = "_")[[1]][7], pattern = "[^[.]]+"),
         year = str_sub(str_split(paths, pattern = "_")[[1]][4], 1, 4))

y1 <- lulcFiles %>%
  filter(year == "1996") %>%
  select(paths, lulcID) %>%
  rename(lulcP1 = paths)

y2 <- lulcFiles %>%
  filter(year == "2007") %>%
  select(paths, lulcID)

y3 <- lulcFiles %>%
  filter(year == "2018") %>%
  select(paths, lulcID) %>%
  rename(lulcP2 = paths)

# create the periods

p1 <- left_join(y1, y2) %>%
  rename(lulcP2 = paths)

p2 <- left_join(y2, y3) %>%
  rename(lulcP1 = paths)

# bind the periods
submit <- bind_rows(p1, p2)

write_tsv(submit, paste0(slmPath, "change-lulc-setup.txt"))

write_tsv(tibble(seq_len(nrow(submit))), paste0(slmPath, "change-lulc-slurm.txt"), col_names = FALSE)
