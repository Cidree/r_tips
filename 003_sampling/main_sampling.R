# ----------------------------------------------------------------------- #
#
# R TIPS series --------
# - Title: R003 - Spatial sampling in R. Random, regular and stratified (random|regular) sampling
# - Author: Adrián Cidre
# - Website: https://adrian-cidre.com
#
# You will learn to:
# - Random sampling
# - Regular sampling
# - Stratified random sampling
# - Stratified regular sampling
# - Stratified sampling by area
#
# ----------------------------------------------------------------------- #

# 1. Load packages -------------------------------------------------------

library(pacman)

pak::pak("Cidree/forestdata")

p_load(forestdata, giscoR, mapview, sf, tidyverse)

# 2. Load data -----------------------------------------------------------

## 2.1. Study area -----------------

## Load Spanish municipalities
municipalities_sf <- gisco_get_communes(country = "Spain")

## Filter Hermigua municipality
hermigua_sf <- municipalities_sf |> 
  filter(NAME_LATN == "Hermigua") |> 
  st_transform("EPSG:25828")

## Visualize
mapview(hermigua_sf)

## 2.2. Forest types ---------------

## Check metadata
metadata_forestdata

## Load Spanish Forestry Map
forest_tenerife_sf <- fd_forest_spain_mfe50(
  province = "Santa Cruz De Tenerife"
) |> 
  st_transform("EPSG:25828")

## Visualize
mapview(forest_tenerife_sf)

# 3. Prepare data --------------------------------------------------------

## Intersection
forest_hermigua_sf <- st_intersection(
  x = forest_tenerife_sf,
  y = hermigua_sf
)

## Visualize
mapview(forest_hermigua_sf)

## Rename from Spanish to English
## Calculate area in hectares
forest_hermigua_sf <- forest_hermigua_sf |> 
  mutate(
    forest_type = case_when(
      NOM_FORARB == "No arbolado" ~ "Non-forested",
      NOM_FORARB == "Fayal-brezal" ~ "Fayal-brezal",
      NOM_FORARB == "Palmerales y mezclas de palmeras con otras especies" ~ "Palm groves and mixtures of palm trees with other species",
      NOM_FORARB == "Sabinares canarios (Juniperus turbinata)" ~ "Canarian juniper forests (Juniperus turbinata)",
      NOM_FORARB == "Pinares de pino carrasco (Pinus halepensis)" ~ "Aleppo pine forests (Pinus halepensis)",
      NOM_FORARB == "Coníferas con frondosas (alóctonas con autóctonas)" ~ "Conifers with broadleaves (non-native with native)",
      NOM_FORARB == "Mezclas de coníferas y frondosas autóctonas en la región biogeográfica macaronésica" ~ "Mixtures of conifers and native broadleaves in the Macaronesian biogeographic region",
      NOM_FORARB == "Laurisilvas macaronésicas" ~ "Macaronesian laurel forests",
      NOM_FORARB == "Pinares de pino radiata (Pinus radiata)" ~ "Radiata pine forests (Pinus radiata)",
      NOM_FORARB == "Mezclas de coníferas autóctonas en la región biogeográfica macaronésica" ~ "Mixtures of native conifers in the Macaronesian biogeographic region",
      NOM_FORARB == "Otras mezclas de frondosas macaronésicas" ~ "Other mixtures of Macaronesian broadleaves",
      NOM_FORARB == "Pinares de pino canario (Pinus canariensis)" ~ "Canarian pine forests (Pinus canariensis)",
      .default = NA
    )
  ) |> 
  select(forest_type) |> 
  filter(
    str_detect(forest_type, "Palm|Non-forested", negate = TRUE)
  )

## Dissolve by forest type
forest_hermigua_sf <- forest_hermigua_sf |> 
  group_by(forest_type) |>   
  summarise(geometry = st_union(geometry)) 

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type")

# 4. Sampling ------------------------------------------------------------

## 4.1. Random sampling --------------

## Do random sampling
set.seed(123)
random_sampling_sf <- forest_hermigua_sf |> 
  st_sample(
    size = 200,
    type = "random"
  ) |> 
  st_as_sf()

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type", layer.name = "Forest types") +
  mapview(random_sampling_sf, legend = FALSE, layer.name = "Samples")

## 4.2. Regular sampling --------------

## Do regular sampling
regular_sampling_sf <- forest_hermigua_sf |> 
  st_sample(
    size = 200,
    type = "regular"
  ) |> 
  st_as_sf()

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type", layer.name = "Forest types") +
  mapview(regular_sampling_sf, legend = FALSE, layer.name = "Samples")

## 4.3. Stratified random sampling ------

## Number of unique groups?
ngroups <- unique(forest_hermigua_sf$forest_type) |> length()

## Do stratified random sampling
srandom_sampling_sf <- forest_hermigua_sf |> 
  st_sample(
    size = rep(10, ngroups),
    type = "random"
  ) |> 
  st_as_sf()

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type", layer.name = "Forest types") +
  mapview(srandom_sampling_sf, legend = FALSE, layer.name = "Samples")

## Check if there are 10 samples per group
st_join(srandom_sampling_sf, forest_hermigua_sf) |> 
  count(forest_type)

## 4.4. Stratified regular sampling ------

## Do stratified regular sampling
sregular_sampling_sf <- forest_hermigua_sf |> 
  st_sample(
    size = rep(10, ngroups),
    type = "regular"
  ) |> 
  st_as_sf()

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type", layer.name = "Forest types") +
  mapview(sregular_sampling_sf, legend = FALSE, layer.name = "Samples")

## Check if there are 10 samples per group
st_join(sregular_sampling_sf, forest_hermigua_sf) |> 
  count(forest_type)

# 5. EXTRA: samples by area ----------------------------------------------

## 1 sample per 20 hectares
## If the area is less than 50 ha, do 1 sample per 10 ha
forest_hermigua_sf <- forest_hermigua_sf |>   
  mutate(
    area = st_area(geometry) |> units::set_units(ha) |> as.numeric()
  ) |> 
  mutate(
    nsamples = if_else(
      area >= 50,
      round(area / 20),
      round(area / 10)
    )
  )

## Do stratified regular sampling
extra_sampling_sf <- forest_hermigua_sf |> 
  st_sample(
    size = forest_hermigua_sf$nsamples,
    type = "regular"
  ) |> 
  st_as_sf()

## Visualize
mapview(forest_hermigua_sf, zcol = "forest_type", layer.name = "Forest types") +
  mapview(extra_sampling_sf, legend = FALSE, layer.name = "Samples")

## Check number of samples per group
st_join(extra_sampling_sf, forest_hermigua_sf) |> 
  group_by(forest_type, nsamples) |> 
  count(forest_type)
