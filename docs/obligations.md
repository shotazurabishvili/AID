# Methodology Obligations

> *Living checklist of every diagnostic, test, and methodological commitment the paper makes. Extracted from the brief's three Self-Review Protocol sections; grows as new ADRs commit us to additional checks.*
>
> *Each item: tick when complete, link to evidence (session log, output file, ADR).*

---

## Causal Identification Checks
*(From brief § Self-Review Protocol — Statistical Layer)*

- [ ] Verify all causal language is precise (association vs causation) — *manuscript-wide audit in Pass 2 (Phase 12)*
- [x] Identify time-varying confounders (conflict, COVID, political transitions) — *Phase 1 Session 07 done: UCDP/PRIO ACD + BRD v25.1 aggregated to country-year panel (data/interim/ucdp.parquet, 7470 × 10 × 1995-2024, 12.3% of cells with active conflict, SSA prevalence gap +16.1 pp); UNESCO COVID closures derived from daily HDX status CSV (data/interim/covid_closures.parquet, 630 × 8 × 2020-2022, cross-validated against UNESCO pre-aggregated at median |diff| = 2 days). Political transitions captured via WGI (Session 02).*
- [~] **Test for reverse causality: Granger causality test on panel** — *Phase 10 Pass 1 (2026-05-23) attempted.* Dumitrescu-Hurlin (2012) Z-tilde via `plm::pgrangertest` requires T > 5+3·order = 8 per country; our HCI-cycle panel has T_eff ≤ 4. Test not feasible at our T — same small-T identification limit as [ADR-0010](decisions/0010-identification-strategy-gmm.md) GMM. Documented in `findings.md §5.8` + `output/pass1_statistical_validity_audit.md` + `output/tables/pass1_granger_test.{csv,md}`.
- [x] Characterize selection bias from missing-data countries explicitly — *Phase 1 Session 09 done: combined-panel SSA missingness at `output/tables/ssa_panel_missingness.csv` on the 2010-2020 ∩ ADR-0002 Option-1 analytical subset. SSA is BETTER covered than non-SSA on the analytical columns (HLO −1.84 pp; CRS commit −15.5 pp; edu_exp −13.5 pp) because high-income non-SSA countries fall outside the HLO/CRS measurement universes. Phase 1 Session 03 partial (UIS-only) preserved as `output/tables/ssa_uis_missingness.csv`.*

## Data Integrity Checks
*(From brief § Self-Review Protocol — Statistical Layer)*

- [x] ODA: commitment vs disbursement — choose and justify → **[ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md)** Accepted 2026-05-19 (Phase 5 Session 03). Lock: `crs_disburse_usd_defl_ma3_lag1` (disburse × constant USD × strictly-past 3-yr MA). 16-cell sensitivity grid shows all HLO β ≥ 0 (no sign flips); commit + disburse both report positive within-country associations; disburse primary on theoretical grounds. Evidence: `output/tables/model2_fe_sensitivity.csv`.
- [x] HLO: cite Altinok et al. harmonization methodology and its critics → **[ADR-0004](decisions/0004-hlo-measure.md)** Accepted 2026-05-17. Sandefur (2018) critique engaged in §3.4 (within-country FE defense + SSA coverage caveat with empirical numbers from `output/tables/ssa_hlo_missingness.csv`). Both lit notes (altinok-angrist-patrinos-2018, sandefur-2018) read; manuscript-engagement box flips in Phase 11 once §3 lives in the Quarto draft.
- [x] **UNESCO enrollment: flag self-reporting incentive bias** — *Phase 10 Pass 1 done.* Qualitative paragraph added to `methodology.md §3.6` (post-Phase-10 update). Documents the well-known incentive for ministries of education to over-report enrollment/under-report OOS in MDG/SDG monitoring cycles; cites UNESCO's own survey-vs-admin-data acknowledgments; flags within-country FE absorption of cross-country reporting differences and within-country year-on-year reporting-effort fluctuations as a §6 limit.
- [x] WGI: cite Langbein & Knack aggregation critique — *Phase 1 Session 02 done: native bundle ingested with `n_sources` retained; per-source values deferred to Phase 5 per ADR-0009. Evidence: `data/interim/wgi.parquet`, `docs/lit/langbein-knack-2010.md`*
- [x] Private expenditure: document missing data rate, especially SSA → done Phase 1 Session 03: 91.8% SSA missing vs 80.3% non-SSA (+11.6pp). Evidence: `output/tables/ssa_uis_missingness.csv`, `docs/decisions/0006-uis-missingness-strategy.md::Data observed`
- [x] Missingness strategy: test MCAR, choose MI or listwise deletion, run sensitivity analysis both ways → **[ADR-0006](decisions/0006-uis-missingness-strategy.md)** Accepted 2026-05-18. *Phase 2 Session 01: production-panel MCAR run twice on the 2010-2020 primary window — 6-col (no UIS) χ² = 175.8, p < 0.000001, 173 complete rows; 7-col (+UIS) χ² = 341.9, p < 0.000001, 69 complete rows (60% sample loss). Locked Option 3: WDI controls only as primary; UIS-augmented listwise + MI as robustness. Evidence: `output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`.*

