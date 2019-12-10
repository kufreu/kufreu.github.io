#### final project ####

# with this project, I attempted to replicate the distance and direction model that I created in the QGIS modeler using SQL

# this is the SQL used in the original/updated model to calculate distance and direction from a point.

# select distDir.*,
# case
# when [% @Prefix %]Dir<=22.5 or [% @Prefix %]Dir>=337.5 then 'N'
# when [% @Prefix %]Dir<=67.5 and [% @Prefix %]Dir>=22.5 then 'NE'
# when [% @Prefix %]Dir<=122.5 and [% @Prefix %]Dir>=67.5 then 'E'
# when [% @Prefix %]Dir<=157.5 and [% @Prefix %]Dir>=112.5 then 'SE'
# when [% @Prefix %]Dir<=292.5 and [% @Prefix %]Dir>=247.5 then 'W'
# when [% @Prefix %]Dir<=247.5 and [% @Prefix %]Dir>=202.5 then 'SW'
# when [% @Prefix %]Dir<=337.5 and [% @Prefix %]Dir>=292.5 then 'NW'
# when [% @Prefix %]Dir<=202.5 and [% @Prefix %]Dir>=157.5 then 'S'
# end [% @Prefix %]CardOrd
# from (select *,
#       distance(centroid(transform((geometry),4326)),transform((select geometry from input1),4326), true) as [% @Prefix %]Dist,
#       degrees(azimuth(transform((select geometry from input1),3395), centroid(transform((geometry),3395)))) as [% @Prefix %]Dir
#       from input2) as distDir


#https://bakaniko.github.io/FOSS4G2019_Geoprocessing_with_R_workshop/

#### getting things in order ####
install.packages("tidyverse")
install.packages("sf")
install.packages("sp")
install.packages("RcolorBrewer")
install.packages("geosphere")
install.packages("viridis")


library(tidyverse)
library(sf)
library(sp)
library(RColorBrewer)
library(geosphere)
library(viridis)
library(viridisLite)


#### a dark theme ####
install.packages("devtools")
devtools::install_github("gadenbuie/rsthemes")
rsthemes::install_rsthemes()
rstudioapi::applyTheme("One Dark {rsthemes}")

#### loading data ####
# data was in same folder as r project
tractsMI <- st_read(dsn = "censusMI.gpkg", layer = "tracts")
chicago <- st_read(dsn = "chicago.gpkg", layer = "tracts2010")
chicagoCBD <- st_read(dsn = "chicago.gpkg", layer = "CBD")

#### looking at the tracts ####
ggplot(tractsMI) +
  geom_sf()

ggplot() +
  geom_sf(data = chicago) +
  geom_sf(data = chicagoCBD)

#### SQL / first batch of things to be converted ####
#distance(centroid(transform((geometry),4326)),transform((select geometry from input1),4326), true) as [% @Prefix %]Dist,
#degrees(azimuth(transform((select geometry from input1),3395), centroid(transform((geometry),3395)))) as [% @Prefix %]Dir
#from input2) as distDir

# when creating this function, I thought it would be in my best interest to learn how to use the functions that were used in SQL for R from the sf package

#### testing st_transform ####
View(tractsMI %>%
       st_transform(4326))

#### learning how to dissolve  from Phil Mike Jones####
#https://philmikejones.me/tutorials/2015-09-03-dissolve-polygons-in-r/
# At first I thought it would be best to dissolve the inputs of the functions rather than try to calculate mean coordinates 

tractsMI$area <- st_area(tractsMI)

michigan <-
  tractsMI %>%
  summarize(area = sum(area))

ggplot(michigan2) + geom_sf()

# OR

michigan <-
  tractsMI %>%
  mutate(state = "michigan") %>%
  group_by(state) %>%
  summarize()

ggplot(michigan) + geom_sf()

# Phil Mike Jones: create a column to group_by() so that the features (rows) that are to be grouped together are given the same data if you don’t have or want data to save the dissolve

#### making centroids ####
centroidTracts <- st_centroid(tractsMI)
ggplot() +
  geom_sf(data = centroidTracts)

# went on and ignored the warning 

