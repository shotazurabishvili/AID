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

- **ACTIVE BRANCH:** `manuscript/path-c` (methodological-discipline arc per [Branching strategy](#branching-strategy-post-pass-1-fork-2026-05-23) section above). Author chose path-c at the post-Pass-1 fork (2026-05-23); `manuscript/path-a` exists as a placeholder branch at tag `v0.10-pass1-closed` for possible revisitation.
- **Phase:** **Phase 10 closed as qualified pass; Pass 1 Statistical Validity signed off.** Brief's diagnostic Statistical-Layer checks all run or documented as not-feasible-at-our-T (Granger test). **Substantive Pass-1 finding: the ADR-0004 principal HLO-AAP-2018 robustness check FAILS sign-agreement** — primary β=+11.14 (WB HCI HLOS 2010-2020); AAP full β=-16.67 (1995-2015, p=0.009); AAP overlap-window β=-3.94 (year≥2010, p=0.66). Overlap-window null rules out sample-window composition as sole driver: HLO measure choice itself materially shapes the headline. **Author response (hedge route):** hedge headline claim throughout manuscript to "in the WB HCI HLOS specification on the 2010-2020 panel"; §6 frames measure-sensitivity as itself a methodological contribution. UIS-augmented listwise (ADR-0006 Robustness 1) also weakly robust (sign-flip, non-significant, partial CI overlap). ADR-0012 NEW retires ADR-0006 Robustness 2 (MI) per MCAR rejection + CLAUDE.md no-fabrication principle. ADR-0004 amended with Phase-10 "Data observed" block; methodology §3.4.1 NEW + §3.6 UNESCO bias paragraph + §3.8 3-level HLM scope decision + §3.9 Robustness-1 result.
- **Last session:** 2026-05-23 — Session 26 (Phase 11 Session 02 on `manuscript/path-c`: §2 Literature Review drafted ~1,500 words across 3 strands; 3 bib corrections after WebSearch verification — `@worldbank2025beyond` → `@mandon2025beyond`, `@brookings2024divergence` → `@muthukrishna2025divergence` (UNDP report Dec 2025 primary venue), `@ilo2024disruption` → `@ilo2026disruption` (joint ILO-WBG, March 2026); 5 new lit-note stubs with honest "primary not read; secondary engagement only" status (vivalt, deaton-cartwright, muthukrishna-schellekens, mandon, ilo); 8 EVIDENCE TRACE HTML comments per major paragraph for auditable evidence-trail discipline). Cumulative finished prose Sessions 01+02 ≈ 2,950 words. Prior session = Session 25 (Phase 11 Session 01: skeleton + abstract + §1 Intro + §5.1 thesis).
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018`), `oecd_crs`, `aiddata_gcdf`, `ucdp`, `covid_closures`, `ai_readiness` → 10 interim parquets, plus production `data/interim/panel.parquet` (3059 × 86 cols), plus `oecd_crs_typology.parquet` + `typology_country_year.parquet` (negative-evidence artifacts, retained for reproducibility).
- **Sources pending:** aiddata_core (deferred per Phase-1 Session-06 author decision; +optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** **0001-0006, 0008-0012 Accepted (11 total)**; **0007 Rejected (2026-05-23)**; ADR-0004 + ADR-0006 carry Phase-10 amendments via ADR-0012 + "Data observed (Phase 10)" blocks; no Pending.
- **Next concrete action:**
  *(**Phase 11 Session 03 — §3 Data & Methodology (~2,000 words)**)*. Per the §3 placeholder comment in `drafts/aid_without_learning.qmd`. Four components: (1) data sources + panel construction (~1,000w; carve from `docs/methodology.md` §3.1–§3.7, §3.10–§3.12); (2) pre-commitment design — ADR architecture (12 ADRs; one Rejected; two amended), brief's Three-Pass Protocol, `obligations.md` as audit list (~500w new prose; the methodological contribution path-c foregrounds); (3) positionality statement (~300w; **awaits author input** on years/regions/role/concrete reporting-bias examples — `docs/positionality.md` is currently a stub); (4) Pass 1 sign-off + audit summary (~200w; source: `output/pass1_statistical_validity_audit.md`). Without positionality input the §3 word count will fall short by ~300w. Sessions 04–09 then cover §4 Results, §5 Discussion elaboration, §6 Policy, §7 Conclusion, Session-09 final-revision pass (PDF render + APA 7 CSL + title decision). Estimated 4–7 sessions remaining on path-c.
- **Open decisions:** (a) AAP-2018 supplementary placement — main results vs appendix; decide at Phase 11 entry; (b) §6 limits paragraph composition — Pass-1 surfaced several first-class limits (small-T, HLO measure-fragility, no MI, AAP-2018 sample-window, Granger not feasible) that path-c reframes from "caveats" to "contributions"; careful authorship needed at Phase 11. The framing-path choice (formerly open) is **resolved on this branch as path-c**; `manuscript/path-a` remains available if path-c does not land.
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

## Branching strategy (post-Pass-1 fork, 2026-05-23)

**Fork point:** tag `v0.10-pass1-closed` on commit `0a1e325` (`main`), the close of Phase 10 Session 01. Pass 1 closed as a qualified pass; the principal HLO robustness check (ADR-0004) failed sign-agreement with the AAP-2018 alternative, surfacing a measure-fragility finding that reshapes how the manuscript should be framed. See `docs/session_log/2026-05-23-24-pass1-statistical-validity.md` and `output/pass1_statistical_validity_audit.md` for the why-this-fork-exists context.

**Three findings-§5.2.1 paths reduced to two execution branches:**
- **`manuscript/path-c` (active)** — *methodological-discipline arc*. The §5.5 Model 4 drop, §5.8 HLO measure-fragility, and ADR-0012 UIS-MI retirement are first-class narrative beats alongside the within-country positive headline. Intro frames the pre-commit-and-test-honestly methodology as a contribution; §6 Discussion treats each methodological discovery as a finding for the cross-country aid-learning literature. Targets *World Development*'s methodological-reflection tradition (Sandefur 2018; Vivalt 2020; Deaton & Cartwright 2018).
- **`manuscript/path-a` (placeholder)** — *hedged within-country headline*. Leads with the +11.14 within-country β, hedged to "the WB HCI HLOS specification on the 2010–2020 panel"; methodological discoveries appear as caveats rather than first-class beats. Preserved for revisitation if path-c does not land. Path-b (cross-section vs within-country contrast) folds into path-a as a sub-variant via §5 emphasis-choice.

**Workflow.** Shared infrastructure work (analysis fixes, new data, ADR-quality methodology decisions) happens on `main` and is merged forward to both manuscript branches. Manuscript-prose work (intro, discussion, ordering, framing language, the eventual Quarto draft under `drafts/`) is branch-specific. Single-author project; be loose about strict branch hygiene rather than pedantic — if a methodology-paragraph edit accidentally lands on path-c when it should have been on main, fix it next pass; don't manufacture branch-hygiene churn.

**Worktree upgrade path.** Today's setup uses branch-switching (one branch checked out at a time in the single `~/AID` working tree). If the author later decides to draft both paths in parallel, spin up a second working tree without disturbing the active one:

```bash
git worktree add ../AID-path-a manuscript/path-a
# work in ~/AID (path-c) and ../AID-path-a (path-a) simultaneously
git worktree remove ../AID-path-a   # when done
```

Worktrees share `.git/` so the disk overhead is just the working-tree files (~30 MB given the interim parquets). Skipped today because there is no parallel-drafting need yet.

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
