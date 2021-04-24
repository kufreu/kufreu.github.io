using dplyr and purrr in st\_segments
================

Although I was originally reluctant to solely use `dplyr` and `purrr`
because my first two slower, I went on to try to replace both loops in
[`st_segments`](https://kufreu.github.io/musings/st_segments/st_segments.nb.html)
with `tidyverse` functions.

``` r
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
      st_sfc(.$geometry, crs = st_crs(layer))
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
```

Rather than casting the features to points and working with two geometry
columns as I had with my first two attempts of the function, I went on
to make the coordinate matrix from `st_coordinates` a tibble and
replicated the loop in `st_segments` with `pmap` from `purrr` and
`lead`. I also found that using `st_as_binary` here is wholly
unnecessary and that doing without it leads to a considerable speed
increase. Straying away from the loops also makes the function more
readable.

``` r
bench::mark(
  base = st_geometry(st_segments(streets, 1)),
  "dplyr/purrr" = st_geometry(st_segments_tbl(streets, 1)),
  iterations = 5
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
    ## 1 base         31.71s  32.76s  33.68s              2.9GB          5        2.71m
    ## 2 dplyr/pur~    5.26s   5.44s   6.34s            131.8MB          5       28.04s

`st_segments_tbl` uses significantly less memory than `st_segments` and
takes a sixth of the time to run which is remarkable. It also runs
faster than the previous `dplyr` version of `st_segments`. What really
slows `st_segments` down seems to be the first loop as replacing the
second loop with either `dplyr` or `data.table` code did allow for the
function to run a little bit faster, though not considerably. This next
benchmark shows that this is indeed the case.

``` r
test = st_coordinates(streets)
bench::mark(
  loop = {
    (function(x) {
      col = ncol(x)
      ids = x[, col]
      feat = unique(ids)
      segments = list()

      for (i in feat) {
        coords = x[ids == i, ]
        for (j in 1:(nrow(coords) - 1)) {
          segments[[length(segments) + 1]] = st_as_binary(st_linestring(coords[j:(j + 1), 1:2]))
        }
      }
      st_as_sfc(segments)
    })(test)
  },
  tidy = {
    (function(x){
      as_tibble(x) %>%
        group_by(L1) %>%
        mutate(X2 = lead(X),
               Y2 = lead(Y)) %>%
        ungroup() %>%
        filter(!is.na(X2)) %>%
        mutate(geometry = pmap(list(X, Y, X2, Y2), function(x, y, x2, y2)
          st_linestring(rbind(
            c(x, y), c(x2, y2)
          )))) %>%
        {
          st_sfc(.$geometry)
        }
    })(test)
  },
  iterations = 50) %>%
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
    ##   name       min   median      max `memory allocation` iterations `total time`
    ##   <chr> <bch:tm> <bch:tm> <bch:tm>           <bch:byt>      <int>     <bch:tm>
    ## 1 loop     981ms    1.07s    1.44s             68.44MB         50       53.85s
    ## 2 tidy     172ms 194.54ms 266.53ms              2.29MB         50        9.83s

I was having trouble using `sym` within `bench::mark` so I needed to
explicitly state which column to group by in the tidy version. Even when
working with a smaller dataset, the same difference in time can be
observed between using a loop and `dplyr`/`purrr`. Looping through the
`st_coordinates` matrix still takes around six times as long to run.
Given just how much faster and more efficient `st_segments_tbl` is than
`st_segments`, `st_segments_tbl` may be my best option for now. Tibbles
print nicely so that's also a plus.
