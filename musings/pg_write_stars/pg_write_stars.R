pg_write_stars =  function(conn, name, layer, tile_size = NULL,bit_depth = NULL) {
  # writes raster (stars) to a postgis database
  # conn: DBIConnection object
  # name: name of table to hold raster
  # layer: stars object 
  # tile_size: size of tiles to split raster into specified as vector with length 1 or 2, expressed as pixel width by height 
  # bit_depth: bit depth of raster
  
  library(stars)
  library(tibble)
  library(glue)
  library(purrr)
  library(DBI)
  
  if (!("postgis_raster" %in% dbGetQuery(conn, "select * FROM pg_available_extensions;")$name))
    stop("PostGIS extension not available.")
  
  if (st_is_longlat(layer)) 
    stop("Raster should have projected coordinates.")
  
  if (any(class(layer) != "stars")) 
    stop("Object should be of class stars.")

  crs = st_crs(layer)$epsg
  if (is.na(crs)) {crs = 0; warning("SRID set to 0")}
  
  dims = st_dimensions(layer)
  res = c(dims$x$delta, dims$y$delta)
  bbox = st_bbox(layer)
  val = c(dims$x$values,dims$y$values)
  aff = attr(dims,"raster")$affine
  
  if (attr(dims, "raster")$curvilinear |
      any(!is.null(val)) |
      any(is.na(res))) {
    stop("Raster must be regular.")
  }
  
  # determine bit depth 
  # from https://github.com/mablab/rpostgis/blob/master/R/pgWriteRast.R 
  if (is.null(bit_depth)) {
    if (is.integer(layer[[1]])) {
      if (min(layer[[1]], na.rm = TRUE) >= 0) {
        bit_depth = "32BUI"
      } else {
        bit_depth = "32BSI"
      }
    } else {
      bit_depth = "32BF"
    }
  }
  
  # determine tile size
  if (!is.null(tile_size)) {
    if (length(tile_size) == 2) {
      bx = tile_size[1]
      by = tile_size[2]
    } else {
      bx = by = tile_size[1]
    }
  } else {
    bx = by = 100
  }
  
  tiles = st_as_stars(bbox, dx = res[1] * bx, dy = res[2] * by) %>%
    st_as_sfc(as_points = F) %>%
    st_intersection(st_as_sfc(bbox))
  
  # create a list with tile dimensions and values 
  info = map(seq_along(tiles), function(x) {
    tile = tiles[x]
    inter = layer[tile]
    dm = dim(inter)
    list(dm, st_dimensions(st_as_stars(
      st_bbox(tile), dx = res[1], dy = res[2]
    )), as.vector(inter[[1]]))
  })
  
  dbExecute(con, glue("drop table if exists {name}"))
  dbExecute(con, glue("create table {name}(rid serial primary key, rast raster)"))
  
  for (i in seq_along(info)) {
    xy = info[[i]][[1]]
    # create table with each value assigned to a row 
    dbWriteTable(con,
                 "rst_tile_val",
                 tibble(val = info[[i]][[3]],
                        y = sort(rep(
                          1:xy[2], xy[1]
                        ))),
                 overwrite = T)
    
    dims = info[[i]][[2]]
    
    # use tile dimensions to create empty raster and populate raster with values from rst_tile_val
    dbExecute(con, glue(
      "insert into {name}(rid, rast) 
     values({i},
     st_setvalues(
        st_addband(
            st_makeemptyraster({xy[1]}, {xy[2]}, {dims$x$offset},{dims$y$offset},{res[1]},{res[2]},{aff[1]},{aff[2]},{crs}),
            array[row(1,'{bit_depth}',0,-99999)]::addbandarg[]),
        1, 1, 1, (select array(select array_agg(val) from rst_tile_val group by y order by y)::double precision[][])
     ))"))
  }
  dbExecute(con,"drop table if exists rst_tile_val")
  dbExecute(con, glue("drop index if exists {name}_rast_idx"))
  # create spatial index
  dbExecute(con, glue("create index {name}_rast_idx on {name} using gist(st_convexhull(rast))")) 
}