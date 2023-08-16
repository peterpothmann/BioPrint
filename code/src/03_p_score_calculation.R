## ---------------------------
##
## Script name: 03_p_score_calculation.R
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
##
## ---------------------------

cli_h1("Initiating p score calculation")

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
  usage       = "Rscript %prog [options] submitInd",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)

# shortcuts
# ---------
line <- cli$options$line
verbose <- cli$options$verbose
submitInd <- as.character(cli$args[1])

# output paths
dpDir <- paste0(workPath, "00_data/03_stage/dp/")

# read submit file with index
# ---------------------------

cli_progress_step("Import submit file")

submit <- read_tsv(paste0(slmPath, "p_score_calculation-setup.txt"), col_types = "cccccdccccc") %>% # year muss das von period 2 sein, am besten auch spalte in period umbenennen
  filter(submitID == submitInd) %>%
  transpose()

cli_process_done()

# calculate p score
# -----------------
# manche failen wil overwrite nicht true ist, muss was mit der Namensgebung falsch sein, vllt auch was mit dem submit script
map(submit, p_score, extinctionParameter, dpDir)

cli_h1("Closing p score calculation")

