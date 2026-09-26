# Fieldnote Academic assets for the collider tutorial

The two templates and LICENSE are copied unchanged from
`fieldnote-academic-slides-extended` v0.2.0. The complete upstream stylesheet
is copied unchanged to `../css/fieldnote-academic-upstream.css`.

Both current collider decks use the templates through vault-relative wikilinks
and loads `colliders-entomology.css` for deck-specific figure and diagram sizing.
Slides Extended is configured to find both CSS files under `assets/css`.
The older assets/css/fieldnote-academic.css is retained for provenance and is not loaded by these decks.

Author slides with Markdown, `::: title` / `::: figure` / `::: interpretation`
or `::: left` / `::: right` slots, and Slides Extended comment annotations.
Grid markup belongs in the reusable template files, not in the deck.

`templates/fieldnote-figure-causal.md` is a local adaptation of the upstream
figure-focus template. It pairs a result plot with a Mermaid causal diagram
and places the interpretation below both, for discussion answers 1–3.
