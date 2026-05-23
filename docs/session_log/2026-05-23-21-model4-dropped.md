---
date: 2026-05-23
session: 21
phase: 7 — Model 4 (closed without estimation)
duration_min: ~60
---

## Goal

Close ADR-0007 (the only Pending ADR) and decide Model 4's fate, given that `R/61_typology_coding.R` had already run on 2026-05-19 23:55 (in the gap after Session 20 closed) and failed all three pre-committed lock criteria.

## What we did

- Read `R/61_typology_coding.R` and the four `output/tables/typology_*` artifacts to verify the dry-run outcome. Confirmed: raw agreement 39.04 %, Cohen's κ = 0.19, rule-based unclassified 75.68 % — all three pre-committed lock criteria FAIL. The R/61 script's own LOCK CRITERIA block correctly reported `ESCALATE (Option 3 hand-coding required)`.
- Diagnosed the failure signature. Two distinct problems, both pointing the same way: (1) the 49-pattern rule cascade leaves 76 % of education-sector projects unmatched — the regex set does not cover the lexical breadth of CRS descriptions; (2) the LLM-via-purpose-code comparator puts 82.7 % of projects in `budget_support` vs the rule-based classifier's 4.2 % — the two methods are measuring different constructs, not the same construct with noise. The "agreement" number was structurally degraded before the data ever spoke.
- Surfaced the implied paths to the author (under the pre-committed protocol, only Path A — Option 3 hand-coding — is the binding next step; Paths B/C are post-hoc tuning options): A) hand-code ~1000 stratified projects + train classifier; B) replace LLM-via-purpose-code with true LLM-on-text; C) iterate keyword rules to v2; D) drop Model 4 entirely.
- **Author decision: drop Model 4 entirely.** Direct quote: *"we are not coding anything. deciding as researchers would decide. rather drop plan element than mess around."* Researcher-grade reading: honor the no-post-hoc-tuning discipline that ADR-0007 was written to enforce; treat the failed gate as evidence rather than as an obstacle to be engineered around.
- Confirmed second-order question: drop Model 4 entirely vs replace with a pre-coded typology axis (OECD sub-sector ANOVA on basic / secondary / post-secondary / vocational; channel-of-delivery ANOVA). Author chose **drop entirely** — preserves epistemic discipline and avoids retrofitting a Model 4 of convenience to fill the brief's slot.
- Updated every downstream living doc to reflect the drop (see *Methodology entries written this session* below).
- Wrote a redesign hook for Model 5 (Phase 8): the brief's counterfactual was specified to use Model-4 effect sizes; without Model 4 it must be rebuilt from Model 2's within-country β translated through the LAYS reporting layer. Phase 8 Session 01 locks the redesign.

## Decisions made

- **ADR-0007 status flipped Pending → Rejected** (`docs/decisions/0007-oecd-crs-intervention-typology.md`). Decision date 2026-05-23. Full "Decision (final)" section added with the three failed-criterion numbers, the two-signature failure diagnosis, the researcher rationale for dropping rather than escalating, and an expanded "How a referee might attack this" section that pre-empts the four most likely critiques (post-hoc framing; LLM black box; cherry-picking; wasted effort).
- **Model 4 dropped from the paper.** Paper now reports Models 1-2-3 (cross-section / within-FE / multilevel) + Model 5 (counterfactual, Phase 8). Brief.md (immutable) still specifies Model 4; methodology.md §3.8 documents the drop as a downstream-of-brief design revision; brief.md is not edited.
- **Model 5 redesign required.** Cannot use Model-4 effect sizes. Phase 8 Session 01 will lock a total-volume / lag-structure / sub-sector counterfactual built from Model 2's β on log(CRS disbursement), translated through LAYS.
- **R/61 + the four `output/tables/typology_*` artifacts + the two interim parquets retained on disk.** They are the negative-evidence artifacts for the reproducibility package. R/61's header annotated with the Rejected outcome.
- **No new code written this session.** Pure documentation discipline. Honors the "rather drop plan element than mess around" principle.

## What we tried that didn't work

