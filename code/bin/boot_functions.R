## ---------------------------
##
## Script name: 00_boot_functions.R
##
## Purpose of script: compendium of all functions
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

read_al <- function(al, varFilter, correction){
  cli_h2(paste0("Processing ", al))

  cli_progress_step(paste0("Importing ", al))
  tmp <- st_read(dsn = paste0(inPath, "al/Brazil.gpkg"), layer = al, quiet = TRUE)

  cli_progress_step(paste0("Filtering ", al))
  tmp <- tmp %>% filter(geoID == varFilter)

  if(correction & al == "al3"){

    cli_progress_step(paste0("Correcting ", al))

    # split the troublemaker polygon into two
    sp <- tmp %>%
      filter(gazID == ".002.004.003.024.129") %>%
      st_cast(., "POLYGON")

    # remove it from tmp and add the one not in amazonia
    tmp <- tmp %>%
      filter(gazID != ".002.004.003.024.129") %>%
      bind_rows(., st_cast(sp[1,], "MULTIPOLYGON"))

    sp <- sp[2,] %>%
      mutate(gazID = ".002.004.003.004.061", # make new ID, one higher than the highset 60
             gazName = "Brazil.Amazonas.ItapirangaAM") %>%  # set name to near polygon, to get its intensity
      st_cast(., "MULTIPOLYGON")

    tmp <- bind_rows(tmp, sp) %>%
      arrange(gazID)

    rownames(tmp) <- seq_len(nrow(tmp))

    # gazID .002.004.003.024.129 rename to the one with the highest in amazonas
    # gazName wird zu Brazil.Amazonas.Tabatinga (gibt es aber schon, wird so gamacht um yield zu verarbeiten)
    #
  }

  if(correction & al == "al2"){
    # polygon mit obiger ID in die region amazonas verschieben
    # bennen wie die anderen polygone in der Region

    # st_cast dann entfernen und wieder hinzu fuegen

    sp <- tmp %>%
      filter(gazName == "Brazil.Santa Catarina") %>%
      st_cast(., "POLYGON")

    ama <- tmp %>%
      filter(gazName == "Brazil.Amazonas") %>%
      st_cast(., "POLYGON")

    sub <- sp[44,] %>%   # this i want to add to Amazonia
      mutate(gazID = ama$gazID,
             gazName = ama$gazName,
             external = ama$external) %>%
      bind_rows(., ama) %>%
      group_by(gazID, gazName, gazClass, match, external, geoID) %>%
      summarise() # now i have the new amazonia

    tmp <- tmp %>%
      filter(gazName != "Brazil.Amazonas") %>%
      bind_rows(., sub)

  }

  cli_progress_step(paste0("Exporting ", al))
  st_write(tmp, dsn = paste0(stage1, "al/al.gpkg"), layer = al, layer_options = "OVERWRITE=true", quiet = TRUE, delete_layer = TRUE)
  cli_progress_done()
  return(tmp)
}

build_vrt <- function(files, outVrt, name){

  input <- str_split(files$paths, pattern = " ")[[1]] # list of lulc TIF files in stage 1 folder

  cli_progress_step(msg = paste0("Building VRT for ", name, "-", files$group),
                    msg_done = paste0("Created VRT for ", name, "-", files$group))

  nameVrt <- paste0(name, "-", str_split(files$group, pattern = ".tif")[[1]][1], ".vrt") # name

  vrt(x = input, filename = paste0(outVrt, nameVrt), overwrite = TRUE) # create vrt

  cli_process_done()

}

# function to intersect aoh with administrative level 1
intersect_aoh_al <- function(aoh, al1){ # brauche ich die Funktion noch?
  cli_progress_step(msg = "Intersecting aoh with administrative level 1",
                    msg_done = "Intersects",
                    msg_failed = "Disjoint")
  aoh <- project(aoh, "epsg:4326")

  if(relate(aoh, vect(al1), relation = "intersects")){
    crp <- crop(aoh, ext(al1))
    crp <- mask(crp, al1)
    crp <- trim(crp)
    cli_process_done()

    return(crp)

  } else{
    tme <- toc()
    write_csv(
      tibble(
        taxonID = names(aoh),
        date = Sys.time(),
        process = "00_preprocess_aoh.R",
        lengthAoh = NA_integer_,
        lengthLaoh = NA_integer_,
        runTimeSec = tme$toc - tme$tic,
        completion = FALSE,
        err = "No intersection with al1"),
      file = paste0(comPath, "obs-aoh.csv"),
      append = TRUE)
    cli_process_failed()

    tmp <- NULL
    return(tmp)
  }
}

