#  Statistical Validity Audit

**Date:** 2026-05-23
**Phase:** 10 — (Statistical Validity)
**Session:** 24
**Brief gate criterion** (`docs/the project brief` lines 213–217): *"Run every diagnostic. Write results in a private document. No paper until this is done."*
**Verdict:** **Qualified pass.** The brief's Statistical-Layer diagnostics are run or documented as not-feasible-at-our-T. The PAP-0004 principal HLO robustness check **fails sign-agreement** — a substantive finding that forces a hedge of the manuscript's central within-country headline claim. The paper proceeds to with the hedge built in throughout.

---

## §1 Causal Identification Checks (4 items)

| # | Obligation | Status | Evidence |
|---|---|---|---|
| 1 | Verify all causal language is precise (association vs causation) | DEFERRED → () | manuscript-wide audit at draft-complete stage |
| 2 | Identify time-varying confounders (conflict, COVID, political transitions) | **PASS** | `data/interim/ucdp.parquet`; `data/interim/covid_closures.parquet`; methodology §3.7 |
| 3 | Test for reverse causality: Granger causality test on panel | **NOT FEASIBLE at our T** | Dumitrescu-Hurlin (2012) Z-tilde requires T > 5+3·order = 8 per country; our HCI-cycle panel provides T_eff ≤ 4. Test does not run. Same identification limit as [PAP-0010](decisions/0010-identification-strategy-gmm.md) GMM (small-T). `output/tables/pass1_granger_test.{csv,md}`. The static-FE-on-small-T story already owns this limit in §6. |
| 4 | Characterize selection bias from missing-data countries | **PASS** | `output/tables/ssa_panel_missingness.csv`; PAP-0002 |

---

## §2 Data Integrity Checks (6 items)

| # | Obligation | Status | Evidence |
|---|---|---|---|
| 1 | ODA: commitment vs disbursement — choose and justify | **PASS** | [PAP-0005](decisions/0005-oda-commitment-vs-disbursement.md) Accepted 2026-05-19; 16-cell sensitivity grid `output/tables/model2_fe_sensitivity.csv` shows all HLO β ≥ 0 |
| 2 | HLO: cite Altinok et al. + critics | **PASS** | [PAP-0004](decisions/0004-hlo-measure.md) Accepted; Sandefur 2018 engaged in methodology §3.4 |
| 3 | UNESCO enrollment: flag self-reporting incentive bias | **PASS (this session)** | Qualitative paragraph added to methodology §3.6 — incentive structure, UNESCO's own survey-vs-admin acknowledgments, within-FE absorption + within-country reporting-effort fluctuation as §6 limit |
| 4 | WGI: cite Langbein & Knack aggregation critique | **PASS** | `docs/lit/langbein-knack-2010.md`; methodology §3.6 + [PAP-0009](decisions/0009-wgi-operationalization.md) |
| 5 | Private expenditure: document missing data rate, especially SSA | **PASS** | `output/tables/ssa_uis_missingness.csv`: 91.8% SSA vs 80.3% RoW (+11.6 pp); [PAP-0006](decisions/0006-uis-missingness-strategy.md) "Data observed" |
| 6 | Missingness strategy: MCAR test, MI/listwise sensitivity | **PASS (with PAP-0012 amendment)** | [PAP-0006](decisions/0006-uis-missingness-strategy.md) Accepted; MCAR rejected at p ≪ 10⁻⁶; primary drops UIS; Robustness 1 (listwise) **executed this session** — β_ODA = -1.97, SE 4.40, N=41; Robustness 2 (MI) **retired** by new [PAP-0012](decisions/0012-retirement-of-uis-multiple-imputation.md) per MCAR rejection + the project no-fabrication principle. |

---

## §3 Model Diagnostics Checklist (10 items)

