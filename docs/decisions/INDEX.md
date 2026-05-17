# ADR Index

Auto-maintainable index of all Architecture Decision Records.

**Update protocol:** every time an ADR is written or its status changes, update the row here. Keep the table sorted by ADR number.

| # | Title | Status | Decided | Phase locked | What it decides |
|---|---|---|---|---|---|
| [0001](0001-toolchain-and-scaffolding.md) | Toolchain and project scaffolding | Accepted | 2026-05-16 | 0 | R + renv on WSL; private GitHub; CLAUDE.md + per-session-log + ADR continuity model |
| [0002](0002-country-universe.md) | Country universe | Pending | — | 1 (Session 09) | Which ~120 countries enter every downstream model |
| [0003](0003-year-range.md) | Year range | Pending | — | 1 (Session 09) | 2000–2022 primary; 2005–2020 robustness |
| [0004](0004-hlo-measure.md) | HLO score harmonization | Pending | — | 1 (Session 04) | WB `HD.HCI.HLOS` primary; AAP-2018 robustness |
| [0005](0005-oda-commitment-vs-disbursement.md) | ODA commitment vs disbursement | Pending | — | 5 (Model 2) | Disbursement primary; commitment robustness; lag structure |
| [0006](0006-uis-missingness-strategy.md) | UIS missingness strategy | Pending | — | 2 (Panel construction) | Listwise vs MI vs drop-UIS-controls for SSA-sparse variables |
| [0007](0007-oecd-crs-intervention-typology.md) | OECD CRS intervention typology coding | Pending | — | 7 (Model 4 ANOVA) | Rule-based keyword vs LLM-assisted classification |
| [0008](0008-china-aid-inclusion.md) | Chinese aid inclusion in primary ODA | Pending | — | 5 (Model 2) | OECD CRS primary; GCDF robustness |
| [0009](0009-wgi-operationalization.md) | WGI operationalization in models | Pending | — | 5 (Model 2) | All-six aggregates with VIF audit + PCA-collapsed robustness, vs single composite vs reconstructed-from-sources |

---

## Status meanings

- **Accepted** — decision locked, applies to all subsequent work
- **Pending** — anticipated decision; placeholder with options laid out; lock at the named phase
- **Superseded by ADR-MMMM** — replaced; refer to the new ADR for the current position
- **Deprecated** — no longer applicable (e.g., a tool we stopped using); kept for historical record
