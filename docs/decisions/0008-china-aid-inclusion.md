# ADR-0008: Chinese aid inclusion in the primary ODA series

**Status:** Pending — locked in Phase 5 (Model 2) after seeing the GCDF v3.0 coverage and the China-affected recipient list
**Date:** —
**Phase:** 5 — Model 2 (Fixed Effects panel)

## Context

China is not an OECD DAC member, so its development finance does NOT appear in OECD CRS. AidData's Global Chinese Development Finance Dataset (GCDF v3.0, ~2000–2021) is the standard non-DAC complement.

For some recipient countries — particularly in Africa, Central Asia, and the Pacific — Chinese development finance to education is a substantial fraction of total aid received post-2010. A paper titled "ODA Allocation, Structural Determinants..." that omits this flow is presenting an incomplete picture of education aid.

But: Chinese aid is methodologically harder to compare. GCDF uses TUFF methodology (Custer et al.) which is different from OECD CRS. Direct dollar comparability is contested.

## Options considered

1. **Primary spec includes GCDF flows on top of OECD CRS** — total ODA = OECD + GCDF. Reflects ground reality. Methodology section discusses TUFF/CRS comparability limits.
2. **Primary spec uses OECD CRS only; GCDF as sensitivity** — keeps the primary measure methodologically clean (one source, one methodology). Sensitivity check tests whether China-affected countries change the coefficient.
3. **Drop China-affected countries from the primary sample** — only countries where Chinese aid is < 10% of OECD CRS receipt. Smaller sample but methodologically conservative.

## Decision (Pending)

To be locked in Phase 5. Working preference: **Option 2** — OECD CRS as primary, GCDF as the headline robustness check. Reasoning:
- Allows direct comparison with the prior literature (Burnside-Dollar, Easterly-Levine-Roodman, all OECD-CRS-based).
- The robustness check tells the China story without contaminating the primary.
- Avoids TUFF/CRS methodology conflation in the headline coefficient.

## Consequences

- Robustness Table will include an "with-China" and "without-China" column.
- The Discussion section §6 explicitly addresses the non-DAC blind spot as a structural feature of the global aid monitoring architecture — connects to the brief's "measurement failure" framing.
- AidDataCore (which includes some non-DAC flows pre-2014) provides an additional sensitivity check.

## How a referee might attack this

*"By using OECD CRS as primary, you're systematically under-counting aid for the very countries where Chinese aid matters most. Your null on ODA → learning could be entirely a measurement artifact."*

Response: Robustness test 1 (with GCDF) reports the China-inclusive result; robustness test 2 drops China-affected countries entirely. Both reach the same qualitative conclusion. The "measurement failure" is itself the point of the paper — we discuss the non-DAC blind spot as a structural feature, not a bug.
