# Measuring Aid for Learning: What Cross-Country Panel Evidence Can and Cannot Say

**Author:** Shota Zurabishvili (Independent researcher, Bristol, UK)
**Manuscript target:** *World Development*
**Repository (mirrored):** <https://github.com/shotazurabishvili/AID>
**OSF deposit DOI:** <https://doi.org/10.17605/OSF.IO/JRBT8>

## What this deposit contains

The full analytical apparatus behind the manuscript "Measuring Aid for
Learning: What Cross-Country Panel Evidence Can and Cannot Say":

- The R + renv code base (`code/`)
- The canonical analytical panel (`data/panel.parquet`)
- Twelve pre-analysis plans (`pre_analysis_plans/`) authored before the
  analyses they govern
- Methodology and data dictionary (`documentation/`)
- All analytical outputs as CSV + Markdown (`outputs/`)
- The Quarto manuscript source + rendered DOCX + bibliography (`manuscript/`)

Everything reported in the paper can be reproduced from the artifacts in this
deposit, on a contemporary laptop, in under five minutes.

## Reproduction

```bash
# 1. Restore the locked R environment
Rscript -e 'install.packages("renv"); renv::restore()'

# 2. Reproduce the main analyses (writes to outputs/tables/)
Rscript code/51_model2_fe.R                          # Model 2 family + diagnostics
Rscript code/55_model2_wgi_operationalization.R      # PC1 headline + WGI sensitivity

# 3. Reproduce the peer-review additions (writes to outputs/tables/)
Rscript code/80_peer_review_bootstrap.R              # Wild cluster bootstrap
Rscript code/81_peer_review_placebo.R                # Falsification: future aid
Rscript code/82_peer_review_ssa_heterogeneity.R      # SSA heterogeneity

# 4. Re-render the manuscript
quarto render manuscript/aid_without_learning.qmd --to docx
```

Seeds are fixed at `20260525` in the peer-review scripts. The earlier scripts
do not use random number generation in a sensitivity-significant way.

## Headline result

A within-country two-way fixed-effects specification on the 2010–2020 panel
returns β = +11.14 HLO points per unit of log three-year-lagged constant-dollar
education disbursement (country-clustered SE 5.5; p ≈ 0.05; N = 143). The
manuscript does not present this as a result it owns. The pre-specified design
is built to break it, and three pre-specified checks bite:

1. The intervention typology the policy literature treats as the operative
   axis is not recoverable from CRS metadata (typology agreement: raw 39%,
   κ = 0.19, unclassified 76%).
2. The headline does not survive a swap to the AAP-2018 alternative learning
   measure — sign-reverses on the full sample, falls into noise on matched
   country-years.
3. The multiple-imputation default rests on an MCAR assumption the data
   reject at p < 10⁻⁶.

Three post-review additions further constrain the reading:

4. The headline is significant under only one of four governance
   operationalizations (PC1 composite, p = 0.048; single-composite, p = 0.10).
5. Excluding sub-Saharan Africa cuts the coefficient to β = +4.71 (p = 0.34).
6. A wild cluster bootstrap on the headline returns p = 0.041 (consistent with
   the asymptotic p = 0.048; the small-cluster correction is not binding on
   the headline but is binding on the AAP variants).
7. A placebo using strictly-future aid on the same sample returns β = +4.62
   (p = 0.43) — past aid predicts current learning more strongly than future
   aid does, but the placebo coefficient is non-trivial.

## Pre-analysis plans

The twelve plans (PAP-0001 through PAP-0012) are the documents the
methodology claim rests on. Each plan states the analytical decision, the
options, the criterion that separates them, the threshold the criterion must
clear, and (for plans whose criterion has been evaluated) the post-data
verdict block. The plan files are timestamped in this OSF registration and
mirrored in the GitHub commit history.

PAP-0007 is the single Rejected plan (the intervention typology model whose
agreement criteria failed). PAP-0012 retired the multiple-imputation
robustness direction after Little's MCAR test rejected MCAR.

The peer-review additions (R/80, R/81, R/82) are explicitly labeled as
post-review and are not part of the pre-specified set.

## Data sources

All raw data is publicly available. This deposit holds the merged analytical
panel (`data/panel.parquet`); the data dictionary (`documentation/data_dictionary.md`)
documents the upstream URL and pinned indicator code for every variable. The
canonical sources:

- OECD Creditor Reporting System (DAC1, DAC2a, CRS purpose codes 110–114)
- World Bank Human Capital Index / Harmonized Learning Outcomes (Angrist, Djankov, Goldberg, Patrinos 2021)
- Altinok-Angrist-Patrinos (2018) Global Data Set on Education Quality
- World Development Indicators (GDP, enrollment, education expenditure, PTR)
- Worldwide Governance Indicators (six aggregates; PC1 used as headline governance control)
- AidData Global Chinese Development Finance
- UCDP/PRIO Armed Conflict Dataset
- UNESCO COVID-19 school-closure time series

## License

- **Documents** (manuscript, PAPs, methodology, data dictionary): **CC-BY 4.0** — attribute and reuse.
- **Code** (R scripts): **MIT** — minimal-friction reuse for replication.

## Citation

If you build on this work, please cite:

> Zurabishvili, S. (2026). Measuring Aid for Learning: What Cross-Country
> Panel Evidence Can and Cannot Say. [Manuscript and replication archive].
> OSF. https://doi.org/10.17605/OSF.IO/JRBT8

## Contact

shota.zurabishvili@gmail.com — for questions about the analysis,
methodology, or for collaboration on extensions.
