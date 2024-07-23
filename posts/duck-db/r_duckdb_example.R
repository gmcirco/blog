# EXAMPLE SCRIPT FOR DUCKDB
# ========================= #

library(tidyverse)
library(duckdb)
library(sf)

wd <- "C:/Users/gioc4/Documents/blog/data/"
file_name <- "crime.csv"
dir <- paste0(wd,file_name)

# Set up a duckdb connector
# use the built-in read_csv function to pull from our file
con = dbConnect(duckdb())
dbGetQuery(con, sprintf("SELECT * FROM read_csv('%s') LIMIT 10", dir))

# some example functions
# get counts of all crime types, by year-month
qu = 
  "SELECT
      crime_type,
      yr_mon,
      COUNT(crime_type) AS N
  FROM
      read_csv('%s')
  GROUP BY
      crime_type,
      yr_mon
  ORDER BY
      crime_type,
      yr_mon"

dbGetQuery(con, sprintf(qu, dir)) 

# Let's pull just 1000 property crimes, convert to an sf, then plot
qu =
  "SELECT *
  FROM 
      read_csv('%s')
  WHERE 
      crime_type = 'property'
  LIMIT 1000"

property_crimes <- st_as_sf(dbGetQuery(con, sprintf(qu, dir)), coords = c('lon','lat'), crs = 4326)

plot(property_crimes)

# same as above, but we for-loop through multiple crime types
# and add them to a list
crime_types <- c("property","violent","disorder")
crime_list = vector(mode = "list", length = length(crime_types))
idx = 1

qu =
  "SELECT *
  FROM 
      read_csv('%s')
  WHERE 
      crime_type = '%s'
  LIMIT 1000" 

# this loops through all of the listed crime types
# performs the query, then converts it to a shapefile
# this is then added to the list we created, for each index 'idx'
for(crime in crime_types){
  crime_list[[idx]] <- st_as_sf(dbGetQuery(con, sprintf(qu, dir, crime)), coords = c('lon','lat'), crs = 4326)
  idx=idx+1
}

# quick plot
par(mfrow = c(2,2))
sapply(crime_list, function(x) plot(st_geometry(x)))
