st_segments = function(x, max_length) {
  # breaks linestrings/polygons into line segments, keeps attributes
  # x: layer with linestrings/polygons
  # max_length: optional parameter, max length of segments, unit from crs
  library(sf)
  
  net = st_sf(x)
  net$fid = 1:nrow(net)
  
  if (!missing(max_length)) {
    net = st_segmentize(net, max_length)
  }
  
  coord = st_coordinates(net)
  col = ncol(coord)
  ids = coord[, col]
  feat = unique(ids)
  segments = list()
  
  for (i in feat) {
    coords = coord[ids == i,]
    for (j in 1:(nrow(coords) - 1)) {
      segments[[length(segments) + 1]] = st_as_binary(st_linestring(coords[j:(j + 1), 1:2]))
    }
  }
  
  fid = matrix(nrow = (length(ids) - length(feat)), ncol = 1)
  k = 0
  
  for (i in feat) {
    id = ids[ids == i]
    for (j in seq_along(id[1:(length(id) - 1)])) {
      fid[k + 1, ] = id[j]
      k = k + 1
    }
  }
  
  colnames(fid) = "fid"
  fid = as.data.frame(fid)
  fid = merge(fid,st_drop_geometry(net), all.x = T)[,-1, drop = F]
  fid$geometry = st_set_crs(st_as_sfc(segments), st_crs(net))
  st_sf(fid)
}