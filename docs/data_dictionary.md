# Data Dictionary

> *Canonical reference for every variable in the project's interim parquets. Updated as ingestion scripts complete. The machine-readable version is `data/catalog.yml::variables[]` per source; this file is the human-facing rendering.*
>
> *Last updated: 2026-05-18 (Session 08 close — Oxford Insights GARI 2025 added; 10/11 sources documented; AidData Core deferred — Phase-1 substantively closed)*

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

## HLO — Harmonized Learning Outcomes, primary (`data/interim/hlo.parquet`)

1 indicator; 2277 rows; 207 countries; years 2010–2020. Sparse by design (the HCI publishes in cycles: 2010, 2017, 2018, 2020). This is the **headline outcome variable** of the paper. Decision: [ADR-0004](decisions/0004-hlo-measure.md) (Accepted 2026-05-17). See `methodology.md § 3.4`.

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 | code | iso3 normalization | 0% |
| `year` | — | Calendar year | integer | as.integer | 0% |
| `hlo_score` | HD.HCI.HLOS | Harmonized Test Scores (HCI component) | ~300–625 scale | none | 74.13% |

**SSA-specific missingness** on the full-joined HLO panel (`output/tables/ssa_hlo_missingness.csv`):
- `hlo_score`: SSA 74.40% missing vs Rest 77.60% — gap **−3.20 pp** (SSA modestly better)

## HLO — AAP 2018 robustness (`data/interim/hlo_aap2018.parquet`)

1 indicator; 486 rows; 137 countries; years 1995–2015 at 5-year intervals (2000, 2005, 2010, 2015 within our YEAR_RANGE). Used as the **principal robustness measure** for the headline outcome variable per [ADR-0004](decisions/0004-hlo-measure.md). Source: Altinok, Angrist & Patrinos (2018) *Global data set on education quality (1965–2015)*, WB Policy Research WP 8314, fetched via the OWID `owid-datasets` GitHub mirror (raw CSV pinned by commit hash).

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 (`Entity` field normalized via `country.name`) | code | iso3 normalization | 0% |
| `year` | — | Calendar year | integer | as.integer | 0% |
| `hlo_aap` | AAP2018.HLO | Average harmonized learning outcome score (already pooled across subjects math/reading/science and levels primary/secondary by the source authors) | ~300–625 scale | filter to YEAR_RANGE; drop sub-national rows | 0% (within-panel) |

**Dropped sub-national rows** (logged to `output/logs/iso3_unresolved_hlo_aap2018.csv`): `Canada (British Colombia)`, `England`, `Scotland`, `United States (Indiana State)`, `Zanzibar` — sub-national entities AAP reports separately from the national rows for harmonization comparison; excluded from the country-year panel.

**SSA-specific missingness** on the full-joined HLO panel (`output/tables/ssa_hlo_missingness.csv`):
- `hlo_aap`: SSA 88.02% missing vs Rest 79.23% — gap **+8.75 pp** (SSA worse — empirical face of the Sandefur 2018 critique; see `methodology.md § 3.4`)

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

## UIS — UNESCO Institute for Statistics (`data/interim/uis.parquet`)

7 variables; 7059 rows; 220 countries; years 1970–2025. From UIS SDG bulk (Feb 2026 release). Scope is *minimal*: private expenditure share + out-of-school rates only, since WDI already covers enrollment / PTR / public expenditure / completion. Adding other UIS indicators requires an ADR.

**Code-substitution notes (planned → actual):**
- `XGDP.FSHH.FFNTP` → `XGDP.FSHH.FFNTR` (only "Initial" variant available)
- `XGDP.FSGOV.FFNTP` → `XGDP.FSGOV` (use UIS simple total; cleanest WDI cross-check)
- `ROFST.<lvl>` → `ROFST.<lvl>.CP` (UIS uses `.CP` for cumulative percentage)

