## ---------------------------
##
## Script name: 00_preprocess_change_lulc.R
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

cli_h1("Initialsing")

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

# read submit file
# ----------------
submit <- read_tsv(paste0(slmPath, "change-lulc-setup.txt"))[submitInd,]

# rast
# ----
cli_progress_step("Read aoh")
lulcP1 <- rast(submit$lulcP1)

lulcP2 <- rast(submit$lulcP2)

# make extents match
# ------------------
cli_progress_step("Match extends")

lulc <- list(lulcP1, lulcP2)

lulc <- match_extent(lulc)

# calculate change of lulc area
# -----------------------------
cli_progress_step("Change of lulc")
change <- lulc[[2]] - lulc[[1]]

names(change) <- paste0("c", names(change))

cli_progress_step("Write raster")
writeRaster(change, paste0(stage1, "lulc/clulc/", names(change), ".tif"))

cli_process_done()
cli_h1("Closing")
