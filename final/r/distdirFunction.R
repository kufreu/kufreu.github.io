# commented code and other things should be added soon?
# this function is dependent on geosphere, tidyverse (mostly dplyr), sp, and sf
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      layer %>%
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
    int <-
      layer %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      center %>%
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
    int <- layer %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  }
  result <- int %>%
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}
