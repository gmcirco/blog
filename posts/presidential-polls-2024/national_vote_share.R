library(lme4)
library(tidyverse)

states_votes <- read_csv("C:\\Users\\gioc4\\Documents\\blog\\data\\1976-2020-president.csv")


# compute the proportion of two-party vote share, by state by year
vote_df <-
  states_votes %>%
  mutate(
    party_simplified = ifelse(
      party_simplified == 'DEMOCRATIC-FARMER-LABOR',
      "DEMOCRAT",
      party_simplified
    )
  ) %>%
  filter(party_simplified %in% c("DEMOCRAT", "REPUBLICAN"),
         state_po != "DC",
         writein == FALSE) %>%
  group_by(year, state_po) %>%
  mutate(two_party_vote = sum(candidatevotes),
         vote_share = candidatevotes / two_party_vote) %>%
  select(
    year,
    state = state_po,
    party = party_simplified,
    candidate,
    votes = candidatevotes,
    two_party_vote,
    vote_share
  ) %>%
  group_by(state,party)

# Let's follow the gelman paper

# SECTION 2
# ======================== #
# section 2, fig 1
# state results from one presidential election to the next
vote_df_wide <- vote_df %>%
  filter(party == 'DEMOCRAT') %>%
  pivot_wider(id_cols = state, names_from = c(party,year), values_from = vote_share)


election_years <- names(vote_df_wide)[-1]

par(mfrow=c(3,4), mar=c(3, 3, 3, 3), mgp=c(2, 0.5, 0))  # Increase the top margin
for(i in 1:11){
  idx_xval = election_years[i]
  idx_yval = election_years[i+1]
  
  plot(
    x = vote_df_wide[[idx_xval]],
    y = vote_df_wide[[idx_yval]],
    xlab = idx_xval,
    ylab = idx_yval,
    xlim = c(.2, .8),
    ylim = c(.2, .8),
    cex.lab = 0.9  # Reduce title size
  )
  abline(a=0, b=1)
}

# fix a model to determine how the states' relative position changes
# this is based on the change (delta) in vote share in year y relative to y-1
pred_dem_df <- vote_df %>%
  filter(party == 'DEMOCRAT',
         year < 2020) %>%
  group_by(year) %>%
  mutate(vote_share_diff = vote_share - mean(vote_share)) %>%
  arrange(state, year) %>%
  group_by(state) %>%
  mutate(vote_share_delta = vote_share_diff  - lag(vote_share_diff, 1))

# state-level estimates
# "Before pooling, the estimates of SD for each state range from 0.012 to 0.07"
vote_delta_state <- pred_dem_df %>% 
  group_by(state) %>% 
  summarize(sd = sd(vote_share_delta, na.rm = TRUE)) %>% 
  pull(sd)

summary(vote_delta_state)
hist(vote_delta_state)

# fully pooled estimate
# "...with complete pooling the common estimate is 0.037"
sd(pred_dem_df$vote_share_delta, na.rm = T)

# partially pooled via hlm
delta_var_model <- lmer(vote_share_delta ~ 1 + (1|state), data = pred_dem_df)

# Extract the variance components for the random effects
state_var_components <- as.data.frame(VarCorr(delta_var_model))
state_random_var <- state_var_components[state_var_components$grp == "state", "vcov"]

# Calculate the variance of the group means (year-specific mean differences) for each state
year_means_var_by_state <- pred_dem_df %>%
  group_by(state, year) %>%
  summarize(mean_vote_share_diff = mean(vote_share_diff, na.rm = TRUE)) %>%
  group_by(state) %>%
  summarize(year_means_var = var(mean_vote_share_diff, na.rm = TRUE))

# Combine the variances to recover the original scale variance for each state
state_var_components <- year_means_var_by_state %>%
  mutate(original_scale_var = state_random_var + year_means_var)

# Display the recovered variances for each state
test <-
state_var_components %>%
  select(state, original_scale_var) %>%
  mutate(original_scale_var = sqrt(original_scale_var))

hist(test$original_scale_var)


vote_df %>%
  ggplot() +
  geom_line(aes(x = year, y = vote_share, color = party)) +
  facet_wrap(~state) +
  scale_color_manual(values = c("blue","red")) +
  theme_bw()





dem_vote_corr <-
  vote_df %>%
  filter(party == "DEMOCRAT") %>%
  pivot_wider(id_cols = year,
              names_from = state,
              values_from = vote_share) %>%
  replace_na(list(DC = 0.951))


test<-cor(as.matrix(dem_vote_corr[,2:51]))
