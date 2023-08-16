## ---------------------------
##
## Script name: 97_lulc_file_path_incoming.R
##
## Purpose of script: creates the slurm submit file list for cluster
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

cli_h1("Initializing lulc file list generation")


# cluster processing
#
if(place == "cluster"){
  cli_progress_step(msg = "Generating cluster file list",
                    msg_done = "Generated and saved cluster list")

  # tmp <- list.files("/gpfs1/data/idiv_meyer/00_data/processed/mapBiomas/", full.name = TRUE, pattern = ".vrt")
  #
  # tmp <- tmp %>%
  #   as_tibble(tmp[1]) %>%
  #   separate_rows(value, sep = "\n") %>%
  #   mutate(value = trimws(value)) %>%
  #   filter(str_detect(value, "1996|2007|2018"))
  #
  # write_tsv(tmp, paste0(metaPath, "lulc-files-in.txt"), col_names = FALSE)
  #
  # cli_process_done()

  lulcfiles <- list.files(paste0(inPath, "lulc/"), pattern = ".tif$", full.names = TRUE)

  write_tsv(tibble(lulcfiles), paste0(slmPath, "lulc-files-in.txt"), col_names = FALSE)

} else{
  cli_progress_step(msg = "Generating local file list",
                    msg_done = "Generated and saved local list")

  LULCFiles <- list.files(path = paste0(inPath, "lulc"), full.names = TRUE, pattern = ".vrt$")

  LULCFiles <- LULCFiles %>%
    as_tibble(LULCFiles[1]) %>%
    filter(str_detect(value, "1996|2007|2018")) %>%
    as.vector() %>%
    unlist()

  write_rds(LULCFiles, paste0(metaPath, "lulcFilesIn.rds"))

  cli_process_done()

}