# function to check if all values are NA or 0
check_0_NA <- function(aoh){
  if(all(is.na(values(aoh)))){
    v <- append(v, TRUE)
  } else{
    v <- append(v, FALSE)
  }
  return(v)
}

# function to rasterize the yields
rasterize_yield <- function(al3, lulc, yieldGap, noInt, outDir){
  cli_alert_info("Rasterizing yield")
  cli_progress_step(paste0("Intersect with al3: ", al3$gazID))
  ras <- crop(lulc, al3$geom)
  crp <- crop(vect(al3$geom), ras)
  ras <- mask(ras, crp, touches = FALSE)

  cli_progress_step("Make NA to 0")
  ras <- ifel(is.na(ras), 0, ras)
  cli_progress_done()

  if(all(unique(ras) == 0)){
    cli_alert_info("All values of lulc grid within al3 are 0 or NA")

    write_csv(
      tibble(
        file = names(ras),
        date = Sys.time(),
        process = "00_preprocess_rasterize_yield.R",
        matchLoca = FALSE,
        matchInt = FALSE,
        err = "No values of lulc within lulc grid"),
      file = paste0(comPath, "obs-yield.csv"),
      append = TRUE)

  } else {

    lulcIDFil <- str_extract(str_split(names(lulc), pattern = "_")[[1]][5], pattern = "[0-9]+") # checken
    yearFil <- substr(str_split(names(lulc), pattern = "_")[[1]][2], 1, 4)

    # no intensiy data
    # ----------------
    if(any(lulcIDFil == c(noInt$lulcID))){ # if any classes match no Intensity classes

      cli_alert_info("No intensity data")

      ras <- ifel(ras != 0, 0, ras) # make it 0 intensity

      names(ras) <- paste0("yieldGap-", str_extract(str_split(names(lulc), pattern = "-")[[1]][2], pattern = "[^_]+"), "_", al3$gazID, "_", paste(str_split(names(lulc), pattern = "_")[[1]][2:3], collapse = "_"), "_lulc_", lulcIDFil)
      writeRaster(ras, paste0(outDir, names(ras), ".tif"))

      write_csv(
        tibble(
          file = names(ras),
          date = Sys.time(),
          process = "00_preprocess_rasterize_yield.R",
          matchLoca = FALSE,
          matchInt = FALSE,
          err = NA_character_),
        file = paste0(comPath, "obs-yield.csv"),
        append = TRUE)

    } else{

      # with intensity data
      # -------------------
      cli_alert_info(paste0("With intensity data"))

      tmp <- yieldGap %>%
        filter(gazID == al3$gazID &
                 lulcID == lulcIDFil &
                 year ==  yearFil) # filter gazID

      # if data has 0 rows (lulc not contained in yield)
      # ------------------------------------------------
      if(nrow(tmp) == 0){

        cli_alert_info(paste0("No matching value in yield data"))

        ras <- ifel(ras != 0, 0, ras) # make it 0 intensity
        names(ras) <- paste0("yieldGap-", str_extract(str_split(names(lulc), pattern = "-")[[1]][2], pattern = "[^_]+"), "_", al3$gazID, "_", paste(str_split(names(lulc), pattern = "_")[[1]][2:3], collapse = "_"), "_lulc_", lulcIDFil)
        writeRaster(ras, paste0(outDir, names(ras), ".tif"))

        write_csv(
          tibble(
            file = names(ras),
            date = Sys.time(),
            process = "00_preprocess_rasterize_yield.R",
            matchLoca = FALSE,
            matchInt = TRUE,
            err = "Match intensity but no matching value in yield data"),
          file = paste0(comPath, "obs-yield.csv"),
          append = TRUE)

      } else{

        cli_alert_info("Match with yield data")

        cli_alert_info("Crop and mask lulc")
        lulcTmp <- crop(lulc, ras)
        lulcTmp <- mask(lulcTmp, ras)

        cli_alert_info("Calculate yield shares")
        ras <- ifel(ras != 0, tmp$yieldGap * ras, ras) # assign the yield and multiply with the covered area of this lulc

        cli_alert_info("Write output")
        names(ras) <- paste0("yieldGap-", str_extract(str_split(names(lulc), pattern = "-")[[1]][2], pattern = "[^_]+"), "_", al3$gazID, "_", paste(str_split(names(lulc), pattern = "_")[[1]][2:3], collapse = "_"), "_lulc_", lulcIDFil)
        writeRaster(ras, paste0(outDir, names(ras), ".tif"))

        write_csv(
          tibble(
            file = names(ras),
            date = Sys.time(),
            process = "00_preprocess_rasterize_yield.R",
            matchLoca = TRUE,
            matchInt = TRUE,
            err = NA_character_),
          file = paste0(comPath, "obs-yield.csv"),
          append = TRUE)
      }
    }
  }
}

