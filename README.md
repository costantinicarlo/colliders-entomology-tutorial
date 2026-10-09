# Colliders in medical entomology

Bilingual teaching slides for Obsidian **Slides Extended**, with a reproducible R simulation of selection bias. Temperature and mosquito pressure are generated independently in the baseline; sampling only bed-net users creates an apparent association. Question 6 adds a direct temperature effect to explore distortion of an existing ecological relationship. The study and institutional responses depicted in the cartoons are fictional.

## Presentations

- [English](docs_EN/current/colliders_entomology_EN.md)
- [Français](docs_FR/current/colliders_entomology_FR.md)

These are the authoritative decks. Both use local Fieldnote Academic templates, `assets/css/fieldnote-academic-upstream.css`, and the deck-specific `assets/css/colliders-entomology.css`. Set the plugin's assets directory to `assets`. No remote fonts or theme services are required.

Image links use vault-relative paths such as `assets/storyline/storyline_01.png` and `figures/fr/fig05_population_correlation.png`. Slides Extended resolves these to the same vault files in preview and copies them into each exported deck. Keep this convention: `../../` image paths can make the exporter copy a file onto itself and stop before copying custom CSS.

Use **right/left** for the main sequence and **down/up** for discussion answers. Keep the plugin's default separators (`---` horizontal, `--` vertical) and the decks' `notesSeparator: "note:"`. An anchored `^--$` override can lose its boundaries during Slides Extended's layout preprocessing.

French prose, speaker notes, Mermaid labels, and plots are translated. Executable R statements and variable names match English. Mermaid diagrams disable HTML labels at both the global and flowchart levels because the bundled renderer reads both settings. Diagram-local font rules keep label measurement and display consistent. The original storyline artwork is shared; text embedded in these images remains in its original language.

## Rebuild everything

From the workspace root, with R installed:

```bash
Rscript R/run_all.R
```

This generates the baseline data and 200 replicates per discussion scenario/design once, then renders **both languages**. It also regenerates the selection surface. `ggplot2` is optional; the standard figures have a base-R fallback. Python 3 is used only for the workspace check below. No package installation is performed.

| Script | Purpose |
|---|---|
| `R/01_simulate.R` | Generate and export the baseline population and sample |
| `R/02_analyse.R` | Analyse the generated data; export slopes and Pearson statistics |
| `R/03_make_plots.R` | Render English figures from generated data |
| `R/04_discussion.R` | Generate discussion experiments and figures from scratch |
| `R/05_make_french_plots.R` | Standalone French build, including data generation |
| `R/lib/` | Shared discussion computation and rendering |

Scripts 02 and 03 require the preceding generated outputs. The complete build, discussion script, and standalone French build require no pre-computed dataset. The French renderer reuses the English plotting expressions, translating only text and output paths; it does not alter the model or overwrite English figures.

## Model and results

The baseline has 6,000 independent house-nights, seed `20260922`, and net-use
logit `-1 - 1.25 * tz + 1.75 * mz`. Here `tz` and `mz` are standardised
temperature and mosquito pressure. At both means, net-use probability is
`plogis(-1)`, about 26.9%; this is not the population-average probability.

`bed_net_entry_rate` is 0.7. Given N attacking mosquitoes in a sampled house,
the count is Binomial(N, p), with mean Np and variance Np(1-p). Every entrant is
assumed to remain inside and be counted. Unsampled counts are `NA`; zero
attackers produce zero captures. Entry changes capture, not sample membership.

Discussion scenarios change universal use, either net-use coefficient, the intercept, or entry probability. Universal coverage illustrates both repeated observation of one fixed population and complete regeneration of the population, with an additional vertical comparison slide. Questions 2–5 use regenerated populations only. Within each replicate, all scenarios share the population; entry-rate variants also share its baseline selected houses. There are 2,400 replicate results in the original discussion run. The extended question 4 adds 1,600 paired results over intercepts −10, −5, −4, −3, −2, −1, 0 and +1; its separate seed preserves earlier outputs. Question 6 adds 1,400 paired replicates (200 fresh populations at each of seven ecological effects) in separate outputs. Discussion bars are central 95% Monte Carlo percentile ranges, **not confidence intervals**. Unequal coefficient magnitudes are not required for collider bias; see [presenter notes](notes/presenter_notes.md).

Outputs:

- `data/simulated_houses.csv`, `data/observed_bednet_sample.csv`: full-precision data.
- `data/expected_results.csv`: three regressions and their confidence intervals.
- `data/population_correlation.csv`, `data/population_correlation_test.txt`: Pearson output.
- `data/discussion_summary.csv`, `data/discussion_replicates.csv`: discussion results.
- `data/intercept_replicates.csv`, `data/intercept_summary.csv`: extended question 4, including sample sizes and estimability diagnostics.
- `data/ecological_example.csv`, `data/ecological_replicates.csv`, `data/ecological_summary.csv`: question 6, including paired slope differences.
- `figures/en/`: English plots; `figures/fr/`: French plots.

Generated outputs are retained so the decks open without running R. After changing model parameters, rebuild and update numerical tables in **both** Markdown decks; those displayed values are authored text, not live R output.

## Checks

```bash
Rscript tests/check_net_entry.R
Rscript tests/check_discussion.R
Rscript tests/check_intercept.R
python3 tests/check_workspace.py
# After generating the HTML presentations in Slides Extended:
python3 scripts/prepare_export_notices.py
python3 tests/check_exports.py
```

The R check verifies reproducibility, count bounds, missingness, boundary entry probabilities, and invalid inputs in a temporary directory. The discussion check verifies replication designs, scenario pairing, conditional expected slopes and grouped summaries. The workspace check verifies bilingual structure/code, asset and template links, numerical summaries, and landing-page links. After exporting, `prepare_export_notices.py` copies the project and retained third-party license texts into each standalone deck. The export check verifies those notices and that stylesheets, scripts, images, and linked badges referenced by each HTML deck exist inside that deck's directory. It also accepts a relocated export directory as an argument. Open both decks in Slides Extended for the final visual check; these checks do not emulate the Obsidian renderer.

## Source and publication

`source/colliders_medical_entomology.md` preserves the source scenario; `notes/presenter_notes.md` contains teaching guidance. The shorter historical stylesheet and unused causal schematic are retained as legacy assets and are not loaded by the current decks. Theme licensing is in `assets/fieldnote-academic/LICENSE`.

`index.html` is the public tutorial hub: it links to both HTML presentations and the GitHub repository, with `assets/storyline/splashscreen.png` as its banner. For browser presentations, use Slides Extended's HTML export. The plugin is configured to write each deck to `export/colliders_entomology_EN/` or `export/colliders_entomology_FR/`, including its own images, custom CSS, and Reveal.js support files. Export each language separately after editing its source. The complete `export/` folder, or an individual deck folder, can be copied elsewhere without the Obsidian vault. Keep each deck's support files together. The generated `export/` directory is ignored by Git. Regenerate it with Slides Extended after cloning; distribute or deploy it as a separate presentation artifact. Other HTML files, including the landing page, can be versioned. Local Obsidian workspace state and R session files are ignored; presentation and plugin settings are preserved.

### Publish the hub with the Quarto website

After exporting both languages, copy this layout into a dedicated website folder, for example `resources/colliders-entomology-tutorial/`:

```text
index.html
assets/storyline/splashscreen.png
export/colliders_entomology_EN/    # complete exported deck
export/colliders_entomology_FR/    # complete exported deck
```

The hub uses relative presentation and banner links, so this layout works under any website subdirectory. Link to the tutorial folder from the website's Resources page; retain its own `resources/index.html` as the resource listing.

Copy the bundle into the website's publication output **after** `quarto render`, and before uploading the GitHub Pages artifact. This preserves the native HTML, CSS, and scripts: Quarto's resource processing can rewrite URLs in copied CSS. For example, from the website workspace, using its default `_site/` output:

```bash
quarto render
tutorial_source=/path/to/colliders-entomology-tutorial
tutorial_output=_site/resources/colliders-entomology-tutorial
mkdir -p "$tutorial_output/assets/storyline"
cp "$tutorial_source/index.html" "$tutorial_output/index.html"
cp "$tutorial_source/assets/storyline/splashscreen.png" "$tutorial_output/assets/storyline/"
cp -R "$tutorial_source/export" "$tutorial_output/"
```

Use the website's configured output directory if it differs from `_site/`. If the deployment command also renders the site, perform the copy in a [Quarto post-render step](https://quarto.org/docs/projects/scripts.html#pre-and-post-render), so it runs after the final render. Both generated export folders must be available to that step; they are not present in a fresh checkout of this tutorial repository. Keep the website's existing GitHub Pages deployment process and add the complete tutorial bundle to its publication output.

## License

The project license is [Creative Commons Attribution 4.0 International](LICENSE) (`CC-BY-4.0`). The bundled Fieldnote Academic theme retains its separate [MIT license notice](assets/fieldnote-academic/LICENSE). The Slides Extended plugin and its runtime are third-party software with separate license terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
