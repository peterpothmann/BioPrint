## ---------------------------
##
## Script name: 00_preprocess_seg_lulc.R
##
## Purpose of script: preprocess lulc data from MapBiomas, select needed years, split in classes
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

cli_h1("Initiating lulc preprocess")

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

  outDir <- paste0(stage1, "lulc/tif/")

  # import lulc data
  # ----------------
  tic()
  cli_progress_step(msg = paste0("Importing ", str_split(lulcFilePath, pattern = "/")[[1]][7]))

  lulc <- rast(lulcFilePath)
  rasName <- names(lulc)


  # import al level data
  #---------------------
  cli_progress_step(msg = "Importing administrative level data")

  al3 <- st_read(paste0(stage1, "al/al.gpkg"), layer = "al3")

  # import template
  # ---------------
  template <- rast(paste0(metaPath, "template.tif"))


  # segregate land use classes and clip with al3
  # --------------------------------------------
  cli_progress_step("Prepare lulc")

  lulc <- seg_lulc(lulc, outDir = outDir)

  cli_process_done()

  # obs table
  # ---------
  tme <- toc()
  write_csv(tibble(
    file = names(lulc),
    date = Sys.time(),
    process = "00_preprocess_lulc.R",
    runTimeSec = tme$toc - tme$tic,
    completion = TRUE),
    append = TRUE,
    file = paste0(comPath, "obs-lulc.csv"))

cli_h1(paste0("Closing lulc split for ", names(lulc)))
