## ---------------------------
##
## Script name: 97_preprocess_vrt_lulc.R
##
## Purpose of script: file paths of data in stage/lulc folder for yield, to create one VRT for year and LULC class
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
## ---------------------------

# list files
# ----------
lulcFilesS1 <- list.files(paste0(stage1, "lulc/tif"), full.names = TRUE)

# tsv for vrt creation --> vielleicht muss ich das dann gar nicht mehr als array job laufen lassen
# --------------------
lulcFilesVrt <- as_tibble(lulcFilesS1) %>%
  rowwise() %>%
  mutate(group = str_extract(paste(str_split(value, "_")[[1]][4:7], collapse = "_"), pattern = "[^[.]]+")) %>%
  group_by(group) %>%
  summarise(paths = paste(value, collapse = " "))

write_tsv(lulcFilesVrt, paste0(slmPath, "preprocess-vrt-lulc-setup.txt")) # output to long for slurm array submit

# tsv for vrt slurm submit
# ------------------------
lulcFileS1Len <- seq_len(nrow(lulcFilesVrt))
write_tsv(tibble(lulcFileS1Len), paste0(slmPath, "preprocess-vrt-lulc-slurm.txt"), col_names = FALSE) # use number of rows