#### making a centroid on a dissolved shape ####
# from sf package
center <-
  tractsMI %>%
  mutate(area = st_area(tractsMI)) %>%
  summarize(area = sum(area)) %>%
  st_centroid()

# from geosphere package
center <-
  tractsMI %>%
  mutate(area = st_area(tractsMI)) %>%
  summarize(area = sum(area)) %>%
  # geosphere uses objects with "spatial" class from the sp package, which I'm not using 
  # I need to convert my objects because of this before making a centroid
  as_Spatial() %>%
  centroid()

# alternate way to dissolve
center <-
  tractsMI %>%
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize() %>%
  st_centroid()


ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = center)

# I ended up using st_centroid because it gave a result which I could easily use and map

#### how does one use st_distance with sf?####
View(st_distance(centroidTracts, center))

#### testing the waters / making a function to calculate distance ####
# making a function to calculate distance from a centroid made on the dissovled geometries of all features
distTest <- function(layer) {
  tbd <- layer %>%
    #transforming to wgs 84 and adding a field to base the dissolve
    st_transform(4326) %>%
    mutate(area = st_area(layer))
  #dissolving layer and making a centroid on dissolved shape
  center <-
    tbd %>%
    summarize(area = sum(area)) %>%
    st_centroid()
  result <- tbd %>%
    mutate(dist = as.double(st_distance(st_centroid(tbd), center)))
}

#### mapping distance test ####
ggplot() +
  geom_sf(data = test, aes(fill = cut_number(dist, 7)), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "distance in meters")) +
  labs(title = "distance test",
       subtitle = "distTest()") +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )
#### pipe dreams / testing pipes in R ####
central <-
  tractsMI %>%
  st_transform(4326) %>%
  mutate(area = st_area(tractsMI)) %>%
  summarize(area = sum(area)) %>%
  st_centroid()

ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = central)


### adding another argument to the distance function ###
distTest2 <- function (layer, center) {
  # center is an optional argument to add a point or polygon(s) from which to calculate distance and direction
  # if center is missing, the a centroid is made on the inputted layer and distance is calculated from it
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(4326) %>%
      mutate(area = st_area(layer))
    cbd <-
      wgs84 %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <-
      wgs84 %>%
      mutate(dist = as.double(st_distance(st_centroid(wgs84), cbd)))
  } else {
    wgs84 <-
      layer %>% st_transform(4326)
    cbd <-
      center %>%
      st_transform(4326) %>%
      mutate(area = st_area(center)) %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <- wgs84 %>%
      mutate(dist = as.double(st_distance(st_centroid(wgs84), cbd)))
  }
}

# making  various centers to test new argument and just to see counties in Michigan I like 
tracts2 <- tractsMI %>%
  # making factors characters to make them easier to work with
  mutate(fips = as.character(COUNTYFP))

delta <- tracts2[tracts2$fips == "041",]

ggplot() +
  geom_sf(data = delta)

berrien <- tracts2[tracts2$fips == "021",]

ggplot() +
  geom_sf(data = berrien)

gogebic <- tracts2[tracts2$fips == "053",]

ggplot() +
  geom_sf(data = gogebic)

ontonagon <- tracts2[tracts2$fips == "131",]

ggplot() +
  geom_sf(data = ontonagon)

charlevoix <- tracts2[tracts2$fips == "029",]

ggplot() +
  geom_sf(data = charlevoix)

alger <- tracts2[tracts2$fips == "003",]

ggplot() +
  geom_sf(data = alger)

#### mapping tests with/without center ####
test <- distTest2(tractsMI)

test <- distTest2(tractsMI, delta)

test <- distTest2(tractsMI, berrien)

test <- distTest2(tractsMI, gogebic)

test <- distTest2(tractsMI, ontonagon)

test <- distTest2(tractsMI, charlevoix)

test <- distTest2(tractsMI, alger)
                
ggplot(data = test) +
  geom_sf(aes(fill = dist), color = NA) 
  
  
#### making dist_from_point ####
dist_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(4326) %>%
      mutate(area = st_area(layer))
    cbd <-
      wgs84 %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <-
      wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd))
      )
  } else {
    wgs84 <-
      layer %>% st_transform(4326)
    cbd <-
      center %>%
      st_transform(4326) %>%
      mutate(area = st_area(center)) %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <- wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd))
      )
  }
}


