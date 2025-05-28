# Experiment statistics
library(rethinking)
library(dagitty)
library(dplyr)
library(ggplot2)
source("MasterThesisLinearPlot.R")
source("MasterThesisDataSimulationUtils.R")
source("MasterThesisPlottingFunctions.R")

# NOISE PROFILE
experiment_noise_1 <- read.csv("time_series_noise_run_1.csv", header = TRUE, stringsAsFactors = FALSE)

# Fix names for plots
experiment_noise_1 <- experiment_noise_1 %>%
  mutate(Technique = case_when(
    Technique == "vanilla" ~ "Original",
    Technique == "depclean" ~ "Depclean",
    Technique == "deptrim" ~ "Deptrim",
    Technique == "jlink" ~ "Jlink",
    Technique == "proguard" ~ "Proguard",
    TRUE ~ Technique  # keep unchanged if unmatched
  ))

#plot(experiment_noise_1$Energy ~ experiment_noise_1$Time)

# Subset the data based on Technique and store in a new column
experiment_noise_1 <- experiment_noise_1 %>%
  filter(Technique %in% c("Original", "Depclean", "Deptrim", "Jlink", "Proguard"))

tool_colors = c("Original" = "blue", "Depclean" = "red", 
                "Deptrim" = "green", "Jlink" = "purple", "Proguard" = "orange")
desired_order <- c("Original", "Depclean", "Deptrim", "Jlink", "Proguard")
experiment_noise_1$Technique <- factor(experiment_noise_1$Technique, levels = desired_order)
# Plot density of power noise
ggplot(experiment_noise_1, aes(x = Power, fill = Technique, color = Technique)) +
  geom_density(alpha = 0.3) +  # Adjust alpha for transparency
  theme_minimal() +
  labs(title = "",
       x = "Power (Watt)",
       y = "Density") +
  scale_fill_manual(values = tool_colors) +
  scale_color_manual(values = tool_colors) +
  theme(
    legend.title = element_blank(),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 16),
    legend.text = element_text(size = 16),
    strip.text = element_text(size = 16),
    plot.title = element_text(size = 16)
  )


# Plot density of memory usage noise
ggplot(experiment_noise_1, aes(x = Memory_Usage, fill = Technique, color = Technique)) +
  geom_density(alpha = 0.3) +  # Adjust alpha for transparency
  theme_minimal() +
  labs(title = "",
       x = "Memory Usage (%)",
       y = "Density") +
  scale_fill_manual(values = tool_colors) +
  scale_color_manual(values = tool_colors) +
  theme(legend.title = element_blank())  # Optional, to remove the legend title

# Plot density of CPU usage noise
ggplot(experiment_noise_1, aes(x = CPU_Usage, fill = Technique, color = Technique)) +
  geom_density(alpha = 0.3) +  # Adjust alpha for transparency
  theme_minimal() +
  labs(title = "",
       x = "CPU Usage (%)",
       y = "Density") +
  scale_fill_manual(values = tool_colors) +
  scale_color_manual(values = tool_colors) +
  theme(legend.title = element_blank())  # Optional, to remove the legend title

# Calculate summary statistics for the Power column
power_stats <- experiment_noise_1 %>%
  summarise(
    mean_power = mean(Power, na.rm = TRUE),
    variance_power = var(Power, na.rm = TRUE),
    sd_power = sd(Power, na.rm = TRUE)
  )

# View the statistics
print(power_stats)

# Filter the dataset to remove values below 0.1W
filtered_data <- experiment_noise_1 %>%
  filter(Power >= 0.5)

# Find the minimum and maximum power values
min_power <- min(filtered_data$Power)
max_power <- max(filtered_data$Power)

# Display the results
cat("Minimum Power: ", min_power, "W\n")
cat("Maximum Power: ", max_power, "W\n")


# EXPERIMENT 1 RESULT BELOW
experiment_results_1 <- read.csv("time_series_results_run_1.csv", header = TRUE, stringsAsFactors = FALSE)

