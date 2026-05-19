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

1. **Session log:** append `docs/session_log/YYYY-MM-DD-NN-<short-topic>.md` using `_template.md`. Be specific about decisions captured. Fill the "What we tried that didn't work" section honestly — failed approaches preserve the reasoning trail that the committed code doesn't show.
2. **ADR(s):** if any consequential analytical choice was made, write or update an ADR under `docs/decisions/`. Update `docs/decisions/INDEX.md` to reflect status changes.
3. **Methodology narrative:** if the decision shifts a methodological stance, update the relevant section of `docs/methodology.md`. This is the proto-§3 of the paper — keep it current.
4. **Findings:** if the session produced substantive empirical findings (coefficients, coverage numbers, region-level patterns, MCAR results, novel comparisons), add them to `docs/findings.md` under the relevant §4/§5/§6 subsection. One-line claim (bold) + key numbers + evidence pointer. This is the proto-§4/§5/§6 of the paper — keep it current; future-you in Phase 11 (Writing) will thank you.
5. **Data dictionary:** if you ingested new variables, add rows to `docs/data_dictionary.md`.
6. **Obligations:** if you completed a diagnostic / test / robustness check committed to in `docs/obligations.md`, tick the box and link the evidence.
7. **Lit note:** if you engaged with a cited author, populate or update `docs/lit/<author>.md`.
8. **CLAUDE.md Current state:** update the phase progress, next concrete action, blocked-on, open decisions.
9. **CURRENT.md pointer:** `ln -sf YYYY-MM-DD-NN-<short-topic>.md docs/session_log/CURRENT.md`.
10. **Commit + push:** `git add -A && git commit -m "<type>: <session topic>" && git push`. Use Conventional Commits (`feat`, `data`, `model`, `docs`, `fix`, `chore`).
11. **Sync:** `bash scripts/sync_to_desktop.sh`.

---

## Current state

- **Phase:** **3 closed.** Both Sessions 01 + 02 complete; §4 descriptive layer fully drafted in `docs/findings.md`.
- **Last session:** 2026-05-19 — Session 12 (correlation matrix on Model-2 candidate variables; 4-panel regional trajectories 2010-2020 via cowplot; income-group Table 1 via WDI metadata). Headline empirical finding: governance × log(GDP/cap) r = 0.79 — binding multicollinearity for Phase 5 ADR-0009; income gradient on HLO sharper (102 pts) than regional gradient (82 pts).
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018`), `oecd_crs`, `aiddata_gcdf`, `ucdp`, `covid_closures`, `ai_readiness` → 10 interim parquets, plus production `data/interim/panel.parquet`.
- **Sources pending:** aiddata_core (deferred per Session-06 author decision; +optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** **0001, 0002, 0003, 0004, 0006 Accepted**; 0005, 0007, 0008, 0009, 0010 Pending. ADR-0010 (System GMM headline robustness) locks Phase 5 Session 1.
- **Next concrete action:**
  *(**Phase 4 Session 01 — Model 1 OLS baseline**)*. Cross-sectional OLS on the production panel within primary window; country-clustered SE. Specification: HLO ~ log(CRS_disburse_defl_MA3) + log(GDP/cap) + PTR + ed_exp_%GDP + Gov_effect. Establishes the naive cross-sectional association that Phase 5 Model 2 (within-country FE) then challenges. Output: `output/tables/model1_ols_baseline.{csv,md}` + LAYS-as-outcome variant. Adds to `findings.md §5.1`.
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
- `docs/findings.md` — proto-§4/§5/§6 of the paper; running register of substantive empirical findings with evidence pointers
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
