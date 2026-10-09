# Validate the exported replication designs after Rscript R/run_all.R.
d <- read.csv("data/discussion_replicates.csv")
s <- read.csv("data/discussion_summary.csv")
fixed <- subset(d, design == "fixed_population")
fresh <- subset(d, design == "new_population")
stopifnot(nrow(fixed) == 400L, nrow(fresh) == 2000L,
          setequal(fixed$scenario, c("baseline", "universal")),
          length(unique(fixed$population_slope)) == 1L,
          length(unique(fresh$population_slope)) == 200L)
for (b in unique(fresh$replicate)) {
  paired <- subset(fresh, replicate == b)
  stopifnot(nrow(paired) == 10L, length(unique(paired$population_slope)) == 1L,
            all(paired$population_id == b))
  entry <- subset(paired, scenario == "baseline" | grepl("^entry_", scenario))
  stopifnot(length(unique(entry$sample_n)) == 1L,
            length(unique(entry$mean_temperature)) == 1L,
            length(unique(entry$mean_attackers)) == 1L)
  # All rates must imply the same selected-attacker slope before capture noise.
  rates <- c(baseline = .7, entry_01 = .1, entry_03 = .3,
             entry_07 = .7, entry_09 = .9)
  implied <- entry$expected_slope / rates[entry$scenario]
  stopifnot(diff(range(implied)) < 1e-10)
}
universal <- subset(d, scenario == "universal")
stopifnot(all(universal$sample_n == 6000L),
          max(abs(universal$expected_slope - .7 * universal$population_slope)) < 1e-10)
# Each summary must use only its own design and scenario, including its quantiles.
for (i in seq_len(nrow(s))) {
  r <- s[i, ]
  x <- d[d$design == r$design & d$scenario == r$scenario, ]
  stopifnot(nrow(x) == 200L, r$replicates == 200L,
            abs(r$mean_slope - mean(x$slope)) < 1e-10,
            abs(r$slope_low - quantile(x$slope, .025)) < 1e-10,
            abs(r$slope_high - quantile(x$slope, .975)) < 1e-10)
}
cat("PASS: replication designs, scenario pairing, entry scaling, universal expectation, grouped summaries\n")

# Question 6: paired regimes, count support, and independently recomputed summaries.
e <- read.csv("data/ecological_example.csv")
d <- read.csv("data/ecological_replicates.csv")
s <- read.csv("data/ecological_summary.csv")
stopifnot(nrow(e) == 6000L, all(e$count >= 0),
          all(e$count <= e$true_attacking_mosquitoes),
          abs(mean(e$tz)) < 1e-10, abs(sd(e$tz) - 1) < 1e-10,
          abs(mean(e$mz)) < 1e-10, abs(sd(e$mz) - 1) < 1e-10,
          nrow(d) == 1400L, all(is.finite(as.matrix(d))),
          all(table(d$temperature_effect) == 200L),
          max(abs(d$difference - (d$selected - d$universal))) < 1e-10,
          all(d$sample_n > 1 & d$sample_n < 6000))
for (i in seq_len(nrow(s))) {
  r <- s[i, ]
  x <- d[d$temperature_effect == r$temperature_effect, r$regime]
  stopifnot(abs(r$mean_slope - mean(x)) < 1e-10,
            abs(r$slope_low - quantile(x, .025)) < 1e-10,
            abs(r$slope_high - quantile(x, .975)) < 1e-10)
}
generator <- parse("R/lib/ecological_effect_compute.R")[[1]]
eval(generator)
set.seed(123)
generated <- generate_ecological_population(0.3)
set.seed(123)
temperature <- rnorm(6000, 27, 2.8)
temperature_z <- as.numeric(scale(temperature))
heterogeneity <- rnorm(6000, 0, 0.65)
attackers <- rpois(6000, exp(log(28) + 0.3 * temperature_z + heterogeneity))
stopifnot(identical(generated$tz, temperature_z),
          identical(generated$true_attacking_mosquitoes, attackers))

for (effect in unique(d$temperature_effect)) {
  rows <- d$temperature_effect == effect
  residual <- d$universal[rows] - d$expected_universal[rows]
  stopifnot(abs(mean(residual)) < 5 * sd(residual) / sqrt(length(residual)))
}
cat("PASS: ecological count support, paired differences, summaries, scaled generator and conditional universal slopes\n")
