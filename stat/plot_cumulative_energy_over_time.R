library(ggplot2)
library(dplyr)

data_jgit <- data %>% filter(SUT == "jgit")
data_zxing <- data %>% filter(SUT == "zxing")

calculate_cumulative_energy <- function(df) {
  df %>%
    arrange(Timestamp) %>%
    group_by(Debloated_Artifact) %>%
    mutate(
      time_diff = c(0, diff(Timestamp)), 
      energy_increment = Power * time_diff, #energy=power * time_diff
      cumulative_energy = cumsum(energy_increment)
    ) %>%
    ungroup()
}

data_jgit <- calculate_cumulative_energy(data_jgit)
data_zxing <- calculate_cumulative_energy(data_zxing)

#jgit plot
plot1 <- ggplot(data_jgit, aes(x = Timestamp, y = cumulative_energy, color = Debloated_Artifact)) +
  geom_line() +
  labs(title = "jgit- cumulative energy consumption over time ",
       x = "Time",
       y = "Energy",
       color = "Debloating Tool") +
  theme_minimal()
print(plot1)

#zxing plot
plot2 <- ggplot(data_zxing, aes(x = Timestamp, y = cumulative_energy, color = Debloated_Artifact)) +
  geom_line() +
  labs(title = "zxing - Cumulative energy consumtion over time",
       x = "Time",
       y = "Energy",
       color = "Debloating Tool") +
  theme_minimal()
print(plot2)
