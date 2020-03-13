# updates and developments
### updated disdir_from_point
```r
#### distdir ####

# this function calculates distance in meters and direction in degrees from an origin (origin) to a destination (input)
# this function is dependent on geosphere, tidyverse (mostly dplyr), sp, and sf
# written by kufre u.

distdir <- function (input, origin, prefix = "") {
  
  library(units)
  library(geosphere)
  library(dplyr)
  library(sf)
    
  print("Distance is measured in meters.")
  
  wgs84 <-
    input %>%
    as("sf") %>%
    st_transform(3395) %>%
    st_geometry %>%
    st_centroid %>%
    st_transform(4326)
  
  if (missing(origin)){
    cbd <- 
      input %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>% 
      st_union %>%
      st_centroid %>%
      st_transform(4326)
  } else {
    cbd <-
      origin %>%  
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_union %>%
      st_centroid %>%
      st_transform(4326)
  }
  int <-
    input %>%
    as("sf") %>%
    mutate(
      distance = drop_units(st_distance(wgs84, cbd)),
      direction_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360 
    )
  result <- int %>%
    mutate(direction_card_ord = ifelse(
      direction_degrees <= 22.5 |
        direction_degrees >= 337.5,
      "N",
      ifelse(
        direction_degrees <= 67.5 &
          direction_degrees >= 22.5,
        "NE",
        ifelse(
          direction_degrees <= 122.5 &
            direction_degrees >= 67.5,
          "E",
          ifelse(
            direction_degrees <= 157.5 &
              direction_degrees >= 112.5,
            "SE",
            ifelse(
              direction_degrees <= 292.5 &
                direction_degrees >= 247.5,
              "W",
              ifelse(
                direction_degrees <= 247.5 &
                  direction_degrees >= 202.5,
                "SW",
                ifelse(
                  direction_degrees <= 337.5 &
                    direction_degrees >= 292.5,
                  "NW",
                  ifelse(direction_degrees <= 202.5 &
                           direction_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
  if (prefix == "") {
    result  
  } else {
    result<- result %>%
      rename(!!paste(prefix, "distance", sep = "_") := distance,
             !!paste(prefix, "direction_degrees", sep = "_") := direction_degrees,
             !!paste(prefix, "direction_card_ord", sep = "_") := direction_card_ord)
  }
return(result)
}
```
