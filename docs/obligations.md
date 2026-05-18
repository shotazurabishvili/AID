# Methodology Obligations

> *Living checklist of every diagnostic, test, and methodological commitment the paper makes. Extracted from the brief's three Self-Review Protocol sections; grows as new ADRs commit us to additional checks.*
>
> *Each item: tick when complete, link to evidence (session log, output file, ADR).*

---

## Causal Identification Checks
*(From brief § Self-Review Protocol — Statistical Layer)*

- [ ] Verify all causal language is precise (association vs causation) — *manuscript-wide audit in Pass 2 (Phase 12)*
- [x] Identify time-varying confounders (conflict, COVID, political transitions) — *Phase 1 Session 07 done: UCDP/PRIO ACD + BRD v25.1 aggregated to country-year panel (data/interim/ucdp.parquet, 7470 × 10 × 1995-2024, 12.3% of cells with active conflict, SSA prevalence gap +16.1 pp); UNESCO COVID closures derived from daily HDX status CSV (data/interim/covid_closures.parquet, 630 × 8 × 2020-2022, cross-validated against UNESCO pre-aggregated at median |diff| = 2 days). Political transitions captured via WGI (Session 02).*
- [ ] Test for reverse causality: Granger causality test on panel — *Phase 5*
- [x] Characterize selection bias from missing-data countries explicitly — *Phase 1 Session 09 done: combined-panel SSA missingness at `output/tables/ssa_panel_missingness.csv` on the 2010-2020 ∩ ADR-0002 Option-1 analytical subset. SSA is BETTER covered than non-SSA on the analytical columns (HLO −1.84 pp; CRS commit −15.5 pp; edu_exp −13.5 pp) because high-income non-SSA countries fall outside the HLO/CRS measurement universes. Phase 1 Session 03 partial (UIS-only) preserved as `output/tables/ssa_uis_missingness.csv`.*

## Data Integrity Checks
*(From brief § Self-Review Protocol — Statistical Layer)*

- [ ] ODA: commitment vs disbursement — choose and justify → **[ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md)** (Phase 5)
- [x] HLO: cite Altinok et al. harmonization methodology and its critics → **[ADR-0004](decisions/0004-hlo-measure.md)** Accepted 2026-05-17. Sandefur (2018) critique engaged in §3.4 (within-country FE defense + SSA coverage caveat with empirical numbers from `output/tables/ssa_hlo_missingness.csv`). Both lit notes (altinok-angrist-patrinos-2018, sandefur-2018) read; manuscript-engagement box flips in Phase 11 once §3 lives in the Quarto draft.
- [ ] UNESCO enrollment: flag self-reporting incentive bias → Phase 3 EDA notes; §3.6 in `methodology.md`
- [x] WGI: cite Langbein & Knack aggregation critique — *Phase 1 Session 02 done: native bundle ingested with `n_sources` retained; per-source values deferred to Phase 5 per ADR-0009. Evidence: `data/interim/wgi.parquet`, `docs/lit/langbein-knack-2010.md`*
- [x] Private expenditure: document missing data rate, especially SSA → done Phase 1 Session 03: 91.8% SSA missing vs 80.3% non-SSA (+11.6pp). Evidence: `output/tables/ssa_uis_missingness.csv`, `docs/decisions/0006-uis-missingness-strategy.md::Data observed`
- [x] Missingness strategy: test MCAR, choose MI or listwise deletion, run sensitivity analysis both ways → **[ADR-0006](decisions/0006-uis-missingness-strategy.md)** Accepted 2026-05-18. *Phase 2 Session 01: production-panel MCAR run twice on the 2010-2020 primary window — 6-col (no UIS) χ² = 175.8, p < 0.000001, 173 complete rows; 7-col (+UIS) χ² = 341.9, p < 0.000001, 69 complete rows (60% sample loss). Locked Option 3: WDI controls only as primary; UIS-augmented listwise + MI as robustness. Evidence: `output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`.*

## Model Diagnostics Checklist
*(From brief § Self-Review Protocol — Statistical Layer)*

