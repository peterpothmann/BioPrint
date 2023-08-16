## ---------------------------
##
## Script name: 00_preprocess_al.R
##
## Purpose of script: preprocess administrative level data from LUCKiNet, check the custom funciton
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

cli_h1("Initiating adminstrative level preprocess")

al3 <- read_al("al3", "3", correction = TRUE) # had to split wrong geometries
al2 <- read_al("al2", "2", correction = TRUE)
al1 <- read_al("al1", "1", correction = FALSE)

cli_h1("Closing administrative level preprocess")
