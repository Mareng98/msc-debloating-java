library(dplyr)
library(brms)
library(ggplot2)
library(bayesplot)
library(posterior)

data <- read.csv("time_series_data.csv")

summary_data <- data %>%
  select(SUT, Debloated_Artifact, Time_Index, Value) %>%
  filter(!is.na(Value) & Value > 0)  #no zeroes or missing

#cat vars
summary_data$SUT <- as.factor(summary_data$SUT)
summary_data$Debloated_Artifact <- relevel(as.factor(summary_data$Debloated_Artifact), ref = "vanilla")  #baseline

linear_model <- brm(
  Value ~ Debloated_Artifact + (1 | SUT),  #fixed slope
  data = summary_data,
  family = lognormal(),  #logN for energy>0
  prior = c(
    prior(normal(1500, 300), class = 'Intercept'),  #baseline
    prior(normal(2, 0.5), class = 'b'),  #effect of db-tools (energy per time unit)
    prior(normal(1, 0.5), class = 'sd'),  
    prior(normal(0, 0.5), class = 'sigma')  #variability across suts
  ),
  #can probably increase core more. When checked 22 were not used
  #may be that doesent matter if chains<cores
  iter = 4000, warmup = 1000, chains = 4, cores = 4,
  control = list(adapt_delta = 0.999, max_treedepth = 15)  
)

print(summary(linear_model))