# function to split lulc data into smaller grids
grid_lulc <- function(grid, lulc, outPath){

  cli_progress_step(paste0("Cliping with grid ", grid$gridID))

  tmp <- crop(lulc, vect(grid$geom))

  if(all(values(tmp) == 0)){ # skip if all values are NA

    cli_process_done()
    cli_inform("All values are 0")

  } else{

  # fill the grid with 0 values, other wise the aggregating will start not correct
  cli_progress_step("Write output")

  names(tmp) <- paste0(str_split(names(lulc), pattern = "_")[[1]][1], grid$gridID, "_", str_split_fixed(names(lulc), pattern = "_", n = 2)[,2])
  writeRaster(tmp, paste0(outPath, names(tmp), ".tif"), gdal = c("COMPRESS=DEFLATE"))
  vrt(paste0(outPath, names(tmp), ".tif"), paste0(outPath, names(tmp), ".vrt"))

  cli_progress_done()
  }
}

# function to set x to NULL if all values are o or NA
remove_elements <- function(x){

  # make 0 values NA
  x <- ifel(x == 0 , NA, x)

  if(all(is.na(values(x)))){
    x <- NULL
  } else {
    x
  }
}

# function to calculate the yield spill over
yield_spill <- function(yield, spillParameter, npixel){
  surrSpillAmount <- sum(yield[-5] * spillParameter / npixel, na.rm = T)
  focusSpillAmount <- yield[5] * spillParameter
  newYield <-  yield[5] + surrSpillAmount - focusSpillAmount
  return(newYield)
}

