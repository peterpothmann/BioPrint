## ---------------------------
##
## Script name: 00_preprocess_aoh.R
##
## Purpose of script: preprocess area of habitat data, clip aoh with al1, change aoh values if they exceed pixel area to maximum pixel area
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
## Notes: # i can skip the ones that have no baseline habitat (not implemented yet)
##
## ---------------------------

cli_h1("Initiating aoh preprocess")

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

# time
# ----
tic()

# import aoh data
# ---------------
cli_progress_step("Read submit file and aoh")
submit <- read_tsv(paste0(slmPath, "preprocess-aoh-setup.txt"), col_types = "ccd")[submitInd,]

aoh <- rast(submit$paths)

# import al 1
# -----------
cli_progress_step(msg = "Import administrative level 1")
al1 <- st_read(paste0(stage1, "al/al.gpkg"), layer = "al1")

cli_process_done()

# read pixel area
# ---------------
pixelArea <- rast(paste0(inPath, "pixelArea/pixelArea-hectares_20190000_1km.tif"))

# clip with extent of Brazil (custom function)
# --------------------------
aoh <- intersect_aoh_al(aoh, al1)

if(is.null(aoh)){ # dont write output if aoh has no intersection with al1

  cli_h1(paste0("Closing aoh preprocess for ", str_split(names(aoh), pattern = "/")[[1]][8]))

} else{

  # crop pixelArea
  # --------------
  cli_progress_step("Crop pixel area with aoh")
  pixelArea <- crop(pixelArea, aoh)
  pixelArea <- mask(pixelArea, aoh)

  # make aoh values > pixelArea the size of the pixelArea (Assume: seasonal habitat don't have impacts)
  # -----------------------------------------------------
  cli_progress_step("Make aoh values > pixelArea = pixelArea and Write tif")
  aoh <- ifel(aoh > pixelArea, pixelArea, aoh)

  # check if aoh > basline area, if TRUE remove
  # -------------------------------------------
  if(global(aoh, "sum", na.rm = T)[1,1] > submit$baseline_area){

    cli_progress_step("Error: aoh > baseline area")

    if(!file.exists(paste0(metaPath, "aoh-biggger-baseline.csv"))){

      write_csv(tibble(
        taxonID = submit$taxonID),
      paste0(metaPath, "aoh-bigger-baseline.csv"))

    } else{

      write_csv(tibble(
        taxonID = submit$taxonID),
      paste0(metaPath, "aoh-bigger-baseline.csv"),
      append = TRUE)
    }

    # set up control tibble
    # ---------------------
    cli_progress_step(msg = "Write obs table")
    tme <- toc()

    write_csv(tibble(
      taxonID = names(aoh),
      date = Sys.time(),
      process = "00_preprocess_aoh.R",
      lengthAoh = length(aoh),
      lengthLaoh = NA_integer_,
      runTimeSec = tme$toc- tme$tic,
      completion = FALSE,
      err = "aoh > baseline area"),
      paste0(comPath, "obs-aoh.csv"),
      append = TRUE)

  } else{

    if(!file.exists(paste0(stage1, "aoh/aoh-area.csv"))){

      write_csv(
        tibble(
          taxonID = submit$taxonID,
          year = str_sub(str_split(names(aoh), "_")[[1]][2], 1, 4),
          aoh_area = global(aoh, "sum", na.rm = T)[1,1]),
        file = paste0(stage1, "aoh/aoh-area.csv"),
        append = FALSE)

    } else{

      write_csv(
        tibble(
          taxonID = submit$taxonID,
          year = str_sub(str_split(names(aoh), "_")[[1]][2], 1, 4),
          aoh_area = global(aoh, "sum", na.rm = T)[1,1]),
        file = paste0(stage1, "aoh/aoh-area.csv"),
        append = T)

    }

    # write tif
    # ---------
    writeRaster(aoh,
                 filename = paste0(stage1, "aoh/tif/", names(aoh), ".tif"),
                 gdal=c("COMPRESS=DEFLATE"))

    # create a VRT
    # ------------
    cli_progress_step(msg = "Write vrt")

    vrt(paste0(stage1, "aoh/tif/", names(aoh), ".tif"),
        filename = paste0(stage1, "aoh/", names(aoh), ".vrt"))


    # set up control tibble
    # ---------------------
    cli_progress_step(msg = "Write obs table")
    tme <- toc()

    write_csv(tibble(
      taxonID = names(aoh),
      date = Sys.time(),
      process = "00_preprocess_aoh.R",
      lengthAoh = length(aoh),
      lengthLaoh = NA_integer_,
      runTimeSec = tme$toc- tme$tic,
      completion = TRUE,
      err = NA_character_),
      paste0(comPath, "obs-aoh.csv"),
      append = TRUE)

    cli_process_done()
  }
}
cli_h1(paste0("Closing aoh preprocess for ", names(aoh))
