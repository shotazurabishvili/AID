# Research Roadmap

Phased plan from infrastructure → submission. Order is mostly linear; modeling and EDA iterate.

| # | Phase | Sessions (est.) | Exit criterion |
|---|---|---|---|
| 0 | Infrastructure | 1 | R works, repo pushed to GitHub, `CLAUDE.md` is readable, `sync_to_desktop.sh` runs |
| 1 | Data ingestion & audit | 4–8 | All 10 sources downloaded (or API-accessible) with access dates in `data/catalog.md`; per-source coverage tables and missingness maps under `output/figures/coverage/` |
| 2 | Panel construction | 2–3 | Single processed panel (~2,600 obs, ISO3 × year); documented join losses; MCAR test result; MI vs listwise decision recorded as ADR |
| 3 | EDA | 2–3 | Enrollment/learning divergence figures by region + income group; descriptive table 1 for paper §4.1; **LAYS reporting layer** constructed (Learning-Adjusted Years of Schooling per GEEAP 2023 / Angrist 2024) |
| 4 | Model 1 — OLS baseline | 1 | Cross-sectional OLS coefficients with clustered SE; result documented |
| 5 | Model 2 — FE panel (PRIMARY) + System GMM | 4–5 | Country + year FE baseline; **System GMM as headline robustness ([ADR-0010](decisions/0010-identification-strategy-gmm.md))** with Roodman diagnostics (Hansen overid, AR(1)/AR(2), instrument count); Hausman + Wooldridge + Breusch-Pagan + VIF run; ODA coefficient reported and contrasted with Model 1; [ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md) locked |
| 6 | Model 3 — Reframed 2-level RE vs FE | 1–2 | **Reframed per Phase-2 external review:** brief's "students nested in schools nested in countries" not supportable on country-year data without PISA/TIMSS/PIRLS microdata (deferred stretch). Model 3 becomes a 2-level country random intercepts + time FE; Hausman test justifies FE-over-RE for Model 2 headline; ADR on the reframe locked at session start |
| 7 | Model 4 — ANOVA on intervention typology | 2 | ADR on group coding (infrastructure / teacher training / curriculum / budget support); Levene's test; Tukey HSD; η² and Cohen's d for ALL pairs |
| 8 | Model 5 — Counterfactual simulation | 1 | Best / worst / expected case across CI bounds; explicit limit acknowledgments |
| 9 | Compounding AI penalty section | 1 | HCI × AI Readiness composite constructed; novel finding documented; figure produced |
| 10 | Pass 1 — Statistical validity | 1 | Every diagnostic from brief's checklist run; private results doc compiled |
| 11 | Writing — full draft | 6–10 | Quarto manuscript ~10k words; matches brief's section structure; all tables/figures embedded |
| 12 | Pass 2 — Argumentative coherence | 1 | Read Abstract → Intro → Discussion → Conclusion in isolation; argument holds without numbers |
| 13 | Pass 3 — Adversarial read | 1 | 48h gap from final draft; read as hostile World Development referee; every "claim X without demonstrating X" sentence fixed or reframed |
| 14 | Submission prep | 1–2 | APA 7 references verified; OSF deposit live; positionality statement finalized; cover letter drafted |

Estimated **30–45 sessions total.** Adjustable as we go.

---

## Phase-specific notes

### Phase 1 — Data ingestion order

Recommended order (cheapest to hardest):

1. **WDI** (R package `WDI`) — easiest, fully API-driven
2. **WGI** (R package `WDI` also exposes WGI series)
3. **EdStats** (World Bank, bulk download)
4. **HCI** (World Bank, downloadable CSV)
5. **UNESCO UIS** (API or bulk CSV)
6. **HLO** (Altinok, Angrist & Patrinos harmonized dataset — downloadable)
7. **OECD DAC CRS** — the awkward one. Bulk extract from stats.oecd.org; very large; filter by sector code 11x (education)
8. **AidData** — geocoded project-level; download from aiddata.org
9. **PISA / TIMSS / PIRLS** — separate downloads, age-cohort harmonization needed
10. **AI Readiness Index** (Oxford Insights) — small CSV per year, manual

Each gets a script `R/10_ingest_<source>.R` + a row in `data/catalog.md` with source URL, access date, version/year, raw filename, and observed row count.

### Phase 2 — Panel construction

- Merge key: ISO3 country code (use `countrycode` package; document any unresolved codes) + year.
- All flows aggregated to ISO3 × year. ODA: 3-year lagged moving average to reflect disbursement lag.
- Listwise vs MI decision is made *after* the missingness map is built — not before.
- The missing-data ADR must explicitly characterize the SSA (sub-Saharan Africa) selection bias.

### Phase 5 — Model 2 (the killer model) + System GMM

This is the central finding. The contrast between the Model 1 (naive OLS) coefficient on ODA and the Model 2 (within-country FE) coefficient is the headline result. Specification:

```
Learning_it = β1·ODA_it + β2·Expenditure_it + β3·Stability_it + αi + λt + εit
```

**System GMM as headline robustness** ([ADR-0010](decisions/0010-identification-strategy-gmm.md)): added per Phase-2 external review. Closes the canonical reverse-causality critique (donors target deteriorating learning); positions paper in the *World Development* / Asongu-2019 / Yogo-2017 mainline aid-effectiveness lit.

Required diagnostics, all reported with the model:
- Hausman test (FE vs RE)
- Wooldridge test for serial autocorrelation
- Breusch-Pagan for heteroskedasticity
- VIF table (flag any > 10)
- Cluster-robust SE at country level
- Sensitivity to ODA lag structure (1y vs 3y MA)
- **GMM-specific:** Hansen overidentification test (target p > 0.10, < 0.99); Difference-in-Hansen for instrument subsets; AR(1) on residuals (p < 0.05 expected); AR(2) on residuals (p > 0.10 required); instrument count < N; Roodman (2009) cited
- **Power / minimum-detectable-effect calculation** per coefficient (n=173 complete rows for primary spec; thin data demands explicit power reporting)

### Phases 12–13 — Adversarial passes

These passes are not optional and the **48-hour gap** in Pass 3 is part of the methodology. The author reads as a skeptical World Bank-affiliated referee. Every sentence that says more than the evidence supports gets reframed.

---

## What this plan deliberately defers

- **Decision on ODA "commitment vs disbursement"** — ADR in Phase 5, after seeing the OECD CRS data
- **Missingness strategy** — ADR in Phase 2, after seeing the coverage maps
- **ANOVA group coding** — ADR in Phase 7, after seeing OECD CRS purpose codes within education
- **Random slopes vs intercepts only in HLM** — ADR in Phase 6, after seeing variance decomposition

These deferrals are deliberate: the brief warns against pre-committing to a strategy before seeing the data.
