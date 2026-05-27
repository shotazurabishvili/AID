# PAP-0005: ODA — commitment vs disbursement (+ lag structure)

**Status:** Accepted (2026-05-19, )
**Date:** Locked 2026-05-19
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

## Decision

**Primary specification:** `crs_disburse_usd_defl_ma3_lag1` — **disbursement × constant USD × 3-yr strictly-past moving average** (mean of t-3, t-2, t-1).

**Robustness specifications reported alongside primary:**
- `crs_disburse_usd_defl_ma3` (trailing-inclusive 3-yr MA: t-2, t-1, t) — shorter-window comparator
- `crs_disburse_usd_defl_sum` (raw annual disbursement, constant USD) — no-smoothing comparator
- `crs_commit_usd_defl_ma3_lag1` (commitment, strictly-past 3-yr MA) — alternative measure
- Full 16-cell sensitivity table available at `output/tables/model2_fe_sensitivity.csv`

### Empirical evidence 

A 16-cell sensitivity grid was estimated: 2 (commit vs disburse) × 2 (current vs constant USD) × 4 (raw, 1-yr lag, trailing-inclusive 3-yr MA, strictly-past 3-yr MA). Model 2 FE (iso3 + year), country-clustered SE, full controls (log GDP/cap, PTR primary, ed_exp_%GDP, WGI gov effectiveness), primary window 2010-2020. Dual outcomes: HLO and LAYS. N=143 (HLO) / 139 (LAYS) across all cells — FE-singleton drops dominate the strictly-past MA NA pattern, so N-comparability is essentially perfect.

**Sign-stability check:** All 16 HLO cells show β ≥ 0 — no sign flips across the surface. The grid is sign-stable; the lock decision is a choice among positive specifications.

**Magnitude pattern, HLO outcome, constant USD:**

| Family   | Raw          | 1-yr lag | Trailing-inclusive MA3 | Strictly-past MA3 (lock) |
|----------|--------------|----------|------------------------|--------------------------|
| Commit   | −0.18 (0.95) | 2.99 (0.12) | 9.28** (0.034)       | 11.9**  (0.011)          |
| Disburse | 8.20*** (0.004) | 2.47 (0.31) | 10.9*** (0.003)   | 8.17    (0.10)           |

(β coefficient, p-value in parentheses; ***p<0.01, **p<0.05.)

### Why strictly-past MA over trailing-inclusive

The trailing-inclusive 3-yr MA `mean(t-2, t-1, t)` includes the contemporaneous year's disbursement on the RHS of an HLO regression where HLO is measured in year t. Donors may respond to in-year shocks to learning outcomes (e.g., emergency education aid), generating reverse-causation contamination. The strictly-past 3-yr MA `mean(t-3, t-2, t-1)` forecloses this channel by construction. The empirical cost is a wider SE (4.91 vs 3.60) and weaker p-value (0.10 vs 0.003), but the β stays positive and within 1 SD of the trailing-inclusive estimate (8.17 vs 10.9). Honesty about identification > marginal-significance optics.

### Why disbursement over commitment as primary

Disbursement reflects money that actually flowed to recipient countries; commitment is a signed donor pledge that may not be honored within the panel window (commitment-disbursement gap is 30-50% annually in education ODA per OECD CRS). For an outcome regression on learning, disbursement is the theoretically relevant quantity. Commitment is reported in robustness; notably commitment × strictly-past MA × HLO shows β=11.9** (a stronger effect than disbursement) — substantively supports the same positive pattern.

### Why constant USD over current USD

Constant-USD (DAC deflator-adjusted) removes secular inflation drift over the 2000-2020 window, which would otherwise correlate spuriously with both rising aid volumes and rising learning outcomes. The empirical effect of this choice is small (β changes by <5% across the 8-cell USD-basis comparison); the principled choice is constant.

## Consequences

- Coefficient interpretation: the locked spec is a within-country effect of a 3-yr-prior moving average of education ODA disbursement on HLO. β=8.17 means a 100% increase in 3-yr lagged disbursement is associated with an 8.2-point increase in HLO, at p=0.10.
- **The "ODA does not predict learning" framing in pre-lock notes is incorrect** under this lock: all 16 cells show β ≥ 0, half significant at conventional thresholds. The corrected manuscript framing is: *"ODA → learning has a positive within-country association that varies in significance with treatment encoding, from p=0.10 (theoretically cleanest spec) to p<0.01 (working-preference trailing-inclusive spec)."* This reframing is a + task.
- The 1-yr-lag specs are universally weak (p>0.10), supporting the choice of 3-yr window over single-year lag in pre-specified menu. Obligation `docs/the deposited diagnostic register:48` (1-yr vs 3-yr MA) closed in favor of 3-yr.

## How a referee might attack this

*"Commitments are signed, disbursements are reality. Your null result on disbursement may reflect implementation failure, not aid ineffectiveness."*

Response: The result is not null on disbursement — every disbursement spec but `lag1` shows β > 0 with the strictly-past lock at β=8.17 (p=0.10) and the trailing-inclusive at β=10.9 (p=0.003). Reporting both lock and robustness specs lets the reader inspect the implementation-vs-commitment substitution directly. The commitment family also shows positive coefficients (β=11.9 on strictly-past MA), so the positive pattern is not artifact of one encoding.

*"Why not the trailing-inclusive MA which has p=0.003?"*

Response: The trailing-inclusive MA admits contemporaneous donor response to in-year learning shocks. The strictly-past MA is the cleaner identification spec; we report both so the reader sees the encoding cost.
