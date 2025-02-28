library(ggplot2)
library(bayesplot)
library(posterior)

#post predictive check
png("ppc_plot.png", width = 800, height = 600)
pp_check(mock_model, type = "dens_overlay")
dev.off()

posterior_samples <- as_draws_df(mock_model)

#save density plot (one for each tool)- proguard
png("density_plot.png", width = 800, height = 600)
ggplot(posterior_samples, aes(x = b_Debloated_Artifactproguard)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Posterior Distribution for ProGuard Energy Reduction",
       x = "Percent Change (%)",
       y = "Density") +
  theme_minimal()
#dev.off()