#### st_geod_azimuth, lost but not forgetten ####
# I tried to use st_geod_azimuth from the sf package though couldn't find a way to supply more than one argument to it
# most of what below is a mess, doesn't do anything of value, or is a combination of both
as.double(st_geod_azimuth(st_centroid(st_transform(tractsMI, 4326))))

for (i in 1:nrow(2)) {
  mutate(centroidTracts2,
         direction = st_geod_azimuth(st_sfc(centroidTracts$geom[[i]], center)))
}

why <-
  do.call(rbind, apply(centroidTracts, 1, function(x) {
    rbind(x, na.cendroid)
  }))


what <- tractsMI %>%
  rowwise() %>%
  st_sfc(tractsMI, center)


atest <- centroidTracts %>%
  mutate(centroidTracts,
         direction = rowwise() %>%
           st_geod_azimuth(st_sfc(geom , center)))

str(st_geod_azimuth(st_centroid(st_transform(tractsMI, 4326)))[[1]][[1]])



#### using geosphere, bearing() vs bearingRhumb() ####

# geosphere was the best alternative to calculate direction, though I had to decide which of the two available functions in the package I would use

View((bearing(
  as_Spatial(st_transform(centroidTracts, 4326)), as_Spatial(st_transform(center, 4326))
) + 360) %% 360)

# these geosphere function require objects to have "spatial" class so sf objects are given this class with as_Spatil

View((bearingRhumb(
  as_Spatial(st_transform(centroidTracts, 4326)), as_Spatial(st_transform(center, 4326))
) + 360) %% 360)

# both bearing and bearingRhumb require geometries that are in lat/long which is why they objects were transformed to wgs 84

# both also give answers in degrees ranging from 180 to -180, so modular division was used to make the answers from 0 to 360 degrees

#### making a direction function ####
dirTest <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(4326) %>%
      mutate(area = st_area(layer))
    cbd <-
      wgs84 %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <-
      wgs84 %>%
      mutate(direction = (bearing(
        as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
      ) + 360) %% 360)
  } else {
    wgs84 <-
      layer %>% st_transform(4326)
    cbd <-
      center %>%
      st_transform(4326) %>%
      mutate(area = st_area(center)) %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <- wgs84 %>%
      mutate(direction = (bearing(
        as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
      ) + 360) %% 360)
  }
}

#### mapping direction test ####
dirtesting <- dirTest(tractsMI, berrien)

ggplot() +
  geom_sf(data = dirtesting, aes(fill = cut_number(direction, 4)), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "direction in degrees")) +
  labs(title = "direction test",
       subtitle = "dirTest(tractsMI, berrien)") +
  theme(
    plot.title = element_text(hjust = 0),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )


#### creating distance/direction ####
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(4326) %>%
      mutate(area = st_area(layer))
    cbd <-
      wgs84 %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <-
      wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd)),
        dir_degrees = (bearing(
          as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
        ) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>% st_transform(4326)
    cbd <-
      center %>%
      st_transform(4326) %>%
      mutate(area = st_area(center)) %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    result <- wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd)),
        dir_degrees = (bearing(
          as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
        ) + 360) %% 360
      )
  }
}

#### more SQL to be converted, cardinal and ordinal directions ####
# case
# when [% @Prefix %]Dir<=22.5 or [% @Prefix %]Dir>=337.5 then 'N'
# when [% @Prefix %]Dir<=67.5 and [% @Prefix %]Dir>=22.5 then 'NE'
# when [% @Prefix %]Dir<=122.5 and [% @Prefix %]Dir>=67.5 then 'E'
# when [% @Prefix %]Dir<=157.5 and [% @Prefix %]Dir>=112.5 then 'SE'
# when [% @Prefix %]Dir<=292.5 and [% @Prefix %]Dir>=247.5 then 'W'
# when [% @Prefix %]Dir<=247.5 and [% @Prefix %]Dir>=202.5 then 'SW'
# when [% @Prefix %]Dir<=337.5 and [% @Prefix %]Dir>=292.5 then 'NW'
# when [% @Prefix %]Dir<=202.5 and [% @Prefix %]Dir>=157.5 then 'S'
# end [% @Prefix %]CardOrd


