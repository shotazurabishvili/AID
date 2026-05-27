# Measuring Aid for Learning

A 133-country, 2010–2020 cross-country panel analysis of whether development assistance to education predicts learning outcomes — under a pre-analysis-plan-disciplined design in which every consequential analytical decision is fixed in writing before the analysis it governs is run.

**Target journal:** *World Development* (Elsevier).
**Author:** Shota Zurabishvili — independent researcher / co-founder, Reed (reed.ge); Bristol, United Kingdom.

## Headline result and why not to believe it

A within-country fixed-effects specification returns a positive aid-to-learning coefficient on the World Bank Harmonized Learning Outcomes measure (β = +11.14 HLO points per unit of log treatment; *p* = 0.048; *N* = 143 country-cycles). Four pre-specified checks break the coefficient four ways: it is carried by sub-Saharan Africa (drops to +4.71 with confidence interval through zero when SSA is excluded); sign-reverses on the Altinok-Angrist-Patrinos (2018) alternative harmonized measure; reaches conventional significance under only one of four pre-specified governance operationalisations; and sits below the panel's minimum-detectable-effect floor. Two further pre-specified commitments bite alongside these four (intervention-typology extraction and the multiple-imputation default). The paper reads what cross-country panel evidence can and cannot defend at the current data frontier.

## Reproducibility

Three steps from a fresh clone:

```bash
git clone https://github.com/shotazurabishvili/AID.git
cd AID
Rscript -e 'renv::restore()'                       # restore the locked R environment
Rscript R/30_merge_panel.R                          # build the analytical panel
Rscript R/51_model2_fe.R                            # reproduce the headline coefficient
```

All numbered scripts under `R/` are deterministic. Numbered prefixes group them by stage (`00_` setup, `10_` ingest, `30_` merge, `40_` audit, `50_` modeling, `70_` counterfactual, `80_` peer-review robustness).

## Where to find what

| Path | Contents |
|---|---|
| `drafts/aid_without_learning.docx` | Rendered manuscript |
| `drafts/aid_without_learning.qmd` | Quarto source for the manuscript |
| `drafts/references.bib` | Bibliography (BibTeX) |
| `data/interim/panel.parquet` | Canonical analytical panel (133 countries × 11 years × 86 columns) |
| `data/interim/*.parquet` | Per-source ingested panels |
| `data/catalog.md` | Source-by-source data catalogue (URLs, indicator codes, access dates) |
| `docs/decisions/` | Twelve pre-analysis plans, PAP-0001 through PAP-0012 |
| `docs/data_dictionary.md` | Canonical variable register |
| `docs/positionality.md` | Positionality statement working draft |
| `docs/lit/` | Literature notes for the cited authors |
| `output/tables/` | All tables, machine-readable plus rendered Markdown |
| `output/figures/` | All figures (PNG + PDF) |

## Data sources

Ten administrative and harmonized-research sources: OECD Creditor Reporting System (education-sector disbursements); World Bank Human Capital Index — Harmonized Learning Outcomes; Altinok-Angrist-Patrinos (2018) Global Data Set on Education Quality (parallel robustness outcome); World Development Indicators; Worldwide Governance Indicators; UCDP/PRIO Armed Conflict Dataset; UNESCO COVID-19 daily school-closure time series; UNESCO Institute for Statistics finance indicators; AidData Global Chinese Development Finance (v3.0); Oxford Insights Government AI Readiness Index. URLs, pinned indicator codes, and access dates are documented in `data/catalog.md` and `docs/data_dictionary.md`.

## License

- **Code** (`R/`, `scripts/`, R Markdown / Quarto sources): MIT — see [`LICENSE`](LICENSE).
- **Prose, manuscript, documentation, and figures** (`drafts/`, `docs/`, `output/figures/`, this README): CC-BY 4.0 — see [`LICENSE-DOCS.md`](LICENSE-DOCS.md).

## Citation

```
Zurabishvili, S. (2026). Measuring Aid for Learning: What Cross-Country Panel
Evidence Can and Cannot Say. Manuscript under review at World Development.
Open Science Framework deposit: https://doi.org/10.17605/OSF.IO/JRBT8
```

A machine-readable [`CITATION.cff`](CITATION.cff) is provided at the repository root.

## Contact

shota.zurabishvili@gmail.com
