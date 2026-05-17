# ADR-0006: UIS missingness strategy

**Status:** Pending — locked in Phase 2 (Panel construction) after the SSA missingness pattern is characterized in Phase 1 Session 03 (UIS ingest)
**Date:** —
**Phase:** 2 — Panel construction

## Context

UNESCO UIS data on private education expenditure share and detailed out-of-school rates is severely missing for sub-Saharan Africa, especially pre-2015 — coverage rates can fall to 30–50% in this subset. The brief flags this explicitly:

> *"Private expenditure: document missing data rate, especially SSA"*
> *"Missingness strategy: test MCAR, choose MI or listwise deletion, run sensitivity analysis both ways"*

The choice between multiple imputation (MI) and listwise deletion is consequential: MI keeps SSA observations but introduces imputation-model assumptions; listwise drops them and risks selection bias.

## Options considered

1. **Multiple Imputation (Amelia / mice)** for UIS variables where missingness is conditional on observable governance/income covariates (MAR). Run 5–10 imputations; pool via Rubin's rules.
2. **Listwise deletion** for any country-year with UIS missing on the primary controls. Smaller, cleaner sample.
3. **Drop UIS controls from the primary specification entirely** — use only WDI controls (which have higher coverage). Report UIS-augmented specs as robustness on the listwise-complete subset.

## Decision (Pending)

To be locked after seeing:
- The Little MCAR test result from `R/lib/coverage.R::ssa_missingness_pattern()` run on UIS data in Session 03
- The combined coverage matrix in Session 09

Working preference: **Option 3** — keep the primary specification minimal (using WDI controls only) to maximize sample retention; UIS-augmented spec reported as robustness. This pre-empts the "imputation drove the result" critique.

## Consequences

- The primary Model 2 likely has a larger N than UIS-augmented specs.
- Sensitivity table in robustness reports both listwise UIS-included and MI UIS-included variants.
- ADR-0009 may be needed for the imputation model specification if MI is used.

## How a referee might attack this

*"Multiple imputation rescued your sample but smuggled in assumptions about the missing-data mechanism."*

Response: Primary spec doesn't impute. Robustness reports both directions: the result is the same sign and within-CI under listwise, MI, and UIS-dropped specifications. We provide the imputation diagnostic plots and the MCAR test result openly.

*"Dropping UIS controls means you're not adjusting for private spending, which differs systematically by region."*

Response: Private spending share is largely time-invariant within country — absorbed by country fixed effects in Model 2. Cross-sectional variation in private spending is real but enters through the country FE, not as a within-country control.
