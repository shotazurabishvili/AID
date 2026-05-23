---
date: 2026-05-23
session: 24
phase: 10 — Pass 1 Statistical Validity (qualified pass)
duration_min: ~150
---

## Goal

Close the brief's Pass 1 Statistical Validity gate before Phase 11 manuscript drafting begins. Walk `obligations.md` line by line, verify intent for unfulfilled items, execute the gaps that are committed-but-unrun, document the gaps that are intent-resolved, and produce the brief's "private document" audit.

## What we did

- **Audited 7 ostensibly unfulfilled obligations** by tracing each through ADR/session-log/commit history. Categorized:
  1. **Sample-window robustness (2005-2020, 2000-2022)** — mechanically satisfied per [ADR-0003](decisions/0003-year-range.md) Session-09 audit (all three windows produce identical Model-2 samples; HLO sparsity is the binding constraint). Document; don't re-run.
  2. **FE-structure (country × decade FE)** — not meaningful in 2010-2020 primary window (~1 decade). No ADR commitment. Mark N/A.
  3. **HLO sensitivity (WB vs AAP-2018)** — genuinely committed in [ADR-0004](decisions/0004-hlo-measure.md) but never run. **Execute.**
  4. **UIS MI execution** — committed in ADR-0006 Robustness 2, but conflicts with the no-fabrication principle + MCAR rejection. **Amend via new ADR-0012.** Run Robustness 1 (listwise) instead.
  5. **Granger causality test** — brief-mandated, never run. **Execute** (`plm::pgrangertest`).
  6. **UNESCO self-reporting bias** — qualitative note never added to methodology §3.6. **Add paragraph.**
  7. **3-level HLM ICC + HLM convergence** — brief commitment superseded by Phase-2 reframe (2-level RE only). **Document scope decision in methodology §3.8.**

- **Wrote `R/72_pass1_robustness_battery.R` (~280 lines).** Pattern from R/71. Four sections: Granger test, HLO measure sensitivity (full AAP coverage + overlap-window decomposition), UIS-augmented listwise, combined sign-off table. 4 output tables × 2 formats = 8 files. Reads locked Model 2 spec 2e β/SE/N inline rather than from `output/tables/model2_fe_baseline_v2.csv` to keep the battery self-contained.

- **Ran R/72. Three findings:**
  - **Granger test NOT FEASIBLE at our T.** Dumitrescu-Hurlin Z-tilde requires T > 5+3·order = 8 per country; HCI-cycle panel gives T_eff ≤ 4. Same small-T limit as [ADR-0010](decisions/0010-identification-strategy-gmm.md) GMM. Documented as a not-feasible-at-our-T outcome.
  - **HLO AAP-2018 sensitivity FAILS sign-agreement.** Primary β = +11.14 (WB HCI HLOS, 2010-2020); AAP full β = **-16.67** (1995-2015, p=0.009); AAP overlap-window β = **-3.94** (year≥2010, p=0.66). Overlap-window null rules out sample-window composition as the sole driver — the HLO measure choice itself materially shapes the headline. Per methodology §3.4 commitment, this fails the principal-robustness criterion.
  - **UIS-augmented listwise weak robustness.** β_ODA = -1.97 (SE 4.40, N=41 post-singleton-drop), sign-flipped vs primary but non-significant. CIs overlap partially (primary [0.32, 21.95]; listwise [-10.59, 6.66]).

- **Escalated the HLO sign-flip to author via AskUserQuestion.** Three options presented: (A) hedge headline + treat measure-sensitivity as itself a paper finding; (B) defend WB HCI HLOS via Sandefur critique of AAP, relegate failure to footnote; (C) drop within-country positive headline entirely, reframe paper around §5.7 + Model 5. **Author chose A** — discipline-matched response: report transparently, hedge throughout, treat measure-sensitivity as a methodological contribution to the cross-country aid-learning literature.

- **Wrote ADR-0012** (`docs/decisions/0012-retirement-of-uis-multiple-imputation.md`) — amends ADR-0006 Robustness 2 sub-commitment. Rationale: MCAR rejected at p ≪ 10⁻⁶ → MAR unsupported; CLAUDE.md no-fabrication principle explicit conflict; ADR-0006 already hedged MI's status ("where used at all"); Robustness 1 covers same direction; within-FE absorbs most cross-country UIS heterogeneity. Four-attack referee defense section.

- **Amended ADR-0004** with a "Data observed (Phase 10 Session 01)" block reporting the AAP sensitivity failure, the overlap-window decomposition, and the chosen researcher adaptation (hedge route). ADR-0004 is *not superseded* — Option 1 primary / Option 2 robustness lock stands; what's updated is the empirical observation that the robustness comparison reveals fragility.

