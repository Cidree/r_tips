# ----------------------------------------------------------------------- #
#
# R TIPS series --------
# - Title: 002 - Geocoding in R using tidygeocoder
# - Author: Adrián Cidre
# - Website: https://adrian-cidre.com
#
# You will learn to:
# - Do forward geocoding of one address
# - Do forward geocoding of several addresses
# - Do backward geocoding of one address
# - Do backward geocoding of several addresses
#
# ----------------------------------------------------------------------- #

# 1. Import packages ------------------------------------------------------

library(pacman)

p_load(
  dplyr, mapview, osmdata, sf, tidygeocoder
)

# 2. Forward geocoding ----------------------------------------------------

## 2.1. Geocoding one address --------------

## Geocoding one address
geo(
  address = "Sober, Galicia",
  method  = "arcgis"
)

## Another example (Health center)
address_tbl <- geo(
  address = "Street Doutor Casares, 21, Monforte de Lemos, Galicia",
  method  = "arcgis"
)

## Convert to sf
address_tbl <- address_tbl |> 
  st_as_sf(
    coords = c("long", "lat"),
    crs    = 4326
  )

## Visualize
mapview(address_tbl, map.types = "OpenStreetMap")

## 2.2. Geocoding several addresses --------

## Tibble with 2 addresses
addresses_tbl <- tibble(
  address = c(
    "Cinema, Monforte de Lemos", 
    "Hospital, Monforte de Lemos"
  )
)

## Geocode, convert to sf and visualize
addresses_tbl |> 
  geocode(
    address = address,
    method  = "arcgis"
  ) |> 
  st_as_sf(
    coords = c("long", "lat"),
    crs    = 4326
  ) |> 
  mapview(
    map.types = "OpenStreetMap"
  )

# 3. Reverse geocoding ----------------------------------------------------

## 3.1. RG one pair of coords ---------

reverse_geo(
  lat    = 42.52366,
  long   = -7.513809,
  method = "arcgis"
)

## 3.2. Load data ----------------

## Pharmacies in Joensuu, Finland
pharmacies_osm <- opq("Joensuu, Finland") |> 
  add_osm_feature(
    key   = "amenity",
    value = "pharmacy"
  ) |> 
  osmdata_sf()

## Extract vectorial data
pharmacies_sf <- pharmacies_osm$osm_points |> 
  select(name, geometry)

## Convert coordinates to tibble
pharmacies_coords_tbl <- pharmacies_sf |> 
  st_coordinates() |> 
  as_tibble()

## Hospital addresses
pharmacies_coords_tbl <- pharmacies_coords_tbl |> 
  reverse_geocode(
    lat    = Y,
    lon    = X,
    method = "arcgis"
  )

## Add to original sf
pharmacies_coords_tbl |> 
  st_as_sf(
    coords = c("X", "Y"),
    crs    = 4326
  ) |> 
  mapview(
    legend    = FALSE,
    map.types = "OpenStreetMap"
  )









