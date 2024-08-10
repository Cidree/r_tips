# ----------------------------------------------------------------------- #
#
# R TIPS series --------
# - Title: 001 - Downloading Open Street Map data directly in R
# - Author: Adrián Cidre
# - Website: https://adrian-cidre.com
#
# You will learn:
# - Download data from Open Street Maps directly into R
# - Download OSM data from any place in the world
#
# Notes:
# - {osmdata} works for small to medium size datasets
# - For big datasets have a look at the {osmextract} package
# ----------------------------------------------------------------------- #

# 1. Load packages --------------------------------------------------------

## Load pacman
library(pacman)

## Load rest of the packages
p_load(giscoR, mapview, osmdata, sf)

# 2. Intro to OSM --------------------------------------------------------

## Available features
available_features()

## Available tags
available_tags("sauna")
available_tags("water")

# 3. Get bounding box ----------------------------------------------------

## -> For the osmdata package the order needs to be (xmin, ymin, xmax, ymax)

## 3.1. Using a polygon -------------

## Get the polygon
czechia_sf <- gisco_get_countries(country = "CZ")

## Extract bounding box with the sf package
st_bbox(czechia_sf)

## 3.2. Using known coordinates -----

## Coordinates of Czechia
c(12.1, 48.56, 18.85, 51.05)

## 3.3. Using a name -----------------

## -> Using the Nominatim API

## Coordinates of Czechia
getbb("Czechia")
getbb("Czech Republic")

## Coordinates of Prague
getbb("Prague")
getbb("Prague, Czechia")
getbb("Praha, Česká republika")

# 4. Build a query -------------------------------------------------------

## Components of the query:
## - Bounding box
## - Features/tags

## OverPass Query
opq(getbb("Czechia"))
opq("Czechia")

## Saunas in Czechia
cz_sauna_opq <- opq("Czechia") |> 
  add_osm_feature(
    key = "sauna"
  )

## Lakes and reservoirs in Czechia
prague_water_opq <- opq("Praha") |> 
  add_osm_feature(
    key   = "water",
    value = c("lake", "reservoir")
  )

# 5. Retrieve the data ---------------------------------------------------

## We use the functions osmdata_*, where * is the output format

## 5.1. Saunas ---------------------

## Retrieve saunas in sf
cz_sauna_osmdata <- osmdata_sf(cz_sauna_opq)

## Extract points
cz_sauna_sf <- cz_sauna_osmdata$osm_points

## Visualize
mapview(cz_sauna_sf)

## 5.2. Lakes and reservoirs ----------

## Retrieve lakes and reservoirs in sf
prague_water_osmdata <- osmdata_sf(prague_water_opq)

## Metadata
prague_water_xml <- osmdata_xml(prague_water_opq)

## Extract points
prague_water_sf <- prague_water_osmdata$osm_polygons

## Visualize
mapview(prague_water_sf)

# 6. The whole game ------------------------------------------------------

## Do it in one step
prague_water_osmdata <- opq("Praha") |> 
  add_osm_feature(
    key   = "water",
    value = c("lake", "reservoir")
  ) |> 
  osmdata_sf()
