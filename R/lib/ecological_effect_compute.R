# Question 6: direct temperature effect, with paired observation regimes.
# Separate seeds preserve every existing question's results.
generate_ecological_population <- function(temperature_effect = 0.3, n = 6000) {
  air_temperature_c <- rnorm(n, 27, 2.8)
  log_pressure <- rnorm(n, log(28), 0.65) +
    temperature_effect * (air_temperature_c - 27) / 2.8
  true_attacking_mosquitoes <- rpois(n, exp(log_pressure))
  tz <- as.numeric(scale(air_temperature_c))
  mz <- as.numeric(scale(true_attacking_mosquitoes))
  sampled <- rbinom(n, 1, plogis(-1 - 1.25 * tz + 1.75 * mz)) == 1
  # Potential counts under universal use; selected observation reveals a subset.
  # Net use affects availability only in this toy model, not attacker abundance.
  count <- rbinom(n, true_attacking_mosquitoes, 0.7)
  data.frame(air_temperature_c, true_attacking_mosquitoes, tz, mz, sampled, count)
}
ecological_slopes <- function(d) {
  c(universal = unname(coef(lm(count ~ air_temperature_c, d))[2]),
    selected = unname(coef(lm(count ~ air_temperature_c, d, subset = sampled))[2]))
}
set.seed(20260927)
ecological_example <- generate_ecological_population(0.3)
write.csv(ecological_example, "data/ecological_example.csv", row.names = FALSE)
set.seed(20260928)
ecological_draws <- do.call(rbind, lapply(c(-0.6, -0.3, -0.15, 0, 0.15, 0.3, 0.6), function(effect) {
  do.call(rbind, lapply(seq_len(200), function(b) {
    d <- generate_ecological_population(effect)
    slopes <- ecological_slopes(d)
    data.frame(temperature_effect = effect, replicate = b,
               universal = slopes[["universal"]], selected = slopes[["selected"]],
               difference = slopes[["selected"]] - slopes[["universal"]],
               sample_n = sum(d$sampled))
  }))
}))
ecological_summary <- do.call(rbind, lapply(split(ecological_draws, ecological_draws$temperature_effect), function(d) {
  data.frame(temperature_effect = d$temperature_effect[1], replicates = nrow(d),
             regime = c("universal", "selected", "difference"),
             mean_slope = sapply(d[c("universal", "selected", "difference")], mean),
             slope_low = sapply(d[c("universal", "selected", "difference")], quantile, .025),
             slope_high = sapply(d[c("universal", "selected", "difference")], quantile, .975),
             row.names = NULL)
}))
write.csv(ecological_draws, "data/ecological_replicates.csv", row.names = FALSE)
write.csv(ecological_summary, "data/ecological_summary.csv", row.names = FALSE)
print(ecological_summary, digits = 3, row.names = FALSE)
