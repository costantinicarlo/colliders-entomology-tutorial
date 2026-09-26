# 03_make_plots.R
# Creates the figures used by the Slides Extended decks.
# Uses ggplot2 if available; otherwise falls back to base graphics.

houses <- read.csv("data/simulated_houses.csv")
obs <- subset(houses, house_sampled == 1)
results <- read.csv("data/expected_results.csv")
dir.create("figures/en", recursive = TRUE, showWarnings = FALSE)

has_ggplot <- requireNamespace("ggplot2", quietly = TRUE)

if (has_ggplot) {
  library(ggplot2)

  p1 <- ggplot(houses, aes(air_temperature_c, true_attacking_mosquitoes)) +
    geom_point(alpha = 0.18, size = 0.8) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(title = "Full population: causal expectation",
         subtitle = "The simulation contains no temperature effect on mosquito pressure",
         x = "air temperature (deg C)", y = "true attacking mosquitoes") +
    theme_minimal(base_size = 13)
  ggsave("figures/en/fig01a_full_population.png", p1, width = 7, height = 4.6, dpi = 180)

  p2 <- ggplot(obs, aes(air_temperature_c, mosquitoes_counted_inside_net)) +
    geom_point(alpha = 0.18, size = 0.8) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(title = "Observed bed-net sample",
         subtitle = "Sampling only bed-net users creates a positive association",
         x = "air temperature (deg C)", y = "mosquitoes counted inside net") +
    theme_minimal(base_size = 13)
  ggsave("figures/en/fig01b_observed_sample.png", p2, width = 7, height = 4.6, dpi = 180)

  results$analysis <- factor(results$analysis, levels = rev(results$analysis))
  p3 <- ggplot(results, aes(slope_per_celsius, analysis)) +
    geom_vline(xintercept = 0, linetype = 2) +
    geom_errorbar(aes(xmin = ci_low, xmax = ci_high),
                  orientation = "y", width = 0.15) +
    geom_point(size = 2.6) +
    labs(title = "Selection and net entry shape the observed slope",
         x = "estimated slope: mosquitoes per deg C", y = NULL) +
    scale_y_discrete(labels = c(
      full_population_true_process = "All: true attackers",
      sampled_houses_true_attackers = "Selected: true attackers",
      sampled_houses_observed_count = "Selected: net counts"
    )) +
    theme_minimal(base_size = 13)
  ggsave("figures/en/fig03_coefficient_comparison.png", p3, width = 8, height = 4.6, dpi = 180)

} else {
  png("figures/en/fig01a_full_population.png", width = 1200, height = 800, res = 180)
  plot(houses$air_temperature_c, houses$true_attacking_mosquitoes,
       pch = 16, cex = 0.35, col = rgb(0, 0, 0, 0.2),
       xlab = "air temperature (deg C)", ylab = "true attacking mosquitoes",
       main = "Full population: causal expectation")
  abline(lm(true_attacking_mosquitoes ~ air_temperature_c, data = houses), lwd = 2)
  dev.off()

  png("figures/en/fig01b_observed_sample.png", width = 1200, height = 800, res = 180)
  plot(obs$air_temperature_c, obs$mosquitoes_counted_inside_net,
       pch = 16, cex = 0.35, col = rgb(0, 0, 0, 0.2),
       xlab = "air temperature (deg C)", ylab = "mosquitoes counted inside net",
       main = "Observed bed-net sample")
  abline(lm(mosquitoes_counted_inside_net ~ air_temperature_c, data = obs), lwd = 2)
  dev.off()
}

# Shared log axes show original count units; zero counts cannot be plotted.
# Fit on all original counts, including zeros; transform only the display.
png("figures/en/fig01_population_vs_sample.png", width = 1800, height = 850, res = 160)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 4, 1), oma = c(2, 0, 2, 0))
all_counts <- c(houses$true_attacking_mosquitoes, obs$mosquitoes_counted_inside_net)
positive_range <- range(all_counts[all_counts > 0], na.rm = TRUE)
count_ticks <- sort(as.vector(outer(c(1, 2, 5),
                                   10^(floor(log10(positive_range[1])):
                                       ceiling(log10(positive_range[2]))))))
count_ticks <- count_ticks[count_ticks >= positive_range[1] &
                             count_ticks <= positive_range[2]]
count_range <- c(min(count_ticks), max(positive_range))
temp_range <- range(houses$air_temperature_c)
temp_grid <- data.frame(air_temperature_c = seq(temp_range[1], temp_range[2],
                                               length.out = 300))
plot_count_panel <- function(data, response, title, ylabel) {
  counts <- data[[response]]
  positive <- counts > 0
  plot(data$air_temperature_c[positive], counts[positive],
       pch = 16, cex = 0.4, col = rgb(0, 0, 0, 0.18),
       log = "y", yaxt = "n", xlim = temp_range, ylim = count_range,
       xlab = "Air temperature (deg C)", ylab = ylabel, main = title)
  axis(2, at = count_ticks, labels = count_ticks, las = 1)
  fit <- lm(reformulate("air_temperature_c", response), data = data)
  fitted_counts <- predict(fit, newdata = temp_grid)
  fitted_counts[fitted_counts <= 0] <- NA_real_
  lines(temp_grid$air_temperature_c, fitted_counts, col = "#0b6b63", lwd = 3)
}
plot_count_panel(houses, "true_attacking_mosquitoes", "Full population",
                 "True attacking mosquitoes (log scale)")
plot_count_panel(obs, "mosquitoes_counted_inside_net",
                 "Selected net users: binomial capture",
                 "Mosquitoes inside net (log scale)")
