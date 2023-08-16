## ---------------------------
##
## Script name: 06_lulc_aggregation.R
##
## Purpose of script: attribute the change of aoh due to land conversion to land uses
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

cli_h1("Inializing lulc aggregation")

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

# set up paths
# ------------
outPath <- paste0(workPath, "00_data/05_stage/")

# read submit file
# ----------------
cli_progress_step("Read submit file")
submit <- read_tsv(paste0(slmPath, "lulc-aggregation-setup.txt")) %>%
  filter(submitID == submitInd)

cli_progress_step("Read raster")
r <- map(str_split(submit$paths, ";")[[1]], rast)
r <- match_extent(r)
r <- rast(r)

cli_progress_step("Aggregate raster")

# if(submit$stat == "sd") {
#  r <- app(r, fun = function(x){x ^ 2})
# }

r <- app(r, "sum", na.rm = T)

# out put pfad haengt jetzt und taxonomischer klasse ab
cli_progress_step("Rename raster")
if(submit$stat == "sd"){
  submit$stat <- "var"
}


names(r) <- paste0(submit$type, "-", submit$taxClass, "_", submit$period, "0000_30arcSec_", submit$lulcID, "_", submit$stat)

writeRaster(r, paste0(outPath, "lulc/", submit$type, "/", submit$taxTree, "/", names(r), ".tif"))

cli_process_done()

cli_h1("Closing tax aggregation")