# function to adjust the habitat with intensification impacts
adjust_habitat <- function(submit, npixel, outDir){

  cli_h1(paste0("Now: ", submit$taxonID, " year: ", submit$year, " paraID: ", submit$paraID))

  cli_progress_step("Set up short cuts")
  yield <- submit$yieldPath
  aoh <- submit$aohPath
  spillParameter <- submit$spillParameter
  responseParameter <- submit$responseParameter
  paraID <- submit$paraID

  cli_progress_step("Read aoh and yield raster")
  yield <- rast(yield)
  aoh <- rast(aoh)

  cli_progress_step("Crop yield and aoh")
  aoh <- crop(aoh, yield)
  yield <- crop(yield, aoh)

  tifName <- paste0("i", names(aoh), "_", paraID)

  if(global(aoh, "sum", na.rm = T)[1,1] == 0){
    cli_progress_step("All values of aoh are 0")

    names(aoh) <- tifName
    writeRaster(aoh, paste0(outDir, tifName, ".tif"), gdal = c("COMPRESS=DEFLATE"))

  } else {

    if(submit$year == 1996){ # i have no intensity data for the year 1996
      cli_progress_step("Year is 1996 - no intensity data")

      cli_progress_step("Rename")
      names(aoh) <- tifName

      cli_progress_step("Make values 0")
      tmp <- aoh
      values(tmp) <- 0
      cli_progress_step("Mask and write output")
      mask(tmp, aoh, filename = paste0(outDir, names(aoh), ".tif"))

    } else{

      # calculate the original aoh loss
      aohLossOrig <- (1 - yield^responseParameter) * aoh - aoh

      # calculate the focus spill amount
      cli_progress_step("Calculate the focus spill amount")
      focusSpillAmount <- values(yield) * spillParameter / npixel # spill amount of every pixel

      # calculate the new adjusted yield
      cli_progress_step("Calculate the new adjusted yield")
      adYield <- focal(yield, w = 3, fun = yield_spill, npixel = npixel, spillParameter = spillParameter) # adjust the yield
      propYield <- as_tibble(focalValues(adYield)) # make matrix

      # calculate proportional yield of spill over
      cli_progress_step("Calculate the proportion of spill over yield")
      propYield <- as.matrix(focusSpillAmount / propYield)

      # calculate the habitat loss with new yield (species response)
      cli_progress_step("Calculte habitat loss - species response")
      aohLoss <- (1 - adYield^responseParameter) * aoh - aoh # calculate the impact, negative results
      aohLossV <- focalValues(aohLoss) # make matrix

      # get the proportion area of lost aoh
      cli_progress_step("Calculte proportion of habitat loss caused by spill over")
      propAoh <- propYield * aohLossV
      propAoh[is.na(propAoh)] <- 0 # make NA 0

      # summarize the caused spill over impact
      cli_progress_step("Summarize the impact")
      impact <- rowSums(propAoh[,-5]) # don't ignore NA --> decreases the length of the vector

      # make it as a matrix
      cli_progress_step("Rasterize the impact")
      impact <- matrix(impact, ncol = ncol(aohLoss), nrow = nrow(aohLoss), byrow = T)

      # make a raster form the matrix
      impact <- rast(impact, crs = "EPSG:4326", extent = ext(aohLoss))

      # calculate changes between original and spill over adjusted, but can be positive if spill yield > incoming yield spill, dont add those changes
      aohLossDif <- abs(aohLossOrig) - abs(aohLoss)

      # remove positive changes
      aohLossDif <- ifel(aohLossDif > 0, 0, aohLossDif)

      # reduce the negative impacts, by the spill over impacts
      impact <- sum(impact, abs(aohLossDif), na.rm = T)

      # add the onsite effects
      impact <- sum(aohLoss, impact, na.rm = T)

      # mask with aoh and write output
      cli_progress_step("Mask raster and write")
      names(impact) <- tifName
      impact <- mask(impact, aohLoss,
                      filename = paste0(outDir, names(impact), ".tif"),
                      gdal = c("COMPRESS=DEFLATE"))
    }
  }
}

