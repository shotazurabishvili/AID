# Findings — Working Narrative

> *This document is the proto-§4 / §5 / §6 of the manuscript. It accumulates substantive empirical findings as they are discovered, organized by eventual manuscript section. Each finding: short claim, key numbers, evidence pointer (CSV/figure/session log/ADR). When Phase 11 (Writing) begins, much of `drafts/paper.qmd § 4-6` is a refactoring of this file.*
>
> *Parallel to [`methodology.md`](methodology.md) (proto-§3) and [`positionality.md`](positionality.md) (proto-§3 positionality). Updated at session end alongside the session log — see [`CLAUDE.md`](../CLAUDE.md) end-of-session protocol.*
>
> *Last updated: 2026-05-19 (Session 11 close — Phase 3 Session 01; first creation of this document, backfilled with all Phase 1-3 substantive findings)*

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

## §5 Results

**TO BE POPULATED** as Phase 4 (Model 1 OLS), Phase 5 (Model 2 FE + System GMM), Phase 6 (Model 3 2-level RE-vs-FE), Phase 7 (Model 4 ANOVA), Phase 8 (Model 5 counterfactual), and Phase 9 (Compounding AI Penalty) run. Each model gets its own subsection here; coefficients + SEs + diagnostics summarized; full tables live in `output/tables/`.

Stub structure to be filled:

- **§5.1 Model 1 — Cross-sectional OLS.** Cross-sectional β on ODA → HLO; expected positive and statistically significant. The "naive" headline that the within-country contrast challenges.
- **§5.2 Model 2 — Within-country FE panel.** Headline result. Contrast β_OLS vs β_FE; cluster-robust SE; Hausman, Wooldridge, Breusch-Pagan, VIF diagnostics. Locks [ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md), [ADR-0008](decisions/0008-china-aid-inclusion.md), [ADR-0009](decisions/0009-wgi-operationalization.md).
- **§5.3 Model 2 — System GMM headline robustness.** Per [ADR-0010](decisions/0010-identification-strategy-gmm.md). Roodman diagnostics. Sign-and-magnitude triangulation: static FE vs Difference GMM vs System GMM.
- **§5.4 Model 3 — 2-level country RE + time FE.** Per the Phase-2 external-review reframe. Hausman test justifies FE choice for Model 2.
- **§5.5 Model 4 — ANOVA on intervention typology.** Per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md). Levene; Tukey HSD; η²; Cohen's d.
- **§5.6 Model 5 — Counterfactual simulation.** Reported in **LAYS units** (per [ADR-0010](decisions/0010-identification-strategy-gmm.md)-adjacent commitment) alongside raw HLO points.

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
