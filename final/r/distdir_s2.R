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
