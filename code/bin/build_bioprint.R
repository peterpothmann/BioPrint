## ---------------------------
##
## Script name: build_bioprint.R
##
## Purpose of script: Main script that sources, orders and holds other scripts
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
git
# requirements:
# - input data spatial - temporal resolution match
# - meet the following raster naming guidelines
# - adapt the submit script to your needs, if needed


# naming guidelines for raster data ---
# =====================================

# NAME          rastername                                  description
# ------------------------------------------------------------------------------------------
# AOH     |     AoH-101228458_20070101_30arcSec       |     Name-taxonID_YYYYMMDD_resolution
#
# LUC     |     mapBiomas-amazonia_19950000_30m       |     Name-region_YYYYMMDD_resolution
#
# yield   |     yield_2001_LUC_30arcSec               |     Name-cropID_YYYYMMDD_resolution


# naming guidelines for data tables ---
# =====================================

# NAME                        COLUMNS         FIELDTYPE         DESCRIPTION
# ----------------------------------------------------------------------------------------------------------------------
#                       |     ID              numeric           unique identifier
# classification.csv    |     Class           string            character string
#                       |     natural         numeric           1 = natural LULC class, 0 = more or less artifical class
# ----------------------------------------------------------------------------------------------------------------------
#                       |
#                       |
# aoh-info.csv          |   WORK IN PROGRESS
#                       |

# naming guidelines for scipts in src folder ---
# ==============================================

# 00_preprocess_XYY --> prepropcess, prepare the data
# 01_ , 02_, ... 06_ --> the actual analysis
# 97_ --> create submit files
# 99_ --> create meta data files



# local or cluster?
# -----------------

place <- "cluster" # local version does not work, and wont work because the scripts are to computing resource heavy

# load packages
# -------------
library(terra, quietly = TRUE)
library(tidyverse, quietly = TRUE)
library(sf, quietly = TRUE)
library(readxl, quietly = TRUE)
library(cli, quietly = TRUE)
library(optparse, quietly = TRUE)
library(tictoc, quietly = TRUE)
library(rlang)
library(tictoc)
# library(lubridate) # for plots
# library(tidyterra) # for plots
# library(paletteer) # for plots
# library(cowplot)   # for plots


# reproduceability stuff
# ----------------------
cli_h1("Session information")
sessionInfo()

# set paths
# ---------
cli_h1("Set up directory paths")

if(place == "cluster"){

  cli_alert_info("Using cluster directory set up")

  # main paths
  dataPath <- "/gpfs1/data/bioprint/00_data/"
  homePath <- "/gpfs0/home/pothmann/bioprint/"
  workPath <- "/gpfs1/work/pothmann/bioprint/"
  # code paths
  binPath <- paste0(homePath, "03_code/bin/")
  srcPath <- paste0(homePath, "03_code/src/")
  # data paths
  slmPath <- paste0(dataPath, "97_slurm/")
  comPath <- paste0(dataPath, "98_computing/")
  metaPath <- paste0(dataPath, "99_metadata/")
  keepPath <- paste0(dataPath, "100_keep/")
  inPath <- paste0(dataPath, "00_incoming/")
  stage1 <- paste0(dataPath, "01_stage/")
  stage2 <- paste0(dataPath, "02_stage/")
  stage3 <- paste0(dataPath, "03_stage/")
  stage4 <- paste0(dataPath, "04_stage/")
  stage5 <- paste0(dataPath, "05_stage/")

} else{

  cli_alert_info("Using local directory set up")

  # main paths
  mainPath <- "I:/MAS/01_projects/BioPrint/"
  dataPath <- paste0(mainPath, "00_data/")
  homePath <- "C:/01_projects/bioprint/"
  workPath <- dataPath
  # code paths
  binPath <- paste0(homePath, "03_code/bin/")
  srcPath <- paste0(homePath, "03_code/src/")
  # data paths
  slmPath <- paste0(dataPath, "97_slurm/")
  comPath <- paste0(dataPath, "98_computing/")
  metaPath <- paste0(dataPath, "99_metadata/")
  keepPath <- paste0(dataPath, "100_keep/")
  inPath <- paste0(dataPath, "00_incoming/")
  stage1 <- paste0(dataPath, "01_stage/")
  stage2 <- paste0(dataPath, "02_stage/")
  stage3 <- paste0(dataPath, "03_stage/")
  stage4 <- paste0(dataPath, "04_stage/")
}

cli_alert_success("Completed directory set up")

# set up observation tables
# -------------------------
# - do this one time, else it overwrites

# obs lulc
# --------
# write_tsv(
#   tibble(file = character(),
#          date = ymd_hms(),
#          process = character(),
#          runTimeSec = numeric(),
#          completion = logical()), # Did the process finished? TRUE/FALSE
#   file = paste0(comPath, "obs-lulc.csv"),
#   col_names = TRUE)

