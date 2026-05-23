---
date: 2026-05-23
session: 23
phase: 9 — Compounding AI penalty section
duration_min: ~75
---

## Goal

Lock the brief's "Compounding AI Penalty" section (`docs/brief.md:159`): construct the HCI × AI Readiness joint composite, characterize the joint distribution (quadrants, SSA over-representation, bottom-N exposure), and write the §5.7 findings entry. Single session; no model dependencies; data already ingested.

## What we did

- Preflighted package availability (`countrycode` ✓, `ggrepel` ✓, `patchwork` ✗ but not needed for single-panel figure). Confirmed no region column in the production panel — region derived via `countrycode::countrycode(iso3, "iso3c", "region")` at analysis time. Confirmed HCI cycle distribution in the panel: 2010 (N=65), 2017 (N=118), 2018 (N=127), 2020 (N=133). Latest-non-missing-per-country strategy yields a HCI-2020 anchor for all 132 joined countries.
- **Corrected an explore-agent miss:** the agent thought §5.8 was a numbered subsection in findings.md; actually that text is a `## §6 Discussion candidates` bullet, not a numbered section. So we wrote §5.7 fresh (between §5.6 and the §6 Discussion candidates section) and updated the §6 bullet to point to §5.7.
- Wrote `R/71_compounding_ai_penalty.R` (367 lines) following R/70's template (suppressPackageStartupMessages + library block, file constants, csv+md output pairs, ggplot figure with PDF+PNG, stdout summary). Steps: latest-non-missing HCI per country → inner-join with GARI 2025 → composite `hci × (gari/100)` → median-split quadrants → 4 output tables (counts, bottom-20, SSA cross-tab, robustness panel) + 1 figure (scatter with quadrant overlay + bottom-15 country labels via `ggrepel`). Includes hand-maintained SSA iso3 fallback in case `countrycode` is missing.
- Ran R/71. **Empirical headline: N=132 joined countries; 47 (35.6%) in the double-excluded cell; 29 of those 47 (61.7%) are SSA against 31.8% SSA share of the joined sample (~2× over-representation).** Top-5 most exposed: SSD, CAF, LBR, YEM, TCD — conflict-affected low-income, 4 of 5 SSA. Robustness Jaccard: HCI-2018-only = 0.94 (very stable); tercile-split = 0.53 (mechanically smaller cell, not fragile).
- **Novelty-claim audit (5-min Google search via WebSearch).** Brief claims "no prior paper has done this". Found multiple adjacent prior works: Brookings' *Next Great Divergence*, World Bank *Beyond the AI Divide* (Working Paper 11073), ILO's *Disruption without dividend?*, tandfonline 2026 on 68 upper-middle-income countries using AI readiness as predictor of HCI, and practitioner tools (symbio6.nl AI Readiness Map; Salesforce Global AI Readiness Index 2025) that compare GARI + HCI across countries. Conclusion: the brief's claim is **overstated**. What is genuinely novel: the specific joint composite + SSA over-representation quantification + peer-reviewed publication in an *educational-aid-effectiveness* paper. Lit note `docs/lit/oxford-insights-2026.md` documents the audit and hedges the manuscript framing.
- Updated methodology.md §3.12 (extending the existing GARI sub-block with a Phase-9 implementation paragraph) and findings.md §5.7 (new subsection with the bolded headline claim, quadrant table, robustness summary, calibrated novelty paragraph, tautology caveat, and §6 Discussion connection). Updated the §6 Discussion candidates bullet to reference the locked §5.7 instead of "Phase 9 will…".
- Annotated data_dictionary.md GARI section with the Phase-9 implementation note (no new persisted column; composite computed at analysis time).
- **Ordering bug caught and fixed in findings.md.** Initial Edit inserted §5.7 *before* §5.6 (because the Edit's old_string was the §5.6 header and the new_string prepended §5.7 to it). Fixed via a paired pair of Edits to move §5.7 to its correct position after §5.6.

## Decisions made

- **Path A (descriptive joint-distribution characterization) over Path B (inferential interaction test).** Explained in the plan and methodology: we have no clean outcome for the interaction test (LAYS/HLO are embedded in HCI; GDP growth needs its own identification story; the compounding *thesis* is about future divergence we can't observe yet). §5.7 reports the joint distribution + over-representation, not a "compounding effect" estimate.
- **Median split as the quadrant default** (with tercile + HCI-2018 robustness panel). Median is the canonical default; the tercile-split Jaccard (0.53) doesn't undermine the headline because tercile cells are mechanically smaller. The HCI-2018-only Jaccard (0.94) shows the choice of HCI cycle doesn't materially move the result.
- **Latest-non-missing HCI per country, which collapses to HCI 2020 for all 132 joined countries.** The 2020 cycle is the most complete; the join with GARI 2025 + countrycode-derived region produces a clean cross-section.
- **Hedge the brief's novelty claim in the manuscript.** The brief's "no prior paper has done this" is too strong. Lit-note audit surfaced multiple adjacent works; the §5.7 calibrated-novelty paragraph and the lit note both hedge to "we are not aware of a prior peer-reviewed paper that constructs the joint composite at this exact country-cross-section and quantifies the regional concentration".
- **No new ADR.** Implementation choices (median-split; latest-HCI; [0,1] normalization) are mechanical given the brief's specification + the existing methodology §3.12 GARI derivation note. The Phase-9 implementation paragraph in methodology §3.12 documents the choices inline.

## What we tried that didn't work

- **The naïve "no prior paper has done this" framing from the brief.** First instinct on writing §5.7 was to echo the brief's claim. Five-minute novelty audit via WebSearch surfaced Brookings / WB / ILO / Salesforce / symbio6.nl as either-articulating-the-thesis or constructing-adjacent-composites. Replaced by: calibrated novelty claim in §5.7 + a detailed audit-and-hedging paragraph in the Oxford Insights lit note. The discipline lesson is the same one ADR-0007 enforced — verify novelty claims empirically before letting the manuscript echo them.
- **Initial ordering of §5.7 in findings.md.** First Edit placed §5.7 immediately before §5.6 because the chosen anchor was the §5.6 header line. Caught at the grep-verification step (`grep -nE "^### §5\." docs/findings.md` showed §5.7 at line 546 and §5.6 at line 569 — wrong sequence). Fixed by a swap pair of Edits.
- **patchwork dependency for a possible second figure panel.** Checked `requireNamespace("patchwork")` in preflight — not available. Since §5.7 only needs one figure (the scatter + quadrant overlay), no second panel needed; no fallback required. The earlier worry was unwarranted.
- **The temptation to expand to a second composite** (e.g., principal-component weighting of the 6 GARI pillars, or Oxford's published rank instead of the derived score-mean). Considered and rejected at planning per the plan's out-of-scope list. The existing `ai_readiness_score_mean` derivation is already locked in methodology §3.12; no second composite to maintain.

## Methodology entries written this session

- **ADRs written / updated:** none. No new ADR for Phase 9 (the brief specifies the constructed variable directly; methodology §3.12 already documents the GARI derivation; implementation choices documented inline).
- **`methodology.md` sections touched:** §3.12 GARI sub-block extended with a "Phase-9 implementation (Session 01, 2026-05-23)" paragraph (HCI cycle rule, composite formula, quadrant thresholds, robustness Jaccard numbers, front-loaded tautology caveat, descriptive-not-causal framing).
- **`data_dictionary.md` rows added:** None (composite computed at analysis time, not stored in the panel). Phase-9 implementation note added to the existing GARI section.
- **`obligations.md` items checked off:** None new. Phase 9 had no pre-committed obligations beyond the plan.md row-9 exit criterion (composite constructed, novel finding documented, figure produced) — all three met.
- **`lit/` notes populated:** **NEW** `docs/lit/oxford-insights-2026.md` (citation, what GARI measures, our derivation, novelty-claim audit with 5 adjacent prior works flagged for Phase 11 engagement).
- **`docs/decisions/INDEX.md` updated:** No (no new ADR).
- **`CLAUDE.md` Current state updated:** yes (Phase 9 closed; Compounding AI Penalty section locked; Next concrete action = Phase 10 Session 01 Pass 1 Statistical validity).

## Results / findings

**Headline:** On a sample-median split of HCI vs GARI/100 across the 132-country GARI 2025 × HCI 2020 cross-section, 47 (35.6%) fall in the low-HCI ∩ low-GARI "double-excluded" cell. **29 of those 47 (61.7%) are SSA** despite SSA being only 31.8% of the joined sample — roughly a **2× over-representation**.

**Top-5 most-exposed countries** (lowest `compound_index = HCI × GARI/100`):

| Rank | iso3 | HCI cycle | HCI | GARI/100 | compound_index |
|---|---|---|---|---|---|
| 1 | SSD | 2020 | 0.306 | 0.108 | 0.0332 |
| 2 | CAF | 2020 | 0.292 | 0.119 | 0.0348 |
| 3 | LBR | 2020 | 0.319 | 0.145 | 0.0463 |
| 4 | YEM | 2020 | 0.373 | 0.126 | 0.0470 |
| 5 | TCD | 2020 | 0.300 | 0.184 | 0.0552 |

**Quadrant distribution:** HHHG 47 (2 SSA) / HHLG 19 (1 SSA) / LHHG 19 (10 SSA) / LHLG 47 (29 SSA).

**Robustness Jaccards:** HCI-2018-only = 0.94 (very stable); tercile-split = 0.53 (mechanically smaller cells, not fragile boundary).

**Novelty audit:** the brief's "no prior paper has done this" claim is overstated. Brookings, WB *Beyond the AI Divide* (WP 11073), ILO *Disruption without dividend?*, tandfonline 2026, and practitioner tools (symbio6.nl, Salesforce) all articulate the compounding-divergence thesis or construct adjacent composites. §5.7 hedges to "we are not aware of a prior peer-reviewed paper that constructs the joint composite at this exact country-cross-section and quantifies the regional concentration".

**Empirical headline for the paper's narrative arc:** the §5.7 result is *necessary-but-not-sufficient* for the brief's compounding-penalty thesis — the dimensions are positively coupled, the double-excluded cell is densely populated, and SSA is heavily over-represented. The forward-looking divergence claim is not tested in this paper (longitudinal claim, would require several future GARI editions); §5.7 is a snapshot of the divergence-vulnerable set.

## What's next

**Phase 10 Session 01 — Pass 1 Statistical validity.** Per plan.md row 10: "Every diagnostic from brief's checklist run; private results doc compiled." This is the methodology audit pass — go through `docs/obligations.md` line by line, verify every committed diagnostic has been run and recorded, and compile a private "everything checked" doc to enter Phase 11 writing on a clean methodological footing. Likely 1 session.

## Open questions for the author

- **Manuscript framing reframe (paths a/b/c per `findings.md §5.2.1`)** — every §5 section is now finalized (§5.1–§5.7 all populated). The framing decision is ripe; recommend tackling it at Phase 11 entry rather than as a separate pre-Phase-10 session, so it can be made with full §5 context.
- **PDF font fix** (em-dash + β + × rendering in figure titles) — same warnings on R/71 as on R/70/R/57. Deferred to Phase 11 figure production as noted in prior sessions.
- **Phase-11 lit-review reading queue.** The Oxford Insights lit note flags five works to engage in §2 (Lit Review) and §6 (Discussion): Brookings *Next Great Divergence*; WBG WP 11073 *Beyond the AI Divide*; the two ILO reports; tandfonline 2026. Suggest adding these to the Phase 11 reading list when the §2/§6 drafting starts.

## Files touched

- `R/71_compounding_ai_penalty.R` (NEW)
- `output/tables/compound_ai_penalty_quadrant.{csv,md}` (NEW)
- `output/tables/compound_ai_penalty_bottom20.{csv,md}` (NEW)
- `output/tables/compound_ai_penalty_ssa_crosstab.{csv,md}` (NEW)
- `output/tables/compound_ai_penalty_robustness.{csv,md}` (NEW)
- `output/figures/compound_ai_penalty_scatter.{pdf,png}` (NEW)
- `docs/lit/oxford-insights-2026.md` (NEW)
- `docs/methodology.md` (§3.12 GARI sub-block extended with Phase-9 implementation paragraph)
- `docs/findings.md` (§5.7 added; §6 Discussion candidates bullet for HCI×GARI updated to point to §5.7)
- `docs/data_dictionary.md` (GARI section annotated with Phase-9 implementation note)
- `docs/session_log/2026-05-23-23-compounding-ai-penalty.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink repointed)
- `CLAUDE.md` (Current state block updated)
