pg_read_stars = function(conn, layer, rast = "rast"){
  # reads raster from postgis database
  # conn: DBIConnection object
  # layer: name of table with raster 
  # rast: name of column that contains raster values
  
  library(stars)
  library(purrr)
  library(DBI)
  library(glue)
  
  values = dbGetQuery(
    conn,
    glue(
      "with arrange as (
          select 
          {rast} as rast, 
          rid from {layer} 
          order by rid asc)
       select
       unnest(st_dumpvalues(rast,1)) as values,
       row_number() over (order by rid) as id
       from arrange"
    )
  )
  
  srid = dbGetQuery(
    conn,
    glue(
      "select distinct 
       st_srid({rast}) as srid 
       from {layer}"))$srid %>% 
    st_crs
  
  boxes = dbGetQuery(
    conn, 
    glue(
      "select 
       st_asewkb(st_envelope({rast})) as geom 
       from {layer}
       order by rid asc"))$geom %>% 
    st_as_sfc(EWKB = T) 
  
  dims = dbGetQuery(
    conn, 
    glue(
      "select  
       st_pixelwidth({rast}) as dx, 
       st_pixelheight({rast}) as dy,
       st_skewx({rast}) as sx,
       st_skewy({rast}) as sy
       from {layer}
       limit 1"))
  
  result = map2(boxes, unique(values$id), function(x, y)
    st_as_stars(
      st_bbox(x),
      dx = dims$dx,
      dy = dims$dy,
      values = values[values$id == y, ]$values
    ) %>% st_set_crs(srid)) %>%
    do.call(what = st_mosaic)
  
  attr(attr(result, "dimensions"), "raster")$affine = c(dims[[3]],dims[[4]])
  
  result
}
