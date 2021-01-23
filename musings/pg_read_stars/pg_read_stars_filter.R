pg_read_stars = function(conn, layer, rast = "rast", boundary = NULL) {
  library(stars)
  library(purrr)
  library(DBI)
  library(glue)
  library(blob)
  
  crs = dbGetQuery(
    conn,
    glue(
      "select 
       distinct st_srid({rast}) as srid 
       from {layer}" ))$srid %>% 
    st_crs
  
  dims = dbGetQuery(
    conn,
    glue(
      "select distinct 
       st_pixelwidth({rast}) as dx, 
       st_pixelheight({rast}) as dy,
       st_skewx({rast}) as sx,
       st_skewy({rast}) as sy
       from {layer}"
    )
  )
  
  if (is.null(boundary)) {
    values = dbGetQuery(
      conn,
      glue(
        "select 
         unnest(st_dumpvalues({rast},1)) as values, 
         row_number() over (order by rid) as id 
         from {layer}"
      )
    )
    
    boxes = dbGetQuery(
      conn,
      glue(
        "select 
         st_asewkb(st_envelope({rast})) as geom 
         from {layer}"
      )
    )$geom %>%
      st_as_sfc(EWKB = T)
    
  } else {
    bounds = st_transform(boundary,crs)
    
    intersects =
      st_intersects(bounds, st_as_sfc(dbGetQuery(
        conn,
        glue(
          "select st_asewkb(st_union(st_envelope({rast}))) as ewkb from {layer}"
        )
      )[[1]], EWKB = T), 
      sparse = F)
    
    if (intersects){
      dbWriteTable(conn, "ewkb_blob", data.frame(
        ewkb = as_blob(
          st_as_binary(
            bounds, EWKB = T)[[1]])
        ), overwrite = T)
      
      values = dbGetQuery(
        conn,
        glue(
          "with intersects as (
          select l.* from {layer} as l, ewkb_blob as e
          where st_intersects(l.{rast},st_geomfromewkb(e.ewkb))
          ),
          clip as
            (select
            st_clip({rast},st_geomfromewkb(e.ewkb)) as clipped,
            rid
            from intersects, ewkb_blob as e)
          select unnest(st_dumpvalues(clipped,1)) as values,
          row_number() over (order by rid) as id
          from clip"
        )
      )
      
      boxes = dbGetQuery(
        conn,
        glue(
          "with clip as
            (select
             st_clip({rast},st_geomfromewkb(e.ewkb)) as clipped
             from {layer}, ewkb_blob as e
             where st_intersects({rast},st_geomfromewkb(e.ewkb))
            )
         select
         st_asewkb(st_envelope(clipped)) as geom
         from clip"
        )
      )$geom %>%
        st_as_sfc(EWKB = T)
      dbExecute(conn, "drop table ewkb_blob")
    } else{
      stop(glue("Boundary and {layer} do not intersect."))
    }
  }
  
  result = map2(boxes, unique(values$id), function(x, y)
    st_as_stars(
      st_bbox(x),
      dx = dims$dx,
      dy = dims$dy,
      values = values[values$id == y, ]$values
    ) %>% st_set_crs(crs)) %>%
    do.call(what = st_mosaic)
  
  attr(attr(result, "dimensions"), "raster")$affine = c(dims[[3]],dims[[4]])
  
  result
}