# updates and developments
### [updated disdir_from_point](r/distdir.R)
```r
#### distdir ####

# this function calculates distance in meters and direction in degrees from an origin (origin) to a destination (input)
# this function is dependent on geosphere, dplyr, sp, and sf
# written by kufre u.

distdir <- function (input, origin, prefix = "") {
  
  library(geosphere)
  library(dplyr)
  library(sf)
  library(units)
    
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
    result %>%
      rename(!!paste(prefix, "distance", sep = "_") := distance,
             !!paste(prefix, "direction_degrees", sep = "_") := direction_degrees,
             !!paste(prefix, "direction_card_ord", sep = "_") := direction_card_ord)
  }
}
```
### [distdir using lwgeom instead of geosphere](r/distdir_lwgeom)
```r
#### distdir_lwgeom ####

# this function calculates distance in meters and direction in degrees from an origin (origin) to a destination (input)
# this function is dependent on lwgeom, dplyr, and sf
# written by kufre u.

distdir_lwgeom <- function (input, origin, prefix = "") {
  library(lwgeom)
  library(dplyr)
  library(sf)
  library(units)
  
  print("Distance is measured in meters.")
  
  input <- filter(input, st_is_empty(input) == F)
  
  wgs84 <-
    input %>%
    as("sf") %>%
    st_transform(3395) %>%
    st_geometry %>%
    st_centroid %>%
    st_transform(4326)
  
  if (missing(origin)) {
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
      filter(st_is_empty(.) == F) %>%
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
    mutate(distance = drop_units(st_distance(wgs84, cbd)),
           o = cbd,
           d = wgs84)
  
  dir <- function(x) {
    st_geod_azimuth(st_sfc(x$o, x$d, crs = 4326))
  }
  
  int$direction_degrees <- (drop_units(set_units(
    set_units(apply(int, 1, dir), "radians"), "degrees"
  )) + 360) %% 360
  
  result <- int %>%
    select(!c("o", "d")) %>%
    mutate(
      direction_card_ord = ifelse(
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
                    ifelse(
                      direction_degrees <= 202.5 &
                        direction_degrees >= 157.5,
                      "S",
                      "nichts"
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  if (prefix == "") {
    result
  } else {
   result %>%
      rename(
        !!paste(prefix, "distance", sep = "_") := distance,
        !!paste(prefix, "direction_degrees", sep = "_") := direction_degrees,
        !!paste(prefix, "direction_card_ord", sep = "_") := direction_card_ord
      )
  }
}
```

### [distdir using s2](r/distdir_sd.R)
```r
# distdir_s2 --------------------------------------------------------------
# this function calculates distance in meters and direction in degrees from an origin (origin) to a destination (input)
# this function is dependent on s2, dplyr, and sf
# written by kufre u.

distdir_s2 = function (input, origin, prefix = "") {
  library(s2)
  library(dplyr)
  library(sf)
  
  message("Distance is measured in meters.")
  
  input = filter(input, st_is_empty(input) == F)
  
  i =
    input %>%
    st_transform(4326) %>%
    st_geometry %>%
    st_as_binary %>%
    s2_centroid
  
  if (missing(origin)) {
    o =
      input %>%
      st_transform(4326) %>%
      st_geometry %>%
      st_as_binary %>%
      s2_centroid %>%
      s2_union_agg %>%
      s2_centroid
  } else {
    o =
      origin %>%
      filter(st_is_empty(.) == F) %>%
      st_transform(4326) %>%
      st_geometry %>%
      st_as_binary %>%
      s2_centroid %>%
      s2_union_agg %>%
      s2_centroid
  }
  
  d2r = pi / 180
  r2d = 180 / pi
  
  phi1 = s2_y(o) * d2r
  lam1 = s2_x(o) * d2r
  phi2 = s2_y(i) * d2r
  lam2 = s2_x(i) * d2r
  
  y = sin(lam2 - lam1) * cos(phi2)
  x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(lam2 - lam1)
  
  result =
    input %>%
    mutate(
      distance = s2_distance(o, i),
      direction = (atan2(y, x) * r2d + 360) %% 360,
      cardinal = case_when(
        direction <= 22.5 |
          direction >= 337.5 ~
          "N",
        direction <= 67.5 &
          direction >= 22.5 ~
          "NE",
        direction <= 122.5 &
          direction >= 67.5 ~
          "E",
        direction <= 157.5 &
          direction >= 112.5 ~
          "SE",
        direction <= 202.5 &
          direction >= 157.5 ~
          "S",
        direction <= 247.5 &
          direction >= 202.5 ~
          "SW",
        direction <= 292.5 &
          direction >= 247.5 ~
          "W",
        direction <= 337.5 &
          direction >= 292.5 ~
          "NW"
      )
    )
  if (prefix == "") {
    result
  } else {
    result %>%
      rename(
        !!paste(prefix, "distance", sep = "_") := distance,
        !!paste(prefix, "direction", sep = "_") := direction,
        !!paste(prefix, "cardinal", sep = "_") := cardinal
      )
  }
}
```
