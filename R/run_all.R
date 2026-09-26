# Complete bilingual build, from the workspace root: Rscript R/run_all.R
# The discussion driver generates the baseline population and simulations once.
source("R/04_discussion.R")
source("R/02_analyse.R")
source("R/03_make_plots.R")
source("R/05_make_french_plots.R")
render_french_figures(regenerate = FALSE)

message("Done. Open docs_EN/current/colliders_entomology_EN.md or docs_FR/current/colliders_entomology_FR.md in Obsidian Slides Extended.")
