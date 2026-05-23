# Methodology — Working Narrative

> *This document is the proto-§3 ("Data & Methodology") of the manuscript. It grows session by session as decisions are locked. Each section references the relevant ADR for the load-bearing call. When Phase 11 (Writing) begins, much of `drafts/paper.qmd § 3` is a refactoring of this file.*
>
> *Last updated: 2026-05-19 (Session 15 close — Phase 5 Session 02; System GMM attempted per ADR-0010; small-T HCI panel prevents clean identification; static FE remains headline)*

---

## 3.1 Conceptual framework

The paper tests whether Official Development Assistance to education predicts learning outcomes across countries, and which structural variables actually drive learning. The conceptual model has three layers:

- **Inputs (donor side):** ODA flows by sector, recipient, year.
- **Mediators (country side):** education expenditure, pupil-teacher ratio, governance quality, conflict, COVID-era schooling disruption.
- **Outcomes:** harmonized learning outcomes (HLO), distinct from enrollment.

The central claim — *"ODA to education predicts enrollment but not learning"* — is operationalized as a contrast between two model specifications: cross-sectional OLS (Model 1) that may show a naive association, and within-country fixed-effects panel (Model 2) that may not.

The argument is *falsifiable*: if the within-country coefficient on ODA is positive, significant, and meaningful in magnitude, the thesis fails.

## 3.2 Sample — country universe

**Locked decision:** [ADR-0002](decisions/0002-country-universe.md) — **Accepted 2026-05-18**.

**N = 133 countries** — those that are ODA-eligible (received any positive OECD CRS commitment in 1995–2024) ∩ have ≥1 HLO observation. Derived empirically in Session 09 from `data/interim/_panel_audit.parquet`; full enumeration at `output/tables/country_universe_candidates.csv`. The Model-2 within-country FE subset uses the **127** countries with ≥2 HLO cycles (slope identification requires ≥2 observations). The 6-country difference is reported in the Methodology footnote.

## 3.3 Period — year range

**Locked decision:** [ADR-0003](decisions/0003-year-range.md) — **Accepted 2026-05-18**.

**Primary: 2010–2020** (HCI-cycle-anchored). Robustness in parallel: **2000–2022** and **2005–2020**. The Session 09 audit (`output/tables/year_range_viability.csv`) confirms all three windows yield *identical* Model-2 sample sizes (156 full-row cells × 163 countries × 589 HLO cells) — HLO is observed only in HCI cycles (2010/2017/2018/2020), so pre-2010 cells contribute zero useful information to within-country FE. The 2010–2020 primary maximizes useful-cell density (5.67% vs 2.71% for 2000–2022); the wider windows are reported alongside as referee-resistant robustness. COVID years (2020–2022) handled with `covid_days_closed` as a time-varying control in Model 2; robustness drops 2020+ entirely.

## 3.4 Outcome variable — learning

**Locked decision:** [ADR-0004](decisions/0004-hlo-measure.md) — Accepted 2026-05-17 (Phase 1 Session 04).

**Primary measure.** World Bank `HD.HCI.HLOS` (Harmonized Test Scores) — the Human Capital Index component score, fetched via the WDI API. Stored as `hlo_score` in `data/interim/hlo.parquet`. Coverage in our ingest: 207 countries × 2010–2020 (HCI publishes in cycles, so missing % within this panel is 74.13%). Scale: ~300–625, with thresholds anchored on PIRLS/TIMSS primary benchmarks (400 minimum / 475 intermediate / 625 advanced).

**Robustness measure.** Altinok, Angrist & Patrinos (2018) — *Global data set on education quality (1965–2015)*, World Bank Policy Research Working Paper 8314. Fetched via the OWID `owid-datasets` GitHub mirror (raw CSV pinned by commit hash) which retains a single per-country-year harmonized score already pooled across subjects (math/reading/science) and levels (primary/secondary) per the methodology of the source paper. Stored as `hlo_aap` in `data/interim/hlo_aap2018.parquet`. Coverage in our ingest: 137 countries × 1995–2015 at 5-year intervals. Identical conceptual scale to `hlo_score`.

**Sandefur (2018) critique.** *Internationally comparable mathematics scores for fourteen African countries* (CGD WP 444) argues that anchor-equating between PISA, TIMSS, SACMEQ and other testing regimes produces score-equivalence claims that may not hold in practice — particularly for sub-Saharan African countries that anchor through small overlapping samples. This is the most serious threat to the validity of the headline outcome variable. We engage it head-on rather than burying it.

**Within-country fixed-effects defense.** Model 2 ($\alpha_i + \lambda_t$) absorbs the cross-country score-comparability problem Sandefur identifies: country fixed effects soak up any time-invariant cross-country level miscalibration in the harmonization. The coefficient on ODA in Model 2 is identified off *within-country variation over time*, which faces a much smaller harmonization burden than cross-country level comparisons. The naive cross-sectional level differences Sandefur highlights are precisely what `αᵢ` controls for. Robustness reports both measures' Model 2 results in Phase 5; the within-country coefficient must be the same sign and within-CI magnitude across the primary and AAP-2018 specifications for the headline claim to stand.

