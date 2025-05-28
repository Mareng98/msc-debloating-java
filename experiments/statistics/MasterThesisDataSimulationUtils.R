library(dplyr)
library(ggplot2)


simulate_time_series <- function(n = 20, num_SUT = 5, power_percentage_deviation = 0.2, power_additive_deviation = 5) {
  
  # Define SUTs and techniques
  SUTs <- 1:num_SUT
  techniques <- 1:5  # 2 debloating techniques + Original
  time <- 1:60  # Original time range
  
  # Generate a grid of all combinations of SUTs and techniques, then repeat each combination 'n' times
  data <- expand.grid(SUT = SUTs, Technique = techniques, Time = time)
  
  # Repeat each combination 'n' times
  data <- data[rep(1:nrow(data), each = n), ]
  
  # Add a Sample column to distinguish samples within each SUT and technique combination
  data$Sample <- rep(1:n, length.out = nrow(data))  # Ensure correct length
  
  # Reorder the rows to get correct indices
  data <- data[order(data$SUT, data$Technique, data$Sample, data$Time), ]
  
  # Reset row names after reordering
  rownames(data) <- NULL
  
  # Introduce time shifts:
  #data <- data %>%
  #  group_by(SUT, Technique) %>%
  #  mutate(Time_Shift_Large = round(rnorm(1, mean = 0, sd = 2))) %>%  # Large shift per SUT/Technique
  #  group_by(SUT, Technique, Sample) %>%
  #  mutate(Time_Shift_Small = round(rnorm(1, mean = 0, sd = 0.5)),  # Small variation per SUT/Technique/Sample
  #         Time = pmax(1, pmin(65, Time + Time_Shift_Large + Time_Shift_Small))) %>%  # Keep within bounds
  #  ungroup()
  
  # Compute base effect of SUT
  # Create a lookup table for SUT effects
  SUT_effects <- setNames(10 + (1:num_SUT), 1:num_SUT)
  
  # Assign SUT_Effect based on SUT
  data$SUT_Effect <- SUT_effects[as.character(data$SUT)]
  # Set how a technique will affect an SUT
  data$Tech_SUT_Relation <- with(data,  ifelse(Technique == 1, 0.98,
                                        ifelse(Technique == 2, 1, 
                                        ifelse(Technique == 3, 1.01, 
                                        ifelse(Technique == 4, 1.04, 1.1)))))
  
  # Compute response variable power
  data$power <- with(data, (SUT_Effect * Tech_SUT_Relation))
  
  # Add noise
  data$powerNoisy <- numeric(nrow(data))  # Initialize the column
  for (i in seq_len(nrow(data))) {
    #additive_sample <- rnorm(1, mean = power_additive_deviation, sd = power_additive_deviation)
    # After getting the noise profile this seems more accurate:
    additive_sample <- rstudent(1,nu=2.5,mu=6.063385,sigma=0.07)
    sd_sample <- data$power[i] * power_percentage_deviation
    if(sd_sample < 0){
      sd_sample = 0
    }
    data$powerNoisy[i] <- rnorm(1, mean = data$power[i], sd = sd_sample) + additive_sample
  }
  # Ensure that noise is never negative (happens very rarely)
  data <- data %>%
    mutate(powerNoisy = ifelse(powerNoisy < 0, 0, powerNoisy))
  # Compute cumulative energy
  data$energy <- ave(data$powerNoisy, data$SUT, data$Technique, data$Sample, FUN = function(x) cumsum(x))
  
  return(data)
}