| Variable | Source code | Definition | Units | Transform | Missing % |
|---|---|---|---|---|---|
| `iso3` | — | ISO 3166-1 alpha-3 (`COUNTRY_ID` in UIS data) | code | normalize_iso3 | 0% |
| `year` | — | Calendar year | integer | as.integer | 0% |
| `priv_exp_pct_gdp` | XGDP.FSHH.FFNTR | Initial private (household) expenditure on education as % of GDP | % | none | **83.0%** (91.8% in SSA) |
| `gov_exp_pct_gdp_uis` | XGDP.FSGOV | Government expenditure on education as % of GDP (UIS) — cross-check vs WDI `edu_exp_pct_gdp`, NOT for model use | % | none | 26.9% |
| `oos_rate_primary` | ROFST.1.CP | Out-of-school rate, primary, both sexes | % | none | 33.5% |
| `oos_rate_primary_f` | ROFST.1.F.CP | OOS rate, primary, female | % | none | 48.4% |
| `oos_rate_primary_m` | ROFST.1.M.CP | OOS rate, primary, male | % | none | 48.5% |
| `oos_rate_lower_sec` | ROFST.2.CP | OOS rate, lower secondary, both sexes | % | none | 53.9% |
| `oos_rate_upper_sec` | ROFST.3.CP | OOS rate, upper secondary, both sexes | % | none | 54.8% |

**SSA-specific missingness pattern** (`output/tables/ssa_uis_missingness.csv`):
- Private expenditure: **91.8% missing in SSA vs 80.3% rest of world** (+11.6pp gap) — variable is effectively unusable for SSA-inclusive models; informs [ADR-0006](decisions/0006-uis-missingness-strategy.md)
- Lower / upper secondary OOS: SSA worse by +10.9 / +13.3 pp
- Primary OOS rates: surprisingly SSA has **slightly better** coverage than rest of world (likely reflects UN priority focus on universal primary)

---

## OECD CRS — DAC Creditor Reporting System (`data/interim/oecd_crs.parquet`)

38 columns; **537,586 rows** (project-level); 172 recipient countries × 125 donor identities; years 1995–2024. Bulk parquet release **CRS-Parquet-v20260408** fetched via dynamic SDMX file-ID discovery (see `R/10_ingest_oecd_crs.R` header for the SDMX endpoint + marker regex). Schema is the legacy **CRS dotStat format**: commitments and disbursements are SEPARATE wide columns (NOT long-format rows on a measure dimension).

**Sector filter at ingest:** `sector_code %in% c(110, 111, 112, 113, 114)` (education sector group). 5-digit `purpose_code` retained for Phase-7 typology granularity. 10.6% of pre-filter rows were on regional/unspecified aggregates (logged in `output/logs/iso3_unresolved_oecd_crs.csv`) and dropped from the country panel.

**Resolution note:** project-level rows. Aggregation to ISO3 × year (sum across donors per recipient; 3-year MA per ADR-0005) happens in `R/30_merge_panel.R` at Phase 2. Do not aggregate in ingest.

