## ---------------------------
##
## Script name: 05_dp_aggregation.R
##
## Purpose of script: aggregate the dp model runs for each species
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

cli_h1("Inializing dp aggregation")

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
outPath <- paste0(stage4, "dp/")

# csv data
# --------
if(!file.exists(paste0(stage4, "dp/p-scores.csv"))){

pScores <- read_csv(paste0(stage3, "dp/p-scores.csv"), col_types = "cccd")

sortOut <- pScores %>% filter(is.na(p)) %>%
  distinct(taxonID)

pScores <- pScores %>%
  anti_join(., sortOut, by = "taxonID")

p <- pScores %>%
  group_by(taxonID, year) %>%
  summarise(var = var(p, na.rm = T),
            p = mean(p, na.rm = T))

write_csv(p, paste0(stage4, "dp/p-scores.csv"))
}

# read submit file and get the paths
cli_progress_step("Read submit file")
submit <- read_tsv(paste0(slmPath, "dp-aggregation-setup.txt")) %>%
  filter(submitID == submitInd) %>%
  pull(paths)

# read raster
cli_progress_step("Read dp raster")
r <- rast(submit)

cli_progress_done()

# aggregate the raster
aggregate_raster(r, outDir = outPath, lulcImpactAggregation = FALSE)

cli_h1("Closing dp aggregation")
