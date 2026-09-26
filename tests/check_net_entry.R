# Run from the workspace root: Rscript tests/check_net_entry.R
# Exercise the actual simulation without overwriting workspace results.
script <- readLines("R/01_simulate.R")
saved <- read.csv("data/simulated_houses.csv")
original_directory <- getwd()
scratch <- tempfile("net-entry-check-")
dir.create(scratch)

tryCatch({
  setwd(scratch)
  simulate <- function(p) {
    variant <- sub("bed_net_entry_rate <- 0.7",
                   paste("bed_net_entry_rate <-", p), script, fixed = TRUE)
    env <- new.env()
    eval(parse(text = variant), envir = env)
    read.csv("data/simulated_houses.csv")
  }
  baseline <- simulate(0.7)
  stopifnot(identical(baseline, saved))
  for (p in c(0, 0.7, 1)) {
    x <- simulate(p)
    selected <- x$house_sampled == 1
    counts <- x$mosquitoes_counted_inside_net[selected]
    attackers <- x$true_attacking_mosquitoes[selected]
    stopifnot(identical(x$house_sampled, baseline$house_sampled),
              identical(x$true_attacking_mosquitoes, baseline$true_attacking_mosquitoes),
              identical(x$air_temperature_c, baseline$air_temperature_c),
              all(x$bed_net_entry_rate == p),
              all(is.na(x$mosquitoes_counted_inside_net[!selected])),
              all(!is.na(counts)), all(counts >= 0), all(counts <= attackers),
              all(counts == floor(counts)))
    if (p == 0) stopifnot(all(counts == 0))
    if (p == 1) stopifnot(identical(counts, attackers))
  }
  # Force zero attackers to exercise an otherwise rare ecological edge case.
  zero_script <- sub(
    "true_attacking_mosquitoes <- rpois(n, lambda = exp(rnorm(n, log(28), 0.65)))",
    "true_attacking_mosquitoes <- rep(0L, n)", script, fixed = TRUE)
  zero_script <- sub("mz <- as.numeric(scale(true_attacking_mosquitoes))",
                     "mz <- rep(0, n)", zero_script, fixed = TRUE)
  env <- new.env()
  eval(parse(text = zero_script), envir = env)
  stopifnot(all(env$mosquitoes_counted_inside_net[env$sampled] == 0))
  for (p in c(-0.1, 1.1, NA_real_)) {
    stopifnot(inherits(try(simulate(p), silent = TRUE), "try-error"))
  }
  message("PASS: reproducibility, fixed selection, count bounds, missingness, p=0/1, zero attackers, invalid probabilities")
}, finally = {
  setwd(original_directory)
  unlink(scratch, recursive = TRUE)
})