| Variable | Definition | Type | Notes |
|---|---|---|---|
| `iso3` | ISO 3166-1 alpha-3 (normalized from `recipient_name` via `country.name`) | code | 0% missing in cleaned panel |
| `year` | Calendar year of obligation/flow | integer | 1995–2024 |
| `donor_code`, `donor_name` | DAC member numeric code + label | numeric/char | 125 donor identities incl. multilateral channels |
| `agency_code`, `agency_name` | Implementing donor agency (sub-donor) | numeric/char | — |
| `crs_id`, `project_number` | Project-level identifiers | char | uniqueness within (donor, year) |
| `recipient_code`, `recipient_name` | OECD area code + label | numeric/char | OECD uses ITS OWN code system (Nigeria=261, not ISO numeric 566) — that's why iso3 is derived from `recipient_name` |
| `region_name`, `incomegroup_name` | OECD region + WB income-group labels | char | for descriptives |
| `sector_code`, `sector_name` | 3-digit sector group (110-114 = education) | int32/char | filter applied at ingest |
| `purpose_code`, `purpose_name` | 5-digit purpose code (11110, 11220, …) | int32/char | finer typology for ADR-0007 |
| `flow_code`, `flow_name` | Flow type (ODA grants, ODA loans, OOF, etc.) | int/char | — |
| `bi_multi` | Bilateral vs multilateral indicator | int | — |
| `category`, `finance_t`, `aid_t` | OECD category / finance type / aid type | int | grant/loan distinction; modality |
| `channel_code`, `channel_name`, `parent_channel_code` | Implementing channel | int/char | — |
| `usd_commitment`, `usd_commitment_defl` | Commitment, current and constant USD millions | numeric | **ADR-0005 candidate column** |
| `usd_disbursement`, `usd_disbursement_defl` | Disbursement, current and constant USD millions | numeric | **ADR-0005 candidate column** (working-preference primary) |
| `usd_received`, `usd_received_defl` | Received, current and constant USD | numeric | special cases |
| `usd_grant_equiv`, `usd_grant_equiv_defl` | Grant equivalent (post-2018 ODA methodology) | numeric | only populated 2015+; 68% missing in the panel |
| `currency_code` | Currency the donor reported in | char | — |
| `project_title` | Title text | char | **ADR-0007 typology source** |
| `short_description` | Short project description | char | **ADR-0007 typology source** |
| `long_description` | Long project description | char | **ADR-0007 typology source** |
| `keywords` | Keyword tags | char | **ADR-0007 typology source** |

**SSA missingness contrast** on (iso3, year) availability of *any* observation per measure (`output/tables/ssa_oecd_crs_missingness.csv`):
- `has_commitment`:   SSA 0.00% missing vs Rest 1.27% — gap **−1.27 pp** (SSA modestly better)
- `has_disbursement`: SSA 1.62% missing vs Rest 2.73% — gap **−1.11 pp** (SSA modestly better)
- `has_grant_equiv`:  SSA 66.6% missing vs Rest 68.5% — gap **−1.85 pp** (both groups sparse — measure only exists 2015+)

Excellent SSA coverage parity for the headline commitment and disbursement measures.

---

## AidData GCDF v3.0 — Chinese development finance (`data/interim/aiddata_gcdf.parquet`)

30 columns; **2,654 rows** (project-level, education sector only); 138 recipient countries; years 2000–2021. Source: AidData Global Chinese Development Finance Dataset v3.0, TUFF methodology (Custer, Strange, Dreher, Tierney et al.). Bulk release xlsx dated 2024-06-17 (per zip mtime); fetched from `https://docs.aiddata.org/ad4/datasets/AidDatas_Global_Chinese_Development_Finance_Dataset_Version_3_0.zip`. Feeds [ADR-0008](decisions/0008-china-aid-inclusion.md) (Pending → Phase 5 lock).

**Filters at ingest:**
- `Sector Name == "EDUCATION"` (1 of 24 sector values in GCDF — note: GCDF uses string-named sectors, NOT CRS purpose codes)
- `Recommended For Aggregates == "Yes"` (per GCDF 3.0 codebook; avoids umbrella project double-counting)
- `Commitment Year` in `1995:2024`

5 rows on regional aggregates ("Africa, regional", "Asia, regional", etc.) logged to `output/logs/iso3_unresolved_aiddata_gcdf.csv` and dropped.

**Resolution note:** project-level rows. Aggregation to (iso3, year) sum-of-amounts happens in `R/30_merge_panel.R` at Phase 2. GCDF and OECD CRS interim parquets are NOT directly stackable on sector dimension (different taxonomies); they're stacked on (iso3, year) value totals.

