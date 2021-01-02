st_blend = function(node, network) {
  # blends node(s) into a network composed of linestrings
  # node: point(s)
  # network: network composed of linestrings
  # returns: network with added node(s)
  
  library(sf)
  library(lwgeom)
  library(dplyr)
  library(purrr)
  
  ncrs = st_crs(network)
  blade = st_sf(node) %>%
    mutate(geometry = st_geometry(.)) %>% # just in case geometry column isn't named geometry
    st_set_geometry("geometry") %>%
    mutate(
      nf = st_nearest_feature(., network),
      # nearest linestring
      nl = do.call(c, map2(
        geometry, nf,  ~ st_nearest_points(st_sfc(.x, crs = ncrs), network[.y, ])
      )),
      # nearest point to edge/linestring
      np = do.call(c, map2(
        nl, geometry, ~ st_cast(st_sfc(.x, crs = ncrs), "POINT") %>% .[. != st_sfc(.y, crs = ncrs)]
      )),
      # nearest point in nearest edge/linestring
      ns = do.call(c, map2(
        nf, np, ~ st_cast(st_geometry(network[.x, ]), "POINT") %>% .[st_nearest_feature(st_sfc(.y, crs = ncrs), .)]
      )),
      len = st_length(nl) %>% units::drop_units()
    ) %>%
    filter(np != ns) %>% # remove rows where nearest point is already in nearest edge/linestring
    st_set_geometry("nl") %>%
    select(nf, len) %>%
    suppressWarnings()
  
  blade = st_geometry(blade) %>%
    {
      (. - st_centroid(.)) * (blade$len * 2 / blade$len) + st_centroid(.) # ensure line is long enough to split edge
    } %>%
    st_set_crs(ncrs) %>%
    st_sf() %>%
    mutate(nf = blade$nf)
  
  st_split(network[blade$nf, ], blade) %>%
    st_collection_extract("LINESTRING") %>%
    rbind(network[-blade$nf, ])
}