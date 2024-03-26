library(tidyverse)
library(lubridate)
library(brms)

# load data
mmm_raw <-
  read_csv("C:/Users/gioc4/Documents/blog/data/MMM_data.csv")


# adstock function

# calculate carryover effect
# L = maximum duration of carryover effect
# lambda = decay rate
# theta = onset delay of peak effect

DelayedSimpleAdstock <- function(advertising, lambda, theta, L){
  N <- length(advertising)
  weights <- matrix(0, N, N)
  for (i in 1:N){
    for (j in 1:N){
      k = i - j
      if (k < L && k >= 0){
        weights[i, j] = lambda ** ((k - theta) ** 2)
      }
    }
  }
  
  adstock <- as.numeric(weights %*% matrix(advertising))
  
  return(adstock)  
}


# setup weekly data
mmm_weekly_data <-
  mmm_raw %>%
  mutate(date = as.Date(DATE, "%m/%d/%Y"),
         year = year(date),
         month = month(date),
         week = week(date)) %>%
  select(
    date,
    year,
    month,
    week,
    sales = `SALES ($)`,
    spend_sms = `Advertising Expenses (SMS)`,
    spend_news = `Advertising Expenses(Newspaper ads)`,
    spend_radio = `Advertising Expenses(Radio)`,
    spend_tv = `Advertising Expenses(TV)`,
    spend_net = `Advertising Expenses(Internet)`,
    demand = DEMAND,
    supply = `POS/ Supply Data`,
    price = `Unit Price ($)`
  ) %>%
  filter(year %in% 2014:2017)


weekly_spend <-
  mmm_weekly_data %>%
  group_by(year, month, week) %>%
  summarise(across(sales:spend_net, sum), across(demand:price, mean), .groups = 'drop') %>%
  mutate(index = 1:nrow(.))


# Plot adstock

# diagnostic plots for delayed adstock
# what happens if we vary each parameter?
x <- c(1, rep(0, 15))
lambda = seq(0,1, by = .1)
theta = seq(0,10, by = 1)
L = seq(1,12, by = 1)

# varying lambda
# fixing theta to 1
# L to 13

par(mfrow = c(3, 4), mai = c(.5, 0.3, 0.2, 0.2))
for (i in lambda) {
  plot(
    DelayedSimpleAdstock(
      x,
      lambda = i,
      theta = 1,
      L = 13
    ),
    lwd = 2,
    col = "#004488",
    type = 'l',
    xlab = "",
    main = paste0("Lambda:", i)
  )
  title(xlab="Weeks", line=1.8, cex.lab=1)
}


# varying theta
# fixing lambda to .8
# L to 13
par(mfrow = c(3, 4), mai = c(.5, 0.3, 0.2, 0.2))
for (j in theta) {
  plot(
    DelayedSimpleAdstock(
      x,
      lambda = .8,
      theta = j,
      L = 13
    ),
    lwd = 2,
    col = "#BB5566",
    type = 'l',
    xlab = "",
    main = paste0("Theta:", j)
  )
  title(xlab="Weeks", line=1.8, cex.lab=1)
}


# varying L
# fixing lambda to .8
# theta to 2
par(mfrow = c(3, 4), mai = c(.5, 0.3, 0.2, 0.2))
for (k in L) {
  plot(
    DelayedSimpleAdstock(
      x,
      lambda = .8,
      theta = 2,
      L = k
    ),
    lwd = 2,
    col = "#DDAA33",
    type = 'l',
    xlab = "",
    main = paste0("L:", k)
  )
  title(xlab="Weeks", line=1.8, cex.lab=1)
}


# our chosen adstock
# peaks at 2 weeks after start
# moderate decay, ends effect at 13 weeks

# L = 13
# lambda = .8
# theta = 2
dev.off()
par(mfrow = c(1,1))
plot(
  DelayedSimpleAdstock(
    x,
    lambda = .8,
    theta = 2,
    L = 13
  ),
  lwd = 2,
  col = "#DDAA33",
  type = 'l',
  xlab = "Weeks",
  ylab = "Adstock",
  main = "Adstock Function\n",
)

# initial model stuff
X <-
  weekly_spend %>%
  mutate(across(spend_sms:spend_net,~ DelayedSimpleAdstock(.,lambda = .8,theta = 2,L = 13)),
         across(spend_sms:price, function(x) x/1e3),
         trend = 1:nrow(.)/nrow(.))
         

