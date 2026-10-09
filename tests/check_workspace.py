"""Check the current bilingual decks; run from the workspace root with Python 3."""
from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
DECKS = [ROOT / f"docs_{lang}/current/colliders_entomology_{lang}.md"
         for lang in ("EN", "FR")]
texts = [p.read_text() for p in DECKS]

def r_code(text):
    return [re.sub(r"\s+", "", re.sub(r"#[^\n]*", "", block))
            for block in re.findall(r"```r\n(.*?)```", text, re.S)]

assert r_code(texts[0]) == r_code(texts[1]), "Executable R differs between decks"
assert re.findall(r"^---?$", texts[0], re.M) == re.findall(r"^---?$", texts[1], re.M), "Slide boundaries differ"
# Authored introductory source slots and homework notes can differ by language.
# Discussion answers must retain matching templates and presenter guidance.
discussions = ["\n".join(s for s in t.split("\n---\n") if "\n--\n" in s)
               for t in texts]
assert re.findall(r"^:::.*$", discussions[0], re.M) == re.findall(r"^:::.*$", discussions[1], re.M), "Discussion template slots differ"
assert discussions[0].count("\nnote:\n") == discussions[1].count("\nnote:\n"), "Discussion note counts differ"

for deck, text in zip(DECKS, texts):
    assert 'verticalSeparator: "^--$"' not in text, "Incompatible separator override"
    assert 'notesSeparator: "note:"' in text, "Use literal note marker"
    assert text.count("```") % 2 == 0, "Unbalanced code fences"
    stacks = [s.split("\n--\n") for s in text.split("\n---\n")]
    assert [len(s) for s in stacks if len(s) > 1] == [2, 4, 3, 3, 4, 3, 5], "Expected population-distribution stack and six discussion stacks"
    for image in re.findall(r"!\[[^\]]*\]\(([^)]+)\)", text):
        assert image.startswith(("assets/", "figures/")), f"Use vault-relative image paths for export: {image}"
        assert ".." not in Path(image).parts, f"Image escapes the exported deck: {image}"
        assert (ROOT / image).is_file(), f"Missing image: {image}"
        if "figures/" in image:
            lang = "en" if "docs_EN" in deck.parts else "fr"
            assert image.startswith(f"figures/{lang}/"), f"Wrong figure language: {image}"
    for image in re.findall(r"!\[\[([^\]|]+)(?:\|[^\]]*)?\]\]", text):
        assert image.startswith("assets/"), f"Use vault-relative embedded assets: {image}"
        assert (ROOT / image).is_file(), f"Missing embedded asset: {image}"
    for template in re.findall(r'template="\[\[([^\]]+)\]\]"', text):
        assert (ROOT / (template + ".md")).is_file(), f"Missing template: {template}"
    for key in ("theme", "css"):
        value = re.search(rf"^{key}: (.+)$", text, re.M)[1]
        assert (ROOT / "assets/css" / value).is_file(), f"Missing {key}: {value}"
    # Restrict to tables, so a stale table cannot pass via a speaker note.
    table_text = "\n".join(line for line in text.splitlines() if line.startswith("|"))
    table_text = table_text.replace("−", "-").replace(",", ".")
    for row in csv.DictReader((ROOT / "data/expected_results.csv").open()):
        assert f'{float(row["slope_per_celsius"]):+.3f}' in table_text, "Stale regression slope table"
    correlation = next(csv.DictReader((ROOT / "data/population_correlation.csv").open()))
    for key in ("pearson_r", "ci_low", "ci_high", "t_statistic", "p_value"):
        assert f'{float(correlation[key]):.4f}' in table_text, f"Stale correlation output: {key}"
    for row in csv.DictReader((ROOT / "data/discussion_summary.csv").open()):
        # Intercept scenarios display composition instead of slope in their table.
        if row["scenario"] in ("intercept_low", "intercept_high"):
            continue
        value = f'{float(row["mean_slope"]):+.3f}'
        assert value in table_text or value.lstrip("+") in table_text, f"Stale discussion output: {row['scenario']}"

    for row in csv.DictReader((ROOT / "data/ecological_summary.csv").open()):
        if float(row["temperature_effect"]) in (-.15, 0, .3):
            assert f'{float(row["mean_slope"]):+.3f}' in table_text, "Stale ecological-effect table"

landing_page = (ROOT / "index.html").read_text()
landing_links = re.findall(r'href="([^"]+)"', landing_page)
export_links = {f"export/colliders_entomology_{lang}/index.html" for lang in ("EN", "FR")}
assert export_links <= set(landing_links), "Landing page must link to both HTML presentations"
for href in landing_links:
    # Generated exports are ignored by Git and may not exist in a fresh clone.
    # check_exports.py validates their contents after Slides Extended builds them.
    if href in export_links:
        continue
    if not re.match(r"(?:https?:|#)", href):
        assert (ROOT / href).exists(), f"Broken landing-page link: {href}"
for image in re.findall(r'<img[^>]+src="([^"]+)"', landing_page):
    assert (ROOT / image).is_file(), f"Missing landing-page image: {image}"
for target in re.findall(r"(?<!!)\[[^\]]*\]\(([^)]+)\)", (ROOT / "README.md").read_text()):
    if not re.match(r"(?:https?:|#)", target):
        assert (ROOT / target).exists(), f"Broken README link: {target}"
assert (ROOT / "notes/presenter_notes.md").is_file(), "Missing presenter notes"
assert (ROOT / "LICENSE").is_file(), "Missing project license"
assert not list((ROOT / "figures").glob("*.png")), "Figures must live in en/ or fr/"
print("PASS: bilingual structure/code, vertical stacks, assets, tables, and landing-page links")