# function to calculate persistence scores
p_score <- function(submit, extinctionParameter, dpDir){
  cli_h3(paste0("Now: taxonID: ", submit$taxonID, " period: ", submit$period, " paraID: ", submit$paraID))

  # read aoh
  cli_progress_step("Read aoh")
  aoh1 <- rast(submit$aohP1)
  aoh2 <- rast(submit$aohP2)

  # read iaoh
  cli_progress_step("Read iaoh")
  iaoh1 <- rast(submit$iaohP1)
  iaoh2 <- rast(submit$iaohP2)

  if(ext(iaoh1) != ext(iaoh2)){ # match extent if needed
  iaoh1 <- match_extent(list(iaoh1, iaoh2))[[1]]
  iaoh2 <- match_extent(list(iaoh1, iaoh2))[[2]]
  }

  # adjust aoh with iaoh
  cli_progress_step("Match aoh and iaoh extents")
  aoh1 <- match_extent(list(iaoh1, aoh1))
  aoh2 <- match_extent(list(iaoh2, aoh2))

  cli_progress_step("Adjust aoh with iaoh")
  jaoh1 <- sum(aoh1[[1]], aoh1[[2]], na.rm = T)
  jaoh2 <- sum(aoh2[[1]], aoh2[[2]], na.rm = T)

  # calculate p scores
  cli_progress_step("Proportional overall p scores")
  p1 <- (global(jaoh1, fun = "sum", na.rmm = TRUE)[1,1] / submit$baseline_area) ^ extinctionParameter
  p2 <- (global(jaoh2, fun = "sum", na.rm = TRUE)[1,1] / submit$baseline_area) ^ extinctionParameter

  # delta p
  cli_progress_step("Delta p")

  if(is.na(p1) | is.na(p2)){
    dp <- NA
  } else{
    dp <- p2 - p1
  }

  # delta aoh
  cli_progress_step("Delta aoh")
  aohChange <- jaoh2 - jaoh1

  # absolute change
  absChange <- global(aohChange, fun = "sum", na.rm = TRUE)

  # contribution of one changed habitat unit to p change
  cli_progress_step("Contribution of one unit habitat change to p change")

  if(dp == 0 | is.na(dp)){ # if delta p = 0 (no habitat change) then the contribution of one unit habitat is 0
    if(is.na(dp)){
      oneUnitContri <- NA
    } else{
      oneUnitContri <- 0
    }
  } else{
    oneUnitContri <- abs(dp / absChange)
    oneUnitContri <- oneUnitContri[1,1]
  }

  # make p spatial
  cli_progress_step("Make delta p spatial")
  pchange <- aohChange * oneUnitContri # this raster gives me the changed pixel with the associated loss in p scores

  # rename p
  names(pchange) <- paste0("dp-", str_split(names(iaoh2), pattern = "-")[[1]][2])

  # write p score to csv
  if(!file.exists(paste0(dpDir, "p-scores.csv"))){ # create file if it not exist

    cli_progress_step("Write p scores")
    tibble(p = c(p1, p2),
           year = c(submit$yearP1, submit$yearP2)) %>%
      rowwise() %>%
      mutate(taxonID = submit$taxonID,
             paraID = submit$paraID) %>%
      select(taxonID, year, paraID, p) %>%
      write_csv(., file = paste0(dpDir, "p-scores.csv"))

  } else {

  cli_progress_step("Write p scores")
    tibble(p = c(p1, p2),
           year = c(submit$yearP1, submit$yearP2)) %>%
    rowwise() %>%
    mutate(taxonID = submit$taxonID,
           paraID = submit$paraID) %>%
    select(taxonID, year, paraID, p) %>%
    write_csv(., file = paste0(dpDir, "p-scores.csv"), append = TRUE)
  }

  if(!file.exists(paste0(dpDir, "p-contribution-oneUnit-habitat.csv"))){ # create file if it not exists

      tibble(taxonID = submit$taxonID,
             period = submit$period,
             paraID = submit$paraID,
             oneUnitContri = oneUnitContri) %>%
      select(taxonID, period, paraID, oneUnitContri) %>%
      write_csv(., file = paste0(dpDir, "p-contribution-oneUnit-habitat.csv"))

  } else{

  tibble(taxonID = submit$taxonID,
         period = submit$period,
         paraID = submit$paraID,
         oneUnitContri = oneUnitContri) %>%
    select(taxonID, period, paraID, oneUnitContri) %>%
    write_csv(., file = paste0(dpDir, "p-contribution-oneUnit-habitat.csv"), append = TRUE)
  }

  cli_process_done()

  # write raster
  writeRaster(pchange, filename = paste0(dpDir, "tif/", names(pchange), ".tif"))

  cli_progress_done()

  return(oneUnitContri)
}

# function to write lulc impacts to csv file
write_lulc_contribution <- function(x, type, filename){
  p <- global(x, fun = "sum", na.rm = TRUE)

  if(file.exists(filename)){ # append rows if file exists
    write_csv(
      tibble(
        taxonID = str_extract(str_split(names(x), "-")[[1]][2], "[^_]+"),
        period = str_sub(str_split(names(x), "_")[[1]][2], 1, 4),
        paraID = str_split(names(x), "_")[[1]][4],
        lulcID = str_split(names(x), "_")[[1]][6],
        type = type,
        delta_p_contri = p[1,1]),
      append = TRUE,
      file = filename)

  } else { # create file if it not exist

    write_csv(
      tibble(
        taxonID = str_extract(str_split(names(x), "-")[[1]][2], "[^_]+"),
        period = str_sub(str_split(names(x), "_")[[1]][2], 1, 4),
        paraID = str_split(names(x), "_")[[1]][4],
        lulcID = str_split(names(x), "_")[[1]][6],
        type = type,
        delta_p_contri = p[1,1]),
      file = filename)
  }
}