# Fix names for plots
experiment_results_1 <- experiment_results_1 %>%
  mutate(Technique = case_when(
    Technique == "vanilla" ~ "Original",
    Technique == "depclean" ~ "Depclean",
    Technique == "deptrim" ~ "Deptrim",
    Technique == "jlink" ~ "Jlink",
    Technique == "proguard" ~ "Proguard",
    TRUE ~ Technique  # keep unchanged if unmatched
  ))
#plot(experiment_results_1$Energy ~ experiment_results_1$Time)

# Scale all data for each SUT to make it easier to fit the linear models to it
experiment_results_1_linear <- experiment_results_1 %>%
  group_by(SUT) %>%
  mutate(Energy = Energy / max(Energy)) %>%
  ungroup() %>%
  mutate(Technique = factor(Technique, levels = desired_order))

# Remove outlier systems (These will be shown separately)
clean_data <- subset(experiment_results_1_linear,SUT != "javaFaker" & SUT != "error-prone")

# Split the data into benchmarks contra real-world programs
real_world_suts <- c("checkstyle", "coreNLP", "tika", "icij-extract")

# Subset real-world programs
real_world_programs <- clean_data %>%
  filter(SUT %in% real_world_suts) %>%
  mutate(Technique = factor(Technique, levels = desired_order))

# Subset benchmarks (everything else)
benchmarks <- clean_data %>%
  filter(!(SUT %in% real_world_suts)) %>%
  mutate(Technique = factor(Technique, levels = desired_order))

# Plot mean/median power over time
source("MasterThesisPlottingFunctions.R")
plot_raw_power_with_mean(benchmarks)
plot_raw_power_with_mean(real_world_programs)
plot_raw_power_with_median(benchmarks)
plot_raw_power_with_median(real_world_programs)
# Plot median cpu utilization over time
plot_raw_cpu_with_median(benchmarks)
plot_raw_cpu_with_median(real_world_programs)
# Plot median memory utilization over time
plot_raw_memory_with_median(benchmarks)
plot_raw_memory_with_median(real_world_programs)
# Plot normalized mean power over time
plot_normalized_power(benchmarks)
plot_normalized_power(real_world_programs)
source("MasterThesisLinearPlot.R")
# LINEAR MODEL
# LINEAR REAL WORLD PROGRAMS
models_precis_real_world_programs <- l_plot(real_world_programs, tool_colors) # Plot linear models against all data
o_plot(models_precis_real_world_programs, title="", xlabel="Power (Watt)", levels(real_world_programs$Technique)) # Plot the mean and CI of the power for each technique
# Get the percentage relative difference from the "original" technique 2
models_precis_percentage_real_world_programs <- convert_linear_models_precis_to_percentage(models_precis_real_world_programs,'Original')
# Plot the differences, however the labels will be wrong now
o_plot(models_precis_percentage_real_world_programs, title="", xlabel="Deviation From Original Power Consumption (%)",levels(real_world_programs$Technique))
# LINEAR BENCHMARKS
models_precis_benchmarks <- l_plot(benchmarks,tool_colors) # Plot linear models against all data
o_plot(models_precis_benchmarks, title="", xlabel="Power (Watt)", levels(real_world_programs$Technique)) # Plot the mean and CI of the power for each technique
# Get the percentage relative difference from the "original" technique 2
models_precis_percentage_benchmarks <- convert_linear_models_precis_to_percentage(models_precis_benchmarks,'Original')
# Plot the differences, however the labels will be wrong now
o_plot(models_precis_percentage_benchmarks, title="", xlabel="Deviation From Original Power Consumption (%)", levels(real_world_programs$Technique))


# HIERARCHICAL MODEL
# Drop the time and power columns, and only keep the final energy value of each trial
dat <- experiment_results_1 %>%
  group_by(SUT, Technique, Sample) %>%
  mutate(group_size = n()) %>%
  summarise(Energy = max(Energy) - 5.884241 * first(group_size), Time_Index = max(Time_Index),
            Time = max(Time), CPU_Usage = mean(CPU_Usage), Memory_Usage = mean(Memory_Usage), .groups = "drop") %>%
  ungroup()

