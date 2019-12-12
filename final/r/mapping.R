#### making maps ####

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


#### loading data ####
# data was in same folder as r project
tractsMI <- st_read(dsn = "censusMI.gpkg", layer = "tracts")
chicago <- st_read(dsn = "chicago.gpkg", layer = "tracts2010")
chicagoCBD <- st_read(dsn = "chicago.gpkg", layer = "CBD")


#### getting counties & tracts ####
tracts2 <- tractsMI %>%
  # making factors characters to make them easier to work with
  mutate(fips = as.character(COUNTYFP))

# counties divided into tracts
delta <- tracts2[tracts2$fips == "041", ]
berrien <- tracts2[tracts2$fips == "021", ]
gogebic <- tracts2[tracts2$fips == "053", ]
ontonagon <- tracts2[tracts2$fips == "131", ]
charlevoix <- tracts2[tracts2$fips == "029", ]
alger <- tracts2[tracts2$fips == "003", ]
washtenaw <- tracts2[tracts2$fips == "161", ]
keweenaw <- tracts2[tracts2$fips == "083", ]

# undivided counties
countiesMI <- tracts2 %>%
  group_by(fips) %>%
  summarize
delta <- countiesMI[countiesMI$fips == "041", ]
berrien <- countiesMI[countiesMI$fips == "021", ]
gogebic <- countiesMI[countiesMI$fips == "053", ]
ontonagon <- countiesMI[countiesMI$fips == "131", ]
charlevoix <- countiesMI[countiesMI$fips == "029", ]
alger <- countiesMI[countiesMI$fips == "003", ]
washtenaw <- countiesMI[countiesMI$fips == "161", ]
keweenaw <- countiesMI[countiesMI$fips == "083", ]


#### distance/direction function ####
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
  if (prefix == "") {
    result
  } else {
    result %>%
      rename(!!paste(prefix, "dist_unit", sep = "_") := dist_unit) %>%
      rename(!!paste(prefix, "dist_double", sep = "_") := dist_double) %>%
      rename(!!paste(prefix, "dir_degrees", sep = "_") := dir_degrees) %>%
      rename(!!paste(prefix, "card_ord", sep = "_") := card_ord)
  }
}


#### maps with tracts ####
#berrien
distdir_from_point(center = berrien,
                   layer = tractsMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  filter(cbd_card_ord == "N") %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = "white") +
  scale_fill_viridis() +
  labs(title = "Census Tracts North of Berrien County")


distdir_from_point(center = berrien,
                   layer = tractsMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  filter(cbd_card_ord == "N" & `Distance in Kilometers` >= 400) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = "white") +
  scale_fill_viridis() +
  labs(title = "Census Tracts North of Berrien County and >= 400km")


distdir_from_point(center = berrien,
                   layer = tractsMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  filter(cbd_card_ord == "NE" & `Distance in Kilometers` >= 200) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = NA) +
  scale_fill_viridis() +
  labs(title = "Census Tracts Northeast of Berrien County and >= 350km")

distdir_from_point(center = berrien,
                   layer = tractsMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  filter(`Distance in Kilometers` >= 100 & `Distance in Kilometers` <= 200) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = "white") +
  scale_fill_viridis() +
  labs(title = "Census Tracts Northeast of Berrien County and >= 350km")

distdir_from_point(layer = tractsMI, center = berrien) %>%
  ggplot() +
  geom_sf(aes(fill = card_ord), color = "gray") +
  scale_fill_discrete() +
  guides(fill = guide_legend(title = "Direction")) +
  labs(title = "Direction from Berrien County",
       subtitle = "distdir_from_point()")
# washtenaw
distdir_from_point(center = washtenaw,
                   layer = tractsMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  filter(cbd_card_ord == "NW") %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = NA) +
  scale_fill_viridis() +
  labs(title = "Census Tracts Northwest of Washtenaw County")




distdir_from_point(center = chicagoCBD,
                   layer = chicago,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = "gray") +
  scale_fill_viridis() +
  labs(title = "Distance from the CBD of Chicago")

# counties
centroidBerrien <- berrien %>%
  st_transform(3395) %>%
  st_geometry %>%
  st_centroid %>%
  st_sf() %>%
  mutate(name = "Berrien County") 


distdir_from_point(center = berrien,
                   layer = countiesMI,
                   prefix = "cbd") %>%
  mutate("Distance in Kilometers" = cbd_dist_double / 1000) %>%
  ggplot() +
  geom_sf(aes(fill = `Distance in Kilometers`),
          color = "white") +
  scale_fill_viridis() +
  labs(title = "Distance from Berrien County")