| Variable | Definition | Type | Notes |
|---|---|---|---|
| `iso3` | ISO 3166-1 alpha-3 (round-trip-validated from `Recipient ISO-3`; falls back to name-based for regionals) | code | 0% missing in cleaned panel |
| `year` | `Commitment Year` cast to integer | integer | 2000–2021 |
| `AidData Record ID` | Project identifier | char | uniqueness within (year, recipient) |
| `Recommended For Aggregates` | Always "Yes" in cleaned panel (codebook filter applied) | char | — |
| `Recipient`, `Recipient ISO-3`, `Recipient Region` | Recipient identity + AidData region label | char | — |
| `Commitment Year`, `Implementation Start Year`, `Completion Year` | Year columns (Commitment is primary; others retained for Phase 5 timing analyses) | int/numeric | — |
| `Status` | Project status (Completion / Implementation / etc.) | char | — |
| `Intent` | Project intent classification | char | — |
| `Sector Code`, `Sector Name` | GCDF sector taxonomy (24 string-named sectors; we keep only EDUCATION) | int/char | — |
| `Infrastructure`, `COVID` | GCDF flags (Yes/No) | char | — |
| `Flow Type`, `Flow Type Simplified`, `Flow Class` | Concessional vs non-concessional classifications | char | — |
| `OECD ODA Concessionality Threshold` | Whether project meets OECD ODA concessionality criteria | char | direct bridge to OECD's ODA definition |
| `Funding Agencies`, `Funding Agencies Type` | Chinese financiers (e.g., China Development Bank, MOFCOM) | char | analytically loaded for ADR-0008 sub-question |
| `Direct Receiving Agencies`, `Direct Receiving Agencies Type` | Recipient-side agencies | char | — |
| `Amount (Constant USD 2021)` | **Primary value column** — total commitment in constant USD 2021 | numeric | for Phase-2 panel construction |
| `Amount (Original Currency)`, `Original Currency` | Commitment in original currency | numeric/char | — |
| `Amount (Nominal USD)` | Commitment in current USD | numeric | — |
| `Title`, `Description` | Project title + free-text description | char | could supplement ADR-0007 typology coding |

**SSA-coverage contrast** on (iso3, year) presence of any Chinese education project (`output/tables/ssa_aiddata_gcdf_coverage.csv`) — **NOT missingness**: GCDF only contains Chinese-funded projects, so absence ≠ missing data, it means "China didn't fund there".

| Indicator | SSA coverage % | Non-SSA coverage % | Gap |
|---|---|---|---|
| `has_china_edu_project` | **45.8%** | 32.7% | **+13.1 pp** |

China systematically concentrates education aid in SSA more than elsewhere. **Headline volume**: 1,131 SSA education projects across 47 of 48 SSA countries, worth $5.61 B constant USD 2021. Empirical hook for ADR-0008 Data Observed; will inform §6 Discussion paragraph on the non-DAC blind spot.

---

## UCDP/PRIO Armed Conflict v25.1 (`data/interim/ucdp.parquet`)

10 columns; **7,470 rows** (country-year panel, balanced); 249 countries; years 1995–2024. Aggregated from UCDP/PRIO ACD v25.1 (`ucdp-prio-acd-251-csv.zip`, 44 KB; 2,752 conflict-year rows × 28 cols, 1946-2024) + UCDP BRD v25.1 conflict-level (`ucdp-brd-conf-251-csv.zip`, 38 KB; 1,586 rows × 25 cols, 1989-2024). Citation: Pettersson, Davies et al. (annual UCDP release). Feeds Model 2 (Phase 5) as time-varying confounder per methodology §3.7.

**Aggregation method:** multi-country conflicts have comma-space-separated Gleditsch-Ward codes in `gwno_loc` (verified — e.g., `"651, 666"` = Egypt+Yemen). Expanded via `strsplit(gwno_loc, ", *")` and converted to ISO3 via `countrycode(origin="gwn")` with manual overrides for GW 678 ("Yemen (North Yemen)" → YEM, captures post-unification state) and GW 345 ("Serbia (Yugoslavia)" → SRB, captures the Kosovo war 1998-1999). Panel filled with 0s for country-years with no conflict observation (NA-as-zero for `in_conflict` / `n_conflicts` / `bd_*`; `intensity_max` stays NA when no conflict).