# 
plot(X$sales, type = 'l')

plot(X[, c('sales',
           'spend_sms',
           'spend_news',
           'spend_radio',
           'spend_tv',
           'spend_net')], col = '#004488')

cor(X[, c('sales',
               'spend_sms',
               'spend_news',
               'spend_radio',
               'spend_tv',
               'spend_net')])

# a real basic test model
# log(sales) ~ 
test_fit <- lm(log(sales) ~
                 as.factor(month) +
                 as.factor(week) +
                 spend_sms +
                 spend_news +
                 spend_radio +
                 spend_tv +
                 spend_net,
               data = X)


summary(test_fit)
car::vif(test_fit)

plot(predict(test_fit))
lines(log(X$sales))

# brms
bprior <- c(prior(normal(0,.5), class = "b", coef = "spend_sms"),
            prior(normal(0,.5), class = "b", coef = "spend_news"),
            prior(normal(0,.5), class = "b", coef = "spend_radio"),
            prior(normal(0,.5), class = "b", coef = "spend_tv"),
            prior(normal(0,.5), class = "b", coef = "spend_net"))

# just intercept
brm_fit_0 <- brm(log(sales) ~ 1, data = X,
                 chains = 4,
                 cores = 4,
                 family = gaussian(),
                 file = "C:/Users/gioc4/Documents/blog/data/brms_models/mmm_fit0.Rdata")

# no random effects, linear trend effect
brm_fit_1 <- brm(log(sales) ~                 
                   demand +
                   supply +
                   price +
                   as.factor(month) +
                   as.factor(week) +
                   trend +
                   spend_sms +
                   spend_news +
                   spend_radio +
                   spend_tv +
                   spend_net,
                 data = X,
                 chains = 4,
                 cores = 4,
                 prior = bprior,
                 family = gaussian(),
                 file = "C:/Users/gioc4/Documents/blog/data/brms_models/mmm_fit1.Rdata")

# random effects for month+week
# smoothing spline for trend
brm_fit_2 <- brm(log(sales) ~                 
                   demand +
                   supply +
                   price +
                   s(trend) +
                   spend_sms +
                   spend_news +
                   spend_radio +
                   spend_tv +
                   spend_net +
                   (1|month) +
                   (1|week),
                 data = X,
                 chains = 4,
                 cores = 4,
                 prior = bprior,
                 family = gaussian(),
                 control = list(adapt_delta = .9),
                 file = "C:/Users/gioc4/Documents/blog/data/brms_models/mmm_fit2.Rdata")

# evaluate models
# looks like smoothing spline is slightly better
waic(brm_fit_0, brm_fit_1, brm_fit_2)

# model summary
summary(brm_fit_2)
pp_check(brm_fit_2)
plot(conditional_smooths(brm_fit_2), ask = FALSE)

# get predictions 
X_no_radio <- X %>% mutate(spend_radio = 0)

pred1 <- predict(brm_fit_2)
pred1_no_radio <- predict(brm_fit_2, newdata = X_no_radio)

pred_dataframe <-
  cbind.data.frame(week = 1:197,
                   obs = pred1[, 1],
                   pred = pred1_no_radio[, 1]) %>%
  pivot_longer(-week) %>%
  group_by(week) %>%
  mutate(diff = value - lead(value, 1))


ggplot(pred_dataframe) +
  geom_line(aes(x = week, y = value, color = name)) +
  theme_minimal() +
  scale_color_manual(values = c("#0077BB","#EE7733")) +
  labs(y = "(log) Sales", x = "Week")
  
pred_dataframe %>%
  na.omit() %>%
ggplot() +
    geom_line(aes(x = week, y = diff)) +
    theme_minimal() +
  labs(y = "(log) Sales", x = "Week")
  


# coef spend_radio 0.18 
# A $1,000 spend on radio increases log(sales) by 0.18
# the median spend on radio is $1786
# if we spend 1.78 on radio we increase log(sales) by:
# 1.78*0.18 = 0.3204
# exp(0.3204) = 1.377679 ??
sum(exp(pred1[,1] - pred1_no_radio[,1]))
sum(X$spend_radio)
