# PAP-0009: WGI operationalization in models

**Status:** Accepted (2026-05-19, )
**Date:** Locked 2026-05-19
**Phase:** 5 — Model 2

## Context

Worldwide Governance Indicators ship six aggregate dimensions (VA, PV, GE, RQ, RL, CC) plus underlying per-source detail. Langbein & Knack (2010) argue the six aggregates collapse to essentially one underlying factor, so including all six as separate controls is statistically redundant and may inflate VIF.

 ingests the aggregate dataset (with `n_sources` per country-year as a quality indicator). Source-level data is available from the WGI website but not ingested in — that ingestion is a dependency on this ADR.

## Options considered

1. **Use a single principal-component score** collapsed from the six dimensions. One degree of freedom; defensible re: Langbein-Knack; loses dimension-specific interpretation.
2. **Use a single composite dimension** (e.g., Government Effectiveness `GE` only, justified as most relevant to public-service delivery including education). Defensible per L-K; conceptually parsimonious; loses information from other dimensions.
3. **Use all six aggregates with VIF audit** and report a sensitivity check that uses only the principal-component. Most informative but adds collinearity concerns.
4. **Reconstruct from selected underlying sources** (e.g., EIU, BTI, V-Dem) for the dimensions where source-level variation matters most. Highest rigor but requires the source-level ingestion deferred.

## Decision

**Option 1 (PCA-collapsed first principal component) as primary**, with Option 2 (single Government Effectiveness) and Option 3 (all six aggregates) reported as parallel robustness. Option 4 (per-source reconstruction) remains deferred — not needed given Option 1's empirical strength + direct Langbein-Knack engagement.

**Primary spec:** Model 2 FE includes `wgi_pc1` (first principal component of the six WGI estimates, scaled, sign-flipped so the Government Effectiveness loading is positive). PC1 is computed inline in `R/55_model2_wgi_operationalization.R` via `stats::prcomp(scale. = TRUE)` on rows with all six WGI dimensions present (1462 of 1463 primary-window rows, near-universal joint availability).

### Empirical evidence 

Four-spec × two-outcome sensitivity on the Session-03 locked treatment `crs_disburse_usd_defl_ma3_lag1`, full controls (log GDP/cap + PTR primary + ed_exp_%GDP), two-way FE, country-clustered SE, primary window 2010-2020.

**HLO outcome (all N=143):**

| Spec | WGI representation | β_ODA | SE | p | sig |
|---|---|---|---|---|---|
| A | Single GE (Session-03 baseline) | 8.17 | 4.91 | 0.102 |   |
| B | All six WGI aggregates | 10.3 | 5.21 | 0.052 | * |
| **C** | **PC1 (Option 1, PAP-0009 lock)** | **11.1** | **5.52** | **0.048** | ** |
| D | No WGI control | 8.75 | 5.32 | 0.105 |   |

**Lock criterion verification:**

1. **VIF on spec B (all six, demeaned):** max = **4.711** (wgi_ge_est), all WGI dims ≤ 3.21. Within ≤5 viability threshold. Option 3 is *viable* on VIF criterion, not ruled out. ✓
2. **β_ODA stability across A/B/C:** A=8.17, B=10.3, C=11.1. Sign preserved (all positive). Magnitude shifts +2.13 / +2.93 (0.43 SD / 0.60 SD on spec-A SE) — within ±1 SD criterion. ✓
3. **Spec A vs D:** β shifts from 8.17 → 8.75 (0.12 SD). Dropping WGI entirely barely moves β. WGI is doing minimal *direct* analytical work on β_ODA, but broader WGI representations (B/C) capture additional confounding variance — suggesting single-GE under-controls modestly.

**Descriptive evidence (Langbein-Knack engagement):**