**LAYS reporting layer (Phase 2 external-review addition, Phase 3 Session 01 verified).** The Learning-Adjusted Years of Schooling (LAYS) metric is the de facto reporting standard in the contemporary cost-effectiveness literature ([GEEAP 2023 Smart Buys](obligations.md); [Angrist et al. 2024](lit/)). It is computed by the World Bank as $\text{LAYS} = \text{EYS} \times (\text{HLO}/625)$ where EYS is expected years of schooling and 625 is the upper anchor of the HCI HLOS scale. The production panel carries the WB-published value directly as `hci_lays_overall` (alongside `_female` / `_male`) from `HD.HCI.LAYS`. Coverage is identical to HLO score itself (published in the same HCI cycles): 443 of 1,463 cells in the 2010–2020 primary window. Spot-checked the LAYS identity on 5 random 2020 countries; implied EYS values are realistic (AFG ≈ 8.9 yrs, ALB ≈ 12.9 yrs, ARG ≈ 12.9 yrs, ARM ≈ 11.3 yrs, AGO ≈ 8.1 yrs). The Phase-5 Model 5 counterfactual reports gains in LAYS units alongside raw HLO points; this puts the paper's findings in the metric Angrist 2024 and GEEAP 2023 use for cross-intervention comparison. Both HLO and LAYS appear as outcome variables in Table 1 (`output/tables/table1_descriptives.md`).

**SSA coverage caveat — empirically grounded.** The Session 04 ingest characterizes SSA missingness for both measures on a full-joined panel (`output/tables/ssa_hlo_missingness.csv`):

| Measure | SSA missing % | Rest-of-world missing % | Gap |
|---|---|---|---|
| `hlo_score` (HCI HLOS) | 74.40% | 77.60% | **−3.20 pp** |
| `hlo_aap` (AAP-2018)   | 88.02% | 79.23% | **+8.75 pp** |

The two measures diverge sharply on SSA representation. The primary HCI measure shows *slightly better* SSA coverage than rest-of-world — consistent with the World Bank Human Capital Project's explicit post-2017 targeting of measurement gaps in low-income countries. The AAP-2018 robustness measure shows the **opposite** pattern (+8.75 pp worse in SSA), which is the empirical face of Sandefur's pre-2018 SSA-coverage concern: the harmonization rests on thin SACMEQ/PASEC anchors that miss many SSA country-years. This is *measurement availability*, distinct from the *measurement equating* version of the Sandefur concern; both flow into the Discussion §6 limits paragraph on outcome-variable uncertainty.

### 3.4.1 Measure-sensitivity finding (Phase 10 Pass 1, 2026-05-23)

The principal robustness check committed in [ADR-0004](decisions/0004-hlo-measure.md) — refit Model 2 spec 2e on the AAP-2018 outcome and verify sign + within-CI agreement with the primary WB HCI HLOS β — was executed at Phase 10 Pass 1. **Sign agreement fails.** Primary β = +11.14 (SE 5.52, N = 143); AAP full coverage β = −16.67 (SE 5.96, N = 69, p = 0.009); AAP restricted to year ≥ 2010 (overlap window) β = −3.94 (SE 8.68, N = 36, p = 0.66). The overlap-window null result rules out sample-window composition as the sole driver of the disagreement: the HLO measure choice itself materially affects the headline coefficient. ADR-0004's "Data observed (Phase 10 Session 01)" block documents the full result; `findings.md §5.8` carries the empirical writeup.

**Manuscript implication.** The headline within-country result is reported with explicit measure-qualification throughout the paper: *"in the WB HCI HLOS specification on the 2010–2020 panel"*, not naked *"ODA positively predicts learning"*. The §6 Discussion frames the measure-sensitivity as itself a methodological contribution about the cross-country aid-learning literature — the result is real in the WB specification but does not carry across to AAP-2018 even on the comparable window. The hedge route was chosen over withdrawing the headline because (a) the WB-specification result is real and the project's other empirical pillars (§5.7 Compounding AI Penalty, Model 5 counterfactual) don't depend on it, and (b) reporting both transparently with the hedge honors the pre-committed methodology §3.4 obligation while preserving the WB result as published-and-defensible.

## 3.5 Treatment variable — ODA to education

**Locked decision:** [ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md) — Accepted (Phase 5 Session 03, 2026-05-19).

Primary: OECD DAC CRS **disbursements** to education (sector codes 110/111/112/113/114), constant USD (DAC deflator), **3-year strictly-past moving average** (mean of t-3, t-2, t-1). Panel column `crs_disburse_usd_defl_ma3_lag1`. The strictly-past window forecloses contemporaneous donor response to in-year learning shocks — a reverse-causation concern flagged in the Phase-3 self-review. Robustness specs reported alongside primary: trailing-inclusive 3-yr MA (shorter window), raw annual disbursement (no smoothing), commitment-side strictly-past MA (alternative measure), and (per ADR-0008) Chinese development finance from AidData GCDF v3.0. Full 16-cell sensitivity grid at `output/tables/model2_fe_sensitivity.csv`; all 16 HLO cells show β ≥ 0, no sign flips.

**Ingest done (Phase 1 Session 05).** Bulk parquet (~1 GB, release CRS-Parquet-v20260408) fetched via dynamic SDMX file-ID discovery (`sdmx.oecd.org/.../DSD_CRS@DF_CRS/1.6` → IDFile GUID). Stored at project-level resolution in `data/interim/oecd_crs.parquet` — **537,586 rows × 38 columns, 172 recipient countries × 125 donor identities, 1995–2024**. Commitments and disbursements are SEPARATE wide columns (legacy CRS dotStat format), not long-format rows, with paired `_defl` constant-USD variants — so the ADR-0005 question becomes a *column choice* at Phase 5, not a *row filter*. Grant-equivalent measure (`usd_grant_equiv`) is the post-2018 ODA methodology and only populates 2015+. Project description text (`project_title`, `short_description`, `long_description`, `keywords`) and the 5-digit `purpose_code` are retained for ADR-0007 typology coding (Phase 7). Country-year aggregation (sum across donors per recipient × year) and 3-year MA happen in `R/30_merge_panel.R` at Phase 2 — ingest preserves source-native resolution. **SSA coverage parity is excellent** on commitments and disbursements (gap −1.3 / −1.1 pp respectively); see `output/tables/ssa_oecd_crs_missingness.csv`.

