## ---------------------------
##
## Script name: 00_preprocess_vrt_yield.R
##
## Purpose of script: creates a vrt for every year with intensity values
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

cli_h1("Intitalizing vrt creation for yield tif")

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
  usage       = "Rscript %prog [options] yieldFileInd",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)

# assign shortcuts
# ----------------
line <- cli$options$line
verbose <- cli$options$verbose
yieldFileInd <- cli$args[1]

 yieldGapFiles <- read_tsv(paste0(slmPath, "preprocess-vrt-yield-setup.txt"))[yieldFileInd,]

 # build a vrt to combine the yield (year has to match, NA values are 0) (to get the edge effects)
 build_vrt(yieldGapFiles, paste0(stage1, "yield/"), name = "yieldGap")

cli_h1("Closing vrt creation for yield tif")
