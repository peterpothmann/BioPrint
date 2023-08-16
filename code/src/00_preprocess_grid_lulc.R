## ---------------------------
##
## Script name: 00_preprocess_grid_lulc.R
##
## Purpose of script: make smaller grid of lulc
##
## Author: Peter Pothmann
##
## Date Created: 10-17-2022
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

cli_h1("Initializing lulc grid intersection")

cli_alert_info("Using cluster array workflow")

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
  usage       = "Rscript %prog [options] lulcFile",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)

# assign shortcuts
# ----------------
line <- cli$options$line
verbose <- cli$options$verbose

lulcFilePath <- cli$args[1]
cli_alert_info(paste0("Now processing: ", lulcFilePath))

# lulcFilePath <- "I:/MAS/01_projects/BioPrint/00_data/00_incoming/lulc/mapBiomas-brazil_19960000_30m.tif"

outPath <- paste0(inPath, "lulc/grid/")

# read lulc
cli_progress_step("Read lulc")
lulc <- rast(lulcFilePath)

# read grids
cli_progress_step("Read grid")
grid <- st_read(paste0(metaPath, "grid.gpkg"), layer = "grid.shp")

# check for intersection
cli_progress_step("Check for intersection")
grid <- grid %>%
  mutate(intersection = as.logical(unlist(relate(lulc, vect(grid), relation = "intersects")))) %>%
  filter(intersection == TRUE) %>%
  transpose()

cli_progress_done()

cli_inform(paste0("Number of intersections: ", length(grid)))

map(grid, .f = grid_lulc, lulc = lulc, outPath = outPath)

cli_h1("Closing lulc grid intersection")


