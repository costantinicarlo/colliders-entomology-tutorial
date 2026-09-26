# Extended Q4 experiment: separate seed preserves the original discussion draws.
# All intercepts share one fresh population within each replicate.
set.seed(20260930)
intercept_values <- c(-10, -5, -4, -3, -2, -1, 0, 1)
intercept_draws <- do.call(rbind, lapply(seq_len(200), function(b) {
  population <- generate_discussion_population()
  do.call(rbind, lapply(c(setdiff(intercept_values, -10), -10), function(a) {
    # Add the extreme case without changing earlier draws or the next population.
    if (a == -10) {
      saved_seed <- .Random.seed
      set.seed(20261000 + b)
    }
    values <- observe_discussion(baseline_logit = a, population = population)
    if (a == -10) assign(".Random.seed", saved_seed, envir = .GlobalEnv)
    data.frame(replicate = b, baseline_logit = a, as.list(values), row.names = NULL)
  }))
}))
intercept_summary <- do.call(rbind, lapply(intercept_values, function(a) {
  d <- intercept_draws[intercept_draws$baseline_logit == a, ]
  valid <- is.finite(d$slope)
  slopes <- d$slope[valid]
  limits <- if (length(slopes)) quantile(slopes, c(.025, .975)) else c(NA_real_, NA_real_)
  data.frame(baseline_logit = a, baseline_probability = plogis(a),
             replicates = nrow(d), valid_slopes = sum(valid),
             empty_samples = sum(d$sample_n == 0),
             sample_n = mean(d$sample_n), sample_low = unname(quantile(d$sample_n, .025)),
             sample_high = unname(quantile(d$sample_n, .975)),
             min_sample_n = min(d$sample_n),
             mean_attackers = if (any(d$sample_n > 0)) mean(d$mean_attackers, na.rm = TRUE) else NA_real_,
             mean_slope = if (length(slopes)) mean(slopes) else NA_real_,
             slope_low = limits[1], slope_high = limits[2], row.names = NULL)
}))
write.csv(intercept_draws, "data/intercept_replicates.csv", row.names = FALSE)
write.csv(intercept_summary, "data/intercept_summary.csv", row.names = FALSE)
print(intercept_summary, digits = 4, row.names = FALSE)