- **The R/61 dry run itself (2026-05-19 23:55) — the "what didn't work" is the substantive finding of this session.** Rule-based keyword cascade with 49 patterns on `paste(project_title, short_description, long_description)`: too narrow, 76 % of education-sector projects unmatched. The patterns target unambiguous keywords ("teacher training", "classroom construction") and miss the bulk of CRS descriptions that are administrative / generic / multi-purpose. Replaced by: nothing — author chose to drop Model 4 rather than tune the rules to v2.
- **LLM-via-purpose-code comparator (R/lib/typology/purpose_code_to_bucket_v1.csv).** This was never an LLM-on-text classifier; it was a Claude classification of the OECD purpose-code descriptions, applied to projects via their purpose-code label. Structural mismatch with the brief's bucket definitions — purpose codes like 11110 (Education policy & administrative management) inherit `budget_support` for all 444k projects bearing that code regardless of project text. The 39 % agreement number was contaminated by this comparator-design problem; it was not a signal of two converging classifiers disagreeing on edge cases. Replaced by: nothing — re-specifying the comparator after seeing the data would have broken ADR-0007's pre-commitment discipline.
- **The temptation to escalate to Option 3 (hand-code 1000 + train classifier).** Per the binding protocol this was the next step. We did not take it: spending 2-3 weeks of author time on hand-coding to validate one of five empirical models, when Models 1-2-3 + 5 already constitute a coherent paper, is a poor researcher trade. Replaced by: drop Model 4 entirely, document the failure transparently in §5.5 of `findings.md` and in §3.8/§3.10 of `methodology.md`.

## Methodology entries written this session

- **ADRs written / updated:** ADR-0007 (Pending → **Rejected**); decision date filled (2026-05-23); full Decision (final) section added with failure numbers, failure-signature diagnosis, researcher rationale, Phase-8 redesign hook; "How a referee might attack this" expanded from 2 attacks to 4.
- **`methodology.md` sections touched:** §3.8 Model 4 paragraph replaced with "Model 4 — Dropped" writeup including the three failed numbers, the binding protocol's escalation step, and the researcher-decision rationale. §3.8 Model 5 paragraph updated with the redesign hook (cannot use Model-4 effect sizes; Phase 8 Session 01 redesigns from Model 2 β + LAYS). §3.10 Intervention typology coding rewritten to reflect Rejected status and reframe the description-text columns as retained-but-inactive.
- **`data_dictionary.md` rows added:** No new rows. Added an "ADR-0007 note (2026-05-23)" block at the CRS section explaining that the four description-text columns are now retained for raw-data fidelity but no longer feed an active analysis path; flagged the two derived interim parquets as negative-evidence artifacts.
- **`obligations.md` items checked off:** Three Phase-7 obligations marked **Withdrawn 2026-05-23** with strike-through (Levene's test; η² + Cohen's d for ALL ANOVA pairs; ANOVA coding rule-based vs LLM-assisted). Not deleted — annotated inline to preserve the audit trail.
- **`lit/` notes populated:** glewwe-muralidharan-2016.md and vegas-coffin-2015.md "Our engagement" sections rewritten — both originally framed Model 4 as the empirical test of their theoretical claim; both now serve the §6 Discussion as theoretical scaffolding (Glewwe-Muralidharan) or qualitative grounding (Vegas-Coffin), with the negative typology-coding result (§5.5) carrying the "we can't test this at panel scale" point.
- **`docs/decisions/INDEX.md` updated:** ADR-0007 row flipped to **Rejected**, decided 2026-05-23. "What it decides" column rewritten to reflect the failed gate + drop decision.
- **`docs/plan.md` updated:** Phase 7 row marked as Closed without estimation; sessions estimate 2 → 1; exit-criterion rewritten with the failed-gate numbers and the drop rationale.
- **`R/61_typology_coding.R` updated:** 6-line header note inserted explaining the run date, Rejected outcome, retention rationale, and cross-references. No code change.
- **`CLAUDE.md` Current state updated:** yes (Phase 7 closed; ADR-0007 Rejected; Model 4 dropped; Next concrete action = Phase 8 Session 01 Model 5 counterfactual redesign).

