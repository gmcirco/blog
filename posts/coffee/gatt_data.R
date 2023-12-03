library(tidyverse)
library(brms)
library(lme4)

coffee <- read_csv("C:/Users/gioc4/Documents/blog/data/catt.csv")

col_pal <- c( '#4477AA', '#EE6677', '#228833', '#CCBB44', '#66CCEE', '#AA3377')


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

eval<-
coffee_data %>%
  group_by(age,gender,expertise) %>%
  summarise(across(starts_with("pref"), mean),
            count = n())


# filter gender == male, female
coffee_ranking <-
  coffee_data %>%
  na.omit() %>%
  select(age, gender, expertise, pref_a:pref_d) %>%
  pivot_longer(cols = starts_with("pref"),
               names_to = "coffee",
               values_to = "ranking") %>%
  mutate(age = case_when(
    age %in% c("<18 years old","18-24 years old") ~ "18-24",
    age == "25-34 years old" ~ "25-34",
    age == "35-44 years old" ~ "35-44",
    age == "45-54 years old" ~ "45-54",
    age %in% c("55-64 years old", ">65 years old") ~ "55+"
  ))

# What is the probability of ranking a coffee 4 or 5 given:
# age, gender
prior <- c(prior(normal(0,2), class = Intercept),
           prior(normal(0,2), class = b),
           prior(normal(0,2), class = sd))

fit1 <-
  brm(
    ranking ~ 1 + 
      gender +
      (expertise | coffee) + 
      (1 | age), 
    data = coffee_ranking,
    prior = prior,
    family = cumulative("probit"),
    chains = 4,
    cores = 4,
    iter = 2000,
    control = list(adapt_delta = 0.9)
  )
summary(fit1)

fit2 <-
  brm(
    ranking ~ 1 + 
      gender +
      (age + expertise | coffee),
    data = coffee_ranking,
    prior = prior,
    family = cumulative("probit"),
    chains = 4,
    cores = 4,
    iter = 2000,
    control = list(adapt_delta = 0.99)
  )
summary(fit2)
save(fit2, file="C:/Users/gioc4/Desktop/fit2.Rdata")

# predictions
strata <- coffee_ranking %>%
  filter(gender %in% c("Male","Female")) %>%
  distinct(expertise, age, gender, coffee) %>%
  complete(expertise,age,gender,coffee)

fit1_preds <-
  predict(fit2, newdata = strata) %>%
  data.frame()


pred_data <-
  tibble(strata, fit1_preds) %>%
  set_names(c(
    'expertise',
    'age',
    'gender',
    'coffee',
    'p1',
    'p2',
    'p3',
    'p4',
    'p5'
  )) %>%
  mutate(
    gender = fct_relevel(gender, "Male"),
    age = fct_relevel(
      age,
      "18-24",
      "25-34",
      "35-44",
      "45-54",
      '55+'
    )
  ) %>%
  pivot_longer(cols = starts_with("p"),
               names_to = 'ranking',
               values_to = 'prob')

# preferences for coffee D
plot_coffee_d <-
pred_data %>%
  filter(coffee == 'pref_d') %>%
  ggplot(aes(x = ranking, y = prob, group = paste0(age, gender,expertise))) +
  geom_line(alpha = .03, linewidth = .8) +
  theme_minimal() +
  labs(title = "Predicted Coffee Ranking - Coffee 'D'", subtitle = "Estimates by Age,Gender, & Expertise")

plot_coffee_c <-
  pred_data %>%
  filter(coffee == 'pref_c') %>%
  ggplot(aes(x = ranking, y = prob, group = paste0(age, gender,expertise))) +
  geom_line(alpha = .03, linewidth = .8) +
  theme_minimal() +
  labs(title = "Predicted Coffee Ranking - Coffee 'C'", subtitle = "Estimates by Age,Gender, & Expertise")


# plot expertise ~ gender
coffee_data %>%
  filter(gender %in% c("Male", "Female")) %>%
  count(gender, expertise) %>%
  group_by(gender) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot() +
  geom_col(aes(
    x = as_factor(expertise),
    y = prop,
    fill = fct_relevel(gender, "Male")
  ), position = "dodge") +
  scale_fill_manual(values = col_pal) +
  theme_minimal() +
  theme(legend.title = element_blank())

# plot expertise ~ age
coffee_data %>%
  filter(gender %in% c("Male", "Female")) %>%
  count(age, expertise) %>%
  group_by(age) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot() +
  geom_col(aes(
    x = as_factor(expertise),
    y = prop,
    fill = age
  ), position = "dodge") +
  theme_minimal() +
  theme(legend.title = element_blank())



# base plot
plot_coffee_d

# median expertise
m_exp <- median(coffee_data$expertise, na.rm = T)

## Gender Differences

# males
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Male', expertise == m_exp), color = col_pal[1], linewidth = .8) +
  annotate(geom = "text", x = c(4.5), y = c(.3), label = c("Male"), color = c(col_pal[1]), fontface = "bold")

# females
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', gender == 'Female', expertise == m_exp), color = col_pal[2], linewidth = .8) +
  annotate(geom = "text", x = c(4.5), y = c(.20), label = c("Female"), color = c(col_pal[2]), fontface = "bold")

# males and females, holding age constant (25-34)
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', age == "25-34", expertise == m_exp), aes(color = gender), linewidth = .8) +
  annotate(geom = "text", x = c(4.5,4.5), y = c(.23,.3), label = c("Female","Male"), color = c(col_pal[2],col_pal[1]), fontface = "bold")+
  scale_color_manual(values = col_pal) +
  theme(legend.position = "none")

## Expertise Differences

# males, holding age constant (25-34), varying expertise
plot_coffee_d +
  geom_line(data = filter(pred_data,coffee == 'pref_d', age == "25-34", gender == "Male", expertise %in% c(1,5,10)), aes(color = factor(expertise)), linewidth = .8) +
  scale_color_manual(values = col_pal)

# age
plot_coffee_c +
  geom_line(data = filter(pred_data,coffee == 'pref_c', gender == 'Female'), aes(color = age), linewidth = .8) +
  scale_color_manual(values = col_pal) +
  facet_grid(age~expertise)

# what is the probability that a male age 25-34 with average expertise likes coffee c just as
# much as a comparable male aged 55+?
p_0 <- posterior_epred(fit2, newdata = data.frame(expertise = 7, age = "25-34", gender = "Male", coffee = "pref_d"))
p_1 <- posterior_epred(fit2, newdata = data.frame(expertise = 7, age = "55+", gender = "Female", coffee = "pref_d"))

par(mfrow = c(1,2))
hist(data.frame(p_0)[,5])
hist(data.frame(p_1)[,5])

diff = data.frame(p_0)[,5] - data.frame(p_1)[,5]
quantile(diff, probs = c(0.025, .5, .975)) 

