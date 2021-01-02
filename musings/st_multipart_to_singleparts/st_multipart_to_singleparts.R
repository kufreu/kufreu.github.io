st_multipart_to_singleparts = function(x) {
  # Replicates Multipart to Singleparts algorithm in QGIS
  library(sf)
  
  mixed = st_sf(x)
  mixed$id = 1:nrow(mixed)
  geo_types = as.character(unique(st_geometry_type(mixed)))
  str_geo = grepl("MULTI", geo_types)
  
  if (sum(str_geo) == 0) {
    return(x)
  }
  
  multi = geo_types[str_geo]
  
  if (sum(str_geo) == length(geo_types)) {
    single = gsub("MULTI", "", multi)
  } else {
    single = geo_types[!str_geo]
  }
  
  multipart = mixed[st_geometry_type(mixed) == multi,]
  id = multipart$id
  rows = 1:nrow(multipart)
  
  singlepart = do.call(rbind, lapply(rows, function(s)
    suppressWarnings(st_cast(
      multipart[s,], single
    ))))
  
  col = colnames(mixed)
  rbind(mixed[-id, ], singlepart)[,col[col!="id"]]
}
