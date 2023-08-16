## ---------------------------
##
## Script name: 00_preprocess_vrt_lulc.R
##
## Purpose of script: create vrt files for every year and lulc class
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

cli_h1("Initializing lulc vrt creation")

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
    usage       = "Rscript %prog [options] fileInd",
    option_list = options,
    description = "",
  )

  cli <- parse_args(parser, positional_arguments = 1)

  # assign shortcuts
  # ----------------
  line <- cli$options$line
  verbose <- cli$options$verbose
  fileInd <- cli$args[1]


  # time
  # ----
  tic()


  # read files
  # ----------
  lulcFile <- read_tsv(paste0(slmPath, "preprocess-vrt-lulc-setup.txt"))[fileInd,] # read only the grouped files

  paths <- lulcFile %>%
    separate_rows(paths, sep = " ") %>%
    pull(paths)

  # build VRT
  # ---------
  name = paste0("lulc-brazil_", lulcFile$group)
  vrt(paths, paste0(stage1, "lulc/", name, ".vrt"))

cli_h1("Closing lulc vrt creation")