**Production panel constructed (Phase 2 Session 01; expanded Phase 5 Session 03).** `R/30_merge_panel.R` aggregates CRS to (iso3, year) sums across donors and builds the ADR-0005 column matrix: **4 raw cols** (`crs_commit_usd_sum`, `crs_commit_usd_defl_sum`, `crs_disburse_usd_sum`, `crs_disburse_usd_defl_sum`); **4 trailing-inclusive 3-year MA cols** `*_ma3` (mean of t-2, t-1, t); **4 one-year lag cols** `*_lag1` on both USD bases; **4 strictly-past 3-year MA cols** `*_ma3_lag1` (mean of t-3, t-2, t-1) added in Session 03 for the ADR-0005 lock grid. `.complete=TRUE` returns NA when fewer than 3 in-panel years are available. NA cells within the ADR-0002 universe are coalesced to 0 before MA computation (rationale: ODA-eligible recipients with no recorded education project in year *t* received $0 that year, not "data missing"). ADR-0005 (Phase 5 Session 03) picks `crs_disburse_usd_defl_ma3_lag1` as primary from this 16-cell grid. Pre-2002 disbursement reporting was sparse on the OECD side (~30% of post-2002 rates) — the 2010–2020 primary window is comfortably post-2002, but disbursement MA noise in the 2000–2022 robustness window is documented and not "fixed" (the point of robustness is window-invariance demonstration).

## 3.6 Controls — macro and sector

**Currently ingested (Session 01):**

- *Macro:* GDP per capita (current USD), GDP per capita PPP, GNI per capita, total population (WDI).
- *Education sector (formerly EdStats, now WDI):* pupil-teacher ratio (primary), education expenditure (% GDP, % gov budget), primary completion rate, lower secondary completion rate, gross/net primary enrollment, gross secondary enrollment, out-of-school primary count.

**UNESCO enrollment — self-reporting incentive bias (Phase 10 Pass 1 note).** The enrollment and out-of-school indicators flowing through WDI and UIS ultimately rest on country-side reporting to UNESCO's annual education survey. Ministries of education face well-documented incentives to over-report enrollment and under-report out-of-school children — particularly during MDG (Education for All) and SDG-4 monitoring cycles where these indicators map directly to international compliance scorecards and donor allocation criteria. UNESCO itself has discussed survey-vs-administrative-data discrepancies (UIS technical notes; see also Sandefur 2022 *CGD WP* on the cross-validation of administrative-source enrollment claims against household-survey-derived attendance). This paper treats enrollment / OOS variables as *suggestive* rather than authoritative measures of true schooling participation; the within-country FE specification (Model 2) absorbs time-invariant cross-country reporting-bias differences, but year-on-year within-country fluctuations may still reflect reporting-effort changes (e.g., new SDG-4 cycle, change of government, donor compliance audit) as much as real schooling-participation changes. This caveat lives in the §6 limits paragraph; we do not adjust for it because the available correction is qualitative judgment, not data we have.

**Governance (ingested Phase 1 Session 02 via native WGI bundle):**

WGI aggregates for all six dimensions — Voice & Accountability, Political Stability, Government Effectiveness, Regulatory Quality, Rule of Law, Control of Corruption — fetched from the native multi-sheet Excel bundle at info.worldbank.org/governance/wgi/, **not** via the WDI R package. The native bundle retains the `n_sources` count per country-year, which is the minimum information needed to acknowledge the Langbein & Knack (2010) aggregation critique in this section of the manuscript.

**Locked decision:** [ADR-0009](decisions/0009-wgi-operationalization.md) — Accepted (Phase 5 Session 05, 2026-05-19). **Option 1 (PCA-collapsed first principal component) is primary**, with single Government Effectiveness (Option 2) and all-six-aggregates (Option 3) reported as parallel robustness. PC1 is computed via `stats::prcomp(scale. = TRUE)` on the six WGI estimate columns (VA, PV, GE, RQ, RL, CC), sign-flipped to align with positive governance-quality direction. Empirical Langbein-Knack engagement: PC1 captures **76.4% of WGI variance** (PC2 adds 10.9%, PC3 adds 6.5%); all six loadings positive in the 0.35-0.45 band; per-dimension coefficients in the all-six spec wash out (none individually significant at p < 0.10 despite joint significance), directly confirming the L-K aggregation critique on this sample. Max VIF on demeaned regressors in the all-six spec = 4.71 (below ≤5 viability threshold). β_ODA increases from 8.17 (single GE, p=0.10) to 11.1 (PC1, p=0.048) as the WGI representation broadens — broader WGI captures more confounding variance that single-GE under-controls. Evidence at `output/tables/model2_wgi_specs.csv`, `model2_wgi_vif.csv`, `model2_wgi_pca_loadings.csv`.

