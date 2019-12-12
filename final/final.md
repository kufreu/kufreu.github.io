# what happens in the end?
### about
For my final project, I replicated the QGIS model I created to calculate distance and direction from a given point with SQL using R and various R packages such as sf, sp, tidyverse, and geosphere. This was all done in [RStudio](https://rstudio.com/). In short, I converted the SQL used in the QGIS model into a function in R. Similar to the QGIS model, the function has three arguments/inputs: the input features, the layer from which direction is calculated, and an optional character string to prefix the new columns for distance and direction.  As with the original model, the intended application of this function is to calculate the distance and direction of features within a city from the city center or central business district, though as can be seen with my focus on caluclating distance and direction between tracts and counties in Michigan, the applications for the model are not limited to cities and CBDs. [Here](r/distdirFunction.R) is the function in its entirety. I will undoubtedly add comments to it in the next two days or so. 
### the function
```r
# commented code and other things should be added soon?
# this function is dependent on geosphere, tidyverse (mostly dplyr), sp, and sf
distdir_from_point <- function (layer, center, prefix = "") {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      layer %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_sf %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <-
      layer %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      center %>%
      as("sf") %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_sf %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <- layer %>%
      as("sf") %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  }
  result <- int %>%
    mutate(card_ord = ifelse(
      dir_degrees <= 22.5 |
        dir_degrees >= 337.5,
      "N",
      ifelse(
        dir_degrees <= 67.5 &
          dir_degrees >= 22.5,
        "NE",
        ifelse(
          dir_degrees <= 122.5 &
            dir_degrees >= 67.5,
          "E",
          ifelse(
            dir_degrees <= 157.5 &
              dir_degrees >= 112.5,
            "SE",
            ifelse(
              dir_degrees <= 292.5 &
                dir_degrees >= 247.5,
              "W",
              ifelse(
                dir_degrees <= 247.5 &
                  dir_degrees >= 202.5,
                "SW",
                ifelse(
                  dir_degrees <= 337.5 &
                    dir_degrees >= 292.5,
                  "NW",
                  ifelse(dir_degrees <= 202.5 &
                           dir_degrees >= 157.5, "S", "nirgendwo")
                )
              )
            )
          )
        )
      )
    ))
  if(prefix == ""){
    result 
  } else {
    result %>%
      rename(!! paste(prefix, "dist_unit", sep = "_"):= dist_unit) %>%
      rename(!! paste(prefix, "dist_double", sep = "_"):= dist_double) %>%
      rename(!! paste(prefix, "dir_degrees", sep = "_"):= dir_degrees) %>%
      rename(!! paste(prefix, "card_ord", sep = "_"):= card_ord)
  }
}
```
### sql that function was based on
```sql
select distDir.*,
case
when [% @Prefix %]Dir<=22.5 or [% @Prefix %]Dir>=337.5 then 'N'
when [% @Prefix %]Dir<=67.5 and [% @Prefix %]Dir>=22.5 then 'NE'
when [% @Prefix %]Dir<=122.5 and [% @Prefix %]Dir>=67.5 then 'E'
when [% @Prefix %]Dir<=157.5 and [% @Prefix %]Dir>=112.5 then 'SE'
when [% @Prefix %]Dir<=292.5 and [% @Prefix %]Dir>=247.5 then 'W'
when [% @Prefix %]Dir<=247.5 and [% @Prefix %]Dir>=202.5 then 'SW'
when [% @Prefix %]Dir<=337.5 and [% @Prefix %]Dir>=292.5 then 'NW'
when [% @Prefix %]Dir<=202.5 and [% @Prefix %]Dir>=157.5 then 'S'
end [% @Prefix %]CardOrd
from (select *,
       distance(centroid(transform((geometry),4326)),transform((select geometry from input1),4326), true) as [% @Prefix %]Dist,
      degrees(azimuth(transform((select geometry from input1),3395), centroid(transform((geometry),3395)))) as [% @Prefix %]Dir
      from input2) as distDir
```
### [maps](maps.md)
![what of it](images/finalDistanceTest.png)

### creating the function
The first step of making this function was to identify the packages I would need to use for this project, installing and loading them in RStudio when they were found. [Tidyverse](https://www.tidyverse.org/) was used because of the relative ease dplyr provides in manipulating data frames and ggplot2 to map results. I could have installed only these two packages from tidyverse, though I thought it would be best to play it safe as  the other packages which make up the tidyverse could also be of use. Along with tidyverse, [sf](https://r-spatial.github.io/sf/index.html) makes up the backbone of this function. Package sf provides simple features as data frames with a geometry list-column, which is a format I was familiar with coming from using tables in QGIS and PostGIS. It also has many of the geometry and geoemtric operations I need to make the function.     
```r
#### installation ####
install.packages("tidyverse","sf", "sp", "geosphere")

#### loading packages ####
library(tidyverse)
library(sf)
library(sp)
library(geosphere)
```
Initially, I thought that I would only need tidyverse and sf, though it soon became apparent that sf was not enough for what I was hoping to do and that I would need to use other packages to anaylze spatial data, these packages being [geosphere](https://cran.r-project.org/web/packages/geosphere/index.html) and [sp](https://cran.r-project.org/web/packages/sp/index.html), the package which it is dependent on. After these packages were loaded, the data being used  for test was loaded into RStudio using a function from sf. 
```r
tractsMI <- st_read(dsn = "censusMI.gpkg", layer = "tracts")
chicago <- st_read(dsn = "chicago.gpkg", layer = "tracts2010")
chicagoCBD <- st_read(dsn = "chicago.gpkg", layer = "CBD")
```
### data sources

### software 
[RStudio](https://rstudio.com/)

#### packages 
[tidyverse](https://www.tidyverse.org/)

[sf](https://r-spatial.github.io/sf/index.html)

[sp](https://cran.r-project.org/web/packages/sp/index.html)

[geosphere](https://cran.r-project.org/web/packages/geosphere/index.html)

