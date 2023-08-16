## ---------------------------
##
## Script name: 00_preprocess_rasterize_yield.R
##
## Purpose of script: rasterize yield data
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
## Notes: i dont have to do this for the baseline year, but i did it to put on shiny app
##
##
## ---------------------------

cli_h1("Initialising rasterize yield")

if(place == "cluster"){
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
    usage       = "Rscript %prog [options] lulcFileS1",
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

  # output dir
  # ----------
  outDir <- paste0(stage1, "yield/tif/prep/")

  # import lulc
  # -----------
  cli_progress_step(msg = "Importing data")
  lulc <- rast(lulcFilePath)

  # import yieldGap
  # ---------------
  yieldGap <- st_read(paste0(stage1, "yield/vct/yield-gap.gpkg"))

  # import al3
  # ----------
  al3 <- st_read(paste0(stage1, "al/al.gpkg"), layer = "al3")

  # import yield translation
  # ------------------------
  yieldTranslation <- read_csv(paste0(metaPath, "yield-translation.csv"))

  # lulcID with no intensity
  # ------------------------
  noInt <- yieldTranslation %>%
    filter(ontoName == "noMatch")

  # find intersections grid and al3 & filter
  # ----------------------------------------
  cli_progress_step("Filter and intersect with al3")
  al3 <- al3 %>%
    mutate(intersection = as.logical(unlist(relate(lulc, vect(al3), relation = "intersects")))) %>%
    filter(intersection == TRUE) %>%
    split(., seq(nrow(.)))

  cli_process_done()

  # rasterize yield gap
  # -------------------
  map(al3, .f = rasterize_yield, lulc, yieldGap, noInt = noInt, outDir = outDir)

  cli_progress_done()
}

cli_h1("Closing rasterize yield")