# function to attribute the persistence score changes
p_attribution <- function(lulc, aoh, oneUnitContri, paraID, type, dir, csvName){  # die pfade muss ich machen sind jetzt alle in einem Ordner: dir

  # calculate the sum of lulc
  # -------------------------
  cli_progress_step("Calculate sum of changed lulc/yield")
  lulcSum <- match_extent(lulc)
  lulcSum <- sum(rast(lulcSum), na.rm = T)

  # calculate the proportion of each lulc
  # -------------------------------------
  cli_progress_step("Calculate proportion of changed lulc/yield")
  lulcProp <- map(lulc,
                  function(x, y) {
                    y <- crop(y, x)
                    x <- ifel(y == 0, 0, x / y)
                    return(x)},
                  y = lulcSum)

  # attribute the aoh change
  # ------------------------
  cli_progress_step("Calculate habitat changes")
  partAoh <- map(lulcProp,
                 function(x, y) {
                   x <- match_extent(list(x, y))
                   x <- x[[1]] * x[[2]]
                   return(x)},
                 y = aoh)

  # attribute the p change
  # ----------------------
  cli_progress_step("Calculate changes in p scores")
  partP <- map(partAoh, function(x, y) {x * y}, oneUnitContri)

  # remove lulc classes where all contributions (pixel values) are 0
  partP <- map(partP, remove_elements)  %>%
    discard(., is.null)

  # rename
  # ------
  cli_progress_step("Rename raster")

  if(type == "iaoh"){

    partP <- map(partP, function(x, caoh){
      names(x) <- paste0("dP", type, "-", str_split(names(caoh), pattern = "-")[[1]][2], "_lulc_", str_split(names(x), "_")[[1]][5])
      return(x)
    }, aoh)

  } else{

    partP <- map(partP, function(x, caoh){
      names(x) <- paste0("dP", type, "-", str_split(names(caoh), pattern = "-")[[1]][2], "_", paraID, "_lulc_", str_split(names(x), "_")[[1]][5])
      return(x)
    }, aoh)

  }

  # write p attribution to csv
  # --------------------------
  cli_progress_step("Write overall values to csv")
  map(partP, write_lulc_contribution, type = type, filename = paste0(dir, csvName))
  cli_progress_done()

  # aggregate positive and negetive impacts if needed for type iaoh
  # ---------------------------------------------------------------
  if(type == "iaoh") {


    partPagg <- map(partP, sum_rasters, dir = dir, aoh = aoh, type = type)

  }

  # write raster
  # ------------
  map(partP,
      function(x) {
        cli_progress_step(paste0("Write tif: ", names(x)))
        writeRaster(x, paste0(dir, "tif/", names(x), ".tif"), gdal = c("COMPRESS=DEFLATE"), overwrite = T)
        cli_progress_done()})
 }

# function to crop aoh with lulc change data
aoh_clulc_crop <- function(lulc, caoh){

  if(relate(lulc, caoh, "overlaps")){
    lulc <- crop(lulc, caoh)
  } else{
    lulc <- NULL
  }
  return(lulc)
}

