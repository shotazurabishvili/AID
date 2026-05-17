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

## Pending sources (to be populated)

- **WGI** (Session 02) — Worldwide Governance Indicators
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
