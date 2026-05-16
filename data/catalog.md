# Data Catalog

Source of truth for every dataset used in the paper. Populated as ingestion scripts run.

For each source, the ingestion script (`R/10_ingest_<source>.R`) must:
1. Download or API-pull the raw data into `data/raw/<source>/`
2. Update the row below with **access date**, **version/year**, **observed rows**, **observed countries**
3. Note any access friction (auth required, rate limits, manual download steps)

| Source | Variables of interest | URL / API | Access date | Version | Raw file(s) | Rows | Countries | Notes |
|---|---|---|---|---|---|---|---|---|
| **Harmonized Learning Outcomes (HLO)** | Learning scores by country × year | https://datatopics.worldbank.org/education/ | — | — | — | — | — | Altinok, Angrist & Patrinos (2018) methodology — cite the paper |
| **PISA** | Math, reading, science scores | https://www.oecd.org/pisa/ | — | — | — | — | — | Triennial since 2000; age-15 cohort |
| **TIMSS** | Math + science, grades 4 and 8 | https://timssandpirls.bc.edu/ | — | — | — | — | — | Quadrennial |
| **PIRLS** | Reading, grade 4 | https://timssandpirls.bc.edu/ | — | — | — | — | — | Quinquennial |
| **OECD DAC CRS** | ODA flows: sector, recipient, year, commitment, disbursement | https://stats.oecd.org/ (CRS) | — | — | — | — | — | Filter sector code 11x (education); large file; bulk download awkward |
| **AidData** | Geocoded aid, project-level | https://www.aiddata.org/ | — | — | — | — | — | Complements OECD with project-level detail; geocoding optional in Phase 1 |
| **EdStats** | Enrollment, expenditure, PTR, teacher salaries | https://datatopics.worldbank.org/education/ | — | — | — | — | — | World Bank; bulk download |
| **WDI** | GDP per capita, GNI, population | https://databank.worldbank.org/source/world-development-indicators | — | — | — | — | — | R package `WDI` makes this trivial |
| **WGI** | Political stability, rule of law, voice & accountability | https://info.worldbank.org/governance/wgi/ | — | — | — | — | — | Cite Langbein & Knack (2010) aggregation critique when using |
| **UNESCO UIS** | Private expenditure share, out-of-school rates | https://uis.unesco.org/ | — | — | — | — | — | Document missing-data rate, especially SSA |
| **Human Capital Index (HCI)** | Composite human capital outcome | https://www.worldbank.org/en/publication/human-capital | — | — | — | — | — | Composite outcome variable |
| **AI Readiness Index** | Country AI capacity | https://oxfordinsights.com/ | — | — | — | — | — | Used in compounding AI penalty section (Phase 9) |

---

## Ingestion order (cheapest to hardest)

1. WDI (R `WDI` package)
2. WGI (R `WDI` exposes WGI)
3. EdStats (bulk download)
4. HCI (CSV download)
5. UNESCO UIS (API or bulk CSV)
6. HLO (download)
7. OECD DAC CRS (large; sector filter)
8. AidData (project-level download)
9. PISA / TIMSS / PIRLS (separate downloads)
10. AI Readiness Index (small CSV per year)

## Panel target

~120 countries × 23 years (2000–2022) = **~2,760 country-year observations** before listwise deletion.

Merge key: ISO3 country code (via `countrycode` package; document unresolved codes) × year.
