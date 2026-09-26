# Run after Rscript R/run_all.R.
d <- read.csv("data/intercept_replicates.csv")
s <- read.csv("data/intercept_summary.csv")
stopifnot(nrow(d) == 1600L, nrow(s) == 8L,
          setequal(s$baseline_logit, c(-10, -5, -4, -3, -2, -1, 0, 1)))
for (b in unique(d$replicate)) {
  x <- d[d$replicate == b, ]
  stopifnot(nrow(x) == 8L, length(unique(x$population_slope)) == 1L)
}
for (i in seq_len(nrow(s))) {
  r <- s[i, ]; x <- d[d$baseline_logit == r$baseline_logit, ]
  stopifnot(r$valid_slopes == sum(is.finite(x$slope)),
            r$empty_samples == sum(x$sample_n == 0),
            r$min_sample_n == min(x$sample_n),
            abs(r$sample_n - mean(x$sample_n)) < 1e-10,
            abs(r$mean_slope - mean(x$slope, na.rm = TRUE)) < 1e-10,
            abs(r$slope_low - quantile(x$slope, .025, na.rm = TRUE)) < 1e-10,
            abs(r$slope_high - quantile(x$slope, .975, na.rm = TRUE)) < 1e-10)
}
# Load only the function definition, avoiding regeneration or output writes.
e <- new.env()
for (expr in parse("R/lib/discussion_compute.R")) {
  if (is.call(expr) && identical(expr[[1]], as.name("<-")) &&
      identical(expr[[2]], as.name("observe_discussion"))) eval(expr, e)
}
pop <- list(n = 3L, air_temperature_c = c(25, 27, 29),
            true_attacking_mosquitoes = c(20L, 30L, 40L),
            tz = c(-1, 0, 1), mz = c(-1, 0, 1), sampled = c(TRUE, FALSE, FALSE))
empty <- e$observe_discussion(baseline_logit = -Inf, population = pop)
one <- e$observe_discussion(fixed_sample = TRUE, population = pop)
zero_entry <- e$observe_discussion(universal = TRUE, entry_rate = 0, population = pop)
stopifnot(empty[["sample_n"]] == 0, is.na(empty[["slope"]]),
          one[["sample_n"]] == 1, is.na(one[["slope"]]),
          zero_entry[["sample_n"]] == 3, zero_entry[["slope"]] == 0)
cat("PASS: paired intercept sweep, diagnostics, summaries, empty/singleton samples versus zero entry\n")
