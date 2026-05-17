# Methodology — Working Narrative

> *This document is the proto-§3 ("Data & Methodology") of the manuscript. It grows session by session as decisions are locked. Each section references the relevant ADR for the load-bearing call. When Phase 11 (Writing) begins, much of `drafts/paper.qmd § 3` is a refactoring of this file.*
>
> *Last updated: 2026-05-17 (Session 06 close — AidData GCDF v3.0 ingested; 7/11 required sources complete; AidData Core deferred)*

---

## 3.1 Conceptual framework

The paper tests whether Official Development Assistance to education predicts learning outcomes across countries, and which structural variables actually drive learning. The conceptual model has three layers:

- **Inputs (donor side):** ODA flows by sector, recipient, year.
- **Mediators (country side):** education expenditure, pupil-teacher ratio, governance quality, conflict, COVID-era schooling disruption.
- **Outcomes:** harmonized learning outcomes (HLO), distinct from enrollment.

The central claim — *"ODA to education predicts enrollment but not learning"* — is operationalized as a contrast between two model specifications: cross-sectional OLS (Model 1) that may show a naive association, and within-country fixed-effects panel (Model 2) that may not.

The argument is *falsifiable*: if the within-country coefficient on ODA is positive, significant, and meaningful in magnitude, the thesis fails.

## 3.2 Sample — country universe

**Locked decision:** [ADR-0002](decisions/0002-country-universe.md) — Pending (Phase 1 Session 09).

Working rule: countries that are **ODA-eligible per WB classification at any point in 2000–2022 ∩ have ≥1 HLO observation**. Expected N ≈ 100–120.

## 3.3 Period — year range

**Locked decision:** [ADR-0003](decisions/0003-year-range.md) — Pending (Phase 1 Session 09).

Working rule: 2000–2022 primary; 2005–2020 robustness. COVID years (2020–2022) included with closure-day controls.

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

**Locked decision:** [ADR-0006](decisions/0006-uis-missingness-strategy.md) — Pending (Phase 2).

Working plan:
1. Phase 1 Session 03 documents the SSA missingness pattern for UIS variables via `R/lib/coverage.R::ssa_missingness_pattern()`.
2. Phase 2 runs the Little MCAR test on the merged panel.
3. Primary specification likely uses WDI controls only (UIS dropped); UIS-augmented spec runs on the listwise-complete subset as robustness. Multiple imputation as third sensitivity if the panel-size loss is severe.

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
- [ ] UIS missingness: listwise vs MI vs UIS-dropped
- [ ] ANOVA coding: rule-based vs LLM-assisted (agreement rate ≥ 85%)
- [ ] Country FE structure: country FE alone vs country × decade FE
- [ ] Lag structure: contemporaneous ODA vs 3-year MA

## 3.13 Positionality

See `docs/positionality.md` for the working draft. Final placement in the manuscript: end of §3 (Methodology). Position framed as a methodological asset — practitioner observation of incentive structures not captured in administrative datasets, used to ground qualitative interpretation in §6 Discussion.

---

## Methodology obligations (cross-reference)

The full list of diagnostics and tests we have committed to running is in [`obligations.md`](obligations.md). Each item there links back to the relevant ADR or methodology section above.
