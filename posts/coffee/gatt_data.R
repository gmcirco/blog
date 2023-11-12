library(tidyverse)
library(lme4)

coffee <- read_csv("C:/Users/gioc4/Documents/blog/data/catt.csv")

# digging a bit deeper into personal preferences
# Two Questions

# 1: What demographic strata enjoy each coffee type the most (1-4)
# 2: What is the correlation between liking one type versus the other?
# 3: What is the probability if I score x_0 highly, I will also score x_1 highly?

# Set up Data
#----------------------#

# recode missing to "Not Provided"

coffee_data <-
  coffee %>%
  select(
    age = `What is your age?`,
    gender = `Gender`,
    race = `Ethnicity/Race`,
    education = `Education Level`,
    pref_a = `Coffee A - Personal Preference`,
    pref_b = `Coffee B - Personal Preference`,
    pref_c = `Coffee C - Personal Preference`,
    pref_d = `Coffee D - Personal Preference`
  ) %>%
  replace_na(
    list(
      age = 'Not Provided',
      gender = 'Not Provided',
      race = 'Not Provided',
      education = 'Not Provided'
    )
  )

# get strata averages and counts
tab1 <- coffee_data %>%
  group_by(age, gender, race, education) %>%
  summarise(across(contains("pref"), mean, na.rm = T),
            n = n())


# OK, if I rank coffee D highly, what is the probability that I score C highly?
coffee_ranking <- 
coffee_data %>%
  na.omit() %>%
  select(pref_a:pref_d) %>%
  pivot_longer(cols = starts_with("pref"), 
               names_to = "coffee", 
               values_to = "ranking")

counts <-
  coffee_data %>%
  select(starts_with("pref")) %>%
  na.omit() %>%
  count(pref_a, pref_b, pref_c, pref_d)


lm(pref_d ~ pref_a + pref_b + pref_c, data = counts)