- **Updated methodology in three places:**
  - §3.4.1 NEW — measure-sensitivity finding with full numbers + manuscript adaptation guidance
  - §3.6 — UNESCO self-reporting incentive bias paragraph (qualitative; cites UNESCO's own discussions of survey-vs-admin discrepancies and Sandefur 2022)
  - §3.8 Model 3 — explicit 3-level → 2-level supersession paragraph; "ICC at all three levels" reframed as "ICC at country level only — the single non-trivial random-effect level in the reframed spec"
  - §3.9 — Robustness 1 result + ADR-0012 pointer

- **Wrote findings §5.8** — full empirical writeup of the Pass 1 battery, bolded headline claim *"the within-country positive ODA coefficient is real in the WB HCI HLOS specification but does not carry across to the AAP-2018 alternative measure"*, scenario table, UIS-listwise weak-robustness numbers, Granger not-feasible note, §6 Discussion connection.

- **Comprehensive obligations.md sweep:** updated 9 line items with status markers + per-item rationale + evidence pointers (Granger, UNESCO bias, ICC, HLM convergence, HLO sensitivity, sample-window, UIS-augmented, FE-structure N/A, Pass 1 itself).

- **Composed `output/pass1_statistical_validity_audit.md`** — the brief's "private document" Pass-1 deliverable. Six sections: Causal ID (4 items), Data Integrity (6), Model Diagnostics (10), Robustness Specs (9), Carry-forward to later passes, Pass-1 sign-off statement. Per-item evidence pointers and rationale. Sign-off framed honestly as "qualified pass" with the HLO measure-sensitivity as the substantive finding requiring hedge-route manuscript adaptation.

## Decisions made

- **ADR-0012 Accepted (NEW 2026-05-23):** retires ADR-0006 Robustness 2 (MI sub-commitment). Listwise alone carries the UIS-inclusion robustness check.
- **ADR-0004 amended (Data observed Phase-10 block):** AAP sensitivity executed and FAILS sign-agreement per methodology §3.4 commitment. Lock decision unchanged; empirical record updated.
- **Hedge route chosen for manuscript headline** (author decision via AskUserQuestion): "in the WB HCI HLOS specification on the 2010-2020 panel" throughout, not naked "ODA positively predicts learning". §6 frames measure-sensitivity as itself a methodological contribution.
- **3-level HLM scope decision made explicit** (methodology §3.8 update): brief's 3-level commitment was for original student-school-country spec, superseded by Phase-2 reframe; reframed obligations satisfied at country-level only with `isSingular()` check.
- **Granger test reported as not-feasible-at-our-T**, linked to the same small-T identification limit ADR-0010 already owns. Not a failure of our work; a property of the data shape.
- **No new code beyond R/72.** Pure documentation + one robustness script.

## What we tried that didn't work

- **`plm::pgrangertest` order=1 Z-tilde panel Granger test.** Failed with explicit error: *"Condition for test = 'Ztilde' not met for all individuals: length of time series must be larger than 5+3*order (>5+3*1=8)"*. Our T_eff ≤ 4. Considered switching to Zbar or Wbar variants but the underlying small-T constraint dominates regardless of test choice. Replaced by: explicit documentation as not-feasible-at-our-T in §5.8, audit doc, and obligations.md, tied to the existing ADR-0010 small-T story.

- **Full AAP-2018 sample as the only HLO sensitivity spec.** Initial R/72 ran AAP only on 1995-2015 (5 cycles); got β = -16.67, sign-flip vs primary. Realized this could be a sample-window composition effect (different aid epoch) rather than a measure-choice effect. Modified R/72 to ALSO run AAP restricted to year ≥ 2010 (the overlap with primary's window — 2 AAP cycles). Result: β_overlap = -3.94, also sign-flipped but null. The overlap-window null is what made the measure-fragility finding decisive (sample-window is not the sole driver). Without the decomposition this would have been an ambiguous result; with it, we have a clean diagnosis. Worth the extra ~15 minutes of R/72 modification.

- **The expectation that this would be a verification-only session.** The CLAUDE.md framing was "verification-focused; no new code; produce a single private results doc". Audit of obligations.md revealed 7 unfulfilled items, of which 3 needed code execution. The plan was reframed mid-session-planning into a Pass-1-audit + gap-closing battery hybrid. ~3 hours of work instead of the originally-estimated 1 session of pure documentation. The reframe was correct: the brief's "no paper until this is done" doesn't allow audit-only when there are committed-but-unrun items.

- **The temptation to defend the WB primary HLO measure aggressively via the Sandefur 2018 critique of AAP.** Considered (Option B in the AskUserQuestion fork). The defense is real — AAP's pre-2018 SACMEQ/PASEC anchors are documented as thin — but choosing that path would have meant relegating a failed pre-committed robustness check to a footnote, which is precisely the methodological-convenience move the project's discipline pattern (ADR-0007 Rejected) has avoided. The hedge route (Option A) honors the prior commitment while preserving the WB-specification result; it's also the more interesting paper-narrative move (measure-sensitivity becomes itself a methodological contribution).

## Methodology entries written this session

- **ADRs written / updated:** **NEW ADR-0012** (UIS MI retirement; Accepted 2026-05-23); **ADR-0004 amended** with Phase-10 "Data observed" block reporting AAP sensitivity failure + hedge-route response. INDEX.md updated.
- **`methodology.md` sections touched:** §3.4.1 NEW (measure-sensitivity finding); §3.6 (UNESCO self-reporting bias paragraph); §3.8 Model 3 (3-level → 2-level scope decision explicit); §3.9 (Robustness 1 result + ADR-0012 pointer).
- **`data_dictionary.md` rows added:** None (no new columns).
- **`obligations.md` items checked off:** 9 items updated with comprehensive status sweep — Granger NOT FEASIBLE; UNESCO bias [x]; 3-level ICC [x] (reframe); HLM convergence [x] (reframe); HLO sensitivity [x] FAILS sign-agreement; sample-window [x] (ADR-0003 mechanical); UIS-listwise [x]; FE-structure [N/A]; Pass 1 [x] qualified pass.
- **`lit/` notes populated:** None this session.
- **`docs/decisions/INDEX.md` updated:** Yes (0012 row added).
- **`CLAUDE.md` Current state updated:** Yes (Phase 10 closed as qualified pass; Next concrete action = Phase 11 Session 01 Writing).

## Results / findings

**Pass 1 = qualified pass.** The brief's gate is met — every Statistical-Layer diagnostic is run or documented — but the principal HLO robustness check FAILS sign-agreement, forcing a hedge of the manuscript's central within-country headline claim.

**Headline numbers (HLO sensitivity battery):**

| Spec | Outcome | Sample | N | β_ODA | SE | p |
|---|---|---|---|---|---|---|
| Primary | hlo_hlo_score | 2010-2020 | 143 | **+11.14** | 5.52 | ~0.05 |
| AAP full | aap_hlo_aap | 1995-2015 | 69 | **-16.67** | 5.96 | **0.009** |
| AAP overlap | aap_hlo_aap | year≥2010 | 36 | -3.94 | 8.68 | 0.66 |
| UIS-augmented listwise | hlo_hlo_score | 2010-2020 | 41 | -1.97 | 4.40 | >0.05 |

**Per methodology §3.4 commitment, this fails the principal-robustness criterion.** The overlap-window null rules out sample-window composition as the sole driver — measure choice matters.

**Researcher adaptation (author decision):** hedge headline claim throughout the paper to "in the WB HCI HLOS specification on the 2010-2020 panel". §6 Discussion frames measure-sensitivity as itself a methodological contribution about the cross-country aid-learning literature. Manuscript-framing reframe is now ripe — Pass-1 finding strengthens the case for path-c (methodological-discipline arc) where §5.5 (Model 4 drop), §5.8 (measure-fragility), and §6 limits become first-class narrative beats alongside the within-country positive headline.

## What's next

**Phase 11 Session 01 — Manuscript drafting (full draft, estimated 6-10 sessions per plan.md row 11).** Quarto manuscript ~10k words; matches brief's section structure; all tables/figures embedded. **The manuscript-framing reframe (paths a/b/c per `findings.md §5.2.1`) is the blocking author-judgment decision at Phase 11 entry** — Pass-1 finding makes the case for path-c (methodological-discipline arc) particularly strong, but the author should explicitly choose before drafting begins.

## Open questions for the author

- **Manuscript framing path** (a/b/c per `findings.md §5.2.1`) — recommend tackling at Phase 11 entry, ideally as the first 30-min author-decision session before drafting begins. The Pass-1 measure-sensitivity finding tilts toward path-c but author judgment is needed.
- **AAP-2018 supplementary table for the manuscript** — should §5.8's AAP results appear in the manuscript's main results section (Table X / Table Y) or be relegated to a supplementary appendix? The hedge-route framing argues for main-section visibility; manuscript-length constraints may push toward appendix. Decide at Phase 11.
- **§6 limits paragraph composition** — Pass 1 surfaced several first-class limits (small-T, HLO measure-fragility, no MI, AAP-2018 sample-window difference, Granger not feasible). The §6 paragraph needs careful authorship to communicate these honestly without overwhelming the paper's contributions. Phase 11 task.
- **PDF font fix** (em-dash + β rendering) still deferred to Phase 11 figure production.

## Files touched

- `R/72_pass1_robustness_battery.R` (NEW)
- `output/tables/pass1_granger_test.{csv,md}` (NEW)
- `output/tables/pass1_hlo_sensitivity.{csv,md}` (NEW)
- `output/tables/pass1_uis_listwise.{csv,md}` (NEW)
- `output/tables/pass1_robustness_signoff.{csv,md}` (NEW)
- `output/pass1_statistical_validity_audit.md` (NEW — the Pass-1 gate document)
- `docs/decisions/0012-retirement-of-uis-multiple-imputation.md` (NEW)
- `docs/decisions/INDEX.md` (0012 row added)
- `docs/decisions/0004-hlo-measure.md` (Phase-10 "Data observed" block added)
- `docs/methodology.md` (§3.4.1 NEW; §3.6 UNESCO bias paragraph; §3.8 Model 3 scope-decision; §3.9 Robustness 1 + ADR-0012 pointer)
- `docs/findings.md` (§5.8 NEW — Pass 1 robustness battery)
- `docs/obligations.md` (9-item comprehensive status sweep)
- `docs/session_log/2026-05-23-24-pass1-statistical-validity.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink repointed)
- `CLAUDE.md` (Current state block updated)
