# Data Dictionary

> *Canonical reference for every variable in the project's interim parquets. Updated as ingestion scripts complete. The machine-readable version is `data/catalog.yml::variables[]` per source; this file is the human-facing rendering.*
>
> *Last updated: 2026-05-17 (Session 01 close)*

---

## How to use

- Variable names in this dictionary are exactly the column names in `data/interim/<src>.parquet`
- "Source code" is the upstream provider's indicator code (cite in any external reference)
- "Transform" describes any pre-merge cleaning applied; "none" means the value is upstream-native
- Units, year-range, and missing % are the *observed-in-our-ingest* values, not the upstream theoretical range

---

## WDI — controls and education indicators (`data/interim/wdi.parquet`)

13 variables; 6480 rows; 216 countries; years 1995–2024.

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 country code (normalized via `R/lib/iso3.R`) | code | iso3 normalization + overrides | 0% |
| `year` | — | Calendar year of observation | integer | as.integer | 0% |
| `gdp_pc_usd` | NY.GDP.PCAP.CD | GDP per capita, current US$ | USD | none | 4.2% |
| `gdp_pc_ppp` | NY.GDP.PCAP.PP.CD | GDP per capita, PPP (current international $) | int. $ | none | 9.0% |
| `gni_pc_usd` | NY.GNP.PCAP.CD | GNI per capita, current US$ | USD | none | 9.1% |
| `population` | SP.POP.TOTL | Total population (mid-year estimate) | persons | none | 0.0% |
| `enroll_prim_gross` | SE.PRM.ENRR | Gross primary enrollment ratio | % | none | 27.9% |
| `enroll_sec_gross` | SE.SEC.ENRR | Gross secondary enrollment ratio | % | none | 39.1% |
| `enroll_prim_net` | SE.PRM.NENR | Net primary enrollment ratio | % | none | 56.6% |
| `ptr_primary` | SE.PRM.ENRL.TC.ZS | Pupil-teacher ratio, primary | ratio | none | 50.9% |
| `edu_exp_pct_gdp` | SE.XPD.TOTL.GD.ZS | Gov't education expenditure (% of GDP) | % | none | 42.0% |
| `edu_exp_pct_gov` | SE.XPD.TOTL.GB.ZS | Gov't education expenditure (% of total gov spending) | % | none | 43.0% |
| `primary_completion` | SE.PRM.CMPT.ZS | Primary completion rate | % | none | 44.4% |
| `lower_sec_completion` | SE.SEC.CMPT.LO.ZS | Lower secondary completion rate | % | none | 50.7% |
| `oos_primary_count` | SE.PRM.UNER | Out-of-school children, primary | persons | none | 45.0% |

## HCI — human capital index (`data/interim/hci.parquet`)

6 variables; 2277 rows; 207 countries; years 2010–2020. Sparse by design (HCI published in HCI-release years only: 2010, 2017, 2018, 2020).

**Excludes `HD.HCI.HLOS` (Harmonized Test Scores)** — that is the headline outcome variable, ingested separately as `hlo` in Session 04.

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 | code | iso3 normalization | 0% |
| `year` | — | Calendar year | integer | as.integer | 0% |
| `hci_overall` | HD.HCI.OVRL | Human Capital Index, overall | 0–1 index | none | 74.3% |
| `hci_female` | HD.HCI.OVRL.FE | HCI, female | 0–1 index | none | 77.6% |
| `hci_male` | HD.HCI.OVRL.MA | HCI, male | 0–1 index | none | 77.6% |
| `lays_overall` | HD.HCI.LAYS | Learning-adjusted years of school | years | none | 74.3% |
| `lays_female` | HD.HCI.LAYS.FE | LAYS, female | years | none | 77.6% |
| `lays_male` | HD.HCI.LAYS.MA | LAYS, male | years | none | 77.6% |

---

## WGI — Worldwide Governance Indicators (`data/interim/wgi.parquet`)

18 variables; 5112 rows; 213 countries; years 1996–2022. Biennial 1996–2002 (gaps in 1997, 1999, 2001), annual since 2002.

