# 01_simulate.R
# Reproducible simulation for the medical-entomology collider tutorial.
# No package is required for the simulation itself.

set.seed(20260922)

n <- 6000L
# Probability that an attacking mosquito enters a used net (illustrative).
bed_net_entry_rate <- 0.7
stopifnot(length(bed_net_entry_rate) == 1L,
          is.finite(bed_net_entry_rate),
          bed_net_entry_rate >= 0, bed_net_entry_rate <= 1)

air_temperature_c <- rnorm(n, mean = 27, sd = 2.8)

# This is the ecological process: mosquito pressure is generated independently
# of temperature. There is no direct causal effect to recover.
true_attacking_mosquitoes <- rpois(n, lambda = exp(rnorm(n, log(28), 0.65)))

tz <- as.numeric(scale(air_temperature_c))
mz <- as.numeric(scale(true_attacking_mosquitoes))

# Behavioural filter:
# - hot nights make bed-net use less likely
# - mosquito nuisance makes bed-net use more likely
# Conditioning on this collider induces a non-causal association.
# At average temperature and pressure (tz = mz = 0):
# logit(P(net use)) = -1, so P(net use) = plogis(-1) = 0.2689.
# This conditional baseline is not the population-average probability.
baseline_logit <- -1
logit_p_net <- baseline_logit - 1.25 * tz + 1.75 * mz
prob_bednet_used <- plogis(logit_p_net)

bednet_used <- rbinom(n, size = 1, prob = prob_bednet_used)
house_sampled <- bednet_used

# Independent entry trials conditional on the number of attackers.
# Assume every entrant remains inside and is counted the next morning.
sampled <- house_sampled == 1
mosquitoes_counted_inside_net <- rep(NA_integer_, n)
mosquitoes_counted_inside_net[sampled] <- rbinom(
  sum(sampled),
  size = true_attacking_mosquitoes[sampled],
  prob = bed_net_entry_rate
)

houses <- data.frame(
  house_id = seq_len(n),
  air_temperature_c = air_temperature_c,
  true_attacking_mosquitoes = true_attacking_mosquitoes,
  prob_bednet_used = prob_bednet_used,
  bed_net_entry_rate = bed_net_entry_rate,
  bednet_used = bednet_used,
  house_sampled = house_sampled,
  mosquitoes_counted_inside_net = mosquitoes_counted_inside_net
)

dir.create("data", showWarnings = FALSE)
write.csv(houses, "data/simulated_houses.csv", row.names = FALSE)
write.csv(subset(houses, house_sampled == 1),
          "data/observed_bednet_sample.csv", row.names = FALSE)

message("Wrote data/simulated_houses.csv and data/observed_bednet_sample.csv")
