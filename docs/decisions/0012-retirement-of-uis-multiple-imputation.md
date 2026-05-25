# PAP-0012: Retirement of UIS multiple imputation (amends PAP-0006)

**Status:** Accepted
**Date:** 2026-05-23
**Phase:** 10 — Statistical Validity, 
**Amends:** [PAP-0006](0006-uis-missingness-strategy.md) (Robustness 2 sub-commitment only; PAP-0006's primary lock — drop UIS from primary — is unaffected.)

## Context

PAP-0006 (Accepted 2026-05-18) committed to three sensitivity directions for the UIS-missingness question:

- **Primary:** drop UIS controls from the headline specification (Option 3).
- **Robustness 1:** UIS-augmented listwise spec on the listwise-complete subset.
- **Robustness 2 (implementation):** Multiple-imputation UIS-augmented spec on the full sample.

The multiple-imputation robustness was deferred and never executed; this pre-analysis plan audits the intent before deciding whether to execute or formally retire it.

## Why retire MI

Four reasons, in order of weight:

1. **MCAR was rejected at p ≪ 10⁻⁶ on both panels** (`output/tables/production_mcar_test_result.txt`: 6-col χ²=175.80, p<10⁻⁶; `output/tables/production_mcar_with_uis.txt`: 7-col χ²=341.90, p<10⁻⁶). MI's MAR assumption — that conditional on observables the missingness is random — is therefore not empirically supported on this data. Defending MI under a MNAR mechanism requires either a selection model (out of scope) or the willingness to publish results whose validity depends on an assumption the data refutes.

2. **the project no-fabrication principle conflict.** The project explicitly states: *"Multiple imputation, where used at all, is a transparent sensitivity step gated by PAP-0006 with MCAR-test evidence... never gap-filling that hides as a real observation."* MCAR is the gate; MCAR was rejected; the gate forecloses MI in this project's own framework.

3. **Robustness 1 covers the same direction.** PAP-0006 Robustness 1 (UIS-augmented listwise) was executed in  (`output/tables/pass1_uis_listwise.{csv,md}`). It tests the same direction of robustness — "does the result hold when UIS is added back?" — without invoking MI's contested assumption. If MI and listwise both ran and agreed, the result would be doubly robust; if they disagreed, MI's MAR assumption would be the obvious suspect. Listwise alone is the cleaner test.

4. **Within-FE absorbs most cross-country UIS heterogeneity.** Model 2's country fixed effects soak up time-invariant cross-country differences in private-spending share. The information MI would add is at the year-within-country level, which is sparse and noisy for UIS variables to begin with.

## Decision

Retire the MI Robustness-2 sub-commitment from PAP-0006. The UIS-missingness sensitivity now rests on two specs only:

- **Primary** (PAP-0006 Option 3): drop UIS, WDI controls only. **Locked.**
- **Robustness 1**: UIS-augmented listwise spec on the listwise-complete subset. **Executed .** Result: β_ODA = −1.97 (SE 4.40, N = 41 post-singleton-drop, p > 0.05). The ODA coefficient is sign-flipped vs primary but non-significant; the 95% CIs partially overlap (primary [0.32, 21.95]; listwise [−10.59, 6.66]). This is *weak robustness*: the result is not contradicted but is not strongly confirmed either at the listwise sample size. Reported transparently in `the manuscript` and the audit doc.

This amendment does **not** affect PAP-0006's primary lock (drop UIS from primary). It only retires the deferred Robustness-2 MI sub-spec.

## Consequences

- `mice` need not be added to renv.
- PAP-0009's "may be needed for the imputation model specification" hook (line in PAP-0006 consequences) is moot.
- sign-off (audit doc) reports two UIS-missingness robustness specs, not three.
- The manuscript should report the listwise robustness result alongside the primary, with the explicit note that MI was considered and retired per the MCAR gate + no-fabrication principle. The §6 limits paragraph already owns the UIS-missingness story openly per PAP-0006.

## How a referee might attack this

*"You retired the MI robustness check after seeing the listwise result was unfavorable — that's specification-search by omission."*

The timeline rebuts this. PAP-0006 (Accepted 2026-05-18) explicitly hedged MI's status: "where used at all". The MCAR test result (, before any Model 2 run) was already on disk and already rejected MCAR at p ≪ 10⁻⁶. The grounds for retiring MI were established *before* any result was generated; the retirement decision is documented in this ADR with the rationale on the record. The listwise result is reported transparently in §5.8 with the same hedging the primary headline gets.

*"MI under MNAR is the standard tool; you're using the failed MCAR test as an excuse to avoid the harder test."*

MNAR sensitivity analyses (e.g., pattern-mixture models, Heckman selection corrections) would be the correct response to MNAR data — and those are explicitly out of scope for this paper's data shape (small-T, ~T_eff ≤ 4) and identification design (static FE, not GMM). The honest response to MCAR rejection + MNAR-tool out-of-scope is to retire the MI commitment, document the reasoning, and acknowledge the resulting limit. That's what this ADR does. Robustness 1 (listwise) remains the operative UIS-inclusion robustness check.

*"Why is this ADR needed if you're just dropping a sub-commitment?"*

Because PAP-0006 made an explicit commitment in writing. Silently dropping it would be exactly the methodological-convenience move the project's discipline pattern (PAP-0007 Rejected, etc.) has avoided throughout. Writing this ADR amendment is the housekeeping cost of honoring the original ADR's status as a load-bearing document.
