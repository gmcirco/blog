library(tidyverse)
library(lubridate)

hartford_crime <- read_csv("C:/Users/gioc4/Documents/blog/data/Police_Crime_Data.csv")

mvt <- hartford_crime %>%
  filter(UCR_1_Category == '07* - MOTOR VEHICLE THEFT',
         Time_24HR != '2400') %>%
  mutate(date = as_date(Date),
         year = year(date),
         month = month(date),
         wday = wday(date, label = T),
         hour = substr(Time_24HR,1,2))

# Count, By Year
mvt %>%
  group_by(year) %>%
  count() %>%
  ggplot() +
  geom_line(aes(x = year, y = n))

# Proportion, By Day of Week
mvt %>%
  group_by(year, wday) %>%
  count() %>%
  group_by(year) %>%
  mutate(prop = n/sum(n)) %>%
  ggplot() +
  geom_line(aes(x = wday, y = prop, group = year), alpha = .2, linewidth = 1) +
  theme_minimal()

# Proportion, By Hour of Day
mvt %>%
  group_by(year, hour) %>%
  count() %>%
  group_by(year) %>%
  mutate(prop = n/sum(n)) %>%
  ggplot() +
  geom_line(aes(x = hour, y = prop, group = year), alpha = .2, linewidth = 1) +
  theme_minimal()

# Heatmap
mvt %>%
  group_by(wday,hour) %>%
  count() %>%
  ggplot() +
  geom_tile(aes(x=hour,y=wday, fill = n)) +
  coord_equal() +
  scale_fill_viridis_c() +
  theme_minimal()
