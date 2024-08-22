library(tidyverse)
library(duckdb)
library(sf)

# Data setup
# --------------------- #

# working directory and cfs data
wd <- "C:/Users/gioc4/Documents/blog/data/green_light/"
dir <- paste0(wd, "calls_all.csv")

# green light locations & precincts
dpd_precinct <- st_read(paste0(wd, "DPD_Precincts.shp")) %>%
  st_transform(crs = 2252)
green_light <- read_csv(paste0(wd, "Project_Green_Light_Locations.csv"))%>%
  mutate(live_date = as.Date(format(
    as.Date(green_light$greenlight_live_date), "%Y-%m-01"
  )))




# Local Functions
# --------------------- #

st_voronoi_point <- function(points){
  ## points must be POINT geometry
  # check for point geometry and execute if true
  if(!all(st_geometry_type(points) == "POINT")){
    stop("Input not  POINT geometries")
  }
  g = st_combine(st_geometry(points)) # make multipoint
  v = st_voronoi(g)
  v = st_collection_extract(v)
  return(v[unlist(st_intersects(points, v))])
}
  
# compute euclidean distance
edist <- function(a,b){
  sqrt(sum((a - b) ^ 2))
}


# SQL Queries
# --------------------- #

qu <- paste0(
  "SELECT
    incident_id, 
    incident_address,
    priority,
    callcode,
    calldescription,
    category,
    call_timestamp,
    precinct_sca,
    officerinitiated,
    longitude,
    latitude
  FROM 
    read_csv('", dir, "')
  WHERE 
    CAST(strftime(call_timestamp, '%Y') AS INT) > 2016
  AND 
    LEFT(precinct_sca, 1) = '9'
  AND 
    longitude IS NOT NULL
  AND 
    latitude IS NOT NULL;"
)

con = dbConnect(duckdb())
calls_for_service <- dbGetQuery(con, qu) %>%
  st_as_sf(coords = c("longitude","latitude"), crs = 4326) %>%
  st_transform(crs = 2252) %>%
  mutate(calls_X = st_coordinates(.)[,1],
         calls_Y = st_coordinates(.)[,2])
dbDisconnect(con)
                        
# 9th precinct only 2017+
greenlight_businesses <-
  green_light %>%
  filter(precinct == 9,
         year(greenlight_live_date) > 2016,!is.na(longitude),!is.na(latitude)) %>%
  distinct(X, Y, .keep_all = TRUE) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)%>%
  st_transform(crs = 2252)


greenlight_businesses_poly <-
  st_voronoi_point(greenlight_businesses) %>% 
  st_intersection(dpd_precinct[dpd_precinct$name == "09", ]) %>%
  st_as_sf() %>%
  mutate(business_id = greenlight_businesses$business_name,
         business_address = greenlight_businesses$address,
         live_date = greenlight_businesses$greenlight_live_date,
         business_X = st_coordinates(greenlight_businesses)[,1],
         business_Y = st_coordinates(greenlight_businesses)[,2])

business_crime <-
  st_join(calls_for_service, greenlight_businesses_poly) %>%
  tibble() %>% 
  select(incident_id,business_address, calls_X, calls_Y, business_X, business_Y) 

  
dmat <-
  matrix(
    c(
      business_crime$calls_X,
      business_crime$calls_Y,
      business_crime$business_X,
      business_crime$business_Y
    ),
    ncol = 4
  )

# compute pairwise distances
dlist <- list()
for(i in 1:nrow(dmat)){
  dlist[[i]] <- edist(c(dmat[i,1], dmat[i,2]), c(dmat[i,3], dmat[i,4]))
}

business_crime$dist <- unlist(dlist)

# get ids of within 300 meters
dist_ids <- business_crime$dist<= 400

# all businesses and voronai
ggplot() +
  geom_sf(data = greenlight_businesses_poly, fill = "#88CCEE", alpha = .3) +
  geom_sf(data = greenlight_businesses, color = '#004488', shape = 3, size = 2, stroke = 1.5) +
  theme_void()

# with cfs
ggplot() +
  geom_sf(data = greenlight_businesses_poly, fill = "#88CCEE", alpha = .3) +
  geom_sf(data = greenlight_businesses, color = '#004488', shape = 3, size = 2, stroke = 1.5) +
  geom_sf(data = calls_for_service[dist_ids,], color = '#BB5566', size = .6, alpha = .7) +
  theme_void()

test <-
business_crime %>%
  filter(dist <= 250) %>%
  left_join(calls_for_service) %>%
  filter(officerinitiated == 'Yes') %>%
  mutate(yr_mon = as.Date(format(call_timestamp, "%Y-%m-01"))) %>%
  group_by(business_address, yr_mon) %>%
  summarise(count = n(), .groups = 'drop') %>%
  complete(business_address, yr_mon, fill = list(count = 0)) %>%
  arrange(business_address, yr_mon)

test %>%
  ggplot() +
  geom_line(aes(x = yr_mon, y = count, group = 1)) +
  facet_wrap(~business_address)
