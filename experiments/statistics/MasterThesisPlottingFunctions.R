plot_raw_power_with_mean <- function(data) {
  summary_df <- data %>%
    group_by(Technique, Time_Index) %>%
    summarise(
      mean_power = mean(Power, na.rm = TRUE),
      lower_ci = quantile(Power, probs = 0.055, na.rm = TRUE),
      upper_ci = quantile(Power, probs = 0.945, na.rm = TRUE),
      .groups = "drop"
    )
  
  ggplot(summary_df, aes(x = Time_Index, y = mean_power, color = Technique, fill = Technique)) +
    geom_line(size = 0.8) +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, color = NA) +
    labs(title = "", x = "Time Index", y = "Power (Watt)", color = NULL, fill = NULL) +
    coord_cartesian(ylim = c(0, 100)) +
    theme_minimal(base_size = 16) +  # Set base font size to 16
    theme(
      legend.position = "right",     # Optional: adjust if needed
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 16),
      legend.text = element_text(size = 16)
    )
}


plot_raw_power_with_median <- function(data) {
  summary_df <- data %>%
    group_by(Technique, Time_Index) %>%
    summarise(
      median_power = median(Power, na.rm = TRUE),
      lower_ci = quantile(Power, probs = 0.055, na.rm = TRUE),
      upper_ci = quantile(Power, probs = 0.945, na.rm = TRUE),
      .groups = "drop"
    )
  
  ggplot(summary_df, aes(x = Time_Index, y = median_power, color = Technique, fill = Technique)) +
    geom_line(size = 0.8) +  # Match default line size (same as mean)
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, color = NA) +
    labs(title = "", x = "Time Index", y = "Power (Watt)", color = NULL, fill = NULL) +
    coord_cartesian(ylim = c(0, 100)) +
    theme_minimal(base_size = 16) +
    theme(
      legend.position = "right",
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 16),
      legend.text = element_text(size = 16)
    )
}

plot_raw_cpu_with_median <- function(data) {
  summary_df <- data %>%
    group_by(Technique, Time_Index) %>%
    summarise(
      median_cpu = median(CPU_Usage, na.rm = TRUE),
      lower_ci = quantile(CPU_Usage, probs = 0.055, na.rm = TRUE),
      upper_ci = quantile(CPU_Usage, probs = 0.945, na.rm = TRUE),
      .groups = "drop"
    )
  
  ggplot(summary_df, aes(x = Time_Index, y = median_cpu, color = Technique, fill = Technique)) +
    geom_line(size = 0.8) +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, color = NA) +
    labs(title = "", x = "Time Index", y = "CPU Usage (%)", color = NULL, fill = NULL) +
    coord_cartesian(ylim = c(0, 100)) +
    theme_minimal(base_size = 16) +
    theme(
      legend.position = "right",
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 16),
      legend.text = element_text(size = 16)
    )
}


plot_raw_memory_with_median <- function(data) {
  summary_df <- data %>%
    group_by(Technique, Time_Index) %>%
    summarise(
      median_memory = median(Memory_Usage, na.rm = TRUE),
      lower_ci = quantile(Memory_Usage, probs = 0.055, na.rm = TRUE),
      upper_ci = quantile(Memory_Usage, probs = 0.945, na.rm = TRUE),
      .groups = "drop"
    )
  
  ggplot(summary_df, aes(x = Time_Index, y = median_memory, color = Technique, fill = Technique)) +
    geom_line(size = 0.8) +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, color = NA) +
    labs(title = "", x = "Time Index", y = "Memory Usage (MB)", color = NULL, fill = NULL) +
    coord_cartesian(ylim = c(0, NA)) +  # Set lower bound to 0, upper bound auto
    theme_minimal(base_size = 16) +
    theme(
      legend.position = "right",
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 16),
      legend.text = element_text(size = 16)
    )
}




# Plot the mean and 89% confidence interval for power normalized over SUT
plot_normalized_power <- function(data) {
  normalized <- data %>%
    group_by(SUT) %>%
    mutate(Normalized_Power = Power / max(Power, na.rm = TRUE)) %>%
    ungroup()
  
  summary_df <- normalized %>%
    group_by(Technique, Time_Index) %>%
    summarise(
      mean_power = mean(Normalized_Power, na.rm = TRUE),
      lower_ci = quantile(Normalized_Power, probs = 0.055, na.rm = TRUE),
      upper_ci = quantile(Normalized_Power, probs = 0.945, na.rm = TRUE),
      .groups = "drop"
    )
  
  ggplot(summary_df, aes(x = Time_Index, y = mean_power, color = Technique, fill = Technique)) +
    geom_line() +
    geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.2, color = NA) +
    labs(title = "", x = "Time Index", y = "Normalized Power", color = NULL, fill = NULL) +
    coord_cartesian(ylim = c(0, 1)) +
    theme_minimal()
}
plot_energy_by_tool_and_sut <- function(dat_plot, tool_colors) {
  # Desired SUT order: prioritize specific ones first
  target_suts <- c("checkstyle", "closure-templates", "coreNLP", "tika")
  remaining_suts <- setdiff(levels(dat_plot$SUT), target_suts)
  ordered_suts <- c(target_suts, remaining_suts)
  
  # Reorder factor levels
  dat_plot$SUT <- factor(dat_plot$SUT, levels = ordered_suts)
  
  # Save original par settings and increase left and bottom margins
  old_par <- par(mar = c(7, 6, 4, 2) + 0.1)
  
  # Assign color and shape manually
  col_vec <- tool_colors[as.character(dat_plot$Technique)]
  pch_vec <- as.numeric(dat_plot$Technique)
  
  # Create the plot
  plot(dat_plot$Energy ~ as.numeric(dat_plot$SUT),
       col = col_vec,
       pch = pch_vec,
       cex = 1.5,
       xaxt = "n",
       xlab = "",
       ylab = "",
       ylim = c(0.89, 1),
       cex.axis = 1.6,
       cex.lab = 1.6)
  
  # Add y-axis label
  mtext("Normalized Energy Consumption", side = 2, line = 3, cex = 1.6)
  
  # X-axis labels
  x_positions <- 1:length(levels(dat_plot$SUT))
  x_labels <- tolower(levels(dat_plot$SUT))
  text(x = x_positions, y = par("usr")[3] - 0.005, labels = x_labels,
       srt = 30, adj = 1, xpd = TRUE, cex = 1.6)
  
  # Vertical lines
  for (x in x_positions) {
    abline(v = x, col = adjustcolor("gray80", alpha.f = 0.4), lty = 2)
  }
  
  # Add a subtle separator line after the target SUTs
  sep_index <- length(target_suts) + 0.5
  abline(v = sep_index, col = adjustcolor("black", alpha.f = 0.2), lty = 1, lwd = 2)
  
  # X-axis ticks
  axis(1, at = x_positions, labels = FALSE, tcl = -0.25)
  mtext("SUT", side = 1, line = 5, cex = 1.6)
  
  # Legend
  legend("topright", legend = levels(dat_plot$Technique), 
         col = tool_colors[levels(dat_plot$Technique)],
         pt.cex = 1.5,
         pch = 1:length(levels(dat_plot$Technique)),
         bg = "white",
         cex = 1.6)
  
  # Restore original par settings
  par(old_par)
}
