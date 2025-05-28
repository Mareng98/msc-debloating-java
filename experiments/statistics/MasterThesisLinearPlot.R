l_plot <- function(timeseries_data, technique_colors = c("red", "blue", "green", "purple", "orange")) {
  # Ensure technique levels are captured correctly
  technique_levels <- levels(timeseries_data$Technique)
  
  # Make sure we have enough colors
  if (length(technique_colors) < length(technique_levels)) {
    technique_colors <- rep(technique_colors, length.out = length(technique_levels))
  }
  
  # Initialize an empty data frame to store model summaries
  models_list_prec <- data.frame(
    Technique = character(),
    mean = numeric(),
    sd = numeric(),
    `5.5%` = numeric(),
    `94.5%` = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Initialize an empty list to store models
  models_list <- list()
  
  # Plot all data as background
  plot(timeseries_data$Time, timeseries_data$Energy, 
       main = "", 
       xlab = "Execution Time (Seconds)", 
       ylab = "Normalized Energy Consumption", 
       pch = 16, 
       col = "gray", 
       cex = 0.8,         # point size
       cex.axis = 1.6,    # axis tick label size
       cex.lab = 1.6,     # axis title size
       cex.main = 1.6     # plot title size (even if blank)
  )
  
  # Loop through each technique
  for (tech in technique_levels) {
    subset_data <- subset(timeseries_data, Technique == tech)
    
    # Fit the linear model
    model <- lm(Energy ~ Time, data = subset_data)
    
    # Store the model in the models_list
    models_list[[tech]] <- model
    
    # Extract summary stats
    prec <- precis(model)[2, ]
    prec$Technique <- tech
    models_list_prec <- rbind(models_list_prec, prec)
    
    # Predict confidence intervals
    predictions <- predict(model, newdata = subset_data, interval = "confidence", level = 0.95)
    lower_bound <- predictions[, "lwr"]
    upper_bound <- predictions[, "upr"]
    
    tech_index <- which(technique_levels == tech)
    
    # Plot regression line
    abline(model, col = technique_colors[tech_index], lwd = 2)
  }
  
  # Capitalize technique names for legend
  legend_labels <- tools::toTitleCase(as.character(technique_levels))
  
  # Add legend in bottom right
  legend("bottomright",
         legend = legend_labels,
         col = technique_colors[seq_along(technique_levels)],
         lwd = 2,
         cex = 1.6)  # legend font size
  
  return(models_list_prec)
}




# PLOT MEANS AND STANDARD DEVIATIONS OF POWER -- Above block has to be executed first
# Loop through techniques and plot the means with 2 SD

o_plot <- function(linear_models_precis_list, 
                   title = "title", 
                   xlabel = "xlabel", 
                   tool_names) {
  # Reverse order
  n <- nrow(linear_models_precis_list)
  y_positions <- rev(1:n)  # Reversed y positions
  
  # Define x limits based on CI
  x_min <- min(linear_models_precis_list$`5.5%`)
  x_max <- max(linear_models_precis_list$`94.5%`)
  par(mar = c(5, 4, 4, 2), mgp = c(3, 1, 0))
  
  
  # Create an empty plot
  plot(1, type = "n", 
       xlim = c(x_min, x_max), 
       ylim = c(0.5, n + 0.5), 
       xaxt = "n", yaxt = "n", 
       xlab = xlabel, ylab = "", 
       main = title,
       cex.lab = 1.6,
       cex.main = 1.6
  )
  
  # Add vertical line at 0
  abline(v = 0, col = "gray50", lwd = 1, lty = 2)
  
  # Loop through each technique
  for (i in 1:n) {
    tech <- y_positions[i]           # reversed position
    prec <- linear_models_precis_list[i, ]
    means <- prec$mean
    lower <- prec$`5.5%`
    upper <- prec$`94.5%`
    
    points(means, tech, pch = 16, cex = 1.5, col = "black")
    lines(c(lower, upper), c(tech, tech), col = "black", lwd = 3)
    segments(lower, tech - 0.1, lower, tech + 0.1, col = "black", lwd = 1)
    segments(upper, tech - 0.1, upper, tech + 0.1, col = "black", lwd = 1)
  }
  
  # Custom y-axis labels (flipped)
  axis(2, at = 1:n, labels = rev(tool_names), cex.axis = 1.6)
  
  # X-axis with percentage labels
  x_ticks <- pretty(c(x_min, x_max))
  axis(1, at = x_ticks, labels = paste0(x_ticks, "%"), cex.axis = 1.6)
}




convert_linear_models_precis_to_percentage <- function(data, technique) {
  # Ensure the reference model exists
  if (!(technique %in% data$Technique)) {
    stop("Reference model not found in the dataset.")
  }
  
  # Extract reference value
  ref_mean <- data$mean[data$Technique == technique]
  
  # Compute percentage differences
  data$mean <- ((data$mean - ref_mean) / ref_mean) * 100 # Offset means with tech 2 and convert to percentage difference
  data$sd <- ((data$sd) / ref_mean) * 100 # convert to percetage
  data$`5.5%` <- ((data$`5.5%` - ref_mean) / ref_mean) * 100
  data$`94.5%` <- ((data$`94.5%` - ref_mean) / ref_mean) * 100
  
  # Return the updated dataframe
  return(data[, c("Technique", "mean", "sd", "5.5%", "94.5%")])
}

convert_hierarchical_model_precis_to_percentage <- function(model, technique) {
  data <- precis(model,depth=2,digits=6)
  # Extract reference value
  ref_mean <- data[technique,1]
  
  # Compute percentage differences
  data$mean <- ((data$mean - ref_mean) / ref_mean) * 100 # Offset means with tech 2 and convert to percentage difference
  data$sd <- ((data$sd) / ref_mean) * 100 # convert to percetage
  data$`5.5%` <- ((data$`5.5%` - ref_mean) / ref_mean) * 100
  data$`94.5%` <- ((data$`94.5%` - ref_mean) / ref_mean) * 100
  
  # Return the updated dataframe
  return(data[, c("mean", "sd", "5.5%", "94.5%")])
}
plot_posterior_vs_real <- function(model, data, 
                                   energy_col = "Energy", 
                                   tech_id_col = "tech_id", 
                                   breaks = 30) {
  # Extract posterior samples
  post <- extract.samples(model)
  
  # Extract real data
  energy_vals <- data[[energy_col]]
  
  # Compute posterior means per tech_id
  pred_mu <- apply(post$Q, 2, mean)
  
  # Adjust margins: bottom, left, top, right
  par(mar = c(5, 5, 4, 2))  # Increase left margin from default 4.1 to 5
  
  # Plot histogram of real data
  hist(energy_vals,
       breaks = breaks,
       col = rgb(1, 0, 0, 0.4), # semi-transparent red
       xlab = "Normalized Energy Consumption",
       main = "",
       freq = FALSE,
       cex.axis = 1.6,
       cex.lab = 1.6,
       cex.main = 1.6)
  
  # Overlay posterior densities in black with opacity for each tech_id
  for (i in seq_along(pred_mu)) {
    curve(dnorm(x, mean = pred_mu[i], sd = mean(post$sigma)),
          col = adjustcolor("black", alpha.f = 0.6),
          add = TRUE,
          lwd = 2)
  }
  
  # Add legend
  legend("topleft",
         legend = c("Observed Data", "Posterior Predictions"),
         fill = c(rgb(1, 0, 0, 0.4), adjustcolor("black", alpha.f = 0.6)),
         border = NA,
         cex = 1.6)
}