# obs aoh
# -------
# write_csv(
#   tibble(
#     taxonID = character(), # the ID of the species
#     date = ymd_hms(), # the date and time the process computed
#     process = character(), # the name of R script
#     lengthAoh = numeric(), # length of aoh, should always be equal to length(years)
#     lengthCaoh = numeric(),  # length of aoh, should always be equal to length(years) - 1
#     Pscore = numeric(), # the P score of the species
#     runTimeSec = numeric(),  # the needed time to compute the results
#     completion = logical(),  # Did the computation complete? TRUE/FALSE
#     err = character()), # explanation if completion FALSE
#   file = paste0(comPath, "obs-aoh.csv"),
#   col_names = TRUE)

# obs yield
# ---------
# write_csv(
#   tibble(
#       file = character(), # name of the file
#       date = ymd_hms(), # the date and time the process computed
#       process = character(), # the name of R script
#       matchLoca = logical(), # if there is a match with loca data
#       matchInt = logical(), # if the lulc should have intensity data, as specified in yield-translation.csv
#       err = character()), # explanation if completion FALSE
#   file = paste0(comPath, "obs-yield.csv"),
#   col_names = TRUE)

# set parameters
# --------------
nResFunc = 10 # number of simulations e.g. number of response functions
nSpillEf <- 5 # number of spill over parameter
rangeSpill <- c(0, 0.1) # range of spill over effect
extinctionParameter <- 0.25
years <- c(1996, 2007, 2018) # need this for the delta_aoh and 00_preprocess_yield.R function
aimRes <- c(0.008333333333333333218, 0.008333333333333333218) # spatial resolution
aimExt <- ext(-74.8973961395788, -26.3883707971246, -34.7917509539491, 13.7172743885051)

# boot functions
# --------------
source(paste0(binPath, "boot_functions.R"))

# terra options
# -------------
terraOptions(memmax = 8, todisk = TRUE, tempdir = paste0("/gpfs1/work/pothmann/terraTemp")) # create a folder where terra can store temporary tif files. Specify the folder path with tempdir

# preprocess data
# ---------------
# al ---
# source(paste0(srcPath, "00_preprocess_al.R"))

# aoh ---
# source(paste0(srcPath, "00_preprocess_species_response.R"))
# source(paste0(srcPath, "97_preprocess_aoh.R))
# source(paste0(srcPath, "00_preprocess_baseline_aoh.R"))
# source(paste0(srcPath, "00_preprocess_aoh.R"))

# lulc ---
# source(paste0(srcPath, "97_lulc_file_path_incoming.R")) (done)
# source(paste0(srcPath, "00_preprocess_grid_lulc.R"))
# source(paste0(srcPath, "00_preprocess_seg_lulc.R"))
# source(paste0(srcPath, "test_lulc_preprocess.R"))
# source(paste0(srcPath, "97_preprocess_rasterize_yield.R))
# source(paste0(srcPath, "00_preprocess_vrt_lulc.R"))
# source(paste0(srcPath, "00_preprocess_change_lulc.R"))

# Intensity ---
# source(paste0(srcPath, "00_preprocess_yield.R"))
# source(paste0(srcPath, "97_preprocess_rasterize_yield.R"))
# source(paste0(srcPath, "00_preprocess_rasterize_yield.R"))
# source(paste0(srcPath, "97_preprocess_sum_yield_lulc.R"))
# source(paste0(srcPath, "00_preprocess_sum_yield_lulc.R"))
# source(paste0(srcPath, "00_preprocess_vrt_yield_lulc.R"))
# source(paste0(srcPath, "97_preprocess_sum_yield_all.R"))
# source(paste0(srcPath, "00_preprocess_sum_yield_all.R"))
# source(paste0(srcPath, "00_preprocess_vrt_yield.R"))
# source(paste0(srcPath, "00_preprocess_change_yield.R"))


# intensity adjust area of habitat
# --------------------------------
# source(paste0(srcPath, "97_intensification_adjust_aoh.R"))
# source(paste0(srcPath, "02_intensification_adjust_aoh.R"))

# p score calculation
# -------------------
# source(paste0(srcPath, "97_p_score_calculation.R"))
# source(paste0(srcPath, "03_p_score_calculation.R"))

# land conversion module
# ----------------------
# source(paste0(srcPath, "04_caoh_attribution.R"))
# source(paste0(srcPath, "04_iaoh_attribution.R"))

# aggregation
# -----------
# source(paste0(srcPath, "05_dp_aggregation.R"))
# source(paste0(srcPath, "97_pcaoh_aggregation.R"))
# source(paste0(srcPath, "05_pcaoh_aggregation.R"))
# source(paste0(srcPath, "97_piaoh_aggregation.R"))
# source(paste0(srcPath, "05_piaoh_aggregation.R"))


# thematical aggegation
# ---------------------
# source(paste0(srcPath, "06_lulc_aggregation.R"))
# source(paste0(srcPath, "06_tax_aggregation.R"))

# metadata ---
# source(paste0(srcPath), "99_taxonID_with_aoh.R") (done)
# knitr::write_bib(c(.packages()), paste0(metaPath, "package-cita.bib"))

