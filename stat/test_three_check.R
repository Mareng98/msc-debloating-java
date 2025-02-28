library(rstan)
library(dplyr)
library(brms)
library(bayesplot)

data <- read.csv("time_series_data.csv")

#sum energy per sut
summary_data <- data %>%
  group_by(SUT, Debloated_Artifact) %>%
  summarize(total_energy = sum(Power * c(diff(Timestamp), 0)), .groups = "drop") %>%
  group_by(SUT) %>%
  mutate(vanilla_energy = total_energy[Debloated_Artifact == "vanilla"]) %>%
  ungroup() %>%
  mutate(percent_change = 100 * (total_energy - vanilla_energy) / vanilla_energy)

summary_data$SUT <- as.factor(summary_data$SUT)
summary_data$Debloated_Artifact <- relevel(as.factor(summary_data$Debloated_Artifact), ref = "vanilla")

model1 <- brm(
  percent_change ~ Debloated_Artifact + (1 | SUT),
  data = summary_data,
  family = gaussian(),
  prior = c(
    prior(normal(0, 5), class = 'b'),
    prior(normal(0, 10), class = 'Intercept'),
    prior(normal(0, 5), class = 'sd')
  ),
  iter = 4000, warmup = 1000, chains = 4, cores = 4,
  control = list(adapt_delta = 0.99)
)

print(summary(model1))
print(summary_data) # Check results


#timestamp level energy change
summary_data2 <- data %>%
  left_join(data %>% filter(Debloated_Artifact == "vanilla") %>%
              select(SUT, Timestamp, Power) %>%
              rename(Vanilla_Power = Power),
            by = c("SUT", "Timestamp")) %>%
  mutate(percent_change = ifelse(Vanilla_Power == 0, 0, 100 * (Power - Vanilla_Power) / Vanilla_Power)) %>%
  select(SUT, Timestamp, Debloated_Artifact, percent_change) %>%
  filter(Debloated_Artifact != "vanilla") 

summary_data2$SUT <- as.factor(summary_data2$SUT)
summary_data2$Debloated_Artifact <- relevel(as.factor(summary_data2$Debloated_Artifact), ref = "vanilla")

model2 <- brm(
  percent_change ~ Debloated_Artifact + (1 | SUT),
  data = summary_data2,
  family = gaussian(),
  prior = c(
    prior(normal(0, 5), class = 'b'),
    prior(normal(0, 10), class = 'Intercept'),
    prior(normal(0, 5), class = 'sd')
  ),
  iter = 4000, warmup = 1000, chains = 4, cores = 4,
  control = list(adapt_delta = 0.99)
)

print(summary(model2))
print(summary_data2) 


#one model peer sut
unique_SUTs <- unique(data$SUT)

models_SUT <- list()

for (sut in unique_SUTs) {
  summary_SUT <- data %>%
    filter(SUT == sut) %>%
    group_by(Debloated_Artifact) %>%
    summarize(total_energy = sum(Power * c(diff(Timestamp), 0)), .groups = "drop") %>%
    mutate(vanilla_energy = total_energy[Debloated_Artifact == "vanilla"]) %>%
    mutate(percent_change = 100 * (total_energy - vanilla_energy) / vanilla_energy)
  
  summary_SUT$Debloated_Artifact <- relevel(as.factor(summary_SUT$Debloated_Artifact), ref = "vanilla")
  
  model_SUT <- brm(
    percent_change ~ Debloated_Artifact,
    data = summary_SUT,
    family = gaussian(),
    prior = c(
      prior(normal(0, 5), class = 'b'),
      prior(normal(0, 10), class = 'Intercept')
    ),
    iter = 4000, warmup = 1000, chains = 4, cores = 4,
    control = list(adapt_delta = 0.99)
  )
  
  models_SUT[[sut]] <- model_SUT
  print(paste("Model for", sut, "completed."))
  print(summary(model_SUT))
}