**Correlation structure observed (Phase 3 Session 02 supplementary EDA).** Pearson correlations across 13 Model-2 candidate variables (country-level means within primary window; flow variables log-transformed) reveal the binding multicollinearity for ADR-0009: governance effectiveness (WGI) correlates with log(GDP/cap) at r = 0.79, and both correlate strongly with HLO and LAYS (r > 0.6). Model 2 specifications including both will likely show VIF > 5–7 for the pair. Full matrix at `output/tables/correlation_matrix_primary.csv`; visualized at `output/figures/eda/correlation_heatmap.png`; full analysis in [`findings.md § 4.7`](findings.md#47-control-variable-correlation-structure-session-12).

**Schooling structure (ingested Phase 1 Session 03):**

UIS private expenditure share + out-of-school rates by sex × level. Source: UNESCO Institute for Statistics SDG bulk download (Feb 2026 release). Scope is deliberately *minimal* — only what WDI doesn't already cover (private expenditure + OOS detail) to avoid duplication.

**SSA missingness pattern characterized** (`output/tables/ssa_uis_missingness.csv`):
- **Private expenditure as % GDP**: 91.8% missing in SSA vs 80.3% rest of world (+11.6pp). Variable is **effectively unusable** for SSA-inclusive primary specifications.
- Lower / upper secondary OOS: SSA worse by 10.9 / 13.3 pp
- Primary OOS rates: SSA modestly better than rest of world (UN universal-primary monitoring focus)

This empirical pattern feeds [ADR-0006](decisions/0006-uis-missingness-strategy.md) (locked in Phase 2 after MCAR test): the strong working preference is the primary specification uses **WDI controls only** with UIS-augmented specs as listwise-complete robustness.

## 3.7 Confounders — conflict and COVID

The brief's self-review identifies conflict and COVID-era disruption as time-varying confounders that must be controlled for in Model 2. Two additional sources are ingested in Phase 1 Session 07:

- **UCDP/PRIO Armed Conflict Dataset (country-year)** — binary in-conflict indicator + battle-related deaths intensity. Cited as Pettersson, Davies et al.
- **UNESCO COVID-19 School Closures** — total + partial closure days per country, 2020–2022. Controls for differential school closure exposure across countries during the pandemic.

**Ingest done (Phase 1 Session 07).**

*UCDP* (`data/interim/ucdp.parquet`): country-year panel aggregated from UCDP/PRIO ACD v25.1 + BRD v25.1 (conflict-level). 7,470 rows × 10 columns × 249 countries × 1995–2024. Binary `in_conflict` plus `intensity_max` (1=minor/2=war), `n_conflicts`, `internal_armed` and `internationalized` flags, and summed `bd_best`/`bd_low`/`bd_high` from BRD. Multi-country conflicts expanded via `gwno_loc` (Gleditsch-Ward numeric codes, comma-space separated). Panel filled with 0s for country-years with no conflict observation. **918 country-years had active conflict (12.3% of cells)**; conflict prevalence **SSA 25.3% vs Rest 9.2%** — gap **+16.1 pp**, reaffirming the well-established SSA over-representation. The UCDP BRD 25-deaths threshold is documented behavior (low-intensity violence below 25 battle deaths/conflict-year is excluded by UCDP construction). Two GW codes required overrides: 678 ("Yemen (North Yemen)" → YEM, captures the post-unification state and 2014+ civil war) and 345 ("Serbia (Yugoslavia)" → SRB, captures the 1998-1999 Kosovo war).

*UNESCO COVID closures* (`data/interim/covid_closures.parquet`): country-year totals derived from the daily Status time-series on HDX (`covid_impact_education.csv`, 169,051 rows). 630 (iso3, year) rows × 8 columns × 210 countries × 2020–2022. Columns: `days_closed` (Status = "Closed due to COVID-19"), `days_partial`, `days_open`, `days_break`, plus `first_closure_date` and `last_closure_date`. Derivation method is **transparent** — counts of daily Status values, not UNESCO's pre-aggregated numbers. Cross-validated against UNESCO's pre-aggregated `duration-of-school-closures-31-march-22.xlsx` (weeks rounded ×7): median |diff| = **2 days**, max |diff| = **33 days** for full closures; the tiny disagreements are rounding noise from UNESCO's week-level reporting. Median country had **116 days** of full closure over 2020-2022; max **556 days** (out of ~770 monitoring-window days).

## 3.8 Empirical strategy — five models

The brief specifies five models, each pre-registered in the research design before any ingestion. All five are below in compact form; full specifications live in `docs/brief.md § Statistical Architecture`.

### Model 1 — OLS baseline (cross-sectional)

$$Learning_i = \beta_0 + \beta_1 ODA_i + \beta_2 GDPpc_i + \beta_3 PTR_i + \varepsilon_i$$

Purpose: establish the naive cross-sectional association that the rest of the paper challenges.

**Estimated (Phase 4 Session 01).** Six sequential-add specifications on country-level means across primary window 2010–2020; HC-robust SE; N varies 120–133 by listwise completeness. Headline ODA coefficient drops from −11.54*** (bivariate) to −1.36 (ns) in the full spec — the cross-sectional negative association is fully absorbed by income and governance controls. Full results: [`findings.md § 5.1`](findings.md#51-model-1--cross-sectional-ols-baseline-phase-4-session-01); regression tables at `output/tables/model1_ols_baseline.{csv,md}` and the LAYS-outcome parallel at `output/tables/model1_ols_lays_outcome.{csv,md}`.

### Model 2 — Fixed Effects panel (PRIMARY) + System GMM headline robustness

$$Learning_{it} = \beta_1 ODA_{it} + \beta_2 Expenditure_{it} + \beta_3 Stability_{it} + \alpha_i + \lambda_t + \varepsilon_{it}$$

Country fixed effects ($\alpha_i$) and year fixed effects ($\lambda_t$). The contrast between $\beta_1$ here and in Model 1 is the headline finding. Cluster-robust standard errors at country level. Required diagnostics: Hausman, Wooldridge, Breusch-Pagan, VIF (see [obligations](obligations.md)).

**Estimated (Phase 5 Session 01).** Static two-way FE on the production panel (primary window 2010-2020) with country-clustered SE. Full-spec β = **+10.95 (SE 3.60, p = 0.003, N = 143)** — large, positive, statistically significant. Cross-sectional Model 1 full-spec β = −1.36 ns; the **β_OLS vs β_FE contrast flips sign and amplifies ~8×** when within-country FE is applied. This is the manuscript's central empirical claim. **The brief's falsification standard ("if β_FE is positive, significant, meaningful in magnitude, the thesis fails") is in play.** Diagnostics: Wooldridge AR(1) F = 0.252, p = 0.62 (no serial autocorrelation); Breusch-Pagan χ² = 137, p = 0.004 (heteroskedasticity, addressed by HC-robust + cluster-robust SE); VIF max on demeaned regressors = 1.64 (within-FE absorbs the cross-sectional governance × income multicollinearity Session 12 surfaced); Hausman test deferred (Swamy-Arora RE requires > 3 time periods, HCI cycles provide only 4). Full results: [`findings.md § 5.2`](findings.md#52-model-2--within-country-fe-panel-phase-5-session-01); regression tables at `output/tables/model2_fe_baseline.{csv,md}` + `model2_fe_lays_outcome.{csv,md}`; headline contrast at `output/tables/model1_vs_model2_contrast.md`.

**System GMM attempted (Phase 5 Session 02; [ADR-0010](decisions/0010-identification-strategy-gmm.md) Accepted with caveats 2026-05-19).** Per the Phase-2 external review commitment, we attempted Difference GMM (Arellano-Bond 1991) and System GMM (Blundell-Bond 1998) with cycle-indexed time variable (1=2010, 2=2017, 3=2018, 4=2020) — calendar-year lag operators fail because HCI cycle spacing is non-uniform (2010→2017 = 7yr; 2017→2018 = 1yr). **Results:** Difference GMM minimal-spec runs cleanly on Hansen (p = 0.498) but gives β = +0.601 ± 10.6 (CI brackets everything). System GMM minimal-spec runs but Hansen overid p = 0.022 rejects instrument validity. Diff/Sys GMM full specs fail to estimate (matrix singularity with T = 3 after listwise on full controls). Bond (2002) consistency bounds (Pooled OLS-LDV + LSDV) are degenerate — lagged-DV soaks up essentially all variance leaving zero coefficient on log(1+CRS). **The HCI-cycle measurement frequency (T ≤ 4 effective points per country) is below the GMM literature's minimum** (Bond 2002 recommends T ≥ 5-10). Asongu (2019) GMM-aid applications use T ≥ 15-20 annual observations; we cannot replicate that machinery on harmonized learning outcomes. Static FE remains the headline; § 3.8 + § 6 own this identification limit transparently. Full triangulation at `output/tables/model2_identification_triangulation.md`; [`findings.md § 5.3`](findings.md#53-model-2--system-gmm-identification-triangulation-phase-5-session-02).

**System GMM headline robustness ([ADR-0010](decisions/0010-identification-strategy-gmm.md), Pending — locks Phase 5 Session 1).** A static-FE-only specification draws the canonical *World Development* / aid-effectiveness referee critique: donors target deteriorating learning (reverse causality), and country FE doesn't catch time-varying confounding. Added per Phase-2 external review. Implementation via `plm::pgmm` or `pdynmc` with full Roodman (2009) diagnostics: Hansen overid p-value reported (target p > 0.10, < 0.99 to avoid weak-instrument false-clean tests); AR(1) p < 0.05 expected, AR(2) p > 0.10 required; instrument count < N managed via `collapse=TRUE` and lag-limit. Difference GMM (Arellano-Bond) reported alongside as a triangulation check. Sign-and-magnitude consistency across static FE / Difference GMM / System GMM is the substantive identification defense; divergence (if it occurs) is the §6 Discussion point.

Power / minimum-detectable-effect calculations reported per Model-2 coefficient — with n≈173 complete rows for the primary spec, thin-data caveats are owned explicitly rather than absorbed into wide CIs.

### Model 3 — 2-level RE-vs-FE (reframed from brief)

**Reframed per Phase-2 external review.** The brief's "students nested in schools nested in countries" is not supportable on country-year aggregate data; PISA/TIMSS/PIRLS student-level microdata is deferred (per [`plan.md`](plan.md) § Phase 1 stretch). Model 3 becomes a 2-level country random intercepts + time FE specification, with a formal Hausman test of FE vs RE — directly justifying the Model 2 FE choice and reporting the RE counterpart for transparency. ICC at the country level is reported; the brief's "30/30 rule" doesn't apply to country-cycle aggregates.

**3-level HLM scope decision (Phase 10 Pass 1, 2026-05-23) — supersession made explicit.** The brief's Statistical Layer obligations include "ICC at all three multilevel model levels" and "Convergence diagnostics for HLM", which were written assuming the original 3-level student-school-country specification. The Phase-2 reframe (this section) collapsed the multilevel structure to 2-level country RE + year FE because the student-level microdata that the 3-level spec would require is deferred per `plan.md` Phase-1 stretch. The downstream consequence for the obligations checklist: (a) "ICC at three levels" becomes "ICC at country level only — the single non-trivial random-effect level in the reframed spec" (reported `findings.md §5.4`: unconditional 91.2%, conditional 79.3%); (b) "Convergence diagnostics for HLM" collapses to the `isSingular()` check already in `R/57_model3_re_panel.R` (no singular fits across the 10 specs run). Both obligations are *satisfied within the reframed scope* — `obligations.md` carries an explicit annotation pointing to this paragraph. If a future revision restores the 3-level structure (e.g., via PISA/TIMSS/PIRLS microdata acquisition), the brief's original 3-level ICC + HLM-convergence obligations come back into scope as-written.

**Empirical lock (Phase 6 Session 01, 2026-05-19).** Model 3 estimated via `lme4::lmer` on the locked encoding (Session-03 treatment + Session-05 WGI PC1) with country random intercepts and year fixed effects. **Headline spec 3e on HLO: β=−1.32, SE=2.68, p=0.622, N=173** — Model 3 RE has *collapsed onto Model 1's cross-sectional estimate* (β=−1.36) rather than splitting the difference with Model 2 FE (β=+11.14). This is the empirical signature of an **extreme country-level ICC: 91.2% unconditional** (`performance::icc()`), 79.3% adjusted after controls. The variance-component structure puts essentially all weight on between-country variation, mechanically replicating the OLS estimate. **Manual univariate Cameron-Trivedi Hausman: H=6.67, df=1, p=0.0098 — formally rejects RE in favor of FE.** `plm::phtest` not estimable (Swamy-Arora requires T > 3; HCI cycles give T_eff ≤ 3-4 — same failure as Sessions 14/06). Model 2 FE is the identified specification; Model 3 RE is the transparency counterpart. The brief's Phase-2 reframe is fully validated. Full Model 1/2/3 three-way contrast in `findings.md §5.4` and `output/tables/model123_three_way_contrast.csv`.

### Model 4 — Dropped (Phase 7 Session 01, 2026-05-23)

The brief specifies a one-way ANOVA on a four-bucket intervention typology (infrastructure / teacher training / curriculum-materials / budget support) coded from CRS project descriptions. [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) pre-committed to a binding lock gate — raw agreement ≥ 85 %, Cohen's κ ≥ 0.70, rule-based unclassified < 30 % — between a rule-based classifier and a purpose-code-mapping comparator. `R/61_typology_coding.R` ran on 2026-05-19; all three criteria failed (39.04 %, 0.19, 75.68 % respectively; full evidence at `output/tables/typology_method_agreement.md`). Per the binding protocol the next step was Option 3 (hand-coding ~1000 stratified projects). The author decision (2026-05-23) was to honor the pre-commitment, drop Model 4 rather than escalate, and report the failed gate as evidence rather than an obstacle. The paper's empirical headline reduces to Models 1–3 plus Model 5 (counterfactual). See `findings.md §5.5` and [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected for the full reasoning trail.

### Model 5 — Counterfactual simulation (locked Phase 8 Session 01, 2026-05-23)

**Locked specification:** [ADR-0011](decisions/0011-counterfactual-specification.md). Marginal within-support counterfactual on Model 2 spec 2e's aggregate within-country β on `crs_disburse_usd_defl_ma3_lag1` (β = 11.14, SE = 5.52, p = 0.048, N = 143). Three within-support percentage shocks (+10 %, +50 %, +100 %) applied to the median estimation-sample country (baseline = $59.7M annual CRS, constant USD millions) × three β-CI scenarios (lower 95 % / point / upper 95 % = 0.32 / 11.14 / 21.95) = nine ΔHLO cells. Each cell translated to ΔLAYS via the WB identity ΔLAYS = EYS × ΔHLO / 625, holding EYS constant, at three implied-EYS percentiles (p10 = 7.25 yr, p50 = 11.57 yr, p90 = 13.18 yr, derived from the LAYS-identity inversion EYS = LAYS × 625 / HLO on the estimation sample). Baseline-quartile sensitivity (Q1 / Q2 / Q3 = $23.7M / $59.7M / $123.7M) reported alongside. CI propagation is plug-in on β only, not full Monte Carlo over joint regressor covariance — a documented limit honoring the static-FE inference base ([ADR-0010](decisions/0010-identification-strategy-gmm.md)).

**Brief-bridge honoring without extrapolation.** The brief's "$1B redirect from input-based to outcome-based" framing cannot be honored literally: (a) Model 4 is dropped, so no input-vs-outcome effect sizes exist (see §5.5, [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected); (b) a literal $1B injected into a single aid-receiving country would be a 17× shock above the median baseline, far outside the within-country log-CRS support the β was identified on. The brief's $1B is therefore *translated*: distributed across the 173-country reconstructed estimation sample, it equals $5.78M per country (≈ 9.7 % of the median baseline and ≈ 5.49 % of total annual sample CRS = $18.22B). It lands in the **low-shock band** of the headline table, not the high-shock band. Reported transparently in `output/tables/model5_counterfactual.md` and in `findings.md §5.6`.

**Limits inventory** (per brief's "acknowledge limits" requirement, locked in ADR-0011):
- Static-FE small-T identification (T_eff ≤ 4); GMM unavailable per [ADR-0010](decisions/0010-identification-strategy-gmm.md).
- Aggregate-β counterfactual only; composition (input-vs-outcome bucket allocation) unanswered per §5.5 and [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) Rejected.
- Single-cycle marginal projection (≈ 5 yr); no inter-temporal discounting; not a steady-state forecast.
- Plug-in CI on β only; joint regressor covariance not propagated.
- LAYS identity holds EYS constant; sensitivity reported across p10/p50/p90 of implied EYS.
- Implementation quality, political economy, absorptive capacity caveats per brief §2.

## 3.9 Missing data strategy

**Locked decision:** [ADR-0006](decisions/0006-uis-missingness-strategy.md) — **Accepted 2026-05-18**.

**Option 3: drop UIS controls from the primary specification.** Primary uses WDI controls only (`wdi_edu_exp_pct_gdp`, `wdi_ptr_primary`, `wdi_gdp_pc_usd`) + WGI governance. UIS-augmented spec is reported in **Robustness 1** on the listwise-complete subset. **Robustness 2 (MI) retired** by [ADR-0012](decisions/0012-retirement-of-uis-multiple-imputation.md) — MCAR rejected at p ≪ 10⁻⁶ → MAR assumption unsupported; CLAUDE.md no-fabrication principle creates explicit conflict with MI; listwise covers same robustness direction.

**Robustness 1 result (Phase 10 Pass 1, 2026-05-23):** refit Model 2 spec 2e with `uis_priv_exp_pct_gdp` added to the regressor stack on the listwise-complete subset. **N = 41 post-singleton-drop; β_ODA = −1.97 (SE 4.40, p > 0.05).** The ODA coefficient is sign-flipped vs primary's +11.14 but non-significant; the 95% CIs partially overlap (primary [0.32, 21.95]; listwise [−10.59, 6.66]). The UIS covariate's own coefficient β = +24.15 (SE 17.37, p = 0.18) is null on this thin sample. This is *weak robustness* on a small sample dominated by listwise selection — reported alongside the primary in `findings.md §5.8` and `output/tables/pass1_uis_listwise.{csv,md}`. The manuscript should report it transparently rather than treat the primary as strongly UIS-robust; the §6 limits paragraph owns the UIS-missingness sample-size constraint openly.

**Empirical basis** (Phase 2 Session 01, production panel `data/interim/panel.parquet`, primary window 2010–2020 = 1,463 rows):

| Subset | N rows | Complete rows | χ² (df) | p | Patterns |
|---|---|---|---|---|---|
| 6-col primary (HLO + 3 WDI + CRS + WGI) | 1,463 | **173** | 175.80 (41) | < 0.000001 | 12 |
| 7-col +UIS (private expenditure) | 1,463 | **69** | 341.90 (84) | < 0.000001 | 20 |

Both reject MCAR strongly; adding UIS drops the analytical sample by 60% (`output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`). The 7-col pattern is structurally SSA-biased (UIS private-expenditure missingness +16.9 pp in SSA vs non-SSA on the production panel; `output/tables/production_ssa_panel_missingness.csv`).

Earlier Phase-1 audit-panel MCAR (Session 09, `output/tables/mcar_test_result.txt`) ran on the unfiltered 250-country audit panel using `crs_commit_usd_sum` (current-USD commitment) and reported χ² = 1216, df = 68; that result is preserved for the audit trail but not the analytical-pipeline finding. The production lock uses `crs_disburse_usd_defl_sum` (production primary intent) on the 133-country universe after the within-universe NA → 0 coalesce.

## 3.10 Intervention typology coding

**Locked decision:** [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) — **Rejected 2026-05-23** (Phase 7 Session 01).

Phase 1 Session 05 ingested CRS *with description text retained*. Phase 7 Session 01 ran `R/61_typology_coding.R` against the pre-committed lock gate (raw agreement ≥ 85 %, κ ≥ 0.70, rule-based unclassified < 30 %); all three criteria failed (39.04 %, 0.19, 75.68 % — evidence at `output/tables/typology_method_agreement.md`). The author honored the no-post-hoc-tuning discipline and dropped Model 4 rather than escalate to Option 3 (hand-coding). The CRS description-text columns remain in the interim parquet for raw-data fidelity but no longer feed an active analysis path. The negative result itself is a §6 Discussion point: the four-bucket typology that the development-aid effectiveness literature (Glewwe-Muralidharan 2016) treats as the natural taxonomy is *not recoverable from OECD CRS project metadata at a defensible inter-method agreement* — an empirical limit on what cross-country panel evidence can say about intervention-type allocation.

## 3.11 Chinese aid inclusion

**Locked decision:** [ADR-0008](decisions/0008-china-aid-inclusion.md) — Accepted (Phase 5 Session 04, 2026-05-19).

**Lock: Option 2.** OECD CRS disbursement is the primary treatment (per ADR-0005 lock: `crs_disburse_usd_defl_ma3_lag1`); AidData GCDF reported as parallel robustness. The pre-specified lock criterion — "if the within-country OECD coefficient changes sign or magnitude when GCDF is added, OECD-only is biased" — is empirically satisfied. Adding GCDF as a separate covariate shifts the OECD β from 8.17 (Session-03 lock) to 8.06 (Session-04 spec B) — a 0.02 SD movement, well within the ±1 SD criterion. GCDF's own coefficient is null (β = −0.27, p = 0.74). Conclusion: the OECD-CRS-only headline is robust to the non-DAC blind spot at static-FE specification. Evidence at `output/tables/model2_china_robustness.csv` and §5.2.2 of `findings.md`.

**Ingest done (Phase 1 Session 06).** AidData GCDF v3.0 (China-only, 2000–2021, TUFF methodology) is on disk at `data/interim/aiddata_gcdf.parquet` — **2,654 project-level rows × 30 columns × 138 recipient countries**. Filtered to `Sector Name = "EDUCATION"` and `Recommended For Aggregates = "Yes"` at ingest (per the GCDF 3.0 codebook; the recommended-aggregates filter avoids umbrella double-counting). Year filter on `Commitment Year` in 1995–2024 (effective 2000–2021). Phase 5 primary uses OECD CRS only; GCDF as headline robustness for the with-vs-without-China sensitivity. AidData Core Research Release v3.1 is **not** ingested — frozen 2016 release ending 2013 gives only marginal overlap with the HLO-usable 2010+ window (author decision Session 06).

**Empirical SSA headline** (the non-DAC blind spot, quantified): China funds education projects in **47 of 48** SSA countries; **1,131 projects** worth **$5.61 B constant USD 2021**. That is **60.4% of all Chinese education aid** ($9.29 B total) over the period. SSA coverage of China's education portfolio is **45.8%** of country-year cells vs **32.7%** for the rest of the world — a **+13.1 pp gap**. China systematically concentrates education aid in SSA more than elsewhere. This is the structural non-DAC blind spot in OECD CRS made concrete; §6 Discussion cites these numbers, not generalities. SSA-coverage contrast at `output/tables/ssa_aiddata_gcdf_coverage.csv`.

## 3.12 Robustness checks (cumulative list)

As decisions accumulate, this list is the running register of robustness specifications the paper commits to running:

- [ ] HLO measure: WB current vs AAP-2018
- [ ] ODA: disbursement vs commitment; 1-year vs 3-year MA
- [ ] Sample: 2000–2022 vs 2005–2020
- [ ] Sample: with vs without China-affected recipients
- [x] UIS missingness: listwise vs MI vs UIS-dropped — locked [ADR-0006](decisions/0006-uis-missingness-strategy.md) Option 3 (drop UIS from primary); UIS-augmented listwise + MI reported as robustness
- [ ] ANOVA coding: rule-based vs LLM-assisted (agreement rate ≥ 85%)
- [ ] Country FE structure: country FE alone vs country × decade FE
- [ ] Lag structure: contemporaneous ODA vs 3-year MA

### Supplementary measure: Oxford Insights AI Readiness (Phase 9 input)

The brief commits to a **Phase-9 "Compounding AI Penalty" section** (line 159: *"Constructed variable: Human Capital Index × AI Readiness Index. No prior paper has done this."*). The Oxford Insights Government AI Readiness Index 2025 (GARI) provides the AI Readiness side. Ingested in Phase 1 Session 08 from the 2026-01-29 PDF release via `pdfplumber`-based table extraction (no machine-readable export exists). The 195-country table has rank + 6 pillar scores (Policy Capacity, AI Infrastructure, Governance, Public Sector Adoption, Development & Diffusion, Resilience) but **no overall composite**; we derive `ai_readiness_score_mean` as an equally-weighted pillar mean and clearly label it as derived. Stored at `data/interim/ai_readiness.parquet` with `year = 2025` for join compatibility (cross-sectional in our use, not a time-varying variable).

**Phase-9 preview** (`cor(ai_readiness_score_mean, hci_overall)` on the 189-country join): **r = 0.777**. The strong positive correlation between human capital and AI readiness is the empirical face of the compounding-penalty thesis — Phase 9 partitions the joint distribution and quantifies the count + share of low-HCI ∩ low-GARI countries.

**Phase-9 implementation (Session 01, 2026-05-23).** For each country we take the **latest non-missing HCI cycle** observation (in practice this is HCI 2020 for all 132 joined countries, as the 2020 cycle is the most complete). GARI is its 2025 cross-section. The composite is `compound_index = hci_overall × (gari_score_mean / 100)`, both axes normalized to [0,1]. **Quadrants** are assigned by sample-median split on each axis; the "double-excluded" cell is `low_hci ∩ low_gari`. **Robustness:** the same partition is re-run using sample terciles and using HCI cycle 2018 only as a pre-COVID anchor — the HCI-2018 specification overlaps the headline median-split set at Jaccard = 0.94 (very stable); the tercile-split Jaccard is 0.53, which reflects the mechanical fact that tercile cells are smaller, not that the headline is fragile. **Front-loaded caveat:** with r = 0.777 between HCI and GARI on the joint sample, the "low-low" cell is partly tautological with "low overall HCI/GARI quality"; the residual 22% of variance is where the *interaction* claim would have empirical bite, but we cannot test the multiplicative-vs-additive distinction at this paper's data shape (HLO/LAYS are embedded in HCI; GDP growth needs its own identification story; the compounding *thesis* is about *future* divergence we cannot observe yet). The section therefore reports a *joint-distribution characterization* — not a "compounding effect" econometric estimate. Limits: cross-sectional GARI 2025 snapshot; static HCI cycle anchor (no panel dynamics); descriptive only; interaction-test deferred to §6 Discussion as out-of-scope for the data shape we have. Implementation at [`R/71_compounding_ai_penalty.R`](../R/71_compounding_ai_penalty.R); evidence at `output/tables/compound_ai_penalty_*.{csv,md}` and `output/figures/compound_ai_penalty_scatter.{pdf,png}`. See also `findings.md §5.7`.

## 3.13 Positionality

See `docs/positionality.md` for the working draft. Final placement in the manuscript: end of §3 (Methodology). Position framed as a methodological asset — practitioner observation of incentive structures not captured in administrative datasets, used to ground qualitative interpretation in §6 Discussion.

---

## Methodology obligations (cross-reference)

The full list of diagnostics and tests we have committed to running is in [`obligations.md`](obligations.md). Each item there links back to the relevant ADR or methodology section above.
