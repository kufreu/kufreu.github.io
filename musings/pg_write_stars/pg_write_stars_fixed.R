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
  
  to = dim(layer)
  
  x1 = seq(1,to[1],bx)
  if (x1[length(x1)] != to[1]) x2 = c(x1[-1]-1,to[[1]])
  width = map2(x1,x2,~c(.x,.y)) %>% do.call(what=rbind)
 
  y1 = seq(1,to[2],by)
  if (y1[length(y1)] != to[2]) y2 = c(y1[-1]-1,to[[2]])
  height = map2(y1,y2,~c(.x,.y))
  
  tiles = map(height,~cbind(width,.x[1],.x[2])) %>% do.call(what=rbind)
  
  
  # create a list with tile dimensions and values 
  info = map(1:nrow(tiles), function(x) {
    tile = tiles[x,]
    tile = layer[1,tile[1]:tile[2],tile[3]:tile[4]]
    list(dim(tile), st_bbox(tile)[c("xmin","ymax")], as.vector(tile[[1]]))
  })
  
  dbExecute(conn, glue("drop table if exists {name}"))
  dbExecute(conn, glue("create table {name}(rid serial primary key, rast raster)"))
  
  for (i in seq_along(info)) {
    xy = info[[i]][[1]]
    # create table with each value assigned to a row 
    dbWriteTable(con,
                 "rst_tile_val",
                 tibble(
                   val = info[[i]][[3]],
                   x = sort(rep(1:xy[2], xy[1])),
                   row_n = 1:prod(xy)
                 ) ,
                 overwrite = T)
    
    offset = info[[i]][[2]]
    
    # use tile dimensions to create empty raster and populate raster with values from rst_tile_val
    dbExecute(conn, glue(
    "insert into {name}(rid, rast) 
     values({i},
     st_setvalues(
        st_addband(
            st_makeemptyraster({xy[1]}, {xy[2]}, {offset['xmin']},{offset['ymax']},{res[1]},{res[2]},{aff[1]},{aff[2]},{crs}),
            array[row(1,'{bit_depth}',0,-99999)]::addbandarg[]),
        1, 1, 1,(select array(select array_agg(val)from (select val, x from rst_tile_val order by row_n) as rst group by x order by x))::double precision[][]
     ))"))
  }
  dbExecute(conn,"drop table if exists rst_tile_val") 
  dbExecute(conn, glue("drop index if exists {name}_rast_idx"))
  # create spatial index
  dbExecute(conn, glue("create index {name}_rast_idx on {name} using gist(st_convexhull(rast))")) 
}
