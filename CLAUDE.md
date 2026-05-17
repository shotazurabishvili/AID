# AID — Education Aid & Learning Outcomes Paper

A cross-country panel study testing whether ODA-to-education predicts learning outcomes.
Target: **World Development** (Elsevier, IF 5.4). Author: practitioner-researcher (Shota Zurabishvili).

Working title: *"Aid Without Learning: A Cross-Country Analysis of ODA Allocation, Structural Determinants, and the Measurement Failure at the Heart of Global Education Finance."*

Core thesis: **ODA to education predicts enrollment but not learning outcomes, and the structural variables that actually drive learning are systematically ignored by donor allocation models.**

---

## How to start any session

1. Read this file (you're doing it).
2. Read `docs/session_log/CURRENT.md` — the most recent session log; tells you exactly where we stopped.
3. Skim `docs/plan.md` for the phase roadmap.
4. Glance at `docs/decisions/INDEX.md` for the ADR landscape; read any ADR new to you.
5. Skim `docs/methodology.md` — the proto-§3 of the paper; confirms current methodological stance.
6. Pick up the **Next concrete action** listed in the Current state block below.

## How to end any session

**Documentation comes first; do all of these before committing.**

1. **Session log:** append `docs/session_log/YYYY-MM-DD-NN-<short-topic>.md` using `_template.md`. Be specific about decisions captured.
2. **ADR(s):** if any consequential analytical choice was made, write or update an ADR under `docs/decisions/`. Update `docs/decisions/INDEX.md` to reflect status changes.
3. **Methodology narrative:** if the decision shifts a methodological stance, update the relevant section of `docs/methodology.md`. This is the proto-§3 of the paper — keep it current.
4. **Data dictionary:** if you ingested new variables, add rows to `docs/data_dictionary.md`.
5. **Obligations:** if you completed a diagnostic / test / robustness check committed to in `docs/obligations.md`, tick the box and link the evidence.
6. **Lit note:** if you engaged with a cited author, populate or update `docs/lit/<author>.md`.
7. **CLAUDE.md Current state:** update the phase progress, next concrete action, blocked-on, open decisions.
8. **CURRENT.md pointer:** `ln -sf YYYY-MM-DD-NN-<short-topic>.md docs/session_log/CURRENT.md`.
9. **Commit + push:** `git add -A && git commit -m "<type>: <session topic>" && git push`. Use Conventional Commits (`feat`, `data`, `model`, `docs`, `fix`, `chore`).
10. **Sync:** `bash scripts/sync_to_desktop.sh`.

---

## Current state

- **Phase:** 1 — Data Ingestion & Audit (5 of 11 sources complete)
- **Last session:** 2026-05-17 — Session 04 (HLO ingested; ADR-0004 Accepted; methodology §3.4 expanded with empirical Sandefur engagement)
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018` robustness) → `data/interim/{wdi,hci,wgi,uis,hlo,hlo_aap2018}.parquet`
- **Sources pending:** oecd_crs, aiddata_core, aiddata_gcdf, ucdp, covid_closures, ai_readiness (+ optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** 0001, 0004 Accepted; 0002, 0003, 0005–0009 Pending. ADR-0004 carries empirical "Data observed" block (Session 04 finding: `hlo_score` SSA gap −3.2 pp; `hlo_aap` SSA gap +8.75 pp). ADR-0006 carries empirical "Data observed" block (Session 03 finding: private exp 91.8% missing in SSA).
- **Next concrete action:**
  *(Phase 1, Session 05)* Ingest **OECD DAC CRS** (Creditor Reporting System) — the awkward source per `docs/plan.md § Phase 1 — Data ingestion order`. Bulk extract from `data-explorer.oecd.org`; filter to sector codes 110/111/112/113/114 (education); **retain project description text** for [ADR-0007](docs/decisions/0007-oecd-crs-intervention-typology.md) (intervention-typology coding, Phase 7 lock). Touches [ADR-0005](docs/decisions/0005-oda-commitment-vs-disbursement.md) (commitment vs disbursement, Phase 5 lock) and [ADR-0008](docs/decisions/0008-china-aid-inclusion.md) (China inclusion, Phase 5 lock); both stay Pending after Session 05.
- **Open decisions:** None pending.
- **Blocked on:** Nothing.

---

## Project structure

- `docs/` — brief, plan, ADRs, session log, lit notes, positionality
- `data/` — `raw/` (gitignored, immutable), `interim/`, `processed/`; index in `data/catalog.md`
- `R/` — numbered pipeline scripts; `lib/` for shared helpers
- `output/` — tables, figures (synced to Windows mirror); `logs/` gitignored
- `drafts/` — Quarto manuscript + numbered revision snapshots
- `scripts/` — utility scripts (e.g., `sync_to_desktop.sh`)
- `tests/` — reproducibility checks

## Conventions

- R + renv. Never `install.packages()` outside renv — always `renv::install()` then `renv::snapshot()`.
- All R/Quarto invocations must run from `~/AID/` so `.Rprofile` activates renv.
- Numbered scripts: `00_*` setup, `10_*` ingest, `20_*` clean, `30_*` merge, `40_*` eda+audit, `5x_*` models, `60_*` diagnostics.
- Commits: Conventional Commits (`feat:`, `data:`, `model:`, `docs:`, `fix:`, `chore:`).
- **ADR-threshold: when in doubt, write one.** Any decision a hostile *World Development* referee could ask "why this choice and not another" → ADR. Cheap to write, invaluable when defending the paper. Stub future ADRs with Status: Pending so the slot is reserved.
- Session logs are append-only — never edit past sessions, supersede them with new entries.
- Causal language is precise: associations are not causal claims unless identification is defended.
- Indicator lists per source are **pinned in script headers** and committed to git. Changes require an ADR.
- **No fabrication.** Every value in every interim parquet must trace to a downloadable raw source via a pinned upstream indicator code. Missing is `NA`; never sentinel values; never silently imputed in ingestion. Multiple imputation, where used at all, is a transparent Phase-2 sensitivity step gated by [ADR-0006](docs/decisions/0006-uis-missingness-strategy.md) with MCAR-test evidence and listwise/UIS-dropped comparisons reported alongside — never gap-filling that hides as a real observation. Sub-national rows or non-country aggregates dropped during ISO3 normalization are logged to `output/logs/iso3_unresolved_<src>.csv` for audit.

## Engagement model

Claude drives, the author ratifies. Routine analytical calls are documented in the session log + ADRs with reasoning. Only decisions that meaningfully turn on the author's institutional knowledge or framing preference get escalated as questions.

## Key references

**Living documents (update as work progresses):**
- `docs/methodology.md` — proto-§3 of the paper; current methodological stance section by section
- `docs/data_dictionary.md` — canonical definitions of every variable in interim parquets
- `docs/obligations.md` — running checklist of every diagnostic / test / robustness spec we've committed to
- `docs/decisions/INDEX.md` — table of all ADRs with status
- `docs/positionality.md` — working draft of the positionality statement
- `docs/lit/` — one structured note per cited author

**Immutable references:**
- `docs/brief.md` — original research design; source of truth
- `docs/plan.md` — phase roadmap
- `docs/brief.md § Self-Review Protocol` — three adversarial review passes
- Target journal: *World Development* — APA 7, 9–11k words, OSF/GitHub deposit expected, positionality statement in §3
