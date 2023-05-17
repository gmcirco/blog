library(tidyverse)

hosp <- read_csv(unz("C:/Users/gioc4/Documents/blog/data/sparcs2.zip", "Hospital_Inpatient_Discharges__SPARCS_De-Identified___2021.csv"))

df <-
  hosp %>%
  group_by(`CCSR Procedure Code`, `APR Severity of Illness Code`) %>%
  mutate(
    proc_charge = median(`Total Costs`),
    charge_diff = (`Total Costs` - proc_charge)/proc_charge,
    `Length of Stay` = as.numeric(ifelse(
      `Length of Stay` == '120+', 120, `Length of Stay`
    ))
  ) %>%
  group_by(id = `Permanent Facility Id`) %>%
  summarise(
    stay_len = mean(`Length of Stay`, na.rm = T),
    charges = mean(`Total Charges`),
    costs = mean(`Total Costs`),
    diff = mean(charge_diff),
    cost_ratio = mean(`Total Costs`/`Total Charges`),
    cost_per_stay = costs / stay_len
  )

adHBOS <- function(X, ub = 15){
  
  # scale input features, define list to hold scores
  X <- scale(X)
  j <- dim(X)[2]
  hbos <- vector("list",j)
  
  # internal function: compute optimal bins
  opt_bins <- function(X, upper_bound = ub)
  {
    
    epsilon = 1
    n <- length(X)
    
    # maximum likelihood estimate for bin
    maximum_likelihood <- array(0, dim = c(upper_bound - 1, 1))
    
    # rule of thumb for upper bound
    if (is.null(upper_bound)) {
      upper_bound <- as.integer(sqrt(length(X)))
    }
    
    for (i in seq_along(1:(upper_bound - 1))) {
      b <- i + 1
      histogram <- hist(X, breaks = b, plot = FALSE)$counts
      
      maximum_likelihood[i] <-
        sum(histogram * log(b * histogram /  n + epsilon) - (b - 1 + log(b) ^ 2.5))
    }
    
    return(which.max(maximum_likelihood))
  }
  
  # run HBOS
  for(j in 1:j){
    
    h <- hist(X[,j], breaks = opt_bins(X[,j]), plot = FALSE)
    fi <- findInterval(X[,j], h$breaks)
    
    hbos[[j]] <- log(1/h$density[fi])
  }
  
  # minmax scale feature vectors
  hbos <- lapply(hbos, function(x){(x- min(x)) /(max(x)-min(x))})
  
  # return score
  return(apply(do.call(cbind, hbos), 1, sum))
  
  
}

df$anom <- adHBOS(df[,2:7])

hist(df$anom)
