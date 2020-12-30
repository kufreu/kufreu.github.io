st_segments_tbl = function(x, max_length) {
  # breaks linestrings or polygons into line segments, keeps attributes
  # x: layer with linestrings/polygons
  # max_length: optional parameter, max length of segments, unit from crs
  library(sf)
  library(dplyr)
  library(purrr)
  
  layer = mutate(x, value = row_number())
  
  if (!missing(max_length)) {
    layer = st_segmentize(layer, max_length)
  }
  
  coord = st_coordinates(layer)
  col = ncol(coord)
  
  geom = as_tibble(coord) %>%
    group_by(!!sym(colnames(coord)[col])) %>%
    mutate(X2 = lead(X),
           Y2 = lead(Y)) %>%
    ungroup() %>%
    filter(!is.na(X2)) %>%
    mutate(geometry = pmap(list(X, Y, X2, Y2), function(x, y, x2, y2)
      st_linestring(rbind(
        c(x, y), c(x2, y2)
      )))) %>%
    {
      st_as_sfc(.[["geometry"]], crs = st_crs(layer))
    }
  
  as_tibble(coord[, col]) %>%
    group_by(value) %>%
    slice(-1) %>%
    ungroup %>%
    left_join(st_drop_geometry(layer), by = "value") %>%
    select(-1) %>%
    mutate(geometry = geom) %>%
    st_sf()
}