# Scale all data for each SUT to make it easier to fit the hierachical models to it
dat <- dat %>%
  group_by(SUT) %>%
  mutate(
    Energy = Energy / max(Energy, na.rm = TRUE),
    CPU_Usage = CPU_Usage / max(CPU_Usage, na.rm = TRUE),
    Memory_Usage = Memory_Usage / max(Memory_Usage, na.rm = TRUE),
    Time = Time / max(Time, na.rm = TRUE)
  ) %>%
  ungroup()

# Detect outliers using Z-score (3 std dev threshold)
energy_outliers <- dat %>%
  group_by(SUT, Technique) %>%
  mutate(
    mean_energy = mean(Energy, na.rm = TRUE),
    sd_energy = sd(Energy, na.rm = TRUE),
    z_score = (Energy - mean_energy) / sd_energy,
    is_outlier = abs(z_score) > 3
  ) %>%
  ungroup()

# Analyze outlier javaFaker
javaFakerOutlier <- subset(energy_outliers,SUT=="javaFaker")

# Boxplot the distributions
ggplot(javaFakerOutlier, aes(x = interaction(SUT, Technique), y = Energy, color = is_outlier)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(title = "Energy Outliers per SUT-Technique Pair", x = "SUT-Technique", y = "Energy")

# Take a closer look at javaFaker/proguard measurements since the box looks long
javaFaker_proguard <- javaFakerOutlier %>%
  filter(SUT == "javaFaker", Technique == "proguard")

# It doesn't seem to be caused by the test ordering or a time-based variable
ggplot(javaFaker_proguard, aes(x = Sample, y = Energy)) +
  geom_line(color = "darkorange", linewidth = 1) +
  geom_point(alpha = 0.6) +
  labs(
    title = "Energy Consumption Over Time (by Sample)",
    x = "Sample (approx. time)",
    y = "Energy"
  ) +
  theme_minimal()

# Analyze outlier error-prone
errorProneOutlier <- subset(energy_outliers,SUT=="error-prone")

# Boxplot the distributions
ggplot(errorProneOutlier, aes(x = interaction(SUT, Technique), y = Energy, color = is_outlier)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(title = "Energy Outliers per SUT-Technique Pair", x = "SUT-Technique", y = "Energy")

# Take a closer look at javaFaker/proguard measurements since the box looks long
errorProne_jlink <- errorProneOutlier %>%
  filter(SUT == "error-prone", Technique == "jlink")

# It doesn't seem to be caused by the test ordering or a time-based variable
ggplot(errorProne_jlink, aes(x = Sample, y = Energy)) +
  geom_line(color = "darkorange", linewidth = 1) +
  geom_point(alpha = 0.6) +
  labs(
    title = "Energy Consumption Over Time (by Sample)",
    x = "Sample (approx. time)",
    y = "Energy"
  ) +
  theme_minimal()


# Clean the data
clean_data <- filter(energy_outliers, !is_outlier)

# Final changes to data
clean_data$Technique <- factor(clean_data$Technique, levels = desired_order)
clean_data$tech_id <- as.integer(clean_data$Technique)

# Remove outlier systems (These will be shown separately)
clean_data <- subset(clean_data,SUT != "javaFaker" & SUT != "error-prone")

# Split the data into benchmarks contra real-world programs
real_world_suts <- c("checkstyle", "coreNLP", "tika", "icij-extract")

# Subset real-world programs
real_world_programs <- clean_data %>% 
  filter(SUT %in% real_world_suts) %>% 
  mutate(Technique = factor(Technique, levels = desired_order))

# Subset benchmarks (everything else)
benchmarks <- clean_data %>% 
  filter(!(SUT %in% real_world_suts)) %>% 
  mutate(Technique = factor(Technique, levels = desired_order))

# Plot descriptive statistics before doing anything
# Create the boxplot without x-axis labels or ticks
boxplot(Energy ~ SUT, data = benchmarks, ylim = c(0.8, 1),
        xaxt = "n", xlab = "", ylab = "", main = "")

# Add y-axis label with more space
mtext("Normalized Energy", side = 2, line = 3)

# Get the unique SUT names and their positions
sut_levels <- levels(factor(benchmarks$SUT))
positions <- 1:length(sut_levels)

# Add diagonal x-axis labels at correct positions
text(x = positions, y = par("usr")[3] - 0.005, labels = sut_levels, 
     srt = 30, adj = 1, xpd = TRUE, cex = 0.8)

# Add x-axis title ("Benchmarks") further below
mtext("Benchmarks", side = 1, line = 3.5)


# Create the boxplot without x-axis labels or ticks
boxplot(Energy ~ SUT, data = real_world_programs, ylim = c(0.8, 1),
        xaxt = "n", xlab = "", ylab = "", main = "")

# Add y-axis label with more space
mtext("Normalized Energy", side = 2, line = 3)

# Get the unique SUT names and their positions
sut_levels <- levels(factor(real_world_programs$SUT))
positions <- 1:length(sut_levels)

# Add diagonal x-axis labels at correct positions
text(x = positions, y = par("usr")[3] - 0.005, labels = sut_levels, 
     srt = 30, adj = 1, xpd = TRUE, cex = 0.8)

# Add x-axis title ("Benchmarks") further below
mtext("Real-world Programs", side = 1, line = 3.5)


# Summarize the energy
source("MasterThesisPlottingFunctions.R")
dat_plot_mean <- clean_data %>%
  group_by(SUT, Technique) %>%
  summarise(Energy = sum(Energy) / n(), .groups = "drop")

dat_plot_median <- clean_data %>%
  group_by(SUT, Technique) %>%
  summarise(Energy = median(Energy, na.rm = TRUE), .groups = "drop")

# Ensure consistent ordering for SUT and Technique
dat_plot_mean$SUT <- factor(dat_plot_mean$SUT, levels = unique(clean_data$SUT))
dat_plot_mean$Technique <- factor(dat_plot_mean$Technique, levels = desired_order)
dat_plot_median$SUT <- factor(dat_plot_median$SUT, levels = unique(clean_data$SUT))
dat_plot_median$Technique <- factor(dat_plot_median$Technique, levels = desired_order)

plot_energy_by_tool_and_sut(dat_plot_mean,tool_colors) # Plot mean
plot_energy_by_tool_and_sut(dat_plot_median,tool_colors) # Plot median



# Plot priors
plot(density(rnorm(10000000, 0.5, 0.4)), xlab = "Energy Consumption", main = "Density Plot",xlim=c(-1,2))
plot(density(rexp(10000000, 1)), xlab = "Energy Consumption", main = "Density Plot",xlim=c(-0.1,5))

# train a simple hierarchical model on max energy of each trial
model_benchmarks <- ulam(
  alist(
    Energy ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = benchmarks,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_energy_benchmarks <- precis(model_benchmarks,depth=2,digits = 6)
precis_energy_benchmarks
precis_percentage_energy_benchmarks <- convert_hierarchical_model_precis_to_percentage(model_benchmarks,1)
precis_percentage_energy_benchmarks
o_plot(subset(precis_percentage_energy_benchmarks, rownames(precis_percentage_energy_benchmarks) != "sigma"), title="", xlabel="Deviation From Original Energy Consumption (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_benchmarks, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_benchmarks)
gc()

model_real_world_programs <- ulam(
  alist(
    Energy ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = real_world_programs,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)

precis_real_world_programs_energy <- precis(model_real_world_programs,depth=2,digits = 6)
precis_real_world_programs_energy
precis_percentage_real_world_programs_energy <- convert_hierarchical_model_precis_to_percentage(model_real_world_programs,1)
precis_percentage_real_world_programs_energy
o_plot(subset(precis_percentage_real_world_programs_energy, rownames(precis_percentage_real_world_programs_energy) != "sigma"), title="", xlabel="Deviation From Original Energy Consumption (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_real_world_programs, real_world_programs,breaks=70)
# Free up memory from previous model
rm(model_real_world_programs)
gc()

# Train on time
model_benchmarks_time <- ulam(
  alist(
    Time ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = benchmarks,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_benchmarks_time <- precis(model_benchmarks_time,depth=2,digits = 6)
precis_benchmarks_time
precis_percentage_benchmarks_time <- convert_hierarchical_model_precis_to_percentage(model_benchmarks_time,1)
precis_percentage_benchmarks_time
o_plot(subset(precis_percentage_benchmarks_time, rownames(precis_percentage_benchmarks_time) != "sigma"), title="", xlabel="Deviation From Original Execution Time (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_benchmarks_time, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_benchmarks_time)
gc()

model_real_world_programs_time <- ulam(
  alist(
    Time ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = real_world_programs,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_real_world_programs_time <- precis(model_real_world_programs_time,depth=2,digits = 6)
precis_real_world_programs_time
precis_percentage_real_world_programs_time <- convert_hierarchical_model_precis_to_percentage(model_real_world_programs_time,1)
precis_percentage_real_world_programs_time
o_plot(subset(precis_percentage_real_world_programs_time, rownames(precis_percentage_real_world_programs_time) != "sigma"), title="", xlabel="Deviation From Original Execution Time (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_real_world_programs_time, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_real_world_programs_time)
gc()


# Train on memory usage
model_benchmarks_memory <- ulam(
  alist(
    Memory_Usage ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = benchmarks,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_benchmarks_memory <- precis(model_benchmarks_memory,depth=2,digits = 6)
precis_benchmarks_memory
precis_percentage_benchmarks_memory <- convert_hierarchical_model_precis_to_percentage(model_benchmarks_memory,1)
precis_percentage_benchmarks_memory
o_plot(subset(precis_percentage_benchmarks_memory, rownames(precis_percentage_benchmarks_memory) != "sigma"), title="", xlabel="Deviation From Original Memory Usage (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_benchmarks_memory, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_benchmarks_memory)
gc()

model_real_world_programs_memory <- ulam(
  alist(
    Memory_Usage ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = real_world_programs,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_real_world_programs_memory <- precis(model_real_world_programs_memory,depth=2,digits = 6)
precis_real_world_programs_memory
precis_percentage_real_world_programs_memory <- convert_hierarchical_model_precis_to_percentage(model_real_world_programs_memory,1)
precis_percentage_real_world_programs_memory
o_plot(subset(precis_percentage_real_world_programs_memory, rownames(precis_percentage_real_world_programs_memory) != "sigma"), title="", xlabel="Deviation From Original Memory Usage (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_real_world_programs_memory, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_real_world_programs_memory)
gc()

# Train on CPU usage
model_benchmarks_cpu <- ulam(
  alist(
    CPU_Usage ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = benchmarks,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_benchmarks_cpu <- precis(model_benchmarks_cpu,depth=2,digits = 6)
precis_benchmarks_cpu
precis_percentage_benchmarks_cpu <- convert_hierarchical_model_precis_to_percentage(model_benchmarks_cpu,1)
precis_percentage_benchmarks_cpu
o_plot(subset(precis_percentage_benchmarks_cpu, rownames(precis_percentage_benchmarks_cpu) != "sigma"), title="", xlabel="Deviation From Original CPU Usage (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_benchmarks_cpu, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_benchmarks_cpu)
gc()


model_real_world_programs_cpu <- ulam(
  alist(
    CPU_Usage ~ dnorm(mu, sigma),
    mu <- Q[tech_id],
    Q[tech_id] ~ dnorm(0.5, 0.4),
    sigma ~ dexp(1)
  ),
  data = real_world_programs,
  chains = 4, cores = 4, iter = 20000, log_lik = TRUE
)
precis_real_world_programs_cpu <- precis(model_real_world_programs_cpu,depth=2,digits = 6)
precis_real_world_programs_cpu
precis_percentage_real_world_programs_cpu <- convert_hierarchical_model_precis_to_percentage(model_real_world_programs_cpu,1)
precis_percentage_real_world_programs_cpu
o_plot(subset(precis_percentage_real_world_programs_cpu, rownames(precis_percentage_real_world_programs_cpu) != "sigma"), title="", xlabel="Deviation From Original CPU Usage (%)", levels(benchmarks$Technique))
plot_posterior_vs_real(model_real_world_programs_cpu, benchmarks,breaks=70)
# Free up memory from previous model
rm(model_real_world_programs_cpu)
gc()

# Check correlation
precis_percentage_real_world_programs_cpu
precis_percentage_real_world_programs_memory
precis_percentage_real_world_programs_time
precis_percentage_real_world_programs_energy
models_precis_percentage_real_world_programs


precis_percentage_benchmarks_cpu
precis_percentage_benchmarks_memory
precis_percentage_benchmarks_time
precis_percentage_energy_benchmarks
models_precis_percentage_benchmarks

# Function to extract means and drop last row (e.g., sigma)
clean_precis_mean <- function(precis_obj) {
  head(precis_obj$mean, -1)
}

# Technique labels
techniques <- c("Original", "DepClean", "DepTrim", "JLink", "ProGuard")

# ---- Real-world Programs ----
df_real <- data.frame(
  Tool = techniques,
  `CPU (%)` = clean_precis_mean(precis_percentage_real_world_programs_cpu),
  `Memory (%)` = clean_precis_mean(precis_percentage_real_world_programs_memory),
  `Execution Time (%)` = clean_precis_mean(precis_percentage_real_world_programs_time),
  `Power (%)` = models_precis_percentage_real_world_programs$mean,
  `Energy (%)` = clean_precis_mean(precis_percentage_real_world_programs_energy)
)

# ---- Benchmarks ----
df_bench <- data.frame(
  Tool = techniques,
  `CPU (%)` = clean_precis_mean(precis_percentage_benchmarks_cpu),
  `Memory (%)` = clean_precis_mean(precis_percentage_benchmarks_memory),
  `Execution Time (%)` = clean_precis_mean(precis_percentage_benchmarks_time),
  `Power (%)` = models_precis_percentage_benchmarks$mean,
  `Energy (%)` = clean_precis_mean(precis_percentage_energy_benchmarks)
)

# Set Tool as rownames and remove column
rownames(df_real) <- df_real$Tool
rownames(df_bench) <- df_bench$Tool
df_real$Tool <- NULL
df_bench$Tool <- NULL

# ---- Clean column names ----
colnames(df_real) <- c("CPU", "Memory", "Time", "Power", "Energy")
colnames(df_bench) <- c("CPU", "Memory", "Time", "Power", "Energy")

# ---- Correlation: Real-world Programs ----
cor_real <- cor(df_real)
cor_real_energy <- cor_real[, "Energy"]
cor_real_power <- cor_real[, "Power"]

cat("Correlations with Energy (Real-world Programs):\n")
print(cor_real_energy)

cat("\nCorrelations with Power (Real-world Programs):\n")
print(cor_real_power)

# ---- Correlation: Benchmarks ----
cor_bench <- cor(df_bench)
cor_bench_energy <- cor_bench[, "Energy"]
cor_bench_power <- cor_bench[, "Power"]

cat("\nCorrelations with Energy (Benchmarks):\n")
print(cor_bench_energy)

cat("\nCorrelations with Power (Benchmarks):\n")
print(cor_bench_power)

# ---------- CHECK CORRELATION BETWEEN RAW DATA USING LINEAR DATA -----------
# Assumes the raw data used for the linear model is loaded

# ---- Real-world Programs Correlation ----
# Select only the necessary columns for correlation
real_world_data <- real_world_programs %>%
  select(Time, Power, CPU_Usage, Memory_Usage)

# Calculate the correlation matrix for the real-world programs data
cor_real_world <- cor(real_world_data, use = "complete.obs")

# Print the correlation matrix
cat("Correlation Matrix - Real-world Programs:\n")
print(cor_real_world)

# ---- Benchmarks Correlation ----
# Select only the necessary columns for correlation
benchmark_data <- benchmarks %>%
  select(Time, Power, CPU_Usage, Memory_Usage)

# Calculate the correlation matrix for the benchmarks data
cor_benchmarks <- cor(benchmark_data, use = "complete.obs")

# Print the correlation matrix
cat("\nCorrelation Matrix - Benchmarks:\n")
print(cor_benchmarks)

# ---------- CHECK CORRELATION BETWEEN RAW DATA USING HIERARCHICAL DATA -----------
# Assumes the raw data used for the hierarchical model is loaded

# ---- Real-world Programs Correlation ----
# Select only the necessary columns for correlation (Energy, Time, CPU_Usage, Memory_Usage)
real_world_data <- real_world_programs %>%
  select(Energy, Time, CPU_Usage, Memory_Usage)

# Calculate the correlation matrix for the real-world programs data
cor_real_world <- cor(real_world_data, use = "complete.obs")

# Print the correlation matrix
cat("Correlation Matrix - Real-world Programs:\n")
print(cor_real_world)

# ---- Benchmarks Correlation ----
# Select only the necessary columns for correlation (Energy, Time, CPU_Usage, Memory_Usage)
benchmark_data <- benchmarks %>%
  select(Energy, Time, CPU_Usage, Memory_Usage)

# Calculate the correlation matrix for the benchmarks data
cor_benchmarks <- cor(benchmark_data, use = "complete.obs")

# Print the correlation matrix
cat("\nCorrelation Matrix - Benchmarks:\n")
print(cor_benchmarks)



# ---------- CREATE TABLES -----------
# Function to extract both mean and sd, excluding last row (sigma)
clean_precis_stats <- function(precis_obj) {
  df <- precis_obj[c("mean", "sd")]
  df <- head(df, -1)  # drop sigma
  return(df)
}
# ---- Real-world Programs ----
df_real_stats <- data.frame(
  Tool = techniques,
  CPU_Mean = clean_precis_stats(precis_percentage_real_world_programs_cpu)$mean,
  CPU_SD = clean_precis_stats(precis_percentage_real_world_programs_cpu)$sd,
  Memory_Mean = clean_precis_stats(precis_percentage_real_world_programs_memory)$mean,
  Memory_SD = clean_precis_stats(precis_percentage_real_world_programs_memory)$sd,
  Time_Mean = clean_precis_stats(precis_percentage_real_world_programs_time)$mean,
  Time_SD = clean_precis_stats(precis_percentage_real_world_programs_time)$sd,
  Power_Mean = models_precis_percentage_real_world_programs$mean,
  Power_SD = models_precis_percentage_real_world_programs$sd,
  Energy_Mean = clean_precis_stats(precis_percentage_real_world_programs_energy)$mean,
  Energy_SD = clean_precis_stats(precis_percentage_real_world_programs_energy)$sd
)

# ---- Benchmarks ----
df_bench_stats <- data.frame(
  Tool = techniques,
  CPU_Mean = clean_precis_stats(precis_percentage_benchmarks_cpu)$mean,
  CPU_SD = clean_precis_stats(precis_percentage_benchmarks_cpu)$sd,
  Memory_Mean = clean_precis_stats(precis_percentage_benchmarks_memory)$mean,
  Memory_SD = clean_precis_stats(precis_percentage_benchmarks_memory)$sd,
  Time_Mean = clean_precis_stats(precis_percentage_benchmarks_time)$mean,
  Time_SD = clean_precis_stats(precis_percentage_benchmarks_time)$sd,
  Power_Mean = models_precis_percentage_benchmarks$mean,
  Power_SD = models_precis_percentage_benchmarks$sd,
  Energy_Mean = clean_precis_stats(precis_percentage_energy_benchmarks)$mean,
  Energy_SD = clean_precis_stats(precis_percentage_energy_benchmarks)$sd
)

# Optional: set Tool as rownames
rownames(df_real_stats) <- df_real_stats$Tool
rownames(df_bench_stats) <- df_bench_stats$Tool
df_real_stats$Tool <- NULL
df_bench_stats$Tool <- NULL

# View results
print(df_real_stats)
print(df_bench_stats)
