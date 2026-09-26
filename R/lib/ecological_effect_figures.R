# Both languages use these same plotting expressions and generated outputs.
e <- read.csv("data/ecological_example.csv")
s <- read.csv("data/ecological_summary.csv")
png("figures/en/fig11_ecological_selection.png", width = 1500, height = 950, res = 160)
par(mfrow = c(1, 2), mar = c(5, 4.5, 3, 1), oma = c(2, 0, 1, 0), bg = "#f7f7f3")
xlim <- range(e$air_temperature_c)
ylim <- range(log1p(e$count))
ticks <- c(0, 1, 5, 10, 50, 100, 500, 1000)
ticks <- ticks[log1p(ticks) <= ylim[2]]
for (selected_only in c(FALSE, TRUE)) {
  d <- if (selected_only) e[e$sampled, ] else e
  plot(d$air_temperature_c, log1p(d$count), pch = 16, cex = .4,
       col = adjustcolor("#0b6b63", alpha.f = .18), xlim = xlim, ylim = ylim,
       yaxt = "n", xlab = "Air temperature (deg C)", ylab = "Captured mosquitoes (log1p scale)",
       main = if (selected_only) "Net users only" else "Universal coverage")
  axis(2, at = log1p(ticks), labels = ticks)
  fit <- lm(count ~ air_temperature_c, d)
  x <- seq(xlim[1], xlim[2], length.out = 300)
  y <- predict(fit, data.frame(air_temperature_c = x))
  lines(x, ifelse(y >= 0, log1p(pmax(y, 0)), NA), col = "#9a631b", lwd = 3)
}
mtext("Same population and capture draws; temperature effect = 0.3", outer = TRUE, side = 1, line = 0.5, cex = .85)
dev.off()
png("figures/en/fig12_ecological_sweep.png", width = 1400, height = 900, res = 160)
par(mar = c(6, 5, 3, 1), bg = "#f7f7f3")
r <- subset(s, regime != "difference")
plot(NA, xlim = range(r$temperature_effect), ylim = range(r$slope_low, r$slope_high),
     xlab = "Temperature effect on log expected abundance (per 2.8 deg C)",
     ylab = "Count slope (mosquitoes per deg C)", main = "Selection distorts an existing relationship")
abline(h = 0, v = 0, lty = 3, col = "#888888")
for (reg in c("universal", "selected")) {
  d <- r[r$regime == reg, ]; d <- d[order(d$temperature_effect), ]
  colour <- if (reg == "universal") "#0b6b63" else "#9a631b"
  lines(d$temperature_effect, d$mean_slope, type = "b", pch = if (reg == "universal") 16 else 17, col = colour, lwd = 2)
  arrows(d$temperature_effect, d$slope_low, d$temperature_effect, d$slope_high,
         angle = 90, code = 3, length = .04, col = colour)
}
legend("topleft", c("Universal coverage", "Net users only"), col = c("#0b6b63", "#9a631b"), pch = c(16, 17), lty = 1, bty = "n")
mtext("200 new populations per effect; paired observation regimes", side = 1, line = 4, cex = .75)
mtext("Points: means; bars: central 95% Monte Carlo percentile ranges", side = 1, line = 5, cex = .7)
dev.off()