# function to attribute changes due to land conversion
caoh_attribution <- function(submit, clulc, type, outPath){

  cli_h2(paste0("Now: taxonID: ", submit$taxonID, ", period: ", submit$period, ", paraID: ", submit$paraID))

  if(submit$oneUnitContri == 0){ # write output directly if oneUnitContri == 0

    cli_progress_step("No habitat changes - next")


  } else{


  aoh1 <- rast(submit$aohP1)

  aoh2 <- rast(submit$aohP2)

  # caoh
  caoh <- aoh2 - aoh1


    # positive p attribute to suitable lulc (can only be due to land conversion)
    # ----------------------------------------------------------------------------
    cli_h3("Entering the positive value attribution")

    # get the positive caoh values
    cli_progress_step("Extract postitive caoh values")
    caohPos <- ifel(caoh > 0, caoh, 0)

    if(all(unique(caohPos) == 0)){ # return nothing if all values are 0 --> no positive changes
      NULL
    } else {

      # get the suitable lulc raster
      cli_progress_step("Get the suitable lulc raster")

      suitLulcID <- str_split(submit$lulcID, "_")[[1]]

      # extract the relevant lulc files
      suitLulc <- clulc %>%
        filter(lulcID %in% suitLulcID,
               year == submit$period)

      # read suitable lulc
      lulc <- map(suitLulc$paths, rast)

      # crop lulc with habitat area
      cli_progress_step("Crop lulc with habitat area")

      lulc <- map(lulc, aoh_clulc_crop, caohPos)  %>%
        discard(., is.null)

      # remove losses of suitable land
      lulc <- map(lulc, function(x) ifel(x > 0, x, 0))

      # check if lulc changed
      lulc <- map(lulc, remove_elements) %>%
        discard(., is.null)

      cli_progress_done()

      # if lulc changed attribute the gains
      if(length(lulc) != 0){
        pcaohPos <- p_attribution(lulc, aoh = caohPos, oneUnitContri = submit$oneUnitContri, paraID = submit$paraID, type = type, dir = outPath, csvName = "pcaoh.csv") # die pfade muss ich machen

      } else{

        NULL

      }
    }

    # attribute negative caoh values
    # ----------------------------------------------------------------------------
    cli_h3("Entering the negetive value attribution")

    # neg caoh scores values
    cli_progress_step("Extract negetive caoh values")
    caohNeg <- ifel(caoh < 0, caoh, 0)

    if(all(unique(caohNeg) == 0)){ # return nothing if all values are 0 --> no negative changes

      NULL

    } else {

      # get the non suitable lulc raster
      cli_progress_step("Get non suitable lulc files")

      suitLulcID <- tibble(lulcID = str_split(submit$lulcID, "_")[[1]])

      nosuitLulc <- clulc %>%
        anti_join(., suitLulcID, by = "lulcID") %>%
        filter(year == submit$period)

      # read suitable lulc
      lulc <- map(nosuitLulc$paths, rast)

      # crop lulc with habitat area
      cli_progress_step("Crop lulc with habitat area")
      lulc <- map(lulc, aoh_clulc_crop, caohNeg)  %>%  # checken
        discard(., is.null)

      # remove losses of non suitable land
      cli_progress_step("Remove losses of non suitable land")
      lulc <- map(lulc, function(x) ifel(x < 0, 0, x))

      # check if lulc changed
      lulc <- map(lulc, remove_elements) %>%  # checken
        discard(., is.null)

      cli_progress_done()

      # attribute the gains if lulc changed
      if(length(lulc) != 0){

        pcaohNeg <- p_attribution(lulc, aoh = caohNeg, oneUnitContri = submit$oneUnitContri, type = type, paraID = submit$paraID, dir = outPath, csvName = "pcaoh.csv")

      } else{
        NULL
      }
    }
  }
}
# function to attribute iaoh changes to lulc changes
iaoh_attribution <- function(submit, cint, type, outPath){

  cli_h2(paste0("Now: taxonID: ", submit$taxonID, ", period: ", submit$period, ", paraID: ", submit$paraID))


  if(submit$oneUnitContri == 0){ # write output directly if oneUnitContri == 0

    cli_progress_step("No habitat changes - next")

  } else{

    # read iaoh
    # ---------
    cli_progress_step("Read iaoh")
    iaoh1 <- rast(submit$iaohP1)
    iaoh2 <- rast(submit$iaohP2)

    cli_progress_step("Calculate change iaoh")
    iaoh <- iaoh2 - iaoh1

    x <- ifel(iaoh == 0, NA, iaoh)

    if(all(values(is.na(x)))){

      cli_progress_step("No habitat changes due to intensity")

    } else{

      # filter the correct period
      cli_progress_step("Filter yield data with correct period")
      cint <- cint %>%
        filter(period == submit$period)

      cint <- map(cint$paths, rast)

      # remove intensity data thats not intersecting with iaoh
      cli_progress_step("Check intersection of yield and iaoh")
      cin <- map(cint, function(x, iaoh){
        if(relate(x, iaoh, "intersects")){

          return(x)

        } else{

          return(NULL)

        }
      }, iaoh = iaoh)

      cin <- discard(cin, is.null)

      # -------------------------------------------------------------------------------------
      # attribute positive intensity changes to land use classes that reduced their intensity
      # -------------------------------------------------------------------------------------
      cli_h2("Attribute positive changes")
      iaohPos <- ifel(iaoh > 0, iaoh, 0)

      x <- ifel(iaohPos == 0, NA, iaohPos)

      if(all(values(is.na(x)))){

        cli_progress_step("No positive habitat changes due to intensity")

      } else{

        cintPos <- map(cin, function(x){ifel(x < 0, x, 0)})

        # check if yield changed
        cintPos <- map(cintPos, remove_elements) %>%
          discard(., is.null)

        cli_progress_done()

        # if yield changed attribute the gains
        if(length(cintPos) != 0){
          pcaohPos <- p_attribution(cintPos, aoh = iaohPos, oneUnitContri = submit$oneUnitContri, paraID = submit$paraID, type = type, dir = outPath, csvName = "piaoh.csv")

        } else{

          NULL

        }
      }

      # -------------------------------------------------------------------------------------
      # attribute negetive intensity changes to land use classes that reduced their intensity
      # -------------------------------------------------------------------------------------
      cli_h2("Attribute negetive changes")
      iaohNeg <- ifel(iaoh < 0, iaoh, 0)
      cintNeg <- map(cin, function(x){ifel(x > 0, x, 0)})

      x <- ifel(iaohNeg == 0, NA, iaohNeg)

      if(all(values(is.na(x)))){

        cli_progress_step("No negetive habitat changes due to intensity")

      } else{

        # check if yield changed
        cintNeg <- map(cintNeg, remove_elements) %>%
          discard(., is.null)

        cli_progress_done()

        # if yield changed attribute the gains
        if(length(cintNeg) != 0){
          pcaohPos <- p_attribution(cintNeg, aoh = iaohNeg, oneUnitContri = submit$oneUnitContri, paraID = submit$paraID, type = type, dir = outPath, csvName = "piaoh.csv")

        } else{

          NULL

        }
      }
    }
  }
}

