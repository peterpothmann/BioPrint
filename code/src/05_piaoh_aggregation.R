## ---------------------------
##
## Script name: 05_piaoh_aggregation.R
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

cli_h1("Inializing caoh aggregation")

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
outPath <- paste0(workPath, "00_data/04_stage/piaoh/tif/")


# aggregate csv data
# ------------------

if(!file.exists(paste0(workPath, "00_data/04_stage/picaoh/piaoh.csv"))){
  cli_progress_step("Aggregate csv")

  contri <- read_csv(paste0(workPath, "00_data/03_stage/piaoh/piaoh.csv"), col_types = "cccccd")

  contri <- contri %>%
    rowwise() %>%
    mutate(period = str_sub(period, 1, 4)) %>%
    group_by(taxonID, period, type, lulcID, paraID) %>%
    summarise(delta_p_contri = sum(delta_p_contri, na.rm = T)) %>%
    group_by(taxonID, period, type, lulcID) %>%
    summarise(var = var(delta_p_contri, na.rm = T),
              delta_p_contri = mean(delta_p_contri, na.rm = T))

  write_csv(contri, paste0(workPath, "00_data/04_stage/piaoh/piaoh.csv"))
}

# read submit file and get the paths
cli_progress_step("Read submit file")
submit <- read_tsv(paste0(slmPath, "piaoh-aggregation-setup.txt"), col_types = "cccc") %>%
  filter(submitID == submitInd) %>%
  pull(paths) %>%
  str_split(., ";")


# read raster
cli_progress_step("Read dp raster")
r <- rast(submit[[1]])

cli_progress_done()

# aggregate the raster
aggregate_raster(r, outDir = outPath, lulcImpactAggregation = TRUE)


cli_h1("Closing piaoh aggregation")
