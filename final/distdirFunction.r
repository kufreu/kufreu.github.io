# commentted code and other things should be added soon?
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      layer %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <-
      layer %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        direction = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      center %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <- layer %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        direction = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  }
  result <- int %>%
    mutate(card_ord = ifelse(
      direction <= 22.5 |
        direction >= 337.5,
      "N",
      ifelse(
        direction <= 67.5 &
          direction >= 22.5,
        "NE",
        ifelse(
          direction <= 122.5 &
            direction >= 67.5,
          "E",
          ifelse(
            direction <= 157.5 &
              direction >= 112.5,
            "SE",
            ifelse(
              direction <= 292.5 &
                direction >= 247.5,
              "W",
              ifelse(
                direction <= 247.5 &
                  direction >= 202.5,
                "SW",
                ifelse(
                  direction <= 337.5 &
                    direction >= 292.5,
                  "NW",
                  ifelse(direction <= 202.5 &
                           direction >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}
