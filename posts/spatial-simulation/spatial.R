library(tidyverse)
library(spatstat)
library(sf)

load("C:\\Users\\gioc4\\Documents\\blog\\data\\hartford_data.rda")

# convert to multitype
sf_to_multitype <- function(window, i, j, i_name, j_name){
  W <- as.owin(window)
  
  i_ppp <- as.ppp(i, W = W)
  marks(i_ppp) <- i_name
  
  j_ppp <- as.ppp(j, W = W)
  marks(j_ppp) <- j_name
  
  ij_multitype <- superimpose(i_ppp, j_ppp, W = W)
  marks(ij_multitype) <- factor(marks(ij_multitype))
  
  return(ij_multitype)
}

# extract simulations as sf
sp_to_sf <- function(sim, crs) {
  out <- st_as_sf(data.frame(x = sim$x, y = sim$y),
                  coords = c("x", "y")) %>%
    `st_crs<-`(. , crs)
  
  return(out)
}


hartford <- hartford_data$hartford
robbery <- hartford_data$robbery
gas <- hartford_data$gas

# plot robbery ~ gas
ggplot() +
  geom_sf(data = hartford, fill = 'grey90', color = 'white') +
  geom_sf(data = robbery, color = "red", size = 1, alpha = .5) +
  geom_sf(data = gas, color = "blue", size = 2) +
  theme_void()

# convert to ppp for spatial stuff
hartford_sp <- as.owin(hartford)

gas_ppp <- as.ppp(gas, W = hartford_sp)
marks(gas_ppp) <- "gas"

robbery_ppp <- as.ppp(robbery, W = hartford_sp)
marks(robbery_ppp) <- "robbery"

gas_robbery_ppp <- superimpose(gas_ppp, robbery_ppp, W = hartford_sp)
marks(gas_robbery_ppp) <- factor(marks(gas_robbery_ppp))


# calculate the density of gas stations & robberies
# replace negative values with 0
gas_density <- density.ppp(gas_ppp, sigma = 500)
gas_density[gas_density < 0] <- 0

robbery_density <- density.ppp(robbery_ppp, sigma = 500)
robbery_density[robbery_density < 0] <- 0

# calculate the pairwise intensity
summary(Kcross(gas_robbery_ppp, i = "robbery", j = "gas"))
plot(Kcross(gas_robbery_ppp, i = "robbery", j = "gas"))




# SIMULATE
# ------------------ #
N_SIM <- 100
N_GAS <- nrow(gas)

# observed K-function
gas_kest <- Kest(gas_ppp)


# simulate gas stations
# generate 100 simulations
gas_sim <- rpoispp(gas_density,nsim = N_SIM)
robbery_sim <- rpoispp(robbery_density, nsim = N_SIM)


# KEST
# ------------------ #

# get N gas stations generated
# and intensity of generated function
sim_N <- sapply(gas_sim, function(x){as.numeric(x$n) })
sim_L <- lapply(gas_sim, Kest, correction = "border", r = gas_kest$r)

# plot envelopes against observed
X <- sapply(sim_L, function(x){x$border})

Xdf <- as.data.frame(X)
Xdf$r <- gas_kest$r


# Plot observed K against simulations of K
obs_K <- data.frame(r = gas_kest$r,
                    K = gas_kest$border)


Xdf %>%
  pivot_longer(-r, names_to = "simulation", values_to = "K") %>%
  group_by(r) %>%
  summarise(Kmin = min(K),
            Kmax = max(K)) %>%
  ggplot() +
  geom_ribbon(aes(x = r, ymin = Kmin, ymax = Kmax), alpha = .3) +
  geom_line(data = obs_K, aes(x = r, y = K), linewidth = 1, color = 'red') + 
  labs(y = 'K(Border)', x = 'Distance (feet)') +
  theme_bw()


# LEST
# ------------------ #

# compute observed L-function
gas_robbery_cross <-
  sf_to_multitype(
    window = hartford,
    i = robbery,
    j = gas,
    i_name = "robbery",
    j_name = "gas"
  )

gas_robbery_lest <- Lcross(gas_robbery_cross, i = "gas", j = "robbery", r = gas_kest$r,  correction = "border")

obs_L <- data.frame(r = gas_robbery_lest$r,
                    L = gas_robbery_lest$border) %>%
  mutate(L = L-r)


# gather simulations, plot L function
sim_list <- lapply(gas_sim, sp_to_sf, crs = st_crs(gas))
sim_list2 <- lapply(robbery_sim, sp_to_sf, crs = st_crs(gas))

sim_cross_list <- list()

for(sim in 1:N_SIM){
  sim_cross_points <-
    sf_to_multitype(
      window = hartford,
      i = sim_list2[[sim]],
      j = sim_list[[sim]],
      i_name = "robbery",
      j_name = "gas"
    )
  sim_cross_list[[sim]] <- sim_cross_points
}


# compute lcross border corrected
lcross_list <- lapply(sim_cross_list, Lcross, i = "gas", j = "robbery", r = gas_kest$r,  correction = "border")

# plot envelopes against observed
X_l <- sapply(lcross_list, function(x){x$border})

X_ldf <- as.data.frame(X_l)
X_ldf$r <- gas_kest$r


X_ldf %>%
  pivot_longer(-r, names_to = "simulation", values_to = "L") %>%
  mutate(L = L-r) %>%
  group_by(r) %>%
  summarise(Lmin = min(L),
            Lmax = max(L)) %>%
  ggplot() +
  geom_ribbon(aes(x = r, ymin = Lmin, ymax = Lmax), alpha = .3) +
  geom_line(data = obs_L, aes(x = r, y = L), linewidth = 1, color = 'red') + 
  geom_hline(yintercept = 0) +
  labs(y = 'L-r(Border)', x = 'Distance (feet)') +
  theme_bw()

