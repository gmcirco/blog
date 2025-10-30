library(spdep)
library(sf)
library(tidyverse)

# ...in feet
MIN_ELLIPSE_SIZE = 2e5
MAX_ELLIPSE_SIZE = 1e6
ELLIPSE_NUM_STEPS = 20
ELLIPSE_SIZE_STEPS = round(seq(MIN_ELLIPSE_SIZE, MAX_ELLIPSE_SIZE, length.out = ELLIPSE_NUM_STEPS))

# some funcs
compute_rate <- function(X) {
  births <- sum(X$BIR79)
  sids <- sum(X$SID79)
  
  return(list(x = sids, n = births))
}

# compute a bernoulli log-likelihood
# try and mimic the approach from SATSCAN
# let GPT figure out the finer points here
bernoulli_llr <- function(c, n, C, N) {
  if (c / n <= (C - c) / (N - n))
    return(0)  # I()=0
  
  # expected values under null
  Ec <- n * (C / N)
  En_c <- n - Ec
  E_Cc <- (N - n) * (C / N)
  E_NnCc <- (N - n) - E_Cc
  
  # log-likelihood ratio
  llr <- 0
  if (c > 0)
    llr <- llr + c * log(c / Ec)
  if ((n - c) > 0)
    llr <- llr + (n - c) * log((n - c) / En_c)
  if ((C - c) > 0)
    llr <- llr + (C - c) * log((C - c) / E_Cc)
  if (((N - n) - (C - c)) > 0) {
    llr <- llr + ((N - n) - (C - c)) * log(((N - n) - (C - c)) / E_NnCc)
  }
  
  return(max(0, llr))
}

# load, transform
nc <- st_read(system.file("shapes/sids.gpkg", package = "spData")[1], quiet =
                TRUE)
nc <- st_transform(nc, crs = 32019) # lamberts conformal conic


nc <- nc %>%
  mutate(rate = (SID74 / BIR74) * 1000)

# get county centroids
centroids <- st_centroid(nc)

llr_df <- tibble()

for (j in seq_along(ELLIPSE_SIZE_STEPS)) {
  ellipse_size <- ELLIPSE_SIZE_STEPS[j]
  
  llr_list <- vector("list", nrow(centroids))
  
  for (i in seq_len(nrow(centroids))) {
    # 1 choose a single county
    buff <- st_buffer(centroids[i, ], ellipse_size)
    
    # 2 get all counties within 'buff'
    z <- centroids[buff, ]
    z_idx <- centroids$CNTY_ID %in% z$CNTY_ID
    G <- centroids[!z_idx, ]
    
    # compute rates
    Z <- compute_rate(z)
    A <- compute_rate(G)
    
    c <- Z$x
    n <- Z$n
    C <- A$x + c
    N <- A$n + n
    
    # store county index and log likelihood ratio
    llr_df <- bind_rows(
      llr_df,
      tibble(
        idx = i,
        llr = bernoulli_llr(c, n, C, N),
        idx_ellipse_size = as.character(j),
        cases = c,
        births = n
      ),
    )
  }
}

# get the most likely cluster & select its buffer
idx_max_llr <- llr_df$idx[llr_df$llr == max(llr_df$llr)]
idx_max_buff <- as.numeric(llr_df$idx_ellipse_size[llr_df$llr == max(llr_df$llr)])
new_buff <- st_buffer(centroids[idx_max_llr, ], ELLIPSE_SIZE_STEPS[idx_max_buff])

# compute the rate
llr_df$rate <- (llr_df$cases / llr_df$births)*1000


ggplot() +
  geom_sf(data = nc, aes(fill = rate)) +
  geom_sf(data = centroids) + 
  geom_sf(data = new_buff, color = "red", fill = NA, size=1) +
  scale_fill_viridis_c() +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title = element_text(face="bold"))