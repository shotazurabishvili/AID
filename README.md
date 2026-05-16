# AID — Aid Without Learning

A cross-country panel analysis (~120 countries, 2000–2022) testing whether Official Development Assistance to education predicts learning outcomes, and which structural variables actually drive learning.

**Status:** active, pre-data. Target journal: *World Development* (Elsevier, IF 5.4).

This repository accompanies a single-author research paper. It contains:

- The full research brief (`docs/brief.md`)
- Data ingestion and cleaning pipeline (R, under `R/`)
- Five statistical models: OLS baseline, fixed-effects panel (primary), three-level HLM, one-way ANOVA on intervention typology, counterfactual simulation
- A Quarto manuscript (`drafts/paper.qmd`)
- ADRs documenting every consequential analytical choice (`docs/decisions/`)
- Per-session work logs (`docs/session_log/`)

## Reproducibility

- R + renv. Run `Rscript R/00_setup.R` after cloning to restore the package environment.
- Raw data is not stored in the repo. See `data/catalog.md` for source URLs and access dates.
- All numbered scripts under `R/` are deterministic; running them in order rebuilds the panel and reproduces every result in the paper.

## Datasets used

Harmonized Learning Outcomes (HLO), PISA/TIMSS/PIRLS, OECD DAC CRS, AidData, EdStats, World Development Indicators, Worldwide Governance Indicators, UNESCO UIS, Human Capital Index, Oxford Insights AI Readiness. Full table with URLs in `data/catalog.md`.

## Author

Shota Zurabishvili — practitioner-researcher in international education development.