**BRD 25-deaths threshold:** UCDP-BRD only records conflicts with ≥25 battle deaths/year. Low-intensity violence below this is excluded by upstream design; this is a documented feature, not a missingness issue.

| Variable | Definition | Type | Notes |
|---|---|---|---|
| `iso3` | ISO 3166-1 alpha-3 (from `countrycode("gwn", "iso3c")` + overrides) | code | 0% missing in panel |
| `year` | Calendar year | integer | 1995–2024 |
| `in_conflict` | 1 if any ACD conflict active in (iso3, year), else 0 | int (0/1) | 0% missing (filled with 0); 12.3% of cells == 1 |
| `intensity_max` | Max `intensity_level` (1=minor / 2=war) across active conflicts | int | NA when no active conflict in cell |
| `n_conflicts` | Count of distinct `conflict_id` active in cell | int | 0 when no active conflict |
| `internal_armed` | 1 if any `type_of_conflict == 3` (intrastate) in cell | int (0/1) | — |
| `internationalized` | 1 if any `type_of_conflict == 4` (internationalized intrastate) | int (0/1) | — |
| `bd_best` | Sum of BRD `bd_best` across active conflicts in (iso3, year) | numeric | 0 when no BRD row above threshold |
| `bd_low` | Sum of BRD `bd_low` (lower-bound estimate) | numeric | — |
| `bd_high` | Sum of BRD `bd_high` (upper-bound estimate) | numeric | — |

**SSA conflict prevalence:** 25.3% of SSA country-years had active conflict 1995-2024, vs 9.2% of non-SSA — gap **+16.1 pp**. This is the well-established SSA over-representation in armed-conflict literature; documented for Phase-5 reading.

---

## UNESCO COVID-19 School Closures (`data/interim/covid_closures.parquet`)

8 columns; **630 rows** (country-year totals); 210 countries; years 2020–2022. Derived from the UNESCO daily Status time-series on HDX (`covid_impact_education.csv`, 169,051 rows; Feb 2020 – Mar 2022). Citation: UNESCO Institute for Statistics — Global Monitoring of School Closures. Feeds Model 2 (Phase 5) as time-varying confounder per methodology §3.7.

**Derivation method:** count days per Status category per (iso3, year). Date parsed via `lubridate::dmy()` (European DD/MM/YYYY format). Status takes exactly 4 values in the source CSV: "Closed due to COVID-19", "Partially open", "Fully open", "Academic break". Mapped to four count columns. **Transparent operationalization** — counts derived from daily data, not relying on UNESCO's pre-aggregation method.

**Cross-validation against UNESCO pre-aggregated xlsx** (`duration-of-school-closures-31-march-22.xlsx`, weeks rounded ×7): median |diff| = **2 days**, max |diff| = **33 days** for days_closed (210 countries compared). Tiny disagreements are UNESCO's week-rounding noise.

