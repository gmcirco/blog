library(tidyverse)
library(brms)
library(lme4)

coffee <- read_csv("C:/Users/gmcir/Documents/data/catt.csv")

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
    expertise = `Lastly, how would you rate your own coffee expertise?`,
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

# filter gender == male, female
# recode age 18-34, 35-44, 45-54, 55+

coffee_ranking <-
  coffee_data %>%
  na.omit() %>%
  select(age, gender, expertise, pref_a:pref_d) %>%
  pivot_longer(cols = starts_with("pref"),
               names_to = "coffee",
               values_to = "ranking")

# What is the probability of ranking a coffee 4 or 5 given:
# age, gender
prior <- c(prior(normal(0,2), class = b),
           prior(normal(0,2), class = Intercept))

fit1 <-
  brm(ranking ~ 1 + expertise + (1|age) + (1 |age) + (1|gender) + (1|age*gender),
      data = coffee_ranking,
      prior = prior,
      family = cumulative("probit"),
      chains = 2, iter = 1000)

summary(fit1)

# predictions
fit1_preds <- coffee_ranking %>% 
  distinct(age, gender, coffee) %>%
  predict(fit1, newdata = .) %>%
  data.frame()

strata <- distinct(coffee_ranking, age, gender, coffee)

pred_data <-
tibble(strata, fit1_preds) %>%
  set_names(c('age','gender','coffee','p1','p2','p3','p4','p5')) %>%
  pivot_longer(cols = starts_with("p"), names_to = 'ranking', values_to = 'prob')

# preferences for coffee D
plot_coffee_d <-
pred_data %>%
  filter(coffee == 'pref_d', gender %in% c("Male","Female")) %>%
  ggplot(aes(x = ranking, y = prob, group = paste0(age, gender))) +
  geom_line(alpha = .2, linewidth = .8) +
  theme_minimal() +
  labs(title = "Predicted Coffee Ranking - Coffee 'D'", subtitle = "Estimates by Age & Sex")

# base plot
plot_coffee_d

# add annotation for males
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Male'), color = 'darkblue', linewidth = .8)

# females
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Female'), color = 'red', linewidth = .8)

# males 18-34
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Male', age == "18-24 years old"), color = 'green', linewidth = .8)

# females 45-64
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Female', age == "45-54 years old"), color = 'purple')

# What is the probability of ranking coffee D highly, given I score C highly?
X <- posterior_predict(fit1, strata)

hist(apply(X, 2, mean))
hist(summary(coffee_data$pref_d))