Source: native WGI bundle (NOT via `WDI` R package — see Langbein-Knack engagement in `methodology.md § 3.6`). For each of six dimensions, three metrics are retained: estimate, standard error, number of underlying sources. Percentile-rank columns dropped (collinear with estimate).

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 (normalized; WGI codes ROM/ZAR/TMP/ADO/KSV remapped) | code | iso3 normalization + overrides | 0% |
| `year` | — | Calendar year | integer | as.integer | 0% |
| `va_est` | VA Estimate | Voice and Accountability — estimate | ~−2.5 to 2.5 | none | 2.9% |
| `va_se` | VA StdErr | VA — standard error | numeric | none | 2.9% |
| `va_n_src` | VA NumSrc | VA — number of underlying sources | count | none | 2.9% |
| `pv_est` | PV Estimate | Political Stability & Absence of Violence/Terrorism — estimate | ~−2.5 to 2.5 | none | 2.9% |
| `pv_se` | PV StdErr | PV — standard error | numeric | none | 2.9% |
| `pv_n_src` | PV NumSrc | PV — n sources | count | none | 2.9% |
| `ge_est` | GE Estimate | Government Effectiveness — estimate | ~−2.5 to 2.5 | none | 4.1% |
| `ge_se` | GE StdErr | GE — standard error | numeric | none | 4.1% |
| `ge_n_src` | GE NumSrc | GE — n sources | count | none | 4.1% |
| `rq_est` | RQ Estimate | Regulatory Quality — estimate | ~−2.5 to 2.5 | none | 4.1% |
| `rq_se` | RQ StdErr | RQ — standard error | numeric | none | 4.1% |
| `rq_n_src` | RQ NumSrc | RQ — n sources | count | none | 4.1% |
| `rl_est` | RL Estimate | Rule of Law — estimate | ~−2.5 to 2.5 | none | 2.0% |
| `rl_se` | RL StdErr | RL — standard error | numeric | none | 2.0% |
| `rl_n_src` | RL NumSrc | RL — n sources | count | none | 2.0% |
| `cc_est` | CC Estimate | Control of Corruption — estimate | ~−2.5 to 2.5 | none | 3.8% |
| `cc_se` | CC StdErr | CC — standard error | numeric | none | 3.8% |
| `cc_n_src` | CC NumSrc | CC — n sources | count | none | 3.8% |

**Scope note:** WGI also publishes per-source detail (one file per source organization: EIU, BTI, V-Dem, Freedom House, etc.). Phase 1 ingests only the aggregates. Per-source values are a Phase-5 dependency tied to [ADR-0009](decisions/0009-wgi-operationalization.md): if the Phase-5 decision selects a reconstructed-from-sources approach, that ingestion runs then.

---

## Pending sources (to be populated)

- **UIS** (Session 03) — UNESCO Institute for Statistics
- **HLO** (Session 04) — Harmonized Learning Outcomes
- **OECD CRS** (Session 05) — DAC Creditor Reporting System (incl. project descriptions)
- **AidDataCore + GCDF v3.0** (Session 06) — DAC + non-DAC + Chinese aid
- **UCDP/PRIO + UNESCO COVID** (Session 07) — confounders
- **AI Readiness** (Session 08) — cross-sectional

---

## Conventions

- **Country code:** always `iso3` (ISO 3166-1 alpha-3), normalized via `R/lib/iso3.R::normalize_iso3()` with overrides for known edge cases (Kosovo, Taiwan, Palestine, South Sudan pre/post-2011, North Macedonia, Eswatini, Czechia, Côte d'Ivoire).
- **Year:** always integer; merged on `(iso3, year)`.
- **Units:** preserve upstream units in interim; any rescaling (e.g., log GDP) happens in `R/30_merge_panel.R` or downstream model scripts, never in ingestion.
- **Snake_case:** all column names are snake_case English; mapping to upstream codes lives in the script header and `catalog.yml::variables[]`.
- **Missing values:** NA (R native); never sentinel values like -9 or 999. Imputation happens in Phase 2, not ingestion.
