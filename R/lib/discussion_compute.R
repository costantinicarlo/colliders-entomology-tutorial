# Self-generating discussion experiments. The baseline deck remains one fixed
# realisation; discussion experiments distinguish two sources of replication.
discussion_population <- new.env()
sys.source("R/01_simulate.R", envir = discussion_population)

# Same ecological generating model as R/01_simulate.R, without writing files
# or resetting the seed. One new population and baseline selection per replicate.
generate_discussion_population <- function(n = discussion_population$n) {
  temperature <- rnorm(n, mean = 27, sd = 2.8)
  attackers <- rpois(n, lambda = exp(rnorm(n, log(28), 0.65)))
  tz <- as.numeric(scale(temperature))
  mz <- as.numeric(scale(attackers))
  sampled <- rbinom(n, 1, plogis(-1 - 1.25 * tz + 1.75 * mz)) == 1
  list(n = n, air_temperature_c = temperature,
       true_attacking_mosquitoes = attackers, tz = tz, mz = mz,
       sampled = sampled)
}

observe_discussion <- function(baseline_logit = -1, temperature_coef = -1.25,
                               nuisance_coef = 1.75, entry_rate = 0.7,
                               universal = FALSE, fixed_sample = FALSE,
                               population = discussion_population) {
  d <- population
  if (universal) {
    sampled <- rep(TRUE, d$n)
  } else if (fixed_sample) {
    sampled <- d$sampled
  } else {
    prob <- plogis(baseline_logit + temperature_coef * d$tz + nuisance_coef * d$mz)
    sampled <- rbinom(d$n, 1, prob) == 1
  }
  x <- d$air_temperature_c[sampled]
  attackers <- d$true_attacking_mosquitoes[sampled]
  counts <- rbinom(sum(sampled), size = attackers, prob = entry_rate)
  stopifnot(all(counts >= 0), all(counts <= attackers))
  estimable <- length(x) >= 2L && length(unique(x)) >= 2L
  c(sample_n = sum(sampled), mean_temperature = mean(x),
    mean_attackers = mean(attackers),
    population_slope = cov(d$air_temperature_c, d$true_attacking_mosquitoes) /
                         var(d$air_temperature_c),
    expected_slope = if (estimable) entry_rate * cov(x, attackers) / var(x) else NA_real_,
    slope = if (estimable) unname(coef(lm(counts ~ x))[2]) else NA_real_)
}

discussion_scenarios <- list(
  baseline = list(), universal = list(universal = TRUE),
  no_heat = list(temperature_coef = 0),
  no_nuisance = list(nuisance_coef = 0),
  intercept_low = list(baseline_logit = -2),
  intercept_high = list(baseline_logit = 1),
  entry_01 = list(entry_rate = 0.1, fixed_sample = TRUE),
  entry_03 = list(entry_rate = 0.3, fixed_sample = TRUE),
  entry_07 = list(entry_rate = 0.7, fixed_sample = TRUE),
  entry_09 = list(entry_rate = 0.9, fixed_sample = TRUE)
)

# Approach 1: repeated observation/capture on the original finite population.
# Retained for the baseline/universal comparison only.
set.seed(20260925)
fixed_draws <- do.call(rbind, lapply(c("baseline", "universal"), function(id) {
  values <- t(replicate(200, do.call(observe_discussion, discussion_scenarios[[id]])))
  data.frame(design = "fixed_population", scenario = id,
             replicate = seq_len(nrow(values)), population_id = 0L, values,
             row.names = NULL)
}))

# Approach 2: a fresh population per replicate, shared by ALL scenarios within
# that replicate. Entry-rate variants share its exact baseline selected houses.
# Other behavioural interventions draw their own use decisions on this same
# population. Replicate IDs therefore pair comparisons across scenarios.
set.seed(20260926)
new_draws <- do.call(rbind, lapply(seq_len(200), function(b) {
  d <- generate_discussion_population()
  do.call(rbind, lapply(names(discussion_scenarios), function(id) {
    args <- discussion_scenarios[[id]]
    if (id == "baseline") args$fixed_sample <- TRUE
    values <- do.call(observe_discussion, c(args, list(population = d)))
    data.frame(design = "new_population", scenario = id, replicate = b,
               population_id = b, as.list(values), row.names = NULL)
  }))
}))
discussion_draws <- rbind(fixed_draws, new_draws)
discussion_summary <- do.call(rbind, lapply(
  split(discussion_draws, interaction(discussion_draws$design,
                                     discussion_draws$scenario, drop = TRUE)),
  function(d) {
    data.frame(design = d$design[1], scenario = d$scenario[1], replicates = nrow(d),
               sample_n = mean(d$sample_n), mean_temperature = mean(d$mean_temperature),
               mean_attackers = mean(d$mean_attackers),
               mean_population_slope = mean(d$population_slope),
               mean_expected_slope = mean(d$expected_slope),
               mean_slope = mean(d$slope),
               slope_low = unname(quantile(d$slope, 0.025)),
               slope_high = unname(quantile(d$slope, 0.975)), row.names = NULL)
  }))
rownames(discussion_summary) <- NULL
write.csv(discussion_draws, "data/discussion_replicates.csv", row.names = FALSE)
write.csv(discussion_summary, "data/discussion_summary.csv", row.names = FALSE)

# Structural checks: pairing, regeneration, universal coverage and fixed entry
# membership within a replicate, without assuming a particular random slope.
stopifnot(all(is.finite(discussion_draws$slope)),
          all(subset(discussion_draws, scenario == "universal")$sample_n ==
                discussion_population$n),
          length(unique(fixed_draws$population_slope)) == 1L,
          length(unique(new_draws$population_slope)) == 200L)
for (b in seq_len(200)) {
  d <- subset(new_draws, replicate == b)
  stopifnot(length(unique(d$population_slope)) == 1L,
            setequal(d$scenario, names(discussion_scenarios)))
  entry <- subset(d, grepl("^entry_", scenario) | scenario == "baseline")
  stopifnot(length(unique(entry$sample_n)) == 1L,
            length(unique(entry$mean_temperature)) == 1L,
            length(unique(entry$mean_attackers)) == 1L)
}
print(discussion_summary, digits = 4, row.names = FALSE)