# Plot all SUTS with different color for a single technique
plot_time_series <- function(data, metric = "energy", technique = 1, ci_type = "sd", ci_level = 0.95) {
  # Summarize data based on confidence interval type
  summary_data <- data %>%
    group_by(SUT, Technique, Time) %>%
    summarise(
      mean_value = mean(.data[[metric]]), 
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      lower_ci = NA,
      upper_ci = NA
    )
  
  if (ci_type == "sd") {
    # Use standard deviation
    summary_data <- summary_data %>%
      left_join(
        data %>%
          group_by(SUT, Technique, Time) %>%
          summarise(sd_value = sd(.data[[metric]]), .groups = "drop"),
        by = c("SUT", "Technique", "Time")
      ) %>%
      mutate(
        lower_ci = mean_value - sd_value,
        upper_ci = mean_value + sd_value
      )
  } else if (ci_type == "sem") {
    # Use standard error of the mean (SEM) with 95% CI
    summary_data <- summary_data %>%
      left_join(
        data %>%
          group_by(SUT, Technique, Time) %>%
          summarise(sd_value = sd(.data[[metric]]), .groups = "drop"),
        by = c("SUT", "Technique", "Time")
      ) %>%
      mutate(
        sem_value = sd_value / sqrt(n),
        lower_ci = mean_value - qnorm(1 - (1 - ci_level) / 2) * sem_value,
        upper_ci = mean_value + qnorm(1 - (1 - ci_level) / 2) * sem_value
      )
  } else if (ci_type == "quantile") {
    # Use quantiles for an empirical confidence interval
    summary_data <- data %>%
      group_by(SUT, Technique, Time) %>%
      summarise(
        mean_value = mean(.data[[metric]]),
        lower_ci = quantile(.data[[metric]], probs = (1 - ci_level) / 2),
        upper_ci = quantile(.data[[metric]], probs = 1 - (1 - ci_level) / 2),
        .groups = "drop"
      )
  }
  
  # Filter for the selected technique
  summary_data <- summary_data %>% filter(Technique == technique)
  
  # Create the plot
  ggplot(summary_data, aes(x = Time, y = mean_value, color = factor(SUT))) +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci, fill = factor(SUT)), alpha = 0.3, color = NA) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    labs(
      title = paste(technique, ": Mean", metric, "with", ci_level * 100, "%", ci_type, "CI by SUT"),
      x = "Time",
      y = paste("Mean", metric),
      color = "SUT",
      fill = "SUT"
    ) +
    theme_minimal() +
    scale_color_brewer(palette = "Set1")
}
# Plot several techniques for each SUT in different color (You should only use one SUT to make it easier to view)
plot_time_series_several_techniques <- function(data, metric = "energy", techniques = c(1, 2, 3), ci_type = "sd", ci_level = 0.95) {
  library(ggplot2)
  library(dplyr)
  
  # Ensure 'Technique' is treated as integer if it's not already
  data$Technique <- as.integer(data$Technique)
  
  # Summarize data based on confidence interval type
  summary_data <- data %>%
    group_by(SUT, Technique, Time) %>%
    summarise(
      mean_value = mean(.data[[metric]]), 
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      lower_ci = NA,
      upper_ci = NA
    )
  
  if (ci_type == "sd") {
    summary_data <- summary_data %>%
      left_join(
        data %>%
          group_by(SUT, Technique, Time) %>%
          summarise(sd_value = sd(.data[[metric]]), .groups = "drop"),
        by = c("SUT", "Technique", "Time")
      ) %>%
      mutate(
        lower_ci = mean_value - sd_value,
        upper_ci = mean_value + sd_value
      )
  } else if (ci_type == "sem") {
    summary_data <- summary_data %>%
      left_join(
        data %>%
          group_by(SUT, Technique, Time) %>%
          summarise(sd_value = sd(.data[[metric]]), .groups = "drop"),
        by = c("SUT", "Technique", "Time")
      ) %>%
      mutate(
        sem_value = sd_value / sqrt(n),
        lower_ci = mean_value - qnorm(1 - (1 - ci_level) / 2) * sem_value,
        upper_ci = mean_value + qnorm(1 - (1 - ci_level) / 2) * sem_value
      )
  } else if (ci_type == "quantile") {
    summary_data <- data %>%
      group_by(SUT, Technique, Time) %>%
      summarise(
        mean_value = mean(.data[[metric]]),
        lower_ci = quantile(.data[[metric]], probs = (1 - ci_level) / 2),
        upper_ci = quantile(.data[[metric]], probs = 1 - (1 - ci_level) / 2),
        .groups = "drop"
      )
  }
  
  # Filter for selected techniques (allow multiple)
  summary_data <- summary_data %>% filter(Technique %in% techniques)
  
  # Modify the plot to distinguish techniques
  ggplot(summary_data, aes(x = Time, y = mean_value, color = factor(Technique), fill = factor(Technique))) +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2) +  
    geom_line(size = 1) +
    geom_point(size = 2) +
    labs(
      title = paste("Mean", metric, "with", ci_level * 100, "%", ci_type, "CI by Technique"),
      x = "Time",
      y = paste("Mean", metric),
      color = "Technique",
      fill = "Technique"
    ) +
    theme_minimal() +
    scale_color_brewer(palette = "Dark2")  
}


