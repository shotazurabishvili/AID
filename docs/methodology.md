# Methodology — Working Narrative

> *This document is the proto-§3 ("Data & Methodology") of the manuscript. It grows session by session as decisions are locked. Each section references the relevant ADR for the load-bearing call. When Phase 11 (Writing) begins, much of `drafts/paper.qmd § 3` is a refactoring of this file.*
>
> *Last updated: 2026-05-18 (Session 10 close — Phase 2 opened; production panel built; ADR-0006 Accepted)*

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

**SSA coverage caveat — empirically grounded.** The Session 04 ingest characterizes SSA missingness for both measures on a full-joined panel (`output/tables/ssa_hlo_missingness.csv`):

| Measure | SSA missing % | Rest-of-world missing % | Gap |
|---|---|---|---|
| `hlo_score` (HCI HLOS) | 74.40% | 77.60% | **−3.20 pp** |
| `hlo_aap` (AAP-2018)   | 88.02% | 79.23% | **+8.75 pp** |

The two measures diverge sharply on SSA representation. The primary HCI measure shows *slightly better* SSA coverage than rest-of-world — consistent with the World Bank Human Capital Project's explicit post-2017 targeting of measurement gaps in low-income countries. The AAP-2018 robustness measure shows the **opposite** pattern (+8.75 pp worse in SSA), which is the empirical face of Sandefur's pre-2018 SSA-coverage concern: the harmonization rests on thin SACMEQ/PASEC anchors that miss many SSA country-years. This is *measurement availability*, distinct from the *measurement equating* version of the Sandefur concern; both flow into the Discussion §6 limits paragraph on outcome-variable uncertainty.

## 3.5 Treatment variable — ODA to education

**Locked decision:** [ADR-0005](decisions/0005-oda-commitment-vs-disbursement.md) — Pending (Phase 5).

Primary: OECD DAC CRS disbursements to education (sector codes 110/111/112/113/114), 3-year lagged moving average. Robustness: commitments, alternative lag structures, and (per ADR-0008) Chinese development finance from AidData GCDF v3.0.

**Ingest done (Phase 1 Session 05).** Bulk parquet (~1 GB, release CRS-Parquet-v20260408) fetched via dynamic SDMX file-ID discovery (`sdmx.oecd.org/.../DSD_CRS@DF_CRS/1.6` → IDFile GUID). Stored at project-level resolution in `data/interim/oecd_crs.parquet` — **537,586 rows × 38 columns, 172 recipient countries × 125 donor identities, 1995–2024**. Commitments and disbursements are SEPARATE wide columns (legacy CRS dotStat format), not long-format rows, with paired `_defl` constant-USD variants — so the ADR-0005 question becomes a *column choice* at Phase 5, not a *row filter*. Grant-equivalent measure (`usd_grant_equiv`) is the post-2018 ODA methodology and only populates 2015+. Project description text (`project_title`, `short_description`, `long_description`, `keywords`) and the 5-digit `purpose_code` are retained for ADR-0007 typology coding (Phase 7). Country-year aggregation (sum across donors per recipient × year) and 3-year MA happen in `R/30_merge_panel.R` at Phase 2 — ingest preserves source-native resolution. **SSA coverage parity is excellent** on commitments and disbursements (gap −1.3 / −1.1 pp respectively); see `output/tables/ssa_oecd_crs_missingness.csv`.

**Production panel constructed (Phase 2 Session 01).** `R/30_merge_panel.R` aggregates CRS to (iso3, year) sums across donors and builds the ADR-0005 column matrix: **4 raw cols** (`crs_commit_usd_sum`, `crs_commit_usd_defl_sum`, `crs_disburse_usd_sum`, `crs_disburse_usd_defl_sum`); **4 trailing 3-year MA cols** (`*_ma3`); **2 one-year lag cols** on the deflated commit + disburse (`*_defl_lag1`). The MA window is trailing-INCLUSIVE: `mean(t-2, t-1, t)`, with `.complete=TRUE` returning NA when fewer than 3 in-panel years are available (years 2000–2001 per country). NA cells within the ADR-0002 universe are coalesced to 0 before MA computation (rationale: ODA-eligible recipients with no recorded education project in year *t* received $0 that year, not "data missing"). ADR-0005 in Phase 5 chooses primary among these. Pre-2002 disbursement reporting was sparse on the OECD side (~30% of post-2002 rates) — the 2010–2020 primary window is comfortably post-2002, but disbursement MA noise in the 2000–2022 robustness window is documented and not "fixed" (the point of robustness is window-invariance demonstration).

## 3.6 Controls — macro and sector

**Currently ingested (Session 01):**

- *Macro:* GDP per capita (current USD), GDP per capita PPP, GNI per capita, total population (WDI).
- *Education sector (formerly EdStats, now WDI):* pupil-teacher ratio (primary), education expenditure (% GDP, % gov budget), primary completion rate, lower secondary completion rate, gross/net primary enrollment, gross secondary enrollment, out-of-school primary count.

**Governance (ingested Phase 1 Session 02 via native WGI bundle):**