## Results / findings

**The headline finding of this session is a negative result and a research-discipline decision, not a coefficient.**

Pre-committed lock gate on the 537,586-project CRS extract:

| Criterion | Observed | Required | Verdict |
|---|---|---|---|
| Raw agreement (joint subsample, N = 130,737 = 24.3 % of total) | **39.04 %** | ≥ 85 % | FAIL |
| Cohen's κ (rule-based vs purpose-code-bucket) | **0.19** | ≥ 0.70 | FAIL |
| Rule-based unclassified | **75.68 %** | < 30 % | FAIL |

Substantive reading: the brief's four-bucket intervention typology (infrastructure / teacher training / curriculum-materials / budget support) is *not recoverable from OECD CRS project metadata* at an inter-method agreement that would survive a *World Development* refereeing. This is itself a §6 Discussion point — the development-aid effectiveness literature (Glewwe & Muralidharan 2016) treats this distinction as load-bearing for policy, yet the standard donor data source cannot support testing it at country-year panel scale without substantial hand-coding effort.

Empirical headline of the paper now reduces to: Model 1 OLS (β=−1.36 ns cross-section); Model 2 FE (β=+11.14**, within-country, p=0.048); Model 3 RE (β=−1.32 ns, collapsed onto Model 1 via 91 % country ICC); Model 5 (Phase 8 counterfactual, redesigned). The Models 1-2-3 five-strand convergence story (Sessions 03/04/05/06/06-S01) is unchanged.

## What's next

**Phase 8 Session 01 — Model 5 counterfactual simulation, redesigned.** Lock the redesign first: the brief's "$1B redirect across the four typology buckets" specification is no longer available; the substitute is a total-volume / lag-structure / sub-sector counterfactual built from Model 2's within-country β on log(CRS disbursement), translated through the LAYS reporting layer (`hci_lays_overall`). Best / worst / expected case across CI bounds; explicit identification-limit acknowledgments. Likely needs a brief ADR (could be ADR-0011 if a substantive lock is required, or just a methodology §3.8 paragraph if the redesign is mechanical).

## Open questions for the author

- **Phase 8 redesign — does the brief-derived "redirect $1B" framing survive in any form?** Concretely: do we keep the dollar-amount counterfactual (translated to a within-country β shock) and let §6 narrate the typology-axis loss as a scope reduction, or do we reframe Model 5 around something different (e.g., a sub-sector reallocation across basic/secondary/post-secondary using existing OECD purpose-code groups, which *are* pre-coded and need no ADR-0007-style gate)? Author judgment task at Phase 8 entry.
- **§6 framing reframe** (paths a/b/c per `findings.md §5.2.1`) — still on the table, still off the critical path. The Model-4 drop is now itself a §6 point that should be woven into whichever framing the author chooses.
- **PDF font fix** (em-dash + β rendering) still deferred to Phase 11 figure production.

## Files touched

- `docs/decisions/0007-oecd-crs-intervention-typology.md` (Pending → Rejected; full rewrite of Decision section + How a referee might attack this)
- `docs/decisions/INDEX.md` (0007 row → Rejected, 2026-05-23)
- `docs/methodology.md` (§3.8 Model 4 → "Dropped"; §3.8 Model 5 → redesign hook; §3.10 → Rejected)
- `docs/findings.md` (§5.5 stub → full negative-result writeup)
- `docs/obligations.md` (3 Phase-7 obligations marked Withdrawn 2026-05-23)
- `docs/plan.md` (Phase 7 row → Closed without estimation)
- `docs/data_dictionary.md` (CRS section → ADR-0007 note added)
- `docs/lit/glewwe-muralidharan-2016.md` (Our engagement → reframed for Model-4 drop)
- `docs/lit/vegas-coffin-2015.md` (Our engagement → reframed for Model-4 drop)
- `R/61_typology_coding.R` (header note added; no code change)
- `docs/session_log/2026-05-23-21-model4-dropped.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink repointed)
- `CLAUDE.md` (Current state block updated)
