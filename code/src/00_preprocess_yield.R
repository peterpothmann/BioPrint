## ---------------------------
##
## Script name: 00_preprocess_yield_data.R
##
## Purpose of script: load, filter, rasterize yield data
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
##
## Notes:
##
##
## ---------------------------

cli_h1("Intialising yield preprocess")

# load data
# ---------

cli_progress_step(msg = "Importing yield data")

yieldTranslation <- read_csv(paste0(metaPath, "yield-translation.csv"))
yield <- read_rds(paste0(inPath, "yield/Brazil.rds"))

cli_progress_step(msg = "Importing administrative boundaries data")
al3 <- st_read(dsn = paste0(stage1, "al/al.gpkg"), layer = "al3", quiet = TRUE)


# filter data
# -----------
cli_progress_step(msg = "Filtering yield data")

yieldTranslation <- yieldTranslation %>% # filter rows with no match, thus will receive 0 intensity in rasterize process
  filter(ontoName != "noMatch")

yieldt <- yield %>% # preprocess, select only needed rows
  drop_na(yield, ontoName) %>%
  filter(year %in% as.character(years),
         external != "Asses",
         gazName != "Brazil") %>%
  mutate(ontoName = case_when(ontoName == "ass" ~ "yam",
                              ontoName ==   "açaí" ~ "acai",
                              TRUE ~ as.character(ontoName))) %>%
  left_join(., yieldTranslation, by = "ontoName")

yieldt <- yieldt %>% # summarize yields based on lulc translation
  group_by(gazName, lulc, year, lulcID) %>%
  summarize(yieldSD = sd(yield),
            yieldCount = n(),
            yield = mean(yield)) %>%
  select(order(colnames(.))) %>%
  separate(gazName, into = c("al1", "al2", "al3"), sep = "[.]") %>%
  drop_na(lulc)

cli_process_done()

# regional maximum yields
# --------------------------
cli_progress_step(msg = "Calculating regional maximum yield")

yieldMax <- yieldt %>%
  group_by(al2, year, lulc, lulcID) %>%
  summarize(RegionalYieldCount = n(),
            RegionalYieldMax = max(yield)) %>%
  mutate(joinCol = str_c(al2, year, lulc)) %>%
  ungroup() %>%
  select(joinCol, RegionalYieldCount, RegionalYieldMax)

cli_process_done()

# calculate the yield gap (%)
# --------------------------
cli_progress_step(msg = "Calculating yield gap")

yieldGap <- yieldt %>%
  mutate(joinCol = str_c(al2, year, lulc)) %>%
  left_join(., yieldMax, by = "joinCol") %>%
  select(-joinCol) %>%
  mutate(yieldGap = yield / RegionalYieldMax,
         gazName = str_c(al1, al2, al3, sep = "."),
         lulcID = as.character(lulcID)) %>%
  select(-al1, -al2, -al3) %>%
  right_join(., al3, by = "gazName")

# write result
# --------------------
cli_progress_step(msg = "Writing yield gap in vector format")

st_write(yieldGap,
         paste0(stage1, "yield/vct/yield-gap.gpkg"),
         layer = "yield-gap",
         quiet = TRUE,
         append = FALSE)


cli_process_done()


cli_h3("Closing yield preprocess")
