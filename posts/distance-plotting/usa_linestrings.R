library(tidyverse)
library(sf)

# load data
cities <- read_csv("C:/Users/gioc4/Documents/blog/data/uscities.csv")
usa <- st_read("C:/Users/gioc4/Documents/blog/data/usa_states/cb_2018_us_state_500k.shp")

# create a base layer map
usa_map <-
  usa %>%
  filter(NAME %in% state.name,!NAME %in% c("Alaska", "Hawaii")) %>%
  st_transform(crs = 4326)

# subset 100 largest us cities
cities_sub <- cities %>%
  filter(state_name %in% state.name,!state_name %in% c("Alaska", "Hawaii")) %>%
  slice(1:50)

# function to iterate through n number of points
# given some input distance data 'dd'
# function expects to see a lng, lat
# and rows sorted by sequence

distance_linestring <- function(dd){
  points_list <- list()
  idx = 1
  for(i in 1:nrow(dd)){
    points_list[[idx]] <- st_point(c(dd$lng[idx],dd$lat[idx]))
    idx = idx+1
  }
  ls = st_linestring(do.call(rbind, points_list)) %>% st_sfc(crs = 4326)
  
  return(ls)
}

# let's draw a line between three random cities
N <- sample(1:length(cities_sub), 3)

d1 = distance_linestring(cities_sub[N,])


ggplot() +
  geom_sf(data = usa_map) +
  geom_sf(data = d1, color = '#BB5566', linewidth = 1)


st_length(d1)

# OK, let's simulate 50 people travelling up to 5 cities
# then we store the results in a list and plot them on a base map
linestring_list <- list()
iter = 100
max_N = 5

for(i in 1:iter){
 k <- sample(2:max_N,1)
 N <- sample(1:length(cities_sub),k)
 
 linestring_list[[i]] <- distance_linestring(cities_sub[N,])
}


# set up base map
base_map <- ggplot() + 
  geom_sf(data = usa_map, fill = '#FFFFFF', color = '#BBBBBB') 

# iterate through the list of locations and add each to the plot
for(p in 1:length(linestring_list)){
  base_map = base_map + geom_sf(data = linestring_list[[p]], color = '#BB5566', linewidth = 1, alpha = .3)
}

base_map +
  theme_void()