mtext(sprintf("Net-entry probability = %.2f; tick labels are original mosquito counts",
              houses$bed_net_entry_rate[1]), outer = TRUE, cex = 0.85)
mtext(sprintf("Zero counts omitted from log display: population %d, sample %d. Fits include zeros and use original counts.",
              sum(houses$true_attacking_mosquitoes == 0),
              sum(obs$mosquitoes_counted_inside_net == 0)),
      side = 1, outer = TRUE, cex = 0.75)
dev.off()

if (!has_ggplot) {
  png("figures/en/fig03_coefficient_comparison.png", width = 1440, height = 830, res = 180)
  par(mar = c(5, 12, 4, 2))
  plot(results$slope_per_celsius, rev(seq_len(nrow(results))),
       xlim = range(c(0, results$ci_low, results$ci_high)),
       ylim = c(0.5, 3.5), yaxt = "n", pch = 16,
       xlab = "Estimated slope: mosquitoes per deg C", ylab = "",
       main = "Selection and net entry shape the observed slope")
  axis(2, at = 3:1, labels = c("All: true attackers", "Selected: true attackers",
                             "Selected: net counts"), las = 1, cex.axis = 0.8)
  abline(v = 0, lty = 2)
  segments(results$ci_low, 3:1, results$ci_high, 3:1, col = "#0b6b63", lwd = 2)
  dev.off()
}

# Raw and standardised variables have the same Pearson correlation.
# Use the full-precision generated data, as in the analysis and teaching slides.
png("figures/en/fig05_population_correlation.png", width = 1500, height = 850, res = 160)
par(mfrow = c(1, 2), pty = "s", mar = c(4.5, 4.5, 3, 1),
    bg = "#f7f7f3", col.axis = "#18212a", col.lab = "#18212a")
plot(houses$air_temperature_c, houses$true_attacking_mosquitoes,
     pch = 16, cex = 0.35, col = rgb(0.04, 0.42, 0.39, 0.18),
     xlab = "Temperature (deg C)", ylab = "Attacking mosquitoes",
     main = "Original units")
abline(lm(true_attacking_mosquitoes ~ air_temperature_c, data = houses),
       col = "#9a631b", lwd = 3)
tz <- as.numeric(scale(houses$air_temperature_c))
mz <- as.numeric(scale(houses$true_attacking_mosquitoes))
z_ticks <- pretty(range(c(tz, mz)))
z_limits <- range(z_ticks)
plot(tz, mz, xlim = z_limits, ylim = z_limits,
     asp = 1, xaxs = "i", yaxs = "i", axes = FALSE,
     pch = 16, cex = 0.35, col = rgb(0.04, 0.42, 0.39, 0.18),
     xlab = "Temperature: tz (SD units)", ylab = "Attackers: mz (SD units)",
     main = "Standardised variables")
axis(1, at = z_ticks)
axis(2, at = z_ticks)
box()
abline(lm(mz ~ tz), col = "#9a631b", lwd = 3)
dev.off()

# Same standardised selection surface in both languages: tz and mz from -2.7 to 2.7.
tz_grid <- seq(-2.7, 2.7, length.out = 180)
mz_grid <- seq(-2.7, 2.7, length.out = 180)
probability <- outer(tz_grid, mz_grid, function(tz, mz) {
  plogis(-1 - 1.25 * tz + 1.75 * mz)
})
palette <- hcl.colors(128, "viridis")
png("figures/en/fig02_selection_surface.png", width = 1400, height = 1000, res = 160)
layout(matrix(c(1, 2), nrow = 1), widths = c(5, 1))
par(mar = c(4.5, 4.5, 3, 0.5))
image(tz_grid, mz_grid, probability, col = palette, zlim = c(0, 1),
      useRaster = TRUE, xlab = "Standardised temperature (tz)",
      ylab = "Standardised nuisance (mz)",
      main = "Observation depends on the behavioural filter")
contour(tz_grid, mz_grid, probability, add = TRUE, col = "white",
        levels = c(0.1, 0.25, 0.5, 0.75, 0.9))
par(mar = c(4.5, 1, 3, 4.5))
image(1, seq(0, 1, length.out = 128), matrix(seq(0, 1, length.out = 128), nrow = 1),
      col = palette, useRaster = TRUE, axes = FALSE, xlab = "", ylab = "")
axis(4, at = seq(0, 1, by = 0.2), las = 1)
mtext("Probability of net use / sampling", side = 4, line = 3)
box()
dev.off()


# Marginal distributions before standardisation or selection: linear axes,
# complete ranges, and frequency counts (no smoothing of discrete attackers).
png("figures/en/fig00_population_distributions.png", width = 1500, height = 700, res = 160)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1), bg = "#f7f7f3")
temperature <- houses$air_temperature_c
attackers <- houses$true_attacking_mosquitoes
hist(temperature, breaks = seq(floor(min(temperature)), ceiling(max(temperature)), by = 1),
     freq = TRUE, col = "#77b7af", border = "#f7f7f3",
     main = "Air temperature", xlab = "Air temperature (deg C)",
     ylab = "Number of house-nights", xaxs = "i", yaxs = "i")
hist(attackers, breaks = seq(-0.5, ceiling((max(attackers) + 0.5) / 10) * 10 - 0.5, by = 10),
     freq = TRUE, col = "#d8ae69", border = "#f7f7f3",
     main = "Attacking mosquitoes", xlab = "Attacking mosquitoes per house-night",
     ylab = "Number of house-nights", xaxs = "i", yaxs = "i")
dev.off()
