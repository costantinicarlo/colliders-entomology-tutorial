# Graphiques français : mêmes calculs que les scripts anglais.
# Depuis la racine du projet : Rscript R/05_make_french_plots.R
# Les constantes textuelles sont traduites sans modifier les noms de variables,
# les calculs, les échelles ni les figures anglaises.
render_french_figures <- function(regenerate = TRUE) {
  old_locale <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", old_locale), add = TRUE)
  Sys.setlocale("LC_CTYPE", "en_US.UTF-8")
  dir.create("figures/fr", recursive = TRUE, showWarnings = FALSE)
  labels <- c(
    "Baseline net-use logit" = "Logit de référence de l’utilisation",
    "Lower use gives less precise slopes" = "Moins d’utilisation, pentes moins précises",
    "Number of sampled house-nights" = "Nombre de maisons-nuits échantillonnées",
    "Low baseline use reduces the sample" = "Une faible utilisation réduit l’échantillon",
    "200 new populations; intercepts paired within each replicate" = "200 populations nouvelles ; constantes appariées par répétition",

    "Air temperature" = "Température de l’air",
    "Number of house-nights" = "Nombre de maisons-nuits",
    "Attacking mosquitoes" = "Moustiques attaquants",
    "Attacking mosquitoes per house-night" = "Moustiques attaquants par maison-nuit",

    "Captured mosquitoes (log1p scale)" = "Moustiques capturés (échelle log1p)",
    "Net users only" = "Utilisateurs seulement",
    "Universal coverage" = "Couverture universelle",
    "Same population and capture draws; temperature effect = 0.3" = "Mêmes population et captures ; effet de température = 0,3",
    "Temperature effect on log expected abundance (per temperature SD)" = "Effet sur le logarithme de l’abondance attendue (par écart-type de température)",
    "Selection distorts an existing relationship" = "La sélection déforme une relation existante",
    "200 new populations per effect; paired observation regimes" = "200 populations par effet ; observations appariées",

    "200 observation/capture replicates; one fixed ecological population" = "200 répétitions d’observation/capture ; une population fixe",
    "200 new populations; scenarios paired within each replicate" = "200 populations nouvelles ; scénarios appariés par répétition",
    "Points: means; bars: central 95% Monte Carlo percentile ranges" = "Points : moyennes ; barres : plages centrales à 95 % de Monte-Carlo",
    "Universal use: one fixed population" = "Utilisation universelle : une population fixe",
    "Universal coverage: what is repeated?" = "Couverture universelle : que répète-t-on ?",
    "Fixed population" = "Population fixe",
    "New population each time" = "Nouvelle population à chaque fois",
    "200 replicates per design; net-entry probability = 0.7" = "200 répétitions par approche ; probabilité d’entrée = 0,7",
    "Standardised temperature (tz)" = "Température standardisée (tz)",
    "Standardised nuisance (mz)" = "Nuisance standardisée (mz)",
    "Observation depends on the behavioural filter" = "L’observation dépend du filtre comportemental",
    "Probability of net use / sampling" = "Probabilité d’utilisation / d’échantillonnage",
    "Full population: causal expectation" = "Population : référence écologique",
    "The simulation contains no temperature effect on mosquito pressure" = "Aucun effet de la température sur la pression dans la simulation",
    "air temperature (deg C)" = "Température de l’air (°C)",
    "Air temperature (deg C)" = "Température de l’air (°C)",
    "true attacking mosquitoes" = "Moustiques attaquants réels",
    "Observed bed-net sample" = "Échantillon des utilisateurs",
    "Sampling only bed-net users creates a positive association" = "La sélection des utilisateurs crée une association positive",
    "mosquitoes counted inside net" = "Moustiques dans la moustiquaire",
    "Selection and net entry shape the observed slope" = "Sélection et entrée modifient la pente",
    "estimated slope: mosquitoes per deg C" = "Pente estimée : moustiques par °C",
    "Estimated slope: mosquitoes per deg C" = "Pente estimée : moustiques par °C",
    "All: true attackers" = "Tous : attaquants",
    "Selected: true attackers" = "Sélectionnés : attaquants",
    "Selected: net counts" = "Sélectionnés : comptages",
    "Full population" = "Population complète",
    "True attacking mosquitoes (log scale)" = "Attaquants réels (échelle log)",
    "Selected net users: binomial capture" = "Utilisateurs : capture binomiale",
    "Mosquitoes inside net (log scale)" = "Moustiques dans la moustiquaire (log)",
    "Net-entry probability = %.2f; tick labels are original mosquito counts" = "Probabilité d’entrée = %.2f ; graduations en nombres de moustiques",
    "Zero counts omitted from log display: population %d, sample %d. Fits include zeros and use original counts." = "Zéros omis du tracé : population %d, échantillon %d. Ajustements sur les comptages d’origine, zéros inclus.",
    "Temperature (deg C)" = "Température (°C)",
    "Attacking mosquitoes" = "Moustiques attaquants",
    "Original units" = "Unités d’origine",
    "Temperature: tz (SD units)" = "Température : tz (écarts-types)",
    "Attackers: mz (SD units)" = "Attaquants : mz (écarts-types)",
    "Standardised variables" = "Variables standardisées",
    "Count slope (mosquitoes per deg C)" = "Pente des comptages (moustiques par °C)",
    "Points: means; bars: central 95% of 200 observation/capture replicates" = "Points : moyennes ; barres : 95 % centraux de 200 répétitions",
    "Baseline" = "Référence", "Universal use" = "Utilisation universelle",
    "No heat effect" = "Sans effet de chaleur",
    "No nuisance effect" = "Sans effet de nuisance",
    "Universal use removes selection" = "L’utilisation universelle supprime la sélection",
    "Remove temperature from net use" = "Supprimer l’effet de la température",
    "Remove nuisance from net use" = "Supprimer l’effet de la nuisance",
    "Baseline net use changes selection" = "L’utilisation de référence change la sélection",
    "Higher entry scales up the count slope" = "Davantage d’entrées augmente la pente",
    "Intercept = -2" = "Constante = −2",
    "Intercept = -1" = "Constante = −1",
    "Intercept = +1" = "Constante = +1",
    "Entry = 0.1" = "Entrée = 0,1", "Entry = 0.3" = "Entrée = 0,3",
    "Entry = 0.7" = "Entrée = 0,7", "Entry = 0.9" = "Entrée = 0,9"
  )
  # Parcourir l’arbre syntaxique : seules les chaînes littérales changent.
  translate <- function(x) {
    if (is.character(x)) {
      return(vapply(x, function(value) {
        if (identical(value, "figures/en")) {
          "figures/fr"
        } else if (startsWith(value, "figures/en/")) {
          sub("^figures/en/", "figures/fr/", value)
        } else if (value %in% names(labels)) {
          unname(labels[value])
        } else value
      }, character(1), USE.NAMES = FALSE))
    }
    if (is.call(x) || is.expression(x) || is.pairlist(x)) {
      for (i in seq_along(x)) {
        # Les arguments omis, par exemple mat[, 1], doivent rester omis.
        if (!identical(x[[i]], quote(expr = ))) x[[i]] <- translate(x[[i]])
      }
    }
    x
  }
  env <- new.env(parent = globalenv())
  if (regenerate) {
    # A standalone French build is self-generating, without rendering English.
    sys.source("R/lib/discussion_compute.R", envir = env)
    sys.source("R/lib/ecological_effect_compute.R", envir = env)
    sys.source("R/lib/intercept_compute.R", envir = env)
    sys.source("R/02_analyse.R", envir = env)
  } else {
    # run_all.R has already generated the shared data exactly once.
    env$discussion_summary <- read.csv("data/discussion_summary.csv")
  }
  for (script in c("R/03_make_plots.R", "R/lib/discussion_figures.R", "R/lib/ecological_effect_figures.R", "R/lib/intercept_figures.R")) {
    eval(translate(parse(script, encoding = "UTF-8")), envir = env)
  }

}
if (sys.nframe() == 0L) render_french_figures()
