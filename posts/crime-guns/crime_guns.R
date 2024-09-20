library(tidyverse)
library(sf)

usa <- st_as_sf(maps::map("state", fill=TRUE, plot =FALSE))

# params
years <- c(2019,2020,2021)
state_recovery_list <- list()

# function to pull data from specific year
pull_data <- function(year){
  recoveries <- read_csv(
    sprintf("C:\\Users\\gioc4\\Documents\\blog\\data\\gun_seizure\\gun_recovery_%s.csv", year)
  ) %>%
    fill(REGISTERED_STATE) %>%
    filter(TIME_RANGE != 'Average Time-to-Crime in Years') %>%
    mutate(across(everything(), ~ str_replace(., ",", "")))
  
  return(recoveries)
}



idx = 0
for(year in years) {
  idx = idx+1
  
  # add state recoveries
  state_recovery_list[[idx]] <-  pull_data(year) %>%
    select(-TOTAL) %>%
    pivot_longer(c(-REGISTERED_STATE, -TIME_RANGE)) %>%
    mutate(
      value = as.numeric(value),
      reg_state = tolower(REGISTERED_STATE),
      recov_state = tolower(name),
      year = year
    ) %>%
    group_by(year, reg_state, recov_state) %>%
    summarise(guns = sum(value, na.rm = T))
}

# now combine
state_recoveries <- do.call(rbind, state_recovery_list) %>%
  group_by(reg_state, recov_state) %>%
  summarise(guns = sum(guns))

state_recoveries_else <- state_recoveries %>%
  group_by(recov_state) %>%
  mutate(prop = 1 - guns/sum(guns)) %>%
  filter(reg_state == recov_state) %>%
  ungroup()


registered_map <-
  usa %>%
  inner_join(state_recoveries, by = c("ID" = "reg_state"))


# what proportion of guns recovered from IL come from elsewhere?
registered_map %>%
  filter(recov_state == 'illinois') %>%
  mutate(prop = round(guns/sum(guns),3)) %>%
  ggplot() +
  geom_sf(aes(fill = prop)) +
  scale_fill_viridis_c(na.value = "white") +
  labs(title = "Guns Recovered in IL (2019 - 2021), by State of Origin") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))
ggsave("plot3.png", bg = "white")

# what proportion in NY?
registered_map %>%
  filter(recov_state == 'new york') %>%
  mutate(prop = round(guns/sum(guns),3)) %>%
  ggplot() +
  geom_sf(aes(fill = prop)) +
  scale_fill_viridis_c(na.value = "white") +
  labs(title = "Guns Recovered in NY (2019 - 2021), by State of Origin") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))
ggsave("plot2.png", bg = "white")

# what proportion of recovered guns are NOT from the same state they were registered?
state_recoveries_else%>%
  filter(recov_state != "district of columbia", reg_state != "district of columbia") %>%
  inner_join(usa, state_recoveries, by = c("reg_state" = "ID")) %>%
  st_as_sf() %>%
  ggplot() +
  geom_sf(aes(fill = prop)) +
  scale_fill_viridis_c(na.value = "white", option = "D") +
  labs(title = "Proportion of Seized Crime Guns Registered in Other State") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))
ggsave("plot1.png", bg = "white")