WGI aggregates for all six dimensions — Voice & Accountability, Political Stability, Government Effectiveness, Regulatory Quality, Rule of Law, Control of Corruption — fetched from the native multi-sheet Excel bundle at info.worldbank.org/governance/wgi/, **not** via the WDI R package. The native bundle retains the `n_sources` count per country-year, which is the minimum information needed to acknowledge the Langbein & Knack (2010) aggregation critique in this section of the manuscript.

Operationalization in models (composite vs PCA-collapsed vs reconstructed-from-sources) is deferred to [ADR-0009](decisions/0009-wgi-operationalization.md), to be locked in Phase 5 after VIF is observed.

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

### Model 2 — Fixed Effects panel (PRIMARY)

$$Learning_{it} = \beta_1 ODA_{it} + \beta_2 Expenditure_{it} + \beta_3 Stability_{it} + \alpha_i + \lambda_t + \varepsilon_{it}$$

Country fixed effects ($\alpha_i$) and year fixed effects ($\lambda_t$). The contrast between $\beta_1$ here and in Model 1 is the headline finding. Cluster-robust standard errors at country level. Required diagnostics: Hausman, Wooldridge, Breusch-Pagan, VIF (see [obligations](obligations.md)).

### Model 3 — Three-level hierarchical linear model

Students nested in schools nested in countries. ICC reported at each level. 30/30 rule checked before estimation. Random intercepts default; random slopes justified per ADR (TBD).

### Model 4 — One-way ANOVA on intervention typology

Compares mean 5-year learning gains across four mutually exclusive aid types: infrastructure / teacher training / curriculum-materials / budget support. Coding from CRS project descriptions per [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md). Levene's test → Welch's if needed. Tukey HSD post-hoc; η² and Cohen's d for all pairs.

### Model 5 — Counterfactual simulation

Redirect $1B from input-based to outcome-based aid; use effect sizes from Model 4 to project learning gains. Report best/worst/expected case across CI bounds.

## 3.9 Missing data strategy

**Locked decision:** [ADR-0006](decisions/0006-uis-missingness-strategy.md) — **Accepted 2026-05-18**.

**Option 3: drop UIS controls from the primary specification.** Primary uses WDI controls only (`wdi_edu_exp_pct_gdp`, `wdi_ptr_primary`, `wdi_gdp_pc_usd`) + WGI governance. UIS-augmented spec is reported in **Robustness 1** on the listwise-complete subset; **Robustness 2** is the multiple-imputation UIS-augmented spec on the full sample (Phase-5 implementation).

**Empirical basis** (Phase 2 Session 01, production panel `data/interim/panel.parquet`, primary window 2010–2020 = 1,463 rows):

| Subset | N rows | Complete rows | χ² (df) | p | Patterns |
|---|---|---|---|---|---|
| 6-col primary (HLO + 3 WDI + CRS + WGI) | 1,463 | **173** | 175.80 (41) | < 0.000001 | 12 |
| 7-col +UIS (private expenditure) | 1,463 | **69** | 341.90 (84) | < 0.000001 | 20 |

Both reject MCAR strongly; adding UIS drops the analytical sample by 60% (`output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`). The 7-col pattern is structurally SSA-biased (UIS private-expenditure missingness +16.9 pp in SSA vs non-SSA on the production panel; `output/tables/production_ssa_panel_missingness.csv`).

Earlier Phase-1 audit-panel MCAR (Session 09, `output/tables/mcar_test_result.txt`) ran on the unfiltered 250-country audit panel using `crs_commit_usd_sum` (current-USD commitment) and reported χ² = 1216, df = 68; that result is preserved for the audit trail but not the analytical-pipeline finding. The production lock uses `crs_disburse_usd_defl_sum` (production primary intent) on the 133-country universe after the within-universe NA → 0 coalesce.

## 3.10 Intervention typology coding

**Locked decision:** [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) — Pending (Phase 7).

Phase 1 Session 05 ingests CRS *with description text retained*. Phase 7 implements rule-based keyword classification as primary, LLM-assisted classification as robustness comparator.

## 3.11 Chinese aid inclusion

**Locked decision:** [ADR-0008](decisions/0008-china-aid-inclusion.md) — Pending (Phase 5).

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

**Phase-9 preview** (`cor(ai_readiness_score_mean, hci_overall)` on the 189-country join): **r = 0.777**. The strong positive correlation between human capital and AI readiness is the empirical face of the compounding-penalty thesis — Phase 9 will partition the joint distribution and quantify the count + share of low-HCI ∩ low-GARI countries.

## 3.13 Positionality

See `docs/positionality.md` for the working draft. Final placement in the manuscript: end of §3 (Methodology). Position framed as a methodological asset — practitioner observation of incentive structures not captured in administrative datasets, used to ground qualitative interpretation in §6 Discussion.

---

## Methodology obligations (cross-reference)

The full list of diagnostics and tests we have committed to running is in [`obligations.md`](obligations.md). Each item there links back to the relevant ADR or methodology section above.
