## ---------------------------
##
## Script name: 00_preprocess_sum_yield_lulc.R
##
## Purpose of script: sum yield for each lulc and year
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

cli_h1("Initialising yield aggregation")

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
  usage       = "Rscript %prog [options] yieldFileInd",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)

# assign shortcuts
# ----------------
line <- cli$options$line
verbose <- cli$options$verbose
yieldFileInd <- cli$args[1] # datei mit seq_along der dateien


# time
# ----
tic()


# read files
# ----------
cli_progress_step(msg = paste0("Importing files with line index: ", yieldFileInd))

yieldFile <- read_tsv(paste0(slmPath, "preprocess-sum-yield-lulc-setup.txt"))[yieldFileInd,] # read only the grouped files, lulc and year (created file in 99_yield_file_path_stage1_prep.R)
input <- str_split(yieldFile$paths, pattern = " ")[[1]]

yield <- map(input, rast) # alle raster innerhalb einer lulc, jahr und grid

# make 0 values NA
# ----------------
yield <- map(yield, function(x) subst(x, 0, NA)) # to merge them

# sum the yields for each region
# ------------------------------
cli_progress_step(msg = paste0("Suming yield for ", yieldFile$gridID, " ", yieldFile$lulcID, " and ", yieldFile$year))

yield <- sprc(yield)
yield <- mosaic(yield, fun = "sum", na.rm = TRUE)
yield <- subst(yield, NA, 0)

names(yield) <- paste0("yieldGap-", yieldFile$gridID, "_", yieldFile$year, "_30arcSec_lulc_", yieldFile$lulcID)

# write output
# ------------
cli_progress_step(msg = paste0("Writing output"))

writeRaster(yield, paste0(stage1, "yield/tif/lulc/tif/", names(yield), ".tif"), gdal = c("COMPRESS=DEFLATE"))

# obs table
# ---------
tme <- toc()

write_csv(
  tibble(
    file = names(yield),
    date = Sys.time(),
    process = "00_preprocess_sum_yield_lulc.R",
    matchLoca = na_lgl,
    matchInt = na_lgl,
    err = NA_character_),
  file = paste0(comPath, "obs-yield.csv"),
  append = TRUE)

cli_process_done()

cli_h1("Closing yield aggregation")