| Variable | Definition | Type | Notes |
|---|---|---|---|
| `iso3` | ISO 3166-1 alpha-3 (from CSV's `ISO` column, round-trip validated) | code | 0% missing in panel |
| `year` | Calendar year (2020, 2021, or 2022) | integer | — |
| `days_closed` | Days where Status == "Closed due to COVID-19" | int | 0% missing (filled at 0); max in 2020 = 295 days |
| `days_partial` | Days where Status == "Partially open" | int | — |
| `days_open` | Days where Status == "Fully open" | int | — |
| `days_break` | Days where Status == "Academic break" | int | — |
| `first_closure_date` | First date in country's record where Status == "Closed due to COVID-19" | Date | NA for countries with no full closure |
| `last_closure_date` | Last such date | Date | — |

Median country had 116 days fully closed across 2020-2022 (max 556 days). Scope: 2020–2022 active monitoring window; outside that window UNESCO did not monitor, so it counts as zero closure days for the panel.

---

## Oxford Insights GARI 2025 (`data/interim/ai_readiness.parquet`)

10 columns; **195 rows** (all GARI-ranked countries; 0 unresolved labels); single year 2025 (cross-sectional source). Extracted from Oxford Insights *Government AI Readiness Index 2025* PDF report (release dated 2026-01-29, ~8 MB) via `.venv-tools/bin/python scripts/extract_pdf_table.py` (pdfplumber). The 195-country score table is split across PDF pages 59–68; the script concatenates all 8-column tables and promotes the header row from page 59. **No machine-readable export exists** at the source; PDF extraction is the only path.

**Important: no overall composite is published in the source.** The 8 source columns are Country, Rank, and 6 pillar scores. Our `ai_readiness_score_mean` is **DERIVED** as the equally-weighted mean of the 6 pillars (clearly labeled in the column name; documented in catalog notes). Oxford's official composite weighting may differ — our derivation is transparent and reproducible; Phase-9 reading should treat the composite as our construction, not Oxford's.

Citation: Oxford Insights (2026). *Government AI Readiness Index 2025*. Report v01_26.

| Variable | Definition | Type | Notes |
|---|---|---|---|
| `iso3` | ISO 3166-1 alpha-3 (from `normalize_iso3(country, origin="country.name")`) | code | 0% missing; all 195 countries resolved |
| `year` | Edition stamp (2025) — NOT a measurement year | integer | constant across rows |
| `ai_readiness_rank` | Oxford's published rank (1 = most ready) | integer | 1–195 |
| `ai_pillar_policy_capacity` | Policy Capacity pillar score | numeric (0–100ish) | — |
| `ai_pillar_ai_infrastructure` | AI Infrastructure pillar | numeric | — |
| `ai_pillar_governance` | Governance pillar | numeric | — |
| `ai_pillar_public_sector_adoption` | Public Sector Adoption pillar | numeric | — |
| `ai_pillar_development_and_diffusion` | Development & Diffusion pillar | numeric | — |
| `ai_pillar_resilience` | Resilience pillar | numeric | — |
| `ai_readiness_score_mean` | **DERIVED** equally-weighted mean of the 6 pillars | numeric (10.28–87.68 observed) | Use for §9 HCI×GARI composite; document the derivation when cited |

**Phase-9 preview**: joining with most-recent HCI cycle per country yields 189 country matches; `cor(ai_readiness_score_mean, hci_overall) = 0.777`. Strong positive correlation — the empirical hook for the brief's "Compounding AI Penalty" §9 thesis.

---

## Pending sources (to be populated)
- **AidData Core v3.1** — *DEFERRED* (Session 06 author decision): 1947–2013 only; ~4-year overlap with HLO window (2010+) is marginal. Possible §6 historical-context ingest later if needed.

---

## Conventions

- **Country code:** always `iso3` (ISO 3166-1 alpha-3), normalized via `R/lib/iso3.R::normalize_iso3()` with overrides for known edge cases (Kosovo, Taiwan, Palestine, South Sudan pre/post-2011, North Macedonia, Eswatini, Czechia, Côte d'Ivoire).
- **Year:** always integer; merged on `(iso3, year)`.
- **Units:** preserve upstream units in interim; any rescaling (e.g., log GDP) happens in `R/30_merge_panel.R` or downstream model scripts, never in ingestion.
- **Snake_case:** all column names are snake_case English; mapping to upstream codes lives in the script header and `catalog.yml::variables[]`.
- **Missing values:** NA (R native); never sentinel values like -9 or 999. Imputation happens in Phase 2, not ingestion.
