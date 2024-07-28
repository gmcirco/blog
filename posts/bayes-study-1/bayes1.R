library(tidyverse)
library(broom.mixed)
library(brms)

set.seed(55432)

# list of files
dir1 <- "https://raw.githubusercontent.com/avehtari/ROS-Examples/master/ElectionsEconomy/data/hibbs.dat"

# EXAMPLE 1: GDP GROWTH AND ELECTION VOTE SHARE
# quick simple example, using bayes for a linear regression
# what is the impact of economic growth on incumbent vote share?
election <- read_delim(dir1, delim = " ")

plot1.1 <- 
  ggplot(election) +
  geom_point(aes(x = growth, y = vote), size = 2, shape = 22, fill = '#004488', color = '#004488') +
  labs(x = "Incumbent vote share", y = "GDP Growth") +
  theme_bw() 
plot1.1

plot1.2 <- 
  ggplot(election) +
  geom_text(aes(x = growth, y = vote, label = year), size = 3.5, fontface = 'bold', color = '#004488') +
  labs(x = "Incumbent vote share", y = "GDP Growth") +
  theme_bw() 
plot1.2

# let's regress
# 1 percentage point in growth is associated with ~ 3% increase in vote share
fit1 <- brm(vote ~ growth, data = election, family = "gaussian")
tidy(fit1)

# what is the predicted vote share given a 2% growth rate?
# 52%, but with a pretty big margin of error
newgrowth = 2.0
newprobs = c(.025, .25, .75, 0.975)

pred1 <- predict(fit2, newdata = data.frame(growth=newgrowth), probs = newprobs)
pred1

# plot the 50% and 95% credible intervals for the point estimate of 2% growth
plot1.1 +
  annotate(geom = "pointrange", x = newgrowth, y = pred1[1], ymin = pred1[3], ymax = pred1[6], color = '#DDAA33') +
  annotate(geom = "pointrange", x = newgrowth, y = pred1[1], ymin = pred1[4], ymax = pred1[5], linewidth=1.1, color = '#DDAA33')

# plot 100 simulations from the posterior
M <- as.matrix(fit1)
sims <- 100
sims_idx <- sample(1:nrow(M), size=sims)

model_sims <-
  M[sims_idx, ][, c(1, 2)] %>% data.frame() %>% setNames(c("intercept", "slope"))

plot1.1 +
  geom_abline(data=model_sims, aes(slope = slope, intercept = intercept), alpha = .125, color = '#004488')