## Model Diagnostics Checklist
*(From brief § Self-Review Protocol — Statistical Layer)*

- [~] **Hausman test (FE vs RE)** — attempted Phase 5 Session 01. *RE estimation failed (Swamy-Arora requires > 3 time periods; HCI cycles provide only 4 effective points per country). FE specification justified theoretically per Mundlak; formal Hausman deferred to Phase-5 Session 05 if RE becomes estimable on a wider/different sample. Evidence: `output/tables/model2_fe_diagnostics.csv`.*
- [x] **Year fixed effects included in panel model** — Phase 5 Session 01. *Two-way FE (country + year) in all Model 2 specs. Evidence: `R/51_model2_fe.R`; `output/tables/model2_fe_baseline.md`.*
- [x] **Breusch-Pagan heteroskedasticity test** — Phase 5 Session 01. *χ² = 137 (df 97), p = 0.0045 — heteroskedasticity present; HC-robust + country-clustered SE applied. Evidence: `output/tables/model2_fe_diagnostics.csv`.*
- [x] **Wooldridge test for serial autocorrelation** — Phase 5 Session 01. *F = 0.252, p = 0.62 — no serial autocorrelation detected (HCI cycle spacing of 7+ years makes AR(1) non-binding). Evidence: `output/tables/model2_fe_diagnostics.csv`.*
- [x] **Cluster standard errors at country level** — Phase 5 Session 01. *Applied via `feols(., vcov = ~iso3)`. Evidence: `R/51_model2_fe.R`.*
- [x] **VIF table — flag any VIF > 10** — Phase 5 Session 01. *Max VIF on within-demeaned regressors = 1.64 (Model 2 full spec); max VIF in Model 1 cross-section = 5.24 on log(GDP/cap). All below 10. The cross-sectional governance × income multicollinearity (Session 12 r=0.79) is fully absorbed by within-country FE. Evidence: `output/tables/model2_fe_diagnostics.csv` + `model1_vif.csv`.*
- [~] ~~**Levene's test before ANOVA** — Phase 7 (Model 4)~~ **Withdrawn 2026-05-23** — Model 4 dropped per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected (pre-committed typology gate failed all three criteria).
- [x] **ICC at all three multilevel model levels** — *Phase 10 Pass 1 scope-resolved.* Brief's 3-level commitment was written for the original student-school-country HLM specification; superseded by the Phase-2 external-review reframe (Model 3 = 2-level country RE + year FE on country-year panel, since student-level microdata is deferred per plan.md). Reframed obligation: ICC at country level only — reported `findings.md §5.4` (unconditional 91.2%, conditional 79.3%), evidence at `output/tables/model3_icc.csv`. Explicit scope decision in `methodology.md §3.8` (Phase-10 update).
- [x] **Convergence diagnostics for HLM** — *Phase 10 Pass 1 scope-resolved.* Per the 3-level → 2-level supersession (above), HLM convergence collapses to the `lme4::lmer` `isSingular()` check already in `R/57_model3_re_panel.R`. All 10 specs (HLO + LAYS × 3a-3e) returned `isSingular() = FALSE`. Evidence in session log 2026-05-19-20.
- [~] ~~**Effect sizes (η², Cohen's d) for ALL ANOVA pairs** — Phase 7~~ **Withdrawn 2026-05-23** — Model 4 dropped per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected.

---

## Robustness Specifications
*(Cross-reference `methodology.md § 3.12`)*

- [x] **HLO measure: WB current vs AAP-2018** — *Phase 10 Pass 1 (2026-05-23) executed.* **Sign-agreement FAILS** per the ADR-0004 / methodology §3.4 principal-robustness commitment. Primary β = +11.14 (WB HCI HLOS, 2010-2020); AAP full β = -16.67 (p=0.009); AAP overlap-window (year≥2010) β = -3.94 (p=0.66). Overlap-window null rules out sample-window composition as the sole driver — the HLO measure choice itself materially shapes the headline. **Researcher response (author decision):** hedge the headline claim throughout the manuscript rather than withdraw it; report measure-sensitivity as itself a methodological finding. Evidence: `output/tables/pass1_hlo_sensitivity.{csv,md}`; ADR-0004 "Data observed (Phase 10 Session 01)" block; methodology §3.4.1; `findings.md §5.8`.
- [x] ODA: disbursement vs commitment — Phase 5 Session 03 done (ADR-0005 lock). Full 16-cell sensitivity table at `output/tables/model2_fe_sensitivity.csv`; disburse and commit both yield positive within-country β on HLO across all MA specs. Disburse primary on theoretical grounds.
- [x] ODA: 1-year vs 3-year moving average lag — Phase 5 Session 03 done. Lag1 specs all weak (β=2.5-3.2, p>0.10); 3-yr MA specs significant (β=9-12). 3-yr window absorbs spending → learning lag better; 3-yr locked in ADR-0005.
- [x] **Sample: 2000–2022 vs 2005–2020** — *Phase 10 Pass 1 (2026-05-23) resolved.* Mechanically satisfied per [ADR-0003](decisions/0003-year-range.md) Session-09 audit: all three windows (2000–2022, 2005–2020, 2010–2020) produce **identical Model-2 samples** because HLO sparsity is the binding constraint (HLO observed only in HCI cycles 2010/2017/2018/2020). Re-running the regressions on alternate windows would produce numerically identical β. Evidence: `output/tables/year_range_viability.csv` per ADR-0003 "Data observed" block. Documented in `output/pass1_statistical_validity_audit.md`.
- [x] Sample: with vs without Chinese aid flows (GCDF) — Phase 5 Session 04 (ADR-0008 lock). Spec B (OECD + GCDF covariate) shifts OECD β from 8.17 → 8.06 (0.02 SD); GCDF own β = −0.27, p = 0.74 ns. OECD-CRS-only headline is robust to non-DAC blind spot. Evidence: `output/tables/model2_china_robustness.csv`.
- [x] **UIS missingness: listwise vs MI vs UIS-dropped** — *Phase 10 Pass 1 (2026-05-23) resolved on amended scope.* Primary (UIS-dropped) per ADR-0006 — locked. **Robustness 1 (listwise) executed:** β_ODA = -1.97 (SE 4.40, N=41), sign-flipped vs primary but non-significant; CIs partially overlap. Evidence: `output/tables/pass1_uis_listwise.{csv,md}`; `findings.md §5.8`; `methodology.md §3.9` updated. **Robustness 2 (MI) retired** by [ADR-0012](decisions/0012-retirement-of-uis-multiple-imputation.md): MCAR rejected at p ≪ 10⁻⁶ → MAR assumption unsupported; CLAUDE.md no-fabrication principle conflict; listwise covers same robustness direction. ADR-0006 amended in scope; primary lock unaffected.
- [~] ~~ANOVA coding: rule-based vs LLM-assisted (target agreement ≥ 85%) — Phase 7~~ **Withdrawn 2026-05-23** — gate ran on 2026-05-19 (raw 39 %, κ=0.19, unclassified 76 %), all three pre-committed criteria failed; Model 4 dropped per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected. The failure is the finding (see `findings.md §5.5`).
- [N/A] **FE structure: country FE alone vs country × decade FE** — *Phase 10 Pass 1 (2026-05-23) resolved.* Not meaningful in the 2010–2020 primary window: ~1 decade covered, so country × decade FE mechanically degenerates to country FE. No ADR commits to this robustness (the bullet is methodology-derived only). Documented in `output/pass1_statistical_validity_audit.md`; obligation marked N/A-for-window rather than executed.
- [x] **Identification: static FE vs Difference GMM vs System GMM** — Phase 5 Session 02 done. *ADR-0010 Accepted (with caveats) 2026-05-19. GMM attempted per brief + Phase-2 external review; Hansen p=0.022 on System GMM rejects instrument validity; Diff GMM full and Sys GMM full fail to estimate (matrix singularity at T=3); Bond consistency bounds degenerate with `lag_hlo` coefficient ≈ 1.0. Small-T HCI panel (T_eff ≤ 4) is below Bond (2002) minimum (T ≥ 5-10). Static FE remains headline; §3.8 + ADR-0010 acknowledge identification limits transparently. Evidence: `output/tables/model2_identification_triangulation.md`, `output/tables/model2_gmm_diagnostics.csv`.*
- [x] **LAYS reporting layer** (Learning-Adjusted Years of Schooling, per GEEAP 2023 / Angrist 2024) — Phase 3 Session 01 done: LAYS column verified as `hci_lays_overall` (WB-published from `HD.HCI.LAYS`); coverage = 443 cells in primary window (same as HLO); spot-checked LAYS = EYS × (HLO/625) identity on 5 countries; included in Table 1. **Phase 8 Session 01 (2026-05-23) closes the loop:** Model 5 counterfactual reported in LAYS units via the WB identity (ΔLAYS = EYS × ΔHLO / 625) with implied-EYS fan at p10/p50/p90 ([ADR-0011](decisions/0011-counterfactual-specification.md); `findings.md §5.6`). Evidence: `docs/methodology.md §3.4 LAYS subsection`; `output/tables/table1_descriptives.md`; `output/tables/model5_counterfactual.{csv,md}`; `R/70_model5_counterfactual.R`.

---

## Three-Pass Adversarial Review
*(From brief § Self-Review Protocol — Argumentative Layer)*

- [x] **Pass 1 — Statistical Validity** — *Phase 10 Session 01 (2026-05-23) closed as **qualified pass**.* Every diagnostic in the brief's Statistical Layer is run or documented as not-feasible-at-our-T. The principal HLO-AAP robustness check fails sign-agreement (a substantive finding documented in §5.8 + methodology §3.4.1 + ADR-0004 Phase-10 block); the manuscript adapts via the hedge route rather than withdrawing the headline. Audit document: `output/pass1_statistical_validity_audit.md`. New ADR-0012 retires UIS MI sub-commitment per MCAR-rejection + no-fabrication principle. Paper proceeds to Phase 11 with explicit measure-qualification of the headline claim.
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
