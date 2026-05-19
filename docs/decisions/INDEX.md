# ADR Index

Auto-maintainable index of all Architecture Decision Records.

**Update protocol:** every time an ADR is written or its status changes, update the row here. Keep the table sorted by ADR number.

| # | Title | Status | Decided | Phase locked | What it decides |
|---|---|---|---|---|---|
| [0001](0001-toolchain-and-scaffolding.md) | Toolchain and project scaffolding | Accepted | 2026-05-16 | 0 | R + renv on WSL; private GitHub; CLAUDE.md + per-session-log + ADR continuity model |
| [0002](0002-country-universe.md) | Country universe | Accepted | 2026-05-18 | 1 (Session 09) | Option 1: ODA-eligible ∩ ≥1 HLO. **N=133 countries** (Model-2 FE: 127 with ≥2 HLO obs) |
| [0003](0003-year-range.md) | Year range | Accepted | 2026-05-18 | 1 (Session 09) | **2010–2020 primary** (HCI-cycle-anchored); 2000–2022 + 2005–2020 reported in parallel as robustness |
| [0004](0004-hlo-measure.md) | HLO score harmonization | Accepted | 2026-05-17 | 1 (Session 04) | WB `HD.HCI.HLOS` primary; AAP-2018 robustness |
| [0005](0005-oda-commitment-vs-disbursement.md) | ODA commitment vs disbursement (+ lag structure) | Accepted | 2026-05-19 | 5 (Session 03) | **Primary: `crs_disburse_usd_defl_ma3_lag1`** (disburse × constant USD × 3-yr strictly-past MA, mean of t-3,t-2,t-1). Robustness: trailing-inclusive MA, raw, commitment. 16-cell sensitivity grid: all HLO β ≥ 0, no sign flips. |
| [0006](0006-uis-missingness-strategy.md) | UIS missingness strategy | Accepted | 2026-05-18 | 2 (Session 01) | **Option 3: drop UIS from primary** (WDI controls only); UIS-augmented listwise + MI as robustness |
| [0007](0007-oecd-crs-intervention-typology.md) | OECD CRS intervention typology coding | Pending | — | 7 (Model 4 ANOVA) | Rule-based keyword vs LLM-assisted classification |
| [0008](0008-china-aid-inclusion.md) | Chinese aid inclusion in primary ODA | Accepted | 2026-05-19 | 5 (Session 04) | **Option 2 confirmed.** OECD CRS primary; GCDF as parallel robustness. Empirical: adding GCDF as covariate shifts the OECD β from 8.17 to 8.06 (0.02 SD, within ±1 SD criterion); GCDF own coefficient null (β=−0.27, p=0.74). |
| [0009](0009-wgi-operationalization.md) | WGI operationalization in models | Accepted | 2026-05-19 | 5 (Session 05) | **Option 1 (PCA-collapsed PC1) primary.** PC1 captures 76.4% of WGI variance (Langbein-Knack engagement); β_ODA=11.1, p=0.048 (vs single-GE β=8.17, p=0.10). Option 2 (single GE) + Option 3 (all six, max demeaned VIF=4.71) as parallel robustness. |
| [0010](0010-identification-strategy-gmm.md) | Identification strategy (System GMM) | Accepted (with caveats) | 2026-05-19 | 5 (Session 02) | System GMM attempted; Hansen p=0.022 rejects validity (small-T limitation); Bond bounds degenerate. Static FE remains headline; §3 acknowledges identification limits transparently. |

---

## Status meanings

- **Accepted** — decision locked, applies to all subsequent work
- **Pending** — anticipated decision; placeholder with options laid out; lock at the named phase
- **Superseded by ADR-MMMM** — replaced; refer to the new ADR for the current position
- **Deprecated** — no longer applicable (e.g., a tool we stopped using); kept for historical record
