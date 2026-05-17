# Data Catalog

*Auto-rendered from `data/catalog.yml` by `R/lib/catalog.R::render_catalog()`. Do not edit by hand.*

| Source | Variables | URL | Access date | Version | Rows | Countries | Years | Notes |
|---|---|---|---|---|---|---|---|---|
| **World Development Indicators** | NY.GDP.PCAP.CD, NY.GDP.PCAP.PP.CD, NY.GNP.PCAP.CD, SP.POP.TOTL, SE.PRM.ENRR, SE… | https://databank.worldbank.org/source/world-development-indicators | 2026-05-17 | WDI API live, fetched 2026-05-17 | 6480 | 216 | 1995–2024 | Includes former EdStats education series; pulled via WDI R package |
| **Worldwide Governance Indicators** | va_est, va_se, va_n_src, pv_est, pv_se, pv_n_src, ge_est, ge_se, ge_n_src, rq_e… | https://info.worldbank.org/governance/wgi/ | 2026-05-17 | Native bundle, fetched 2026-05-17 | 5112 | 213 | 1996–2022 | Native source bundle (not via WDI API) — need underlying source-of-sources data |
| **Human Capital Index** | HD.HCI.OVRL, HD.HCI.OVRL.FE, HD.HCI.OVRL.MA, HD.HCI.LAYS, HD.HCI.LAYS.FE, HD.HC… | https://www.worldbank.org/en/publication/human-capital | 2026-05-17 | WDI API live, fetched 2026-05-17 | 2277 | 207 | 2010–2020 | Composite outcome; HD.HCI.HLOS handled separately in HLO source (Session 04) |
| **Harmonized Learning Outcomes** | — | https://datatopics.worldbank.org/education/ | — | — | — | — | —–— | ADR-0004 pins specific version; default HD.HCI.HLOS via WDI API; sensitivity at… |
| **OECD DAC Creditor Reporting System** | — | https://data-explorer.oecd.org/vis?fs[0]=Topic%2C0%7CDevelopment%23DEV%23&pg=0&fc=Topic&bp=true&snb=22&df[ds]=dsDisseminateFinalDMZ&df[id]=DSD_CRS%40DF_CRS&df[ag]=OECD.DCD.FSD&df[vs]=1.4 | — | — | — | — | —–— | Sector codes 110/111/112/113/114; retain description text for ADR-0007 typology… |
| **AidData Core Research Release** | — | https://www.aiddata.org/data | — | — | — | — | —–— | DAC + non-DAC project-level; coverage ~2000-2014 |
| **AidData Global Chinese Development Finance v3.0** | — | https://www.aiddata.org/data/aiddatas-global-chinese-development-finance-dataset-version-3-0 | — | — | — | — | —–— | China-specific aid; complements OECD CRS (China is not DAC member) |
| **UNESCO Institute for Statistics** | — | https://uis.unesco.org/ | — | — | — | — | —–— | Private expenditure share, out-of-school rates; SSA missingness severe pre-2015… |
| **UCDP/PRIO Armed Conflict Dataset** | — | https://ucdp.uu.se/downloads/ | — | — | — | — | —–— | Country-year version (not GED); pin version in catalog at access time |
| **UNESCO COVID-19 School Closures** | — | https://covid19.uis.unesco.org/global-monitoring-school-closures-covid19/country-dashboard/ | — | — | — | — | —–— | Total/partial closure days 2020-2022 by country |
| **Oxford Insights AI Readiness Index** | — | https://oxfordinsights.com/ai-readiness/ | — | — | — | — | —–— | Cross-sectional in our use (single edition, most recent covering target window) |