- [ ] **Hausman test (FE vs RE)** — report result — Phase 5 (Model 2)
- [ ] **Year fixed effects included in panel model** — Phase 5 (Model 2 spec)
- [ ] **Breusch-Pagan heteroskedasticity test** — Phase 5
- [ ] **Wooldridge test for serial autocorrelation** — Phase 5
- [ ] **Cluster standard errors at country level** — Phase 5 (default in `fixest::feols`)
- [ ] **VIF table — flag any VIF > 10** — Phase 5
- [ ] **Levene's test before ANOVA** — Phase 7 (Model 4)
- [ ] **ICC at all three multilevel model levels** — Phase 6 (Model 3 HLM)
- [ ] **Convergence diagnostics for HLM** — Phase 6
- [ ] **Effect sizes (η², Cohen's d) for ALL ANOVA pairs** — Phase 7

---

## Robustness Specifications
*(Cross-reference `methodology.md § 3.12`)*

- [~] HLO measure: WB current vs AAP-2018 — Phase 5/sensitivity. *Both measures ingested Session 04: `data/interim/hlo.parquet` (207 countries, 2010–2020) + `data/interim/hlo_aap2018.parquet` (137 countries, 1995–2015). Actual Model 1 + Model 2 sensitivity run is Phase 5.*
- [ ] ODA: disbursement vs commitment — Phase 5
- [ ] ODA: 1-year vs 3-year moving average lag — Phase 5
- [ ] Sample: 2000–2022 vs 2005–2020 — Phase 5/sensitivity
- [ ] Sample: with vs without Chinese aid flows (GCDF) — Phase 5
- [~] UIS missingness: listwise vs MI vs UIS-dropped — Phase 2 lock done; Phase 5 will run the three sensitivity specs and report alongside. *ADR-0006 Accepted 2026-05-18: drop UIS from primary; UIS-augmented listwise + MI both reported as Robustness 1 + Robustness 2. Implementation in Phase 5.*
- [ ] ANOVA coding: rule-based vs LLM-assisted (target agreement ≥ 85%) — Phase 7
- [ ] FE structure: country FE alone vs country × decade FE — Phase 5
- [ ] **Identification: static FE vs Difference GMM vs System GMM** — Phase 5. *Added Phase-2 external review. ADR-0010 Pending; System GMM headline robustness with Roodman (2009) diagnostics.*
- [ ] **LAYS reporting layer** (Learning-Adjusted Years of Schooling, per GEEAP 2023 / Angrist 2024) — Phase 3 EDA construction; Phase 5 Model 5 counterfactual reports in LAYS units alongside raw HLO score units.

---

## Three-Pass Adversarial Review
*(From brief § Self-Review Protocol — Argumentative Layer)*

- [ ] **Pass 1 — Statistical Validity** (before any writing): every diagnostic above completed; results in private document — Phase 10
- [ ] **Pass 2 — Argumentative Coherence** (after full draft): read Abstract → Intro → Discussion → Conclusion only; argument must hold without numbers — Phase 12
- [ ] **Pass 3 — Adversarial Read** (48 hours after final draft): read as skeptical World Development referee; every "claim X but not demonstrated X" sentence fixed or reframed — Phase 13

---

## Reproducibility Obligations

- [x] All raw data hashed (SHA-256) at fetch time → recorded in `data/catalog.yml::raw_files[]` — Phase 1 substantively complete: WDI, HCI, WGI, UIS, HLO primary + HLO AAP-2018, OECD CRS, AidData GCDF, UCDP, COVID closures, AI Readiness all hashed (11 sources). Only deferred: AidData Core v3.1 (per Session 06 author decision).
- [ ] All code committed to GitHub before each phase close — **on track**
- [ ] OSF or Harvard Dataverse deposit live before submission — Phase 14
- [ ] `renv.lock` pins full package environment — **complete (188 packages)**
- [ ] `renv::restore()` reproduces analysis on a fresh machine — **to be verified before submission**

---

## Submission Readiness
*(World Development specific)*

- [ ] Word count: 9,000–11,000 words + tables + figures — Phase 11
- [ ] References in APA 7 — Phase 14
- [ ] Code + data deposit URL embedded in manuscript — Phase 14
- [ ] Positionality statement in §3 Methodology — Phase 11; draft in `positionality.md`
- [ ] Cover letter drafted — Phase 14