#### adding cardinal directions ####
#if(){ vs ifelse
#ifelse()
dirtesting <- distdir_from_point(tractsMI)
View(dirtesting %>%
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
                              dir_degrees >= 157.5, "S", "nichts")
                   )
                 )
               )
             )
           )
         )
       )))
# if{}else
View(dirtesting %>%
       mutate(card_ord =
                if ('dir_degrees' <= 22.5 |
                    'dir_degrees' >= 337.5) {
                  "N"
                } else {
                  "warum"
                }))


#### going with ifelse(), adding to function ####
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(4326) %>%
      mutate(area = st_area(layer))
    cbd <-
      wgs84 %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    int <-
      wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd)),
        dir_degrees = (bearing(
          as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
        ) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>% st_transform(4326)
    cbd <-
      center %>%
      st_transform(4326) %>%
      mutate(area = st_area(center)) %>%
      summarize(area = sum(area)) %>%
      st_centroid()
    int <- wgs84 %>%
      mutate(
        dist_unit = st_distance(st_centroid(wgs84), cbd),
        dist_double = as.double(st_distance(st_centroid(wgs84), cbd)),
        dir_degrees = (bearing(
          as_Spatial(cbd), as_Spatial(st_centroid(wgs84))
        ) + 360) %% 360
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}
# this works, though there are some warning messages with st_centroid which I've mostly ignored and some other things that can be changed

#### mapping for distance and direction function result  ####
test <- distdir_from_point(tractsMI)

ggplot() +
  geom_sf(data = test, aes(fill = card_ord), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "direction in degrees")) +
  labs(title = "direction test",
       subtitle = "distdir_from_point()") +
  theme(
    plot.title = element_text(hjust = 0),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )
#### editing wgs84 object and st_centroid() warnings ####
# Warning: st_centroid does not give correct centroids for longitude/latitude data
# Warning message:
# In st_centroid.sf(.) :
#   st_centroid assumes attributes are constant over geometries of x

#https://github.com/r-spatial/sf/issues/406

# testing st_centroid with projected mercator and adding st_geometry
test <- tractsMI %>%
  st_transform(3395) %>%
  st_geometry %>%
  st_centroid() %>%
  st_transform(4326)

ggplot() +
  geom_sf(data = test)

# seing if it projected correctly
st_crs(test)

# testing st_centroid with projected mercator, adding st_geometry, and using an alternative way to dissolve
test <- tractsMI %>%
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize() %>%
  st_transform(3395) %>%
  st_geometry() %>%
  st_centroid() %>%
  st_transform(4326)

# it worked! (no warning)

#mapped results
ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = test)


# function with edited wgs84 and dissolve
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      # I removed the parentheses because I realized they weren't necessary
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      layer %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <-
      layer %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      center %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <- layer %>%
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}

#### testing out final? functioon ####
test <- distdir_from_point(tractsMI)

ggplot() +
  geom_sf(data = test, aes(fill = cut_number(dist_double, 6), color = "grey")) +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "distance in meters")) +
  labs(title = "distance test",
       subtitle = "distdir_from_point(tractsMI)") +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )

#### final function? ####
distdir_from_point <- function (layer, center) {
  if (missing(center)) {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      layer %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <-
      layer %>%
      mutate(
        dist_unit = st_distance(wgs84, cbd),
        dist_double = as.double(st_distance(wgs84, cbd)),
        dir_degrees = (bearing(as_Spatial(cbd), as_Spatial(wgs84)) + 360) %% 360
      )
  } else {
    wgs84 <-
      layer %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    cbd <-
      center %>%
      mutate(nichts = "nichts") %>%
      group_by(nichts) %>%
      summarize %>%
      st_transform(3395) %>%
      st_geometry %>%
      st_centroid %>%
      st_transform(4326)
    int <- layer %>%
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}

test <- distdir_from_point(tractsMI)

#### further testing of the function ####
# this worked, though I also wanted to see if you can put points into the function

centroidsDelta <- delta %>%
  transform(3395) %>%
  st_centroid

point_test <- distdir_from_point(tractsMI, centroidsDelta)


ggplot() +
  geom_sf(data = point_test, aes(fill = cut_number(dist_double, 5)), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "distance in meters")) +
  labs(title = "distance test",
       subtitle = "distTest()") +
  theme(
    plot.title = element_text(hjust = 1),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )

