library(dplyr)
library(brms)
library(ggplot2) #for plots in console
library(bayesplot) #for plots in console
library(posterior)

data <- read.csv("time_series_data.csv")

summary_data <- data %>%
  select(SUT, Debloated_Artifact, Time_Index, Value) %>%
  filter(!is.na(Value) & Value > 0)

#cat var
summary_data$SUT <- as.factor(summary_data$SUT)
summary_data$Debloated_Artifact <- relevel(as.factor(summary_data$Debloated_Artifact), ref = "vanilla") #vanilla baseline

linear_model <- brm(
  #N2S double check formula with daggity
  Value ~ Debloated_Artifact * Time_Index + (Time_Index | SUT), #time index and SUT not fixed
  data = summary_data,
  family = lognormal(), #pos value, test
  prior = c(
    prior(normal(1500, 300), class = 'Intercept'),  #baseline
    prior(normal(2, 0.5), class = 'b'),  #effect of db-tool
    prior(normal(1, 0.5), class = 'sd'),  #var across suts
    prior(normal(0, 0.5), class = 'sigma')  #Res var
  ),
  #iter = 2000, warmup = 500, chains = 4, cores = 12,
  iter = 3000, warmup = 1000, chains = 4, cores = 12,
  control = list(adapt_delta = 0.999, max_treedepth = 12)
)

print(summary(linear_model))

