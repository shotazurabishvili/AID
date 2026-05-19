# Findings — Working Narrative

> *This document is the proto-§4 / §5 / §6 of the manuscript. It accumulates substantive empirical findings as they are discovered, organized by eventual manuscript section. Each finding: short claim, key numbers, evidence pointer (CSV/figure/session log/ADR). When Phase 11 (Writing) begins, much of `drafts/paper.qmd § 4-6` is a refactoring of this file.*
>
> *Parallel to [`methodology.md`](methodology.md) (proto-§3) and [`positionality.md`](positionality.md) (proto-§3 positionality). Updated at session end alongside the session log — see [`CLAUDE.md`](../CLAUDE.md) end-of-session protocol.*
>
> *Last updated: 2026-05-19 (Session 13 close — Phase 4 Session 01; §5.1 populated with Model 1 OLS baseline)*

---

## §4.1 Sample, period, and coverage

**Final analytical universe: 133 countries.** ODA-eligible (received any positive OECD CRS commitment in 1995–2024) ∩ has ≥1 HLO observation. Reproducible from raw sources without a separate DAC-list ingest. Of these, **127 are within-country FE identifiable** (have ≥2 HLO observations in 2000–2022).
> *Source:* [ADR-0002](decisions/0002-country-universe.md); `output/tables/country_universe_candidates.csv`; [session 09](session_log/2026-05-18-09-audit.md)

**Primary window 2010–2020 (HCI-cycle-anchored).** All three candidate windows (2000–2022, 2005–2020, 2010–2020) yield *identical* Model-2 samples — HLO sparsity is the binding constraint, not window choice. 156 full-row cells × 163 countries × 589 HLO observations across all three; 2010–2020 maximizes useful-cell density (5.67% vs 2.71% for 2000–2022).
> *Source:* [ADR-0003](decisions/0003-year-range.md); `output/tables/year_range_viability.csv`; [session 09](session_log/2026-05-18-09-audit.md)

