## ---------------------------
##
## Script name: 02_intensification_adjust_aoh.R
##
## Purpose of script: calculate the intensification (Chance of Survival) of each pixel at each time step
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
## ---------------------------

cli_h1("Initializing adjust habitat area with internsification")

# cluster arguments set up
# ------------------------
options <- list (

  make_option(
    opt_str = c("-l", "--line"),
    dest    = "line",
    default = 1,
    type    = "integer",
    help    = "which input file to handle default to all",
    metavar = "42"),

  make_option(
    opt_str = c("-v", "--verbose"),
    action  = "store_true",
    help    = "print more output on what's happening")
)

parser <- OptionParser(
  usage       = "Rscript %prog [options] aohFileS1",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)


# shortcuts
# ---------
line <- cli$options$line
verbose <- cli$options$verbose

aohFileInd <- as.character(cli$args[1])

# split submit script input
# -------------------------
# purpose: imports needed arguments for foloowing functions
cli_progress_step("Import parameter and function arguments")
submit <- read_tsv(paste0(slmPath, "intensification_adjust_aoh-setup.txt"), col_types = c("ccdccddcc")) %>%
  filter(submitID == aohFileInd) %>%
  transpose

cli_inform(paste0("Number of files to process: ", length(submit)))

# set up paths
# ------------
cli_progress_step("Set up paths")
outDir <- paste0(workPath, "00_data/02_stage/iaoh/tif/")

cli_process_done()

# calculate the lost habitat due to intensification
# -------------------------------------------------
cli_inform("Start map function")
map(submit, adjust_habitat, npixel = 8, outDir = outDir)
cli_inform("Stop map function")

cli_h1("Closing adjust habitat area with internsification")
