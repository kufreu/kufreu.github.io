speeding st\_segments up with data.table
================

Although I already saw a drastic performance improvement with
[`st_segments_tbl`](https://kufreu.github.io/musings/st_segments_tbl/st_segments_tbl.nb.html),
I still wanted to go ahead and work with `data.table` to see if the
function can be made faster and more efficient.

``` r
st_segments_dt = function(x, max_length) {
  # breaks linestrings/polygons into line segments, keeps attributes
  # x: layer with linestrings
  # max_length: optional parameter, max length of segments, unit from crs
  library(sf)
  library(data.table)
  library(tibble)
  
  x$id = 1:nrow(x)
  
  if (!missing(max_length)) {
    x = st_segmentize(x, max_length)
  }
  
  coord = st_coordinates(x)
  col = ncol(coord)
  colname = colnames(coord)[col]
  
  geom = as.data.table(coord)
  geom[, `:=`(x2 = shift(X, type = "lead"), y2 = shift(Y, type = "lead")), by = colname]
  geom = na.omit(geom)
  geom[, rows := .I]
  geom[,geometry := .(list(st_linestring(rbind(c(X,Y),c(x2,y2))))), by = rows]
  geom = st_sfc(geom$geometry, crs = st_crs(x))
  
  fid = as.data.table(coord[, col])
  colnames(fid) = "id"
  setkey(fid, id)
  fid = fid[fid[, .I[-1], by = id]$V1][as.data.table(st_drop_geometry(x)), on = "id"]
  fid[, `:=`(geometry = geom, id = NULL)]
  st_sf(as_tibble(fid))
}
```

`st_segments_dt` essentially has the same structure as
`st_segments_tbl`, though everything save for the last line with
`as_tibble` is done using either `data.table` or `sf`. `as_tibble` is
not entirely necessary here but I prefer the print method of tibbles
over data.tables and `sf` supports tibbles.

``` r
bench::mark(
  "dplyr/purrr" = st_geometry(st_segments_tbl(streets,1)),
  data.table = st_geometry(st_segments_dt(streets,1)),
  iterations = 10
) %>%
  mutate(name = as.character(expression),
         max = bench::as_bench_time(lapply(time, max))) %>%
  select(
    name,
    min,
    median,
    max,
    "memory allocation" = mem_alloc,
    iterations = n_itr,
    "total time" = total_time
  )
```

    ## # A tibble: 2 x 7
    ##   name            min  median     max `memory allocatio~ iterations `total time`
    ##   <chr>      <bch:tm> <bch:t> <bch:t>          <bch:byt>      <int>     <bch:tm>
    ## 1 dplyr/pur~    5.36s   5.54s   5.88s              132MB         10        55.7s
    ## 2 data.table    5.16s   5.34s   5.61s              109MB         10        53.7s

`st_segments_dt` provides a slight improvement in speed and is more
efficient than `st_segments_tbl`. Both functions are still considerably
faster than `st_segments`.
