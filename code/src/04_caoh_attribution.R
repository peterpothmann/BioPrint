## ---------------------------
##
## Script name: 04_caoh_attribution.R
##
## Purpose of script: attribute the change of aoh due to land conversion to land use classes
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

cli_h1("Inializing caoh attribution")


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

cli_alert_info(paste0("Now processing: ", submitInd))

# set paths
# ---------
outDir <- paste0(workPath, "00_data/03_stage/pcaoh/")

# read submit set up
# ------------------
submit <- read_tsv(paste0(slmPath, "attribution-setup.txt"), col_types = "cccdcccccd") %>%
  filter(submitID == submitInd) %>%
  transpose

# create change lulc file list
# ---------------------
clulcFiles <- tibble(paths = list.files(paste0(stage1, "lulc/clulc/"), full.names = TRUE, pattern = ".tif$")) %>%
  rowwise() %>%
  mutate(lulcID = str_extract(str_split(paths, pattern = "_")[[1]][7], pattern = "[^[.]]+"),
         year = str_sub(str_split(paths, pattern = "_")[[1]][4], 1, 4))

# change area of habitat
# ----------------------
map(submit, caoh_attribution, clulc = clulcFiles, type = "caoh", outDir)

cli_h1("Closing caoh attribution")

