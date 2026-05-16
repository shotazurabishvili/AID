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
4. Glance at `docs/decisions/` for any ADR you haven't seen.
5. Pick up the **Next concrete action** listed in the Current state block below.

## How to end any session

1. Append a new session file: `docs/session_log/YYYY-MM-DD-NN-<short-topic>.md` using `docs/session_log/_template.md`.
2. Update the `CURRENT.md` pointer: `ln -sf YYYY-MM-DD-NN-<short-topic>.md docs/session_log/CURRENT.md`.
3. If a consequential analytical choice was made, write an ADR under `docs/decisions/` using `_template.md`.
4. Update the **Current state** block in this file (phase / next action / blocked-on / open decisions).
5. Commit and push: `git add -A && git commit -m "session NN: <topic>" && git push`.
6. Refresh the Windows-side mirror: `bash scripts/sync_to_desktop.sh`.

---

## Current state

- **Phase:** 0 — Infrastructure (complete)
- **Last session:** 2026-05-17 — bootstrap (session 00) closed
- **Toolchain state:** R 4.3.3 on WSL Ubuntu 24.04; 188 packages locked in `renv.lock`; cmake + libuv1-dev installed as transitive build deps; `gh` repo `shotazurabishvili/AID` (private) pushed
- **Next concrete action:**
  *(Phase 1, session 01)* Ingest the cheapest data source first — **WDI** via the R `WDI` package — to validate the ingestion pattern end-to-end before tackling the awkward sources (OECD CRS, AidData). Write `R/10_ingest_wdi.R` that pulls the brief's WDI indicators (GDP per capita, GNI, population) for ISO3 × year, caches raw extract to `data/raw/wdi/`, normalizes country codes via `countrycode`, writes interim parquet to `data/interim/wdi.parquet`, and updates `data/catalog.md` with access date + row count.
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
- Numbered scripts: `00_*` setup, `10_*` ingest, `20_*` clean, `30_*` merge, `40_*` eda, `5x_*` models, `60_*` diagnostics.
- Commits: Conventional Commits (`feat:`, `data:`, `model:`, `docs:`, `fix:`, `chore:`).
- ADR per analytical decision a referee could question (variable operationalization, missingness strategy, group coding, sample restrictions, commitment-vs-disbursement, etc.).
- Session logs are append-only — never edit past sessions, supersede them with new entries.
- Causal language is precise: associations are not causal claims unless identification is defended.

## Engagement model

Claude drives, the author ratifies. Routine analytical calls are documented in the session log + ADRs with reasoning. Only decisions that meaningfully turn on the author's institutional knowledge or framing preference get escalated as questions.

## Key references

- Original brief: `docs/brief.md` (immutable source of truth)
- Phase roadmap: `docs/plan.md`
- Adversarial review protocols: `docs/brief.md § Self-Review Protocol`
- Target journal: World Development — APA 7, 9–11k words, OSF/GitHub deposit expected, positionality statement in §3
