##### script used to load data into database  

#install package for twitter and initialize the library
install.packages("tidycensus")
install.packages("RPostgreSQL")
library(tidycensus)
library(RPostgreSQL)


# getting counties from census
Counties <- get_estimates("county",product="population",output="wide",geometry=TRUE,keep_geo_vars=TRUE, key="woot")


# connecting to the postgis database
con <- dbConnect(RPostgres::Postgres(), dbname='eh', host='nope', user='meh', password='ha') 

counties<-lownames(Counties)

#writing data to the database 
dbWriteTable(con,'dorian',dorian, overwrite=TRUE)
dbWriteTable(con,'november',november, overwrite=TRUE)
dbWriteTable(con,'counties',counties, overwrite=TRUE)


#disconnecting from the database
dbDisconnect(con)




