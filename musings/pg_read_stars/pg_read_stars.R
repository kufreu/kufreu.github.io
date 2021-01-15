pg_read_stars = function(conn, layer, rast){
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
  
  res = dbGetQuery(
    conn, 
    glue(
      "select  
       st_pixelwidth({rast}) as x, 
       st_pixelheight({rast}) as y 
       from {layer}
       limit 1"))
  
  map2(boxes, unique(values$id), function(x, y)
    st_as_stars(
      st_bbox(x),
      dx = res$x,
      dy = res$y,
      values = values[values$id == y, ]$values,
      crs = crs
    ) %>% st_set_crs(srid)) %>%
    do.call(what = st_mosaic)
}