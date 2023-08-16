## ---------------------------
##
## Script name: 97_preprocess_aoh.R
##
## Purpose of script: extracts full file names for HPC array computing, serves as input for 00_preprocess_aoh.R
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
## Notes: - preprocess only the ones that have baseline area
##
##
## ---------------------------

h1("Intiaing species ID file creation")

# aoh files S1 for array job 00_preprocess_aoh.R (aoh prep, clip ...)
# ------------------------
cli_progress_step(msg = "Creating aoh file list for cluster")

# preprocess only the ones that have baseline area
# ------------------------------------------------
baseline <- read_csv(paste0(stage1, "aoh/baseline-area.csv"), col_types =  "ccd")

# preprocess only terrestrial species
# -----------------------------------
nonTeres <- read_csv(paste0(metaPath, "aquatic-species.csv"), col_type = "c")

submit <- tibble(paths = list.files(paste0(inPath, "aoh"), full.names = TRUE, pattern = ".tif$")) %>%  # working with vrt get the intersection wrong
  rowwise() %>%
  mutate(taxonID = str_extract(str_split(paths, "-")[[1]][2], "[^_]+")) %>%
  right_join(., baseline, by = "taxonID") %>%
  anti_join(., nonTeres, by = "taxonID") %>%
  select(taxonID, paths, baseline_area)

write_tsv(submit, paste0(slmPath, "preprocess-aoh-setup.txt"), col_names = TRUE)

submitLen <- seq_along(unique(submit$paths))
write_tsv(as_tibble(submitLen), paste0(slmPath, "preprocess-aoh-slurm.txt"), col_names = FALSE)

cli_progress_done()

h1("Closing species ID file creation")
