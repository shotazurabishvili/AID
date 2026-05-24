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
- **Last session:** 2026-05-24 — Session 33 (Phase 11 Session 08b on `manuscript/path-c`: pre-Session-09 hardening pass — fresh-eye end-to-end manuscript read surfaced 9 referee-catchable defects; verification of defect #1 (citation-key duplications) made a worse discovery — **3 citation keys used in the prose are MISSING from references.bib entirely** (`@sandefur2018harmonized`, `@vegascoffin2015education`, `@angrist2024`) while the canonical bib-check grep used to gate every session commit since Session 02 silently passes them as present. The broken bib-check is `pipe | while read k; do ... done` which aborts after the first failed inner grep; the robust form is `for k in $keys; do ... done`. **Every session log going back to Session 02 incorrectly claims a clean bib check; the manuscript would have rendered citeproc `(?)` placeholders at PDF render time.** 21 targeted Edit calls executed: 3 citation-key consolidations to existing bib entries (`@sandefur2018internationally`, `@vegas2015when`, `@angrist2024lays` — bracket-anchored to avoid the `@angrist2024` ⊂ `@angrist2024lays` substring-corruption trap); 2 EVIDENCE-TRACE meta-mention fixes (strip `@` from `@rubin1976inference` + `@little1988test` to silence bib-check false positives without adding speculative bib entries); 7 prose defect fixes (§7 ¶2 GMM/Granger conflation separated to two-test form; §4.5 173-country sample mislabel re-labeled to "ODA-recipient countries in the brief-bridge calculation"; §4.7 ¶3 "sixty percent" ambiguity clarified to "103 → 41 countries"; §4.6 ¶3 "Session 23" project-internal leakage removed; §7 ¶1 missing "we are not aware of" hedge restored; §6.4 ¶1 untested "predictive benchmarks" claim softened to "leave variation unexplained"; Abstract "unambiguously supports" softened to "supports in the WB HCI HLOS specification — with the published-measure-sensitivity caveats documented below"); 5 acronym expansions at first mention (GEEAP, SACMEQ, PIRLS, TIMSS, PASEC, LLECE, EGRA); 3 in-prose session-marker leakage cleanups surfaced by the new project-internal-leakage gate (`§5.5 (Session 07)` → `§5.5`; `§5.3 (next subsection... drafted in this same session)` → `§5.3 below`; `§5.4 elaboration in Session 07` → `§5.4 elaboration below`). 4 new augmented verification gates added: robust bib-check (mandatory), project-internal-leakage scan, hedge-symmetry count, sample-size cross-check. **Final state: zero MISSING IN BIB; 52 EVIDENCE TRACE comments unchanged; word count 19,079 → 19,184 (+105w net — acronym expansions and methodological precision additions); 10 placeholders unchanged; 13 hedge mentions unchanged; 4 "we are not aware of" hedge occurrences (was 3); quarto check OK; git status clean.** Cumulative finished prose Sessions 01-08b ≈ 12,020w of 9-11k target — over the 11k ceiling by ~1,020w; Session 09 trim now ~1,020w (slightly larger than prior 640-790w band because the 9 defect fixes net-added ~120w, with acronym expansions dominating).

**Context utilization note (2026-05-24, post-/compact):** Sessions 07-08-08b all executed in the same fresh-context conversation. The "verify the verification before fixing" discipline at Session 08b caught a silent false-pass that had been carrying broken citations across 6+ sessions of "clean bib check" output. Future sessions should run the for-loop bib-check variant exclusively and never trust the original `pipe | while read` formulation. Recommend new conversation for Session 09 — the final-revision work (PDF render + placeholder conversion + author-review + appendix population + trim) is a distinct cognitive shape from the drafting sessions and benefits from fresh context.
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018`), `oecd_crs`, `aiddata_gcdf`, `ucdp`, `covid_closures`, `ai_readiness` → 10 interim parquets, plus production `data/interim/panel.parquet` (3059 × 86 cols), plus `oecd_crs_typology.parquet` + `typology_country_year.parquet` (negative-evidence artifacts, retained for reproducibility).
- **Sources pending:** aiddata_core (deferred per Phase-1 Session-06 author decision; +optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** **0001-0006, 0008-0012 Accepted (11 total)**; **0007 Rejected (2026-05-23)**; ADR-0004 + ADR-0006 carry Phase-10 amendments via ADR-0012 + "Data observed (Phase 10)" blocks; no Pending.
- **Next concrete action:**
  *(**Phase 11 Session 09 — Final-revision PDF render + author-review pass + appendices**)*. Five sub-components: (a) Quarto PDF render with full bibliography slot-fill via citeproc on APA 7 CSL — now safe to render since bib-check passes cleanly after Session 08b; (b) placeholder → live Quarto syntax conversion — 10 placeholder blocks for Tables 1-6 + Figures 1-3 + one additional figure pointing at `output/tables/` + `output/figures/`; (c) author-review of the 5 framing-level contribution-claim flags + §5.6 inclusion decision (the 9 referee-catchable defects + bib-check bug are all fixed in Session 08b); (d) appendices A/B/C population — full regression tables from `output/tables/` + robustness chain + variable operationalization from `data_dictionary.md`; (e) word-count trim ~1,020w to land at ≤11,000w (primary target: §4.2 Session-04 locked-encoding-stack substantive-density paragraph; secondary target: §3.2 ¶1 ADR-inventory paragraph compression to one-narrative + appendix-table form; tertiary target: §3.4 "Phase 10 Session 01" obligations-bookkeeping language re-write). **Open author-review flags for Session 09 (framing-level, deferred from Sessions 06-08):** (i) §4.6 ¶3 novelty hedge phrasing; (ii) §5.3 within-country Sandefur-critique extension claim (strongest contribution-claim wording); (iii) §5.5 ¶2 contribution-claim restatement; (iv) §5.6 inclusion decision (deferred Session 07); (v) §6.1 ¶2 named DAC delegates verification (Norway, Sweden, FCDO, DGIS, GPE Secretariat); (vi) §6.2 + §6.3 AEA Data Editor 2019 + 18-month adoption claim verification; (vii) §6.4 "more robust across alternative specifications" claim verification against §4.2 + §4.7 coefficient stability; (viii) §7 ¶3 closing line "ten thousand words drawing" reads-as-confident-not-defensive check (will need updating to actual final wordcount after trim). **Author-input gates for submission (independent of Session 09 timing):** §3.3 positionality still awaits 4 specifics (years/roles, regions, donor relationship type, 1-2 reporting-bias examples) — not blocking PDF render but blocks submission. **Verification-grep canonical form (post-Session-08b):** use the for-loop variant, NOT the broken `pipe | while read` variant; see the Session 33 log for the full takeaway. **Estimated sessions remaining:** 1-2 (Session 09 = render + author-review + trim + appendices; optional Session 10 if substantive author-edits surface).

**Blocking author input for §3.3 positionality** (deferred to whenever convenient; doesn't block §4 drafting): (a) exact years and roles in education sector; (b) countries / regions of direct field experience; (c) donor/implementer relationship type (multilateral / bilateral / INGO / national government); (d) 1-2 first-hand reporting-bias incentive-mismatch examples. ~300w prose unblocked once provided.
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