ggplot() +
  geom_sf(data = point_test, aes(fill = card_ord), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "Direction")) +
  labs(title = "direction test",
       subtitle = "distdir_from_point()") +
  theme(
    plot.title = element_text(hjust = 0),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )

#vs

tract_test <- distdir_from_point(tractsMI, delta)

ggplot() +
  geom_sf(data = tract_test, aes(fill = card_ord), color = "grey") +
  scale_fill_brewer(palette = "YlGnBu") +
  guides(fill = guide_legend(title = "Direction?")) +
  labs(title = "direction test",
       subtitle = "distdir_from_point()") +
  theme(
    plot.title = element_text(hjust = 0),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )

# making centroid from centroids because it seems as though it looks fine?
centroidDelta <- centroidsDelta %>%
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize %>%
  st_transform(3395) %>%
  st_geometry %>%
  st_centroid %>%
  st_transform(4326)

# vs from dissolved tracts
dissolved_delta <-
  delta %>%
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize %>%
  st_transform(3395) %>%
  st_geometry %>%
  st_centroid

ggplot() +
  geom_sf(data = delta) +
  geom_sf(data = dissolved_delta, color = "blue") +
  geom_sf(data = centroidDelta) +
  geom_sf(data = centroidsDelta, color = "red")


# looking at michigan as a whole
michigan_centroids <-
  tractsMI %>%
  # centroids on tracts
  st_transform(3395) %>%
  st_centroid

michigan_centroid <-
  # centroid made from dissolved centroids
  michigan_centroids %>%
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize %>%
  st_transform(3395) %>%
  st_centroid

oneMichigan <- michigan %>%
  # centroid made from dissolved tracts
  st_transform(3395) %>%
  st_centroid

ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = michigan_centroid, color = 'red') + 
  geom_sf(data = oneMichigan)

# creating centroids from centroids (mean coordinates) rather than dissolving the original provides a result closer to the orginal qgis model
# the red point in the map above is exactly where distance/direction would be calcualted from in the QGIS model if tractsMI was supplied as an input layer for cbd
# I both added and forgot a step: added dissolving which wasn't originally in the model and forgot to make centroids


# I made a model in QGIS which created centroids, dissolved those centroids, and then created another centroid from what was dissovled
# this gave the same result as making centroids and then finding the mean coordinates of those centroids

#### function edits cont. ####
test <-
  tractsMI %>%
  #moved the functions used to dissolve the geometries
  st_transform(3395) %>%
  st_geometry %>%
  st_centroid %>%
  # got an error from using a list of geometries, so I needed to make it an sf object again
  # https://github.com/r-spatial/sf/issues/243
  st_sf %>%
  # creating centroids and then dissolving
  mutate(nichts = "nichts") %>%
  group_by(nichts) %>%
  summarize %>%
  # this should result in the mean coordinates
  st_geometry %>%
  st_centroid %>%
  st_transform(4326)

ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = test)


# I thought it would also be good to allow for objects with spatial class to be used so I added as("sf") to coerce objects with spatial class into sf objects
# testing 

spatialMI <- as_Spatial(tractsMI)

test <-
  spatialMI %>%
  # making sf object 
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

ggplot() +
  geom_sf(data = michigan) +
  geom_sf(data = test)



#### adding edits to function ####
distdir_from_point <- function (layer, center) {
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}

#### testing and mapping new function output ####
test <- distdir_from_point(spatialMI, delta) %>%
  mutate("Distance in Kilometers" = dist_double / 1000) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = NA) +
  scale_fill_continuous(type = "viridis") +
  labs(title = "Distance Test with Final Function",
       subtitle = "distdir_from_point(spatialMI, delta)")

test <- distdir_from_point(spatialMI, delta) %>%
  ggplot() +
  geom_sf(aes(fill = card_ord), color = NA) +
  scale_fill_viridis(discrete = TRUE)

#### final function ####
distdir_from_point <- function (layer, center) {
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
                           dir_degrees >= 157.5, "S", "nichts")
                )
              )
            )
          )
        )
      )
    ))
}


