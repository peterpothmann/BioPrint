## ---------------------------
##
## Script name: 99_geoprocessing_grid.R
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

# make grid
# ---------

template <- rast(paste0(inPath, "lulc/mapBiomas-brazil_19960000_30m.tif"))

boundary <- st_as_sf(as.polygons(ext(template)))

grids <- st_make_grid(boundary, square = T, what = "polygons", cellsize = res(template)[1] * 30000) %>%  # the grid, covering bounding box
  st_sf() %>%
  st_set_crs(4326) %>%
  st_cast(., "POLYGON") %>%
  mutate(gridID = row_number())
plot(grids)

st_write(grids, paste0(metaPath, "grid.gpkg"), layer = "grid.shp", append = FALSE)
