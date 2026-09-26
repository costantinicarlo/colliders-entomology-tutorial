# 02_analyse.R
# Expected causal result vs observed result.

houses <- read.csv("data/simulated_houses.csv")

fit_full <- lm(true_attacking_mosquitoes ~ air_temperature_c, data = houses)
fit_sample_true <- lm(true_attacking_mosquitoes ~ air_temperature_c,
                      data = subset(houses, house_sampled == 1))
fit_observed <- lm(mosquitoes_counted_inside_net ~ air_temperature_c,
                   data = subset(houses, house_sampled == 1))

extract <- function(fit, label) {
  s <- summary(fit)
  ci <- confint(fit)["air_temperature_c", ]
  data.frame(
    analysis = label,
    intercept = unname(coef(fit)[1]),
    slope_per_celsius = unname(coef(fit)[2]),
    se_slope = unname(s$coefficients["air_temperature_c", "Std. Error"]),
    ci_low = unname(ci[1]),
    ci_high = unname(ci[2]),
    n = nobs(fit)
  )
}

results <- rbind(
  extract(fit_full, "full_population_true_process"),
  extract(fit_sample_true, "sampled_houses_true_attackers"),
  extract(fit_observed, "sampled_houses_observed_count")
)

write.csv(results, "data/expected_results.csv", row.names = FALSE)
print(results, digits = 3)

# Check linear association in the full population, before selection.
# Standardisation changes units, not Pearson correlation.
tz <- as.numeric(scale(houses$air_temperature_c))
mz <- as.numeric(scale(houses$true_attacking_mosquitoes))
correlation_raw <- cor.test(houses$air_temperature_c,
                            houses$true_attacking_mosquitoes, method = "pearson")
correlation_z <- cor.test(tz, mz, method = "pearson")
stopifnot(isTRUE(all.equal(unname(correlation_raw$estimate),
                          unname(correlation_z$estimate))),
          isTRUE(all.equal(correlation_raw$p.value, correlation_z$p.value)))
correlation_results <- data.frame(
  n = nrow(houses),
  pearson_r = unname(correlation_raw$estimate),
  ci_low = correlation_raw$conf.int[1],
  ci_high = correlation_raw$conf.int[2],
  t_statistic = unname(correlation_raw$statistic),
  df = unname(correlation_raw$parameter),
  p_value = correlation_raw$p.value
)
write.csv(correlation_results, "data/population_correlation.csv", row.names = FALSE)
capture.output(print(correlation_raw),
               file = "data/population_correlation_test.txt")
print(correlation_results, digits = 4)
