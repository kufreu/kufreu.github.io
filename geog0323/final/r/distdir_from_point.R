#### distdir_from_point ####

# this function calculates distance in meters and direction in degrees from an origin (origin) to a destination (input)
# this function is dependent on geosphere, tidyverse (mostly dplyr), sp, and sf
# written by kufre u.

##### packages ####
install.packages("geosphere")
install.packages("tidyverse")
install.packages("sf")
install.packages("sp")

library(tidyverse)
library(sf)
library(sp)
library(geosphere)

#### final function ####
distdir_from_point <- function (input, origin, prefix = "") {
  # input: destination layer. input also becomes the origin layer if origin is not supplied can either be an sf object or an object with a spatial class (sf preferred)
  # origin: origin layer / where distance and direction are calculated from. can either be an sf object or an object with a spatial class (sf preferred)
  # prefix: customizable prefix, must be a character string in quotes
  
  # example uses:
  # distdir_from_point(tracts, city_center, "cbd" )
  # distdir_from_point(input = tracts, origin = city_center, prefix = "cbd")
  # unless the arguments are clearly defined as they are in the second example, the inputs should always be written in the order input, origin, then prefix
  
  if (missing(origin)) {
    # this section calculates distance/directon from input if origin is not supplied
    wgs84 <- # destination layer, centroid made on each feature  
      input %>%
      as("sf") %>% # coerces objects with spatial class into sf objects
      st_transform(3395) %>% # transforms input into WGS 84  (projected coordinate system)
      st_geometry %>% # gets geometry from the object as a list to be used with st_centroid 
      st_centroid %>%
      st_transform(4326) # transforms input into WGS 84 (geographic coordinate system)
    cbd <- # point made from mean coordinates of centroids 
      input %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>% # creating a layer of centroids 
      st_sf %>% # this creates an sf object/data frame from the list of geometries made in st_geometry
      mutate(nichts = "nichts") %>% # creating a column to dissolve on  
      group_by(nichts) %>%
      summarize %>% # grouping by new field and dissolving centroids into a single geometry 
      st_geometry %>%
      st_centroid %>% # making centroid from a multipoint feature 
      st_transform(4326)
    int <-
      input %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd), # unaltered output of st_distance (meters)
        dist_double = as.double(st_distance(wgs84, cbd)), # distance as a double (in meters, though unit is not shown with number) 
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360 # direction (in degrees, 0-360), objects need to be given the spatial class to be used with bearing and other geosphere functions
      )
  } else {
    # this section calculates distance/direction from origin if it is supplied 
    wgs84 <-
      input %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      origin %>% # input is replaced with origin here 
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_sf %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <- input %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  }
  result <- int %>%
    # assigning cardinal/ordinal directions to dir_degrees
    mutate(card_ord = ifelse(
      dir_degrees <= 22.5 |
        dir_degrees >= 337.5,
      "N",
      ifelse(
        dir_degrees <= 67.5 &
          dir_degrees >= 22.5,
        "NE",
        ifelse(
          dir_degrees <= 122.5 &
            dir_degrees >= 67.5,
          "E",
          ifelse(
            dir_degrees <= 157.5 &
              dir_degrees >= 112.5,
            "SE",
            ifelse(
              dir_degrees <= 292.5 &
                dir_degrees >= 247.5,
              "W",
              ifelse(
                dir_degrees <= 247.5 &
                  dir_degrees >= 202.5,
                "SW",
                ifelse(
                  dir_degrees <= 337.5 &
                    dir_degrees >= 292.5,
                  "NW",
                  ifelse(dir_degrees <= 202.5 &
                           dir_degrees >= 157.5, "S", "nirgendwo")
                )
              )
            )
          )
        )
      )
    ))
  # adding prefixes
  if (prefix == "") {
    result # result is returned if no prefix is given 
  } else {
    result %>%
      rename(!!paste(prefix, "dist_unit", sep = "_") := dist_unit) %>%
      rename(!!paste(prefix, "dist_double", sep = "_") := dist_double) %>%
      rename(!!paste(prefix, "dir_degrees", sep = "_") := dir_degrees) %>%
      rename(!!paste(prefix, "card_ord", sep = "_") := card_ord)
  }
}