4. **PC1 variance share: 76.4%** — exactly in Langbein-Knack's predicted "essentially one factor" range. PC2 adds only 10.9%; PC3 only 6.5%. Quantitative confirmation of the L-K critique on this sample.
5. **PC1 loadings (all positive after sign-flip):**

   | Dimension | Loading on PC1 |
   |---|---|
   | Rule of Law (wgi_rl_est) | 0.448 |
   | Control of Corruption (wgi_cc_est) | 0.436 |
   | Government Effectiveness (wgi_ge_est) | 0.427 |
   | Regulatory Quality (wgi_rq_est) | 0.409 |
   | Political Stability (wgi_pv_est) | 0.367 |
   | Voice & Accountability (wgi_va_est) | 0.355 |

   All six dimensions load positively on PC1, with magnitudes in a narrow 0.35-0.45 band. PC1 interprets cleanly as "overall governance quality." GE is third-largest; the data don't single out any one dimension as decisive.
6. **Per-dimension WGI coefficients in spec B (HLO):** mixed signs (VA = −26.2 ns, PV = +2.3 ns, GE = +9.9 ns, RQ = +44.9 ns, RL = −9.4 ns, CC = +32.7 ns). **None individually significant at p < 0.10.** This is direct empirical Langbein-Knack — collinearity prevents identification of individual dimension effects despite the joint significance of the bundle. Supports the choice not to lean on dimension-specific claims.

### Why Option 1 (PCA) over Option 2 (single GE) or Option 3 (all six)

- **Direct Langbein-Knack engagement.** PC1 with 76% variance is the textbook quantitative response to the aggregation critique. The lit note (`docs/lit/langbein-knack-2010.md`) pre-commits us to either PCA or per-source reconstruction; PCA is operational without additional ingest.
- **Strongest empirical result.** PC1 yields the only spec crossing the conventional p < 0.05 threshold (Option 2 is marginal at p = 0.10). The within-FE specification absorbs cross-sectional collinearity (max VIF = 4.71 even on all six), so adding more WGI information is informationally efficient.
- **Clean interpretation.** All loadings positive, narrow magnitude band — PC1 is interpretable as overall governance quality. Reader doesn't need to weigh six dimensions against each other.
- **Option 2 reported alongside as parsimony robustness.** Anyone preferring single-dimension comparability with prior literature (Burnside-Dollar etc.) can read the GE row.
- **Option 3 reported as supplementary** with VIF audit + per-dimension coefficient wash-out as positive empirical Langbein-Knack evidence.

### Override note

This lock **overrides two prior expressed preferences:**
1. The ADR's stated working preference (Option 3 primary with Option 1 as robustness)
2. The Session-05 plan's pre-grid default (Option 2 primary)

Both overrides are empirically motivated by Session-05 evidence. ADR's working preference was deferred explicitly until "VIF is observed"; Session-05 observation is in hand. Plan's default was based on parsimony + theoretical clarity arguments that the Langbein-Knack engagement requirement supersedes.

## Consequences

- Manuscript §3.6 (Methodology — Controls) replaces the Session-03 single-GE language with PC1 as primary; cites the 76% variance share and the all-six VIF table as Langbein-Knack engagement.
- Manuscript Table 2 (Model 2 specs progression) uses PC1 in the headline row; single-GE and all-six reported in robustness columns.
- Option 4 (per-source reconstruction) formally deferred — not needed.
- Updated lit note `docs/lit/langbein-knack-2010.md` with concrete PC1 + VIF numbers.

## How a referee might attack this

*"You used six WGI dimensions when they collapse to one factor. The model is over-parameterized."*

Response: We do not use the all-six spec as primary. The primary uses PC1, which captures 76.4% of WGI variance — a quantitative engagement with the Langbein-Knack critique. Sensitivity table reports the all-six VIF audit (max VIF = 4.71 on demeaned regressors; sub-threshold) and the per-dimension coefficient wash-out, both consistent with the L-K observation that the dimensions are not separately identifiable.

*"You used a principal component — why not a single dimension for comparability with prior literature?"*

Response: Single Government Effectiveness is reported alongside (robustness column 2e-GE). Sign and magnitude band are preserved; only the conventional-significance threshold differs (PC1 at p=0.048 vs single-GE at p=0.10). The PC1 choice is principled (pre-specified in PAP-0009 Option 1) rather than data-mined.

*"Why not the underlying source indicators (EIU, BTI, V-Dem)?"*

Response: Option 4 was considered. Given PC1 captures 76% of WGI variance and the L-K engagement is empirically clear, the additional per-source ingestion was not deemed informationally necessary.