| # | Obligation | Status | Evidence |
|---|---|---|---|
| 1 | Hausman test (FE vs RE) | **PASS** | Manual univariate Cameron-Trivedi (): H=6.67, p=0.0098 → rejects RE. `output/tables/model3_hausman_test.csv`. `plm::phtest` failed (Swamy-Arora T>3 violation — same small-T limit); manual is operative. |
| 2 | Year fixed effects in panel model | **PASS** |  — two-way FE country + year in all Model 2 specs. `R/51_model2_fe.R`. |
| 3 | Breusch-Pagan heteroskedasticity test | **PASS** | : χ²=137, p=0.0045 → HC-robust + country-clustered SE applied. `output/tables/model2_fe_diagnostics.csv`. |
| 4 | Wooldridge serial autocorrelation test | **PASS** | : F=0.252, p=0.62 → no AR(1) detected (HCI cycle spacing makes AR(1) non-binding). |
| 5 | Cluster SE at country level | **PASS** |  — `feols(., vcov = ~iso3)`. |
| 6 | VIF table (flag VIF > 10) | **PASS** | : max VIF demeaned regressors = 1.64; max cross-section = 5.24 (log GDP/cap). All below 10. |
| 7 | Levene's test before ANOVA | **WITHDRAWN** | Model 4 dropped per [PAP-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected (2026-05-23). |
| 8 | ICC at all three multilevel model levels | **PASS (scope-resolved)** | Brief's 3-level commitment was for the original student-school-country HLM, superseded by Phase-2 reframe (Model 3 = 2-level country RE + year FE; student-level microdata deferred). Reframed obligation = ICC at country level only, computed : unconditional 91.2%, conditional 79.3%. Explicit scope decision in methodology §3.8 (this session). |
| 9 | Convergence diagnostics for HLM | **PASS (scope-resolved)** | Per the 3-level → 2-level supersession (above), collapses to `lme4::lmer::isSingular()` check in `R/57_model3_re_panel.R` — all 10 specs return `isSingular() = FALSE` (). |
| 10 | Effect sizes (η², Cohen's d) for ANOVA pairs | **WITHDRAWN** | Model 4 dropped per [PAP-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected (2026-05-23). |

---

## §4 Robustness Specifications (not strictly brief Pass-1 scope, but tracked for Phase-11 writing)

| # | Spec | Status | Evidence |
|---|---|---|---|
| 1 | HLO measure: WB current vs AAP-2018 | **FAILS sign-agreement (this session)** | β_primary = +11.14 (WB HCI HLOS, 2010-2020); β_AAP_full = -16.67 (1995-2015, p=0.009); β_AAP_overlap = -3.94 (year≥2010, p=0.66). Overlap-window null rules out sample-window as the sole driver — measure choice itself matters. **Manuscript adapts via the hedge route** per author decision: report "in the WB HCI HLOS specification on the 2010-2020 panel" throughout; §6 frames measure-sensitivity as itself a methodological contribution. Evidence: `output/tables/pass1_hlo_sensitivity.{csv,md}`; PAP-0004 "Data observed ()" block; methodology §3.4.1; findings §5.8. |
| 2 | ODA: disbursement vs commitment | **PASS** | [PAP-0005](decisions/0005-oda-commitment-vs-disbursement.md); 16-cell sensitivity grid `output/tables/model2_fe_sensitivity.csv` — all HLO β ≥ 0, no sign flips. |
| 3 | ODA: 1-year vs 3-year MA lag | **PASS** | [PAP-0005](decisions/0005-oda-commitment-vs-disbursement.md); 3-yr MA locked because 1-yr specs ns. |
| 4 | Sample: 2000–2022 vs 2005–2020 | **PASS (mechanically satisfied)** | [PAP-0003](decisions/0003-year-range.md) Session-09 audit: all three windows produce identical Model-2 samples because HLO sparsity is the binding constraint. Re-running on alternate windows would produce numerically identical β. `output/tables/year_range_viability.csv`. |
| 5 | Sample: with vs without China (GCDF) | **PASS** | [PAP-0008](decisions/0008-china-aid-inclusion.md); `output/tables/model2_china_robustness.csv`: OECD β shifts 8.17 → 8.06 (0.02 SD, within ±1 SD criterion); GCDF own coefficient null. |
| 6 | UIS missingness: listwise vs MI vs UIS-dropped | **PASS on amended scope** | Primary (UIS-dropped) per [PAP-0006](decisions/0006-uis-missingness-strategy.md); Robustness 1 (listwise) executed this session — β = -1.97, SE 4.40, N=41, weak robustness; Robustness 2 (MI) retired by [PAP-0012](decisions/0012-retirement-of-uis-multiple-imputation.md) per MCAR rejection + no-fabrication principle. |
| 7 | Identification: static FE vs Difference GMM vs System GMM | **PASS (with documented limits)** | [PAP-0010](decisions/0010-identification-strategy-gmm.md) Accepted with caveats — GMM attempted; Hansen p=0.022 rejects System GMM instruments; Diff GMM full + Sys GMM full fail (matrix singularity at T=3); Bond bounds degenerate; small-T (T_eff ≤ 4) below Bond (2002) minimum. Static FE remains headline; §3.8 + §6 acknowledge identification limit transparently. `output/tables/model2_identification_triangulation.md`. |
| 8 | LAYS reporting layer | **PASS** |  +  — `hci_lays_overall` verified; Model 5 counterfactual reports gains in LAYS units via WB identity. `output/tables/model5_counterfactual.{csv,md}`. |
| 9 | FE structure: country FE alone vs country × decade FE | **N/A-for-window** | Primary window covers ~1 decade (2010-2020); country × decade FE mechanically degenerates to country FE. No ADR commits; methodology-derived bullet only. Marked N/A in `the deposited diagnostic register`. |

---

## §5 Carry-forward to later passes

- ** Argumentative Coherence ():** read Abstract → Intro → Discussion → Conclusion without numbers; verify argument holds. Item-1 obligation (causal language audit) belongs here.
- **Pass 3 — Adversarial Read ():** 48-hour gap from final draft; read as skeptical *World Development* referee; mark every "claim X but not demonstrated X" sentence.
- **Reproducibility checks ():** `renv::restore()` on fresh machine; OSF/Dataverse deposit; APA 7 reference audit; cover letter.

---

## §6 sign-off statement

** Statistical Validity is closed as a sign-off at , 2026-05-23.**

Every diagnostic in the brief's  is either:
- **Executed and PASS** (8 of 10 Model Diagnostics; 2 of 6 Data Integrity executed this session; all 4 Robustness specs that the brief doesn't strictly require for but the paper claims);
- **WITHDRAWN per a documented ADR** (2 ANOVA items per PAP-0007 Rejected);
- **PASS on documented scope-resolution** (3-level ICC + HLM convergence per Phase-2 reframe);
- **DEFERRED to a later pass** with documentation (item-1 causal language audit → ; reproducibility items → ); or
- **Documented as not-feasible-at-our-T** (Granger test, per the same small-T identification limit that PAP-0010 owns).

**The substantive finding of is the HLO measure-sensitivity failure** (§4 row 1 above). This is not an obligations-bookkeeping outcome — it is a methodological discovery that reshapes the manuscript's framing. The author decision (2026-05-23) is to *hedge* the headline within-country claim throughout the paper to "in the WB HCI HLOS specification on the 2010–2020 panel" rather than naked "ODA positively predicts learning". §6 Discussion frames the measure-sensitivity as itself a methodological contribution. PAP-0004 carries the "Data observed ()" block; methodology §3.4.1 documents the operative analytical position; findings §5.8 reports the numbers transparently.

**Paper may proceed to manuscript drafting** with the hedge built in throughout. The manuscript-framing reframe (paths a/b/c per `the manuscript §5.2.1`) is now ripe and recommended as the first decision at entry; the Pass-1 finding further sharpens the case for the pre-analysis framework (methodological-discipline arc), in which §5.5 (Model 4 drop), §5.8 (measure-sensitivity finding), and the §6 Discussion limits become first-class narrative beats alongside the within-country positive headline.

---

*Compiled by , 2026-05-23. Source artifacts:*
- *Battery script:* `R/72_pass1_robustness_battery.R`
- *Output tables:* `output/tables/pass1_*.{csv,md}`
- *Living docs touched this session:* methodology §3.4.1 / §3.6 / §3.8 / §3.9; findings §5.8; obligations comprehensive sweep; PAP-0004 Phase-10 block; new PAP-0012; INDEX.md.
- *Session log:* `docs/session_log/2026-05-23-24-pass1-statistical-validity.md`.
