## ---------------------------
##
## Script name: 00_preprocess_baseline_aoh.R
##
## Purpose of script: calculate baseline aoh based on range maps (intersected with Brazil)
##
## Author: Peter Pothmann
##
## Date Created: 04-12-2023
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

cli_h1("Initializing baseline aoh calculation")

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
  usage       = "Rscript %prog [options] speciesName",
  option_list = options,
  description = "",
)

cli <- parse_args(parser, positional_arguments = 1)

# shortcuts
# ---------
line <- cli$options$line
verbose <- cli$options$verbose

subPrep <- cli$args[1]

speciesName <- str_split(subPrep, pattern = "_")[[1]][1]
taxID <- str_split(subPrep, pattern = "_")[[1]][2]

cli_h3(paste0("Now processing species: ", speciesName))

# start time
# ----------
tic()

# read al1
# --------
cli_progress_step("Import admin. level 1")
al1 <- vect(paste0(stage1, "al/al.gpkg"), layer = "al1")

# read update names
# -----------------

# some names are outdated, i updated by hand using the following table
cli_progress_step("Update Names")
updateBinomial <- read_csv(paste0(metaPath, "update-taxon-names.csv"))

if(any(speciesName == updateBinomial$binomial)){
speciesName <- updateBinomial %>%
  filter(binomial == speciesName) %>%
  pull(rangeName)
}

if(speciesName == "FALSE"){
  cli_inform("No available range map")
  # write obs table
  # ---------------
  cli_progress_step("Write obs table")
  tme <- toc()

  write_csv(
    tibble(
      taxonID = taxID,
      date = Sys.time(),
      process = "00_preprocess_baseline_aoh.R",
      lengthAoh = NA_integer_,
      lengthCaoh = NA_integer_,
      Pscore = NA_integer_,
      runTimeSec = tme$toc - tme$tic,
      completion = FALSE,
      err = "No range map available"),
    file = paste0(comPath, "obs-aoh.csv"),
    append = TRUE)

} else {

  # read and query range maps
  # -------------------------
  cli_progress_step("Import needed range geometries")
  sql_query <- paste0("SELECT * FROM animalia WHERE binomial in ('", paste(speciesName, collapse = "','"),"')")
  range <- st_read("/gpfs1/data/idiv_meyer/00_data/processed/rangeMap/rangeMap-animalia_20220000_2deg.sqlite", query = sql_query, quiet = T)
  # range = st_read("I:/MAS-data/00_data/processed/rangeMap/rangeMap-animalia_20220000_2deg.sqlite", query = sql_query, quiet = T)

  # calculate baseline area in Brazil for each species
  # --------------------------------------------------

  cli_progress_step("Calculate area")
  area <- tryCatch({
    range <- vect(range)
    range <- crop(range, al1)
    range$area <- expanse(range, unit = "ha")
    area <- tibble(
      taxonID = taxID,
      binomial = speciesName,
      baseline_area = sum(range$area))},

    error = function(e){ # write to obs table if geometries are not valid
      tme <- toc()
      write_csv(
        tibble(
          taxonID = taxID,
          date = Sys.time(),
          process = "00_preprocess_baseline_aoh.R",
          lengthAoh = nrow(range),
          lengthCaoh = NA_integer_,
          Pscore = NA_integer_,
          runTimeSec = tme$toc - tme$tic,
          completion = FALSE,
          err = "No valid geometry"),
        file = paste0(comPath, "obs-aoh.csv"),
        append = TRUE)
      return(NULL)
    })

  if(is.null(area)){
    cli_inform("No valid geometry")
  } else{

    if(area$baseline_area == 0){

      cli_inform("No habitat in Brazil")
      # write obs table
      # ---------------
      cli_progress_step("Write obs table")
      tme <- toc()

      write_csv(
        tibble(
          taxonID = taxID,
          date = Sys.time(),
          process = "00_preprocess_baseline_aoh.R",
          lengthAoh = nrow(range),
          lengthCaoh = NA_integer_,
          Pscore = NA_integer_,
          runTimeSec = tme$toc - tme$tic,
          completion = FALSE,
          err = "No habitat in Brazil"),
        file = paste0(comPath, "obs-aoh.csv"),
        append = TRUE)

    } else {

      # append output
      # -------------
      cli_progress_step("Write output")

      if(!file.exists(paste0(stage1, "aoh/baseline-area.csv"))){

        write_csv(area, paste0(stage1, "aoh/baseline-area.csv"))

      } else {

      write_csv(area, paste0(stage1, "aoh/baseline-area.csv"), append = TRUE)

      }

      # write obs table
      # ---------------
      cli_progress_step("Write obs table")
      tme <- toc()

      write_csv(
        tibble(
          taxonID = taxID,
          date = Sys.time(),
          process = "00_preprocess_baseline_aoh.R",
          lengthAoh = nrow(range),
          lengthCaoh = NA_integer_,
          Pscore = NA_integer_,
          runTimeSec = tme$toc - tme$tic,
          completion = TRUE,
          err = NA_character_),
        file = paste0(comPath, "obs-aoh.csv"),
        append = TRUE)
    }
  }
}

cli_progress_done()

cli_h1("Closing baseline aoh calculation")
