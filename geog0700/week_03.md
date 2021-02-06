# delving more into kang et al. and looking beyond
This week undoubtedly was a slow one for me. I had another go at running the [COVID-19 Accessibility Notebook](https://github.com/cybergis/COVID-19AccessibilityNotebook) locally and on CyberGISX though had limited success. I was able to download the network file for Illinois locally using a Jupyter Notebook but the code never completed running even after several days of waiting. I moved on from this notebook to look at the [Multiscale Dynamic Human Mobility Flow Dataset](https://github.com/GeoDS/COVID19USFlows). I followed the thorough instructions on the repository's README and had success getting data at the county level. I used two scripts from the repository to download the data and merge it into one file: [download_daily_data.py](https://github.com/GeoDS/COVID19USFlows/blob/master/codes/download_daily_data.py) and [merge_files.py](https://github.com/GeoDS/COVID19USFlows/blob/master/codes/merge_files.py).

```r
library(reticulate)
library(stringr)
library(glue)

os = import("os")

os$system(str_remove_all(
  glue(
    "python download_daily_data.py
    --start_year 2020
    --start_month 7
    --start_day 3
    --end_day 5  
    --output_folder data
    --county"
  ),
  "\n"
))

os$system(
    "python merge_files.py -i data/county2county -o cnty_fourth"
)
```
Although this is not the route that I took, this is how the data could be retrieved using a Jupyter Notebook.

```python
%run download_daily_data.py --start_year 2020 --start_month 7 --start_day 3 --end_day 5 --output_folder data --county
%run  merge_files.py -i data/county2county -o cnty_fourth
```
I did not  work with the data as much as I would have liked, though I did get as far as filtering the data to movement to counties in Vermont.  

```r
library(data.table)
library(sf)
library(s2)

sf_use_s2(T)

states = tigris::states() %>% st_transform(4326)
county = fread("cnty_fourth")
county[, id := .I]
setkey(county,"id")

county[, `:=`(o_point =
                list(st_point(c(lng_o, lat_o)))
              ,
              d_point = list(st_point(c(lng_d, lat_d)))
              ),
       by = id]

o = st_sfc(county$o_point, crs = 4326)
d = st_sfc(county$d_point, crs = 4326)

county[,`:=`(origin = o, destination = d)]

vt = states[states$NAME == "Vermont",]

vermont = county[
    lengths(
      st_intersects(
        county$destination, vt
      )
    ) > 0,
  ]
```
Using download_daily_data.py, I was unable to get daily data for census tracts, which was the scale I originally wanted to work with. I wrote a short script based on download_daily_data.py that only downloads daily data for census tracts to circumvent the problem rather than face it.

```r
# getting daily data for census tracts ------------------------------------
library(vroom)
library(lubridate)
library(glue)
library(purrr)

# required
start_year = 2020
start_month = 7
start_day = 3
output_folder = "data"

# optional
end_year = NULL
end_month = NULL
end_day = 5

if (is.null(end_year)) end_year = start_year

if (is.null(end_month)) end_month = start_month

if (is.null(end_day)) end_day = start_day

if (!dir.exists(output_folder)) dir.create(output_folder)

if (!dir.exists(glue("{output_folder}/ct2ct"))) dir.create(glue("{output_folder}/ct2ct"))

sdate = ymd(glue("{start_year}-{start_month}-{start_day}"))
edate = ymd(glue("{end_year}-{end_month}-{end_day}"))  

dates = seq(sdate,edate, by = "day")

map(dates, function(x) {
  d = day(x)
  if (d < 10) d = glue("0{d}")

  m = month(x)
  if (m < 10) m = glue("0{m}")

  y = year(x)

  if (!dir.exists(glue("{output_folder}/ct2ct/{y}_{m}_{d}"))) {
    dir.create(glue("{output_folder}/ct2ct/{y}_{m}_{d}"))
  }

  map(0:19, function(z)
    vroom(
      glue(
        "https://raw.githubusercontent.com/GeoDS/COVID19USFlows/master/daily_flows/ct2ct/{y}_{m}_{d}/daily_ct2ct_{y}_{m}_{d}_{z}.csv"
      )
    ) %>%
      vroom_write(
        glue("{output_folder}/ct2ct/{y}_{m}_{d}/daily_ct2ct_{y}_{m}_{d}_{z}.csv")
      )
    )
})
```
