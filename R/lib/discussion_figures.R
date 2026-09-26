# Render existing discussion_summary; no simulation is performed here.
# Plot slope distributions; bars are central 95% simulation ranges, not CIs.
dir.create("figures/en", recursive = TRUE, showWarnings = FALSE)
discussion_plot <- function(ids, labels, file, title,
                            design = "new_population") {
  pool <- discussion_summary[discussion_summary$design == design, ]
  d <- pool[match(ids, pool$scenario), ]
  png(file, width = 1400, height = 900, res = 160)
  par(mar = c(6, 5, 3, 1), bg = "#f7f7f3", col.axis = "#18212a",
      col.lab = "#18212a")
  plot(seq_along(ids), d$mean_slope, pch = 19, cex = 1.5,
       col = "#0b6b63", xlim = c(0.6, length(ids) + 0.4),
       ylim = range(c(0, d$slope_low, d$slope_high)) + c(-0.15, 0.15),
       xaxt = "n", xlab = "", ylab = "Count slope (mosquitoes per deg C)",
       main = title)
  abline(h = 0, lty = 2, col = "#66707a")
  axis(1, at = seq_along(ids), labels = labels, cex.axis = 0.9)
  arrows(seq_along(ids), d$slope_low, seq_along(ids), d$slope_high,
         angle = 90, code = 3, length = 0.07, lwd = 2, col = "#0b6b63")
  caption <- if (design == "fixed_population") {
    "200 observation/capture replicates; one fixed ecological population"
  } else {
    "200 new populations; scenarios paired within each replicate"
  }
  mtext(caption, side = 1, line = 3, cex = 0.75)
  mtext("Points: means; bars: central 95% Monte Carlo percentile ranges",
        side = 1, line = 4, cex = 0.7)
  dev.off()
}
discussion_plot(c("baseline", "universal"), c("Baseline", "Universal use"),
                "figures/en/fig06_discussion_universal.png", "Universal use: one fixed population",
                design = "fixed_population")
discussion_plot(c("baseline", "no_heat"), c("Baseline", "No heat effect"),
                "figures/en/fig07_discussion_no_heat.png", "Remove temperature from net use")
discussion_plot(c("baseline", "no_nuisance"), c("Baseline", "No nuisance effect"),
                "figures/en/fig08_discussion_no_nuisance.png", "Remove nuisance from net use")
discussion_plot(c("entry_01", "entry_03", "entry_07", "entry_09"),
                c("Entry = 0.1", "Entry = 0.3", "Entry = 0.7", "Entry = 0.9"),
                "figures/en/fig10_discussion_entry.png", "Higher entry scales up the count slope")


# Focus on universal coverage to show the extra variability from generating
# temperatures and attackers, without the much larger baseline selection slope.
d <- subset(discussion_summary, scenario == "universal")
d <- d[match(c("fixed_population", "new_population"), d$design), ]
png("figures/en/fig06b_universal_replication.png", width = 1400, height = 900, res = 160)
par(mar = c(6, 5, 3, 1), bg = "#f7f7f3")
plot(1:2, d$mean_slope, pch = 19, cex = 1.5, col = "#0b6b63",
     xlim = c(0.6, 2.4), ylim = range(c(0, d$slope_low, d$slope_high)) + c(-0.03, 0.03),
     xaxt = "n", xlab = "", ylab = "Count slope (mosquitoes per deg C)",
     main = "Universal coverage: what is repeated?")
axis(1, at = 1:2, labels = c("Fixed population", "New population each time"), cex.axis = 0.85)
abline(h = 0, lty = 2, col = "#66707a")
arrows(1:2, d$slope_low, 1:2, d$slope_high, angle = 90, code = 3,
       length = 0.07, lwd = 2, col = "#0b6b63")
mtext("Points: means; bars: central 95% Monte Carlo percentile ranges",
      side = 1, line = 3, cex = 0.75)
mtext("200 replicates per design; net-entry probability = 0.7",
      side = 1, line = 4, cex = 0.75)
dev.off()
