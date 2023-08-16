## ---------------------------
##
## Script name: 04_iaoh_attribution.R
##
## Purpose of script: attribute the change of aoh due to intensiv use to land uses
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

cli_h1("Inializing iaoh aggregation")

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

submitInd <- cli$args[1]

cli_alert_info(paste0("Now processing: ", submitInd))

# set paths
# ---------
outPath <- paste0(workPath, "00_data/03_stage/piaoh/")

# read submit file
# ----------------
submit <- read_tsv(paste0(slmPath, "attribution-setup.txt")) %>%
  filter(submitID == submitInd) %>%
  transpose()

# get the change yield files with intensity
# ----------------------------------
cint <- tibble(paths = list.files(paste0(stage1, "yield/cyield"), full.names = TRUE)) %>%
  rowwise() %>%
  mutate(lulcID = str_extract(str_split(paths, pattern = "_")[[1]][7], pattern = "[^[.]]+"),
         period = str_sub(str_split(paths, pattern = "_")[[1]][4], 1, 4))

# attribute the change of intensity
# ---------------------------------
map(submit, iaoh_attribution, cint = cint, type = "iaoh", outPath = outPath)

cli_h1("Closing iaoh aggregation")

