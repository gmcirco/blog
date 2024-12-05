library(tidyverse)
library(sf)

usa <- st_as_sf(maps::map("state", fill=TRUE, plot =FALSE))
gun_laws_state <- read_csv("C:\\Users\\gioc4\\Documents\\blog\\data\\state_firearm_database.csv")

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

# compute the number of restrictive and permissive gun laws
# enacted in the last 30ish years, as well as the ratio of
# permissive:restrictive laws
state_gun_law_total <-
  gun_laws_state %>%
  filter(`Effective Date Year` >= 1990, `Type of Change` %in% c("Implement","Modify","Repeal")) %>%
  mutate(permissive = ifelse(Effect == 'Permissive',1,0),
         restrictive = ifelse(Effect == 'Restrictive',1,0),
         State = tolower(State)) %>%
  group_by(State) %>%
  summarise(across(c (permissive,restrictive), sum)) %>%
  mutate(ratio = permissive/restrictive) %>%
  arrange(desc(ratio))

registered_map <-
  usa %>%
  inner_join(state_recoveries, by = c("ID" = "reg_state"))

gun_law_map <- 
  usa %>%
  inner_join(state_gun_law_total, by = c("ID" = "State"))


# plot the number of restrictive gun laws by state
gun_law_map %>%
  ggplot() +
  geom_sf(aes(fill = restrictive))+
  scale_fill_viridis_c(na.value = "white", option = "G") +
  labs(title = "Number of Restrictive Gun Laws (1990 - 2022)",
       subtitle = "Implemented Modified, or Repealed") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))


# ratio of permissive:restrictive
gun_law_map %>%
  ggplot() +
  geom_sf(aes(fill = ratio))+
  scale_fill_viridis_c(na.value = "white", option = "G") +
  labs(title = "Ratio of Permissive:Restrictive Gun Laws (1990 - 2022)",
       subtitle = "Implemented Modified, or Repealed") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))

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

# CA?
registered_map %>%
  filter(recov_state == 'california') %>%
  mutate(prop = round(guns/sum(guns),3)) %>%
  ggplot() +
  geom_sf(aes(fill = prop)) +
  scale_fill_viridis_c(na.value = "white") +
  labs(title = "Guns Recovered in NY (2019 - 2021), by State of Origin") +
  theme_void() +
  theme(legend.position = "bottom", legend.title = element_text(face = 'bold'))

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

state_recoveries_else %>%
  inner_join(state_gun_law_total, by = c("reg_state" = "State")) %>%
  inner_join(data.frame(reg_state = tolower(state.name), state_abb = state.abb)) %>%
  ggplot() +
  geom_text(
    aes(x = restrictive, y = prop, label = state_abb),
    size = 4,
    fontface = "bold",
    color = "#004488"
  ) +
  labs(title = "Number of Restrictive Gun Laws on Proportion of Imported Crime Guns", x = "Restrictive Gun Laws", y = "Proportion of Crime Guns") +
  scale_y_continuous(breaks = seq(0,1, by = .25)) +
  theme_bw() +
  theme(axis.text = element_text(size = 10, color = "black"))
