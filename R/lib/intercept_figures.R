# Use numerical intercept spacing so the curve is not visually linearised.
d <- read.csv("data/intercept_summary.csv")
png("figures/en/fig09_discussion_intercept.png", width = 1800, height = 800, res = 160)
par(mfrow = c(1, 2), mar = c(5, 5, 3, 1), oma = c(2, 0, 0, 0), bg = "#f7f7f3")
plot(d$baseline_logit, d$mean_slope, type = "b", pch = 19, col = "#0b6b63", lwd = 2,
     ylim = range(c(0, d$slope_low, d$slope_high), na.rm = TRUE),
     xlab = "Baseline net-use logit", ylab = "Count slope (mosquitoes per deg C)",
     main = "Lower use gives less precise slopes")
abline(h = 0, lty = 2, col = "#888888")
arrows(d$baseline_logit, d$slope_low, d$baseline_logit, d$slope_high,
       angle = 90, code = 3, length = .04, col = "#0b6b63")
plot(d$baseline_logit, d$sample_n, type = "b", pch = 19, col = "#9a631b", lwd = 2,
     ylim = range(c(0, d$sample_low, d$sample_high)),
     xlab = "Baseline net-use logit", ylab = "Number of sampled house-nights",
     main = "Low baseline use reduces the sample")
arrows(d$baseline_logit, d$sample_low, d$baseline_logit, d$sample_high,
       angle = 90, code = 3, length = .04, col = "#9a631b")
mtext("200 new populations; intercepts paired within each replicate", side = 1, outer = TRUE, line = 0, cex = .85)
mtext("Points: means; bars: central 95% Monte Carlo percentile ranges", side = 1, outer = TRUE, line = 1, cex = .8)
dev.off()
