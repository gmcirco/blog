# R CODE TO SELECT SUBSET OF CASES
# ---------------------- #

library(tidyverse)
set.seed(5698745)

N <- 200
narratives <- read_csv(
  "C:\\Users\\gioc4\\Documents\\blog\\gcirco_blog\\posts\\prompt-testing\\data\\train_features.csv"
)
labels <- read_csv(
  "C:\\Users\\gioc4\\Documents\\blog\\gcirco_blog\\posts\\prompt-testing\\data\\train_labels.csv"
)

# first, we get a count of all possible case configurations
# then we weight them inversely proportional to their appearance
wt_tbl <-
  labels %>%
  select(-uid) %>%
  group_by(across(everything())) %>%
  summarise(count = n(), .groups = 'drop') %>%
  mutate(prop = count / sum(count), inv_prob = 1 / prop) %>%
  left_join(labels) %>%
  select(uid, prop, inv_prob)

# then we draw a sample of size N with weights
uid_sample <- sample(
  wt_tbl$uid,
  prob = wt_tbl$inv_prob,
  size = N,
  replace = FALSE
)

#uid_sample <- sample(wt_tbl$uid, size = N, replace = FALSE)

# export samples
labels_sample <- filter(labels, uid %in% uid_sample)
narratives_sample <- filter(narratives, uid %in% uid_sample)

write_csv(
  labels_sample ,
  "C:\\Users\\gioc4\\Documents\\blog\\gcirco_blog\\posts\\prompt-testing\\data\\train_labels_sample_200.csv"
)

write_csv(
  narratives_sample ,
  "C:\\Users\\gioc4\\Documents\\blog\\gcirco_blog\\posts\\prompt-testing\\data\\train_narratives_sample_200.csv"
)


# finally, can compare sample to observed
# see how close we are

# all cases
all_cases <-
  labels %>%
  select(-uid, -InjuryLocationType, -WeaponType1) %>%
  summarise(across(everything(), sum)) %>%
  pivot_longer(everything()) %>%
  mutate(prop = value / 4000)

sample_cases <-
  labels_sample %>%
  select(-uid, -InjuryLocationType, -WeaponType1) %>%
  summarise(across(everything(), sum)) %>%
  pivot_longer(everything(), values_to = "value_sample") %>%
  mutate(prop_sample = value_sample / N)

# this gets us pretty close, and we have examples for all features
test<-
inner_join(all_cases, sample_cases) %>%
  mutate(diff = prop - prop_sample)
