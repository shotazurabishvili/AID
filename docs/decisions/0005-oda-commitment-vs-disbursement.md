# ADR-0005: ODA — commitment vs disbursement

**Status:** Pending — locked in Phase 5 (Model 2 FE panel) after the commitment-disbursement gap is observed in OECD CRS
**Date:** —
**Phase:** 5 — Model 2 (Fixed Effects panel)

## Context

OECD DAC CRS reports two distinct ODA measures:
- **Commitment** — firm written obligation by donor, signed in year t
- **Disbursement** — actual flow of funds, may span years t through t+5 depending on project

For education ODA the commitment-disbursement gap can be 30–50% of commitment in any given year. The choice of measure shapes the headline coefficient on ODA → learning.

## Options considered

1. **Disbursement (preferred for a learning-outcome regression)** — money that actually flowed reaches schools, teachers, materials. Smaller annual values; lagged structure.
2. **Commitment** — captures donor intent; cleaner signal of donor allocation decisions but doesn't reflect what hit the ground.
3. **Both, reported separately** — primary spec uses disbursement; commitment in robustness.

## Decision (Pending)

To be locked after Phase 1 Session 05 ingests CRS and Phase 5 sees the within-country variance of each measure. Working preference: **Option 3** — disbursement primary, commitment as robustness, both with 3-year lagged moving averages to absorb implementation delay.

## Consequences

- Coefficient interpretation depends sharply on this choice. The paper's §3 (Methodology) and Table 2 (model output) must be explicit about which measure is being interpreted.
- Lag structure adds an additional ADR-worthy choice: 1y vs 3y MA (brief flags this for sensitivity in Phase 5).

## How a referee might attack this

*"Commitments are signed, disbursements are reality. Your null result on disbursement may reflect implementation failure, not aid ineffectiveness."*

Response: That distinction is the substantive point — the paper argues precisely that **implementation quality matters more than commitment volume**. Reporting both lets the reader trace this directly: if commitment and disbursement give the same null, the implementation-quality story is not what's driving the result.