**HLO is observed only in 4 HCI cycles** (2010, 2017, 2018, 2020) across 133 universe countries. All 133 have a 2020 observation (most recent cycle). The "thin slope" reality is owned in [§3.4](methodology.md#34-outcome-variable--learning) and the manuscript power statement.
> *Source:* [session 04](session_log/2026-05-17-04-hlo.md); `output/tables/year_range_viability.csv`

**Universe distribution by World Bank region** (production panel, 133 countries):

| Region | n countries | Share |
|---|---|---|
| Sub-Saharan Africa | 42 | 32% |
| Latin America & Caribbean | 26 | 20% |
| East Asia & Pacific | 24 | 18% |
| Europe & Central Asia | 18 | 14% |
| Middle East & North Africa | 16 | 12% |
| South Asia | 7 | 5% |

> *Source:* `output/tables/table1_descriptives.md`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

---

## §4.2 The enrollment–learning divergence (paper headline visual)

**Enrollment is uniformly high (98–109%) across all six WB regions** in 2010–2020. HLO score and LAYS show 82-point and 4.3-year spreads respectively. Enrollment has converged; learning has not.
> *Source:* `output/tables/table1_descriptives.md` rows "Gross primary enrollment (%)" + "HLO score (HCI HLOS)" + "LAYS (years)"; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

**2020 cross-section: R² = 0.021 between gross primary enrollment and HLO score** (n = 106 countries with both indicators non-NA). OLS slope = **−0.65** HLO points per 1pp enrollment increase (p = 0.13, not significant). Enrollment "explains" ~2% of cross-country learning variance; the bivariate relationship is essentially null and trends slightly *negative*.
> *Source:* `output/tables/divergence_2020_summary.txt`; `output/figures/eda/enrollment_vs_learning.{pdf,png}`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

**Named-country contrasts** (2020 cross-section, the paper's §4.2 narrative anchors):

| Country | Enrollment | HLO | Reading |
|---|---|---|---|
| **Kenya** | 92% | **455** | Lower enrollment, *higher* learning — inverts the global pattern |
| Brazil | 106% | 413 | High enrollment, modest learning |
| India | 101% | 399 | High enrollment, middling learning |
| Indonesia | 101% | 395 | High enrollment, middling learning |
| **Bangladesh** | **110%** | 368 | Over-100% gross enrollment, low learning — brief's headline contrast country |
| Egypt | 96% | 356 | Moderate enrollment, low learning |
| Nigeria | 84% | 309 | Low enrollment AND low learning |

The Kenya–Bangladesh pair is the empirically cleanest illustration of "enrollment is celebrated, learning is not delivered." Kenya enrolls ~90% of students *and* teaches them substantially better than Bangladesh, which enrolls ~110% (gross) but produces lower test scores.
> *Source:* `output/tables/divergence_2020_summary.txt`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

---

## §4.3 Region-level patterns (Table 1 highlights)

**Sub-Saharan Africa carries the heaviest aggregate burden:**
- Lowest HLO score: **374** (vs ECA 456 — an 82-point gap; +0.55 SD on the within-universe scale)
- Lowest LAYS: **4.9 years** (vs ECA 9.2 years — almost 2× gap)
- Highest pupil-teacher ratio (primary): **40.6** (vs ECA 16.4 — 2.5× gap)
- Worst primary completion: **70%** (vs ECA 97%)
- Highest primary out-of-school rate: **18.6%** (vs ECA 4.2%)
- Lowest governance effectiveness (WGI): **−0.79** (vs ECA −0.14)
- Largest CRS donor count per country-year: **23.4** (vs LAC 17.3)

> *Source:* `output/tables/table1_descriptives.md`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

**South Asia (n = 7 countries) carries the heaviest concentrated aid burden:**
- Highest CRS education ODA: **$349M** per country-year (India dominates; vs MENA $144M, SSA $78M)
- Highest CRS donor count: **29.7** distinct donors per country-year (vs total panel mean 19.5)
- Highest active-conflict prevalence: **45.5% of country-years** (vs panel 19.8%)
- Longest COVID-19 school closures: **179 days** in 2020 (vs EAP 73 days)

> *Source:* `output/tables/table1_descriptives.md`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

**Europe & Central Asia is the "high-functioning low-aid" comparator:**
- Highest HLO, highest LAYS, lowest PTR, best primary completion (97%), best governance
- Lowest CRS education ODA: **$45M** per country-year
- Lowest GCDF Chinese education aid: $1.8M per country-year
- Modest active-conflict prevalence: 8.6%

> *Source:* `output/tables/table1_descriptives.md`

**MENA shows the only large within-region HLO outlier**: Egypt 356 (low), Jordan etc. 405+ (mid). Worth disaggregating in §4.4 supplementary.
> *Source:* `output/tables/table1_descriptives.md`; eyeball of the divergence figure (`output/figures/eda/enrollment_vs_learning.png`)

### Regional trajectories 2010–2020 (Session 12 supplementary)

**HLO regional means show non-monotonic temporal patterns dominated by cycle-composition changes** (`output/figures/eda/regional_trajectories.png` Panel A). The 2010 HCI cycle included 119 of the 133 universe countries; 2020 includes all 133 — so region means at different cycle years are computed over different country subsets. Most striking shift: **East Asia & Pacific HLO mean dropped 56 points (473 → 417) between 2010 and 2020** — almost certainly a composition effect (Korea, Singapore, and other high-performing EAP countries graduated out of the universe over time, while lower-performing EAP countries entered via later HCI cycles). The figure caption documents this caveat; reading the slope as a learning *deterioration* would be misleading. Sub-Saharan Africa shifted −22 points (395 → 374) over the same window; ECA was roughly stable (+6 points). South Asia has no 2010 observation (HCI cycle membership only from 2017+ for that region).
> *Source:* `output/figures/eda/regional_trajectories.png`; [session 12](session_log/2026-05-19-12-eda-supplementary.md)

**Gross primary enrollment trajectories are flat across all regions** (Panel B). Already-saturated enrollment landscape: 2010-2020 region means hover in a 95-110% band per region throughout the window. Reinforces the "enrollment expansion is over" Discussion thread (§6); the SDG era cannot rely on enrollment as a growth lever because there's no expansion left to harvest. The slight downward drift visible 2018-2020 in several regions is likely COVID-related undercount in WDI reporting.

**GDP per capita trajectories show modest within-region growth** (Panel C). ECA + EAP rising fastest; SSA + South Asia flat at low levels (~$2-3k); MENA stable at high middle-income level (~$13k). No cross-region convergence over the decade.

**OECD CRS aid trajectories: South Asia dominates volume** (Panel D). India's mass drives the South Asia panel ($350M+ average per country-year, much of it India). SSA, MENA, LAC, EAP all bunched between $50-150M; ECA lowest at $45M (graduated-recipient effect).

### Income-group stratification (Session 12 supplementary)

The income gradient is **even sharper than the regional gradient** for outcomes (`output/tables/table1_by_income.md`):

| Variable | Low income | Lower-middle | Upper-middle | High income | Total |
|---|---|---|---|---|---|
| HLO score | **354** | 386 | 415 | 456 | 403 |
| LAYS (years) | — | 6.2 | 7.9 | **9.4** | 6.9 |
| GDP per capita | (low) | 2,276 | 6,367 | **23,984** | 7,138 |
| Pupil-teacher ratio | (high) | 31.6 | 20.1 | **14.3** | 27.5 |
| In active conflict | (high) | 19.6% | 14.0% | **2.8%** | 19.8% |
| OECD CRS aid (USD M) | (high) | 143 | 92 | **8** | 96 |
| GCDF Chinese aid (USD M) | (mod) | 6.1 | 2.1 | **0.2** | 3.3 |

HLO spread Low → High = **102 points**, vs the region spread (SSA → ECA) of 82 points. LAYS spread is ~5.4 years across income groups. Aid intensity inverts as expected (graduated High-income countries get ~$8M CRS aid per country-year vs $143M for Lower-middle). Conflict prevalence drops 7× across the income gradient (19.6% → 2.8%). **Caveat: the High income bucket (n=23) comprises graduated ODA recipients** like Chile, Argentina, Korea — countries that received aid in 1995–2024 but are now classified high-income by WB. They are part of our universe by ADR-0002 definition.
> *Source:* `output/tables/table1_by_income.md`; [session 12](session_log/2026-05-19-12-eda-supplementary.md)
> Kosovo (XKX) is the single "Not classified" country: HLO 356, LAYS 4.45 yrs.

---

## §4.4 Treatment-side facts (ODA + Chinese aid)

**OECD CRS bulk parquet: 537,586 project-level rows × 172 recipients × 125 donors × 1995–2024.** Already filtered to education sector codes 110–114 at ingest.
> *Source:* [session 05](session_log/2026-05-17-05-oecd-crs.md); `data/interim/oecd_crs.parquet`

**SSA coverage on commitments and disbursements is excellent** (gap −1.3 / −1.1 pp vs RoW). The standard DAC reporting machinery is *not* the source of SSA invisibility in the data — Chinese aid is.
> *Source:* `output/tables/ssa_oecd_crs_missingness.csv`; [session 05](session_log/2026-05-17-05-oecd-crs.md)

**Pre-2002 OECD disbursement reporting was sparse** (~30% of post-2002 rates; e.g., 1995: 415 disbursement rows vs 1408 commitment rows). Primary window 2010–2020 is comfortably post-2002, but disbursement MA noise in the 2000–2022 robustness window is documented and not "fixed". Robustness purpose is to show window-invariance, not to clean noise.
> *Source:* `R/30_merge_panel.R` header + methodology §3.5; empirical check in [session 10](session_log/2026-05-18-10-production-merge.md)

**AidData GCDF v3.0 (Chinese aid): 2,654 education projects × 138 recipient countries × 2000–2021.** Filtered to `Sector Name = EDUCATION` ∩ `Recommended For Aggregates = Yes`.
> *Source:* [session 06](session_log/2026-05-17-06-aiddata-gcdf.md); `data/interim/aiddata_gcdf.parquet`

**The structural non-DAC blind spot, quantified.** China funds education projects in **47 of 48 SSA countries**; **1,131 projects** worth **$5.61 billion constant USD 2021** — **60.4% of all Chinese education aid** ($9.29B total) over the period. SSA coverage of China's portfolio is **45.8% of country-year cells** vs **32.7% for the rest of the world** — a **+13.1 pp gap**. Chinese aid concentrates in SSA at substantially higher intensity than DAC aid does.
> *Source:* `output/tables/ssa_aiddata_gcdf_coverage.csv`; [session 06](session_log/2026-05-17-06-aiddata-gcdf.md); [ADR-0008](decisions/0008-china-aid-inclusion.md)

**In the production panel (133 universe × 2010–2020 primary window):**
- Mean OECD CRS education disbursement: **$96M** per country-year (constant USD; max ~$1B); GCDF: **$3.3M** per country-year
- SSA's GCDF concentration is **7.4M/country-year vs 0.1–2M elsewhere** — 60–100× higher than MENA, 4× higher than EAP
- South Asia receives the largest aggregate OECD ODA per country ($349M average) due to India dominating

> *Source:* `output/tables/table1_descriptives.md`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

---

## §4.5 Confounder facts (conflict + COVID)

**UCDP/PRIO active-conflict prevalence in primary window: 12.3% of (country, year) cells panel-wide.** SSA 25.3% vs RoW 9.2% — a +16.1pp gap (confirms the well-established SSA over-representation). Two GW-code overrides required: 678 → YEM (post-unification Yemen incl. 2014+ civil war) and 345 → SRB (1998-1999 Kosovo war).
> *Source:* `data/interim/ucdp.parquet`; `R/10_ingest_ucdp.R` header; [session 07](session_log/2026-05-17-07-ucdp-covid.md)

**Active conflict in 2010–2020 by region**: South Asia 45.5%, MENA 34.7%, SSA 27.3%, EAP 14.8%, ECA 8.6%, LAC 3.8%, panel-wide 19.8%. South Asia's conflict prevalence is the highest cross-regionally (driven by Pakistan, Afghanistan, India internal/internationalized conflicts).
> *Source:* `output/tables/table1_descriptives.md`; [session 11](session_log/2026-05-19-11-eda-table1-divergence.md)

**UNESCO COVID school closures (2020 only within primary window):** median 116 days closed; max 556 days. Region means (2020): South Asia 179 days (longest), MENA 134, LAC 152, SSA 100, ECA 85, EAP 73 (shortest). South Asia + MENA experienced ~2.5× the closure exposure of EAP — relevant for the COVID-control story in Model 2.
> *Source:* `data/interim/covid_closures.parquet`; cross-validated against UNESCO pre-aggregated within ±2 days median; [session 07](session_log/2026-05-17-07-ucdp-covid.md); `output/tables/table1_descriptives.md`

---

## §4.6 Phase-9 hook — AI Readiness × HCI

**Oxford Insights GARI 2025: 195 countries.** Extracted from the 2026-01-29 PDF release via `pdfplumber`; no machine-readable export exists. No published overall composite — derived equally-weighted mean of 6 pillars and clearly labeled as derived.
> *Source:* [session 08](session_log/2026-05-17-08-ai-readiness.md); `data/interim/ai_readiness.parquet`

**Compounding-penalty preview**: `cor(ai_readiness_score_mean, hci_overall) = 0.777` across 189 countries that join. Strong positive correlation between human capital and AI readiness — the empirical face of the brief's "Compounding AI Penalty" §9 thesis. Phase 9 will partition the joint distribution and quantify the count + share of low-HCI ∩ low-GARI countries.
> *Source:* [session 08](session_log/2026-05-17-08-ai-readiness.md); `methodology.md §3.12 Supplementary measure`

---

## §4.7 Control-variable correlation structure (Session 12)

Pearson correlations across the 13 Model-2 candidate variables, computed on country-level means within primary window 2010–2020. Skewed variables log-transformed before correlation: log(GDP/cap), log(Pop), log(1+CRS_disburse_defl_MA3), log(1+GCDF_amount_const2021_sum). Other variables (HLO, LAYS, PTR, ed exp %, primary completion, gross enrollment, gov effectiveness, in_conflict, COVID days) used raw.

**Top 5 |r| pairs** (`output/tables/correlation_matrix_primary.csv`):

| Pair | r | Reading |
|---|---|---|
| LAYS — HLO | **0.85** | Tautological by construction (LAYS = EYS × HLO/625); confirms the panel's LAYS column is consistent with HLO — not independent information |
| Gov effectiveness — log(GDP/cap) | **0.79** | Strong institutional-quality / income coupling; ADR-0009 (WGI operationalization) will need to address governance × income collinearity |
| LAYS — log(GDP/cap) | 0.78 | Human capital strongly tracks income — the central correlation the paper challenges via within-country FE |
| PTR primary — log(GDP/cap) | **−0.77** | Higher-income countries have lower pupil-teacher ratios (more teachers per student) |
| Primary completion — LAYS | 0.77 | Quality and completion correlate cross-sectionally; less obviously co-moving within country (Phase 5 will test) |

**Phase-5 VIF prep implications:**
- **log(GDP/cap) is the central confounder.** It correlates ≥0.6 with LAYS, HLO, gov effectiveness, PTR (negatively), primary completion, log(1+CRS), log(1+GCDF). In Model 2 specifications including governance + GDP, expect VIF > 5 for both; consider orthogonalizing or dropping one.
- **WGI governance × log(GDP/cap) r = 0.79** is the binding multicollinearity for [ADR-0009](decisions/0009-wgi-operationalization.md). If Model 2 includes both, VIF likely > 7. Options: (a) drop governance entirely and rely on log(GDP/cap) as the institutional-quality proxy; (b) PCA-collapse the 6 WGI dimensions and use the first principal component (residualized against log GDP/cap); (c) keep governance, drop log(GDP/cap). Phase 5 ADR-0009 lock chooses among these.
- **CRS and GCDF moderately co-target** (r = 0.36 in logs): the same countries that DAC donors prioritize also tend to receive Chinese education aid. Useful context for ADR-0008 (China inclusion) — a regression including both treatments will have moderate but not severe collinearity.
- **In_conflict negatively correlates with most positive outcomes** (HLO r=−0.26, gov effectiveness r=−0.60, primary completion r=−0.27) and positively with COVID closure days (r=+0.21). Treat as an important time-varying covariate.
- **COVID days closed are weakly correlated with everything except in_conflict** — the panel-scale variation in pandemic exposure isn't a function of pre-pandemic structural variables in our universe.

The heatmap (`output/figures/eda/correlation_heatmap.png`) is the Phase-5 prep visual; the manuscript may reproduce it as supplementary or fold the high-|r| pairs into a §3.6 footnote.
> *Source:* `output/tables/correlation_matrix_primary.csv`; `output/figures/eda/correlation_heatmap.png`; [session 12](session_log/2026-05-19-12-eda-supplementary.md); [ADR-0009](decisions/0009-wgi-operationalization.md)

---

## §5 Results

### §5.1 Model 1 — Cross-sectional OLS baseline (Phase 4 Session 01)

**The naive cross-sectional ODA → HLO association is large and negative; it is fully absorbed by income and governance controls.** Across the 133-country ADR-0002 universe over 2010–2020 (country-level means), bivariate OLS shows a strongly significant negative slope of HLO on log(1 + CRS education disbursement). Once log(GDP per capita) enters the specification, ~90% of the coefficient is absorbed; subsequent controls reduce it to essentially zero with wide CIs. This is the "naive association is illusory" pattern the brief predicts.

**Headline coefficients on log(1 + CRS_disburse_defl_sum)** (`output/tables/model1_ols_baseline.md`):

| Spec | β | SE (HC robust) | p | N | R² |
|---|---|---|---|---|---|
| 1a — bivariate | **−11.54** | 2.72 | <0.001 | 133 | 0.154 |
| 1b — + log(GDP/cap) | −1.20 | 2.28 | 0.598 | 133 | 0.397 |
| 1c — + PTR primary | −1.14 | 2.44 | 0.640 | 125 | 0.396 |
| 1d — + ed exp %GDP (brief spec) | −1.79 | 2.60 | 0.493 | 120 | 0.402 |
| 1e — + Gov effectiveness (full) | **−1.36** | 2.48 | 0.584 | 120 | 0.444 |
| 1f — + log(1+GCDF) China-robust | −1.15 | 2.41 | 0.633 | 120 | 0.445 |

**Other full-spec (1e) coefficients:**
- log(GDP per capita): **+9.30** (SE 7.44, ns; was +26.25*** in 1b before WGI entered)
- Pupil-teacher ratio (primary): −0.54 (SE 0.41, ns)
- Govt education expenditure (% GDP): −1.02 (SE 1.59, ns) — note the unexpected negative sign (compositional %-GDP effect)
- **Govt effectiveness (WGI): +24.51***** (SE 8.76, p<0.01) — the dominant cross-sectional correlate of HLO
- Intercept: 359.3*** (SE 75.0)

**VIF diagnostic (full spec 1e):** log(GDP/cap) = 5.24; Gov effectiveness = 2.95; PTR = 2.64; log_CRS_disb = 1.60; ed_exp = 1.13. Only one VIF marginally above 5, on log(GDP/cap) — the inflation comes from its correlation with both governance and PTR, not just governance alone. The Session-12 prediction was directionally right but milder in magnitude than the bivariate r=0.79 suggested.

**Substantive read:**
- The CROSS-SECTIONAL negative association (β = −11.5 bivariate) is **selection-driven**: poorer + worse-governed countries receive more education aid AND have lower HLO scores. Once those structural factors are absorbed, aid intensity has no cross-sectional association with learning outcomes.
- WGI governance dominates the cross-section (β = 24.5, ~0.5 SD HLO per 1-unit WGI), absorbing much of GDP/cap's bivariate effect when added.
- GCDF (Chinese aid) coefficient is essentially zero (β = −0.31, ns) — Chinese aid intensity also doesn't predict learning cross-sectionally.

**The Model 1 → Model 2 contrast is the paper's empirical spine.** Model 1 here establishes the cross-sectional null after controls. Phase 5 Model 2 asks the harder question: does within-country variation in ODA predict within-country variation in HLO? That is the headline result the paper turns on.

**LAYS-outcome parallel** (`output/tables/model1_ols_lays_outcome.md`): same 6 specs with `hci_lays_overall` as DV. LAYS coefficients are a metric translation of HLO results (LAYS = EYS × HLO/625); not independent evidence. Reported for GEEAP / Angrist 2024 comparability per the Phase-2 external review LAYS commitment. Full-spec ODA coefficient on LAYS: −0.018 (ns); the same null-after-controls story in years-of-learning units.

> *Sources:* `output/tables/model1_ols_baseline.{csv,md}`; `output/tables/model1_ols_lays_outcome.{csv,md}`; `output/tables/model1_vif.csv`; `output/figures/eda/model1_coefficient_plot.png`; [session 13](session_log/2026-05-19-13-model1-ols.md)

### §5.2 Model 2 — Within-country FE panel (Phase 5)

**To be populated.** Will report β_FE and the β_OLS vs β_FE contrast (Model 1 vs Model 2) — the headline result. Static FE baseline + Hausman test + Wooldridge + Breusch-Pagan + VIF + cluster-robust SE per [methodology §3.8](methodology.md). Locks [ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md) (commit vs disburse), [ADR-0008](decisions/0008-china-aid-inclusion.md) (China inclusion), [ADR-0009](decisions/0009-wgi-operationalization.md) (WGI operationalization).

### §5.3 Model 2 — System GMM headline robustness (Phase 5)

**To be populated.** Per [ADR-0010](decisions/0010-identification-strategy-gmm.md). Roodman (2009) diagnostics. Sign-and-magnitude triangulation: static FE vs Difference GMM vs System GMM.

### §5.4 Model 3 — 2-level country RE + time FE (Phase 6)

**To be populated.** Per the Phase-2 external-review reframe. Hausman test justifies FE choice for Model 2.

### §5.5 Model 4 — ANOVA on intervention typology (Phase 7)

**To be populated.** Per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md). Levene; Tukey HSD; η²; Cohen's d.

### §5.6 Model 5 — Counterfactual simulation (Phase 8)

**To be populated.** Reported in LAYS units alongside raw HLO points.

---

## §6 Discussion candidates

**Counterintuitive SSA finding: SSA is *better* covered than RoW on the analytical subset** (after the ODA-eligibility universe filter). On the production panel within primary window: SSA missingness on `wdi_edu_exp_pct_gdp` is 11.5% vs RoW 25.1% (−13.5pp); on `crs_disburse_usd_defl_sum` SSA 0% vs RoW 0%; HLO 68.2% vs 70.0% (essentially equal). High-income non-SSA countries (US/EU/Japan/Korea) are *outside* the HLO and CRS-recipient measurement universes; restricting to ODA-eligible recipients (mostly SSA + South Asia + Latin America) makes SSA over-represented relative to non-SSA-but-ODA-eligible peers. **Worth a §6 paragraph on the *structural* SSA over-coverage in development-aid measurement universes** — the regions of richest data are those of richest aid attention.
> *Source:* `output/tables/production_ssa_panel_missingness.csv`; [session 10](session_log/2026-05-18-10-production-merge.md); [ADR-0006](decisions/0006-uis-missingness-strategy.md)

**The Chinese-aid blind spot is structural, not residual.** OECD CRS misses 47 of 48 SSA countries on the China-funded portion of their education portfolios. With 60.4% of Chinese education aid going to SSA, that's not a marginal omission. §6 should cite the +13.1pp SSA-coverage gap and the $5.61B SSA total as concrete numbers, not generalities.
> *Source:* §4.4 above; [session 06](session_log/2026-05-17-06-aiddata-gcdf.md); [ADR-0008](decisions/0008-china-aid-inclusion.md)

**Enrollment expansion is over.** Gross primary enrollment is universally 98–109% across the 133-country universe. The MDG era achieved enrollment convergence; the SDG era cannot rely on enrollment expansion to produce learning gains because there's no enrollment expansion left to harvest. This is the substantive frame for the negative-slope 2020 cross-section finding.
> *Source:* §4.2 + §4.3 above

**Multiple imputation is not a free pass.** The production-panel MCAR test rejects MCAR at p ≪ 10⁻⁶ on both the 6-col and 7-col subsets. Including UIS private-expenditure as a control costs 60% of the analytical sample (173 → 69 complete rows). [ADR-0006](decisions/0006-uis-missingness-strategy.md) locks Option 3 (drop UIS from primary; UIS-augmented listwise + MI as robustness). §6 owns this explicitly rather than burying the missing-data architecture.
> *Source:* `output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`; [session 10](session_log/2026-05-18-10-production-merge.md); [ADR-0006](decisions/0006-uis-missingness-strategy.md)

**Identification limits are real.** The within-country FE coefficient is identified off ≤4 HLO observations per country (HCI cycles 2010/2017/2018/2020). Static FE doesn't fix time-varying endogeneity (donors target deteriorating learning). [ADR-0010](decisions/0010-identification-strategy-gmm.md) adds System GMM as headline robustness in Phase 5; sign-and-magnitude triangulation across static FE / Diff GMM / System GMM is the substantive identification defense. §6 owns the thin-data caveat openly — power calculations reported alongside coefficients per Phase-2 external-review obligation.
> *Source:* [ADR-0010](decisions/0010-identification-strategy-gmm.md); [session 09](session_log/2026-05-18-09-audit.md) year-range viability

**HLO sparsity and the Sandefur (2018) critique.** AAP-2018 robustness shows SSA 88.0% missing vs RoW 79.2% (+8.8pp gap) — the empirical face of pre-2018 thin SACMEQ/PASEC anchors. The primary HCI HLO measure shows SSA *slightly better* than RoW (−3.2pp gap), reflecting the WB Human Capital Project's explicit post-2017 SSA-measurement targeting. The two measures' divergent SSA representation feeds the §6 limits paragraph on outcome-variable uncertainty.
> *Source:* `output/tables/ssa_hlo_missingness.csv`; [session 04](session_log/2026-05-17-04-hlo.md); [ADR-0004](decisions/0004-hlo-measure.md)

**HCI × AI Readiness compounding penalty.** r = 0.777 across 189 countries. Phase 9 will quantify the count + share of countries in the joint low-HCI ∩ low-GARI quadrant. The compounding-penalty thesis: countries with weak human capital today will fall further behind as AI-driven productivity asymmetries widen.
> *Source:* §4.6 above; [session 08](session_log/2026-05-17-08-ai-readiness.md)

---

## §6 Methodological transparency claims (for §3 and §6 to share)

- **133-country universe is reproducible** from raw OECD CRS + WDI HLOS without a separate DAC-list ingest. Documented in [ADR-0002](decisions/0002-country-universe.md) "Data observed" block.
- **Year-window invariance**: all three candidate windows yield identical Model-2 samples; the 2010–2020 primary is the densest framing, not a cherry-pick. [ADR-0003](decisions/0003-year-range.md) "Data observed" block.
- **Production panel is committed to git** (`data/interim/panel.parquet`, 915 KB). OSF/GitHub deposit standard for *World Development*.
- **Pinned indicator codes per source**; substitutions documented (e.g., UIS `XGDP.FSHH.FFNTP → FFNTR` per Session 03).
- **All ingest scripts hash raw files** (SHA-256 via `digest`); raw fingerprints recorded in `data/catalog.yml::raw_files[]`.
- **All ADRs carry "Data observed" blocks** where empirical evidence motivates the decision — not just hypothetical Options sections.

---

## How to maintain this document

- **At session end:** add new findings under the relevant §4/§5/§6 subsection. One-line claim (bold) + key numbers + evidence pointer. Cross-link relevant ADRs and session logs.
- **When findings supersede earlier ones:** mark the superseded line `~~strikethrough~~` and add the superseding finding below with a reference; do not delete (audit trail).
- **Header timestamp** bumps with each substantive update (date + session number).
- **Section ordering** mirrors the eventual manuscript section structure, not chronology of discovery.
- **Pointers** use repository-relative paths so the doc renders correctly on GitHub.
