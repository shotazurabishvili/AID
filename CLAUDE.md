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
- **Last session:** 2026-05-24 — Session 32 (Phase 11 Session 08 on `manuscript/path-c`: §6 Policy Implications + §7 Conclusion drafted — §6.1 An intervention-type policy marker in the OECD DAC CRS (~290w; 2 paragraphs; voluntary 0/1/2 marker on purpose codes 11110-11430 with GEEAP 2023 controlled vocabulary; gender-1997-to-mandatory-2007 precedent; named sympathetic DAC delegates; §4.4 39% inter-method agreement as binding-constraint evidence), §6.2 Auditable measurement infrastructure for cross-country learning outcomes (~290w; 2 paragraphs; WB HCP linking-anchor decision public release in partnership with IEA/SACMEQ/PASEC/LLECE/EGRA consortia + monitoring §4.6 double-excluded cell as future GARI/HCI editions arrive [folds in original §6 outline (c) compounding-vulnerable hook]; journal-level measure-sensitivity expectation on AEA Data Editor 2019 precedent; aspirational funded cross-measure benchmarking with IDRC/FCDO RED/J-PAL GPI as natural funders), §6.3 Missingness-disclosure as a routine condition of cross-country panel publication (~280w; 2 paragraphs; structured 3-item disclosure section — MCAR test + listwise robustness + MAR justification if MI; AEA Data Editor mechanism precedent; WD editorial + BITSS TIER protocol implementation paths), §6.4 Structural determinants in donor allocation models (~210w; 2 paragraphs; chastened recommendation — structural variables WGI PC1 + conflict + ECD + sectoral-concentration more robust than hedged ODA coefficient across §4.2 + §4.7; "include" not "act on" framing), §7 Conclusion (~400w; 3 paragraphs; ¶1 three contributions [§4.6 operationalization + path-c methodological framework + within-country β=+11.14 in primary specification]; ¶2 limits owned [T_eff ≤ 4; Arellano-Bond GMM not feasible per Dumitrescu-Hurlin; AAP-2018 sign-reversal; snapshot not trajectory]; ¶3 each limit points to a §6 research-infrastructure recommendation; closing "ten thousand words drawing the calibrated map" framing). 5 new EVIDENCE TRACE comments (52 total in the .qmd); no new placeholder blocks (10 total, unchanged — §6 + §7 pure prose); 2 new short-form hedge invocations in §6.4 ¶1 + §7 ¶1 (13 hedge mentions total). **Session 08 prose came in at ~1,465w vs ~1,400w target = 5% over.** Cumulative finished prose Sessions 01-08 ≈ 11,955 words — **over the 11k ceiling by ~955w; Session 09 trim is now required to land in the target window** (modest trim, not substantive — §4.2 substantive-density paragraphs from Session 04's 50%-overrun are the obvious first cut target).

**Context utilization note (2026-05-24, post-/compact):** Session 08 continued in the same fresh-context conversation that executed Session 07. The "/compact then proceed for Sessions 07-08" pattern worked: design conventions (placeholder-only; long-form-then-short-form hedge; EVIDENCE TRACE per paragraph; plain-text-ADR-reference in §5+§6 prose register; chastened-recommendation framing in §6) survived intact across both sessions. Recommend new conversation for Session 09 — the final-revision work + author-review pass is a distinct cognitive shape from the drafting sessions and benefits from fresh context.
- **Sources ingested:** `wdi`, `hci`, `wgi`, `uis`, `hlo` (+ `hlo_aap2018`), `oecd_crs`, `aiddata_gcdf`, `ucdp`, `covid_closures`, `ai_readiness` → 10 interim parquets, plus production `data/interim/panel.parquet` (3059 × 86 cols), plus `oecd_crs_typology.parquet` + `typology_country_year.parquet` (negative-evidence artifacts, retained for reproducibility).
- **Sources pending:** aiddata_core (deferred per Phase-1 Session-06 author decision; +optional PISA/TIMSS/PIRLS stretch)
- **ADRs:** **0001-0006, 0008-0012 Accepted (11 total)**; **0007 Rejected (2026-05-23)**; ADR-0004 + ADR-0006 carry Phase-10 amendments via ADR-0012 + "Data observed (Phase 10)" blocks; no Pending.
- **Next concrete action:**
  *(**Phase 11 Session 09 — Final-revision PDF render + author-review pass + appendices**)*. Five sub-components: (a) Quarto PDF render with full bibliography slot-fill via citeproc on APA 7 CSL — verify all citations render correctly; (b) figure-text rendering check — the 10 placeholder blocks need to be converted to live Quarto image/table syntax pointing at `output/tables/` + `output/figures/` (author directive in force throughout Sessions 02-08 was placeholder-only; Session 09 is where this lands); (c) author-review of the 9 accumulated contribution-claim flags listed below + §5.6 inclusion decision; (d) appendices A/B/C population — full regression tables from `output/tables/` + robustness chain + variable operationalization from `data_dictionary.md`; (e) word-count trim ~955w to land at ≤11,000w (primary target: §4.2 substantive-density paragraphs from Session 04's 50%-overrun — locked-encoding-stack paragraph; secondary: §6 subsection compression at author-review; tertiary: §7 ¶3 trim if needed). **Open author-review flags accumulated for Session 09:** (i) §4.6 ¶3 novelty hedge "we are not aware of a prior peer-reviewed paper that constructs the joint composite at this exact country cross-section" (Session 06); (ii) §5.3 contribution claim "the path-c contribution here is empirical demonstration that the within-country dimension is not safe ground for the Sandefur critique either" (Session 06); (iii) §5.4 ¶3 contribution claim "the field has under-engaged with" — soften to "has not consistently engaged with" (Session 07); (iv) §5.5 ¶2 contribution-claim restatement (Session 07); (v) §5.6 inclusion decision — include ~150w closing paragraph or close §5 at §5.5 (Session 07 deferred); (vi) §6.1 ¶2 named DAC delegates (Norway, Sweden, FCDO, DGIS, GPE Secretariat) — verify framing reads as practitioner-informed (Session 08); (vii) §6.2 + §6.3 AEA Data Editor 2019 + 18-month adoption claim — verify or trim to "an editor-level decision can shift practice" (Session 08); (viii) §6.4 "more robust across alternative specifications" claim — verify §4.2 + §4.7 structural-determinant coefficient stability (Session 08); (ix) §7 ¶3 closing line "ten thousand words drawing" — verify lands as confident-not-defensive (Session 08). **Author-input gates for submission:** §3.3 positionality still awaits 4 specifics (years/roles, regions, donor relationship type, 1-2 reporting-bias examples) — not blocking Session 09 PDF render but blocks submission. **Estimated sessions remaining:** 1-2 (Session 09 = render + author-review + trim + appendices; optional Session 10 if substantive author-edits surface).

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