# function to match the extents of a list of raster
match_extent <- function(x) {
  extents <- map(x, ext)

  # make a matrix out of it, each column represents a raster, rows the values
  extents <- lapply(extents, function(x) as.matrix(as.vector(x)))
  extents <- matrix(unlist(extents), ncol = length(extents))

  # create an extent with the extrem values of your extent
  maxExtend <- ext(min(extents[1,]), max(extents[2,]), min(extents[3,]), max(extents[4,]))

  x <- map(x, extend, maxExtend)

  return(x)
}

# function to aggregate multiple raster by mean and variance
aggregate_raster <- function(r, outDir, lulcImpactAggregation){

  if(lulcImpactAggregation == TRUE){

    nme <- paste0(paste(str_split(names(r)[1], "_")[[1]][1:3], collapse = "_"), "_lulc_", str_extract(str_split(names(r), "_")[[1]][6], "[^[.]]+"))

  } else{
    nme <- paste(str_split(names(r)[1], "_")[[1]][1:3], collapse = "_")
  }

  cli_progress_step("Calculate mean")
  m <- mean(r, na.rm = T)
  names(m) <- paste0(nme, "_mean")

  cli_progress_step("Calculate standard deviation")
  s <- var(r, na.rm = T)
  names(s) <- paste0(nme, "_var")

  cli_progress_step("Write Raster")
  writeRaster(m, paste0(outDir, names(m), ".tif"))
  writeRaster(s, paste0(outDir, names(s), ".tif"))
}

# function to sum multiple raster
sum_rasters <- function(x, dir, aoh, type){
  if(file.exists(paste0(dir, "tif/", names(x), ".tif"))) {
    cli_progress_step("Aggregate raster for process iaoh")
    r <- rast(paste0(dir, "tif/", names(x), ".tif"))
    r <- match_extent(list(r, x))
    r <- rast(r)
    r <- ifel(is.na(r), 0, r)
    x <- sum(r, na.rm = T)
    x <- ifel(x == 0, NA, x)
    names(x) <- paste0("dP", type, "-", str_split(names(aoh), pattern = "-")[[1]][2], "_lulc_", str_split(names(r[[1]]), "_")[[1]][5])

    return(x)

  } else{

    return(x)

  }
}

