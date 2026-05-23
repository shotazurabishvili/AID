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

- **Phase:** **Phase 7 closed without estimation; Model 4 dropped.** Models 1-2-3 chain remains the empirical headline (Model 1 = −1.36 ns / Model 2 FE = +11.14** / Model 3 RE = −1.32 ns; Hausman p=0.0098 rejects RE; country ICC 91.2 % unconditional). Phase 7 Session 01 (this session) closed ADR-0007 as **Rejected**: the pre-committed lock gate for the four-bucket CRS intervention typology failed all three criteria (raw 39.04 %, κ=0.19, unclassified 75.68 %) when `R/61_typology_coding.R` ran on 2026-05-19. Author researcher-grade decision: drop Model 4 rather than escalate to hand-coding. Negative result documented as a §6 methodological finding (`findings.md §5.5`). No new code written; all changes are documentation discipline.
- **Last session:** 2026-05-23 — Session 21 (Phase 7 closure; ADR-0007 Rejected; Model 4 dropped; methodology §3.8/§3.10 rewritten; findings §5.5 stub → full negative-result writeup; obligations.md three Phase-7 items withdrawn; plan.md Phase 7 row marked Closed; lit notes Glewwe-Muralidharan + Vegas-Coffin reframed; R/61 header annotated; data_dictionary.md CRS section annotated).
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018`), `oecd_crs`, `aiddata_gcdf`, `ucdp`, `covid_closures`, `ai_readiness` → 10 interim parquets, plus production `data/interim/panel.parquet` (3059 × 86 cols), plus `oecd_crs_typology.parquet` + `typology_country_year.parquet` (negative-evidence artifacts, retained for reproducibility).
- **Sources pending:** aiddata_core (deferred per Phase-1 Session-06 author decision; +optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** **0001, 0002, 0003, 0004, 0005, 0006, 0008, 0009, 0010 Accepted**; **0007 Rejected (2026-05-23)**; no Pending.
- **Next concrete action:**
  *(**Phase 8 Session 01 — Model 5 counterfactual simulation, redesigned**)*. Per plan.md row 8. The brief's "redirect $1B across the four typology buckets" specification depended on Model-4 effect sizes; with Model 4 dropped, Phase 8 Session 01 must first lock a redesigned counterfactual built from Model 2's within-country β on log(CRS disbursement), translated through the LAYS reporting layer (`hci_lays_overall`). Framed as a total-volume / lag-structure / sub-sector counterfactual rather than a four-bucket reallocation. Best / worst / expected case across CI bounds with explicit identification-limit acknowledgments. May need a brief ADR-0011 if the redesign is substantive; otherwise a methodology §3.8 paragraph.
- **Open decisions:** (a) Phase 8 redesign — keep the dollar-amount counterfactual translated to a within-country β shock, or reframe entirely around a sub-sector reallocation using OECD purpose-code groups (no ADR-0007-style gate needed). Author judgment at Phase 8 entry. (b) Manuscript framing reframe (paths a/b/c per `docs/findings.md §5.2.1`) is load-bearing for Phase 11 (§6 manuscript drafting); the Model-4 drop is now itself a §6 point. Off critical path.
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
