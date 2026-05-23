---
date: 2026-05-23
session: 27
phase: 11 — Manuscript drafting (path-c); Session 03: §3 Data & Methodology
duration_min: ~120
---

## Goal

Phase 11 Session 03 on `manuscript/path-c`. §3 Data & Methodology — the largest single section (~2,000 words target) and the methodological-contribution showcase for path-c framing. Four subsections: (3.1) data + panel construction; (3.2) pre-commitment design (path-c centerpiece); (3.3) positionality (awaits author input); (3.4) Pass 1 sign-off.

User-given discipline (carried from Session 02): no hallucination; evidence-based work; every claim traceable. For §3 this means carving from project-internal sources (methodology.md, INDEX.md, brief.md, pass1 audit) rather than re-introducing external citations beyond what Sessions 01–02 have already verified.

## What we did

- Read the full §3 source material before drafting: methodology.md §3.1–§3.7 (panel construction), methodology.md §3.8–§3.11 (the model specs + the pre-commitment locks), `docs/decisions/INDEX.md` (12 ADRs), `docs/brief.md` lines 212–227 (Three-Pass Protocol), `output/pass1_statistical_validity_audit.md` §6 (Pass 1 sign-off block), `docs/positionality.md` (stub).
- **Drafted §3.1 Data sources + panel construction** (~1,100 words; target was 1,000). Five paragraphs as planned: universe + period (¶1); outcome HLO + Sandefur defense + LAYS layer (¶2); treatment ODA + 16-cell sensitivity grid + ADR-0005 lock (¶3); macro/sector/governance controls including the Phase-10 UNESCO self-reporting bias paragraph (¶4); confounders (UCDP + COVID closures, ¶5). Each paragraph followed by an EVIDENCE TRACE HTML comment identifying every claim's source in methodology.md.
- **Drafted §3.2 Pre-commitment design** (~700 words; target 500–600; ran over because the ADR roster carved into a longer single sentence than estimated). Three paragraphs as planned: ADR architecture inventory with all 12 ADRs and one-line operational summaries (¶1); brief's Three-Pass Self-Review Protocol with Pass 1 close as a qualified-pass exemplar (¶2); `obligations.md` as audit spine with the 24-checked / 2-withdrawn / 2-scope-resolved / 1-not-feasible-at-our-T closing summary (¶3). This is the path-c methodological centerpiece — the prose explicitly names the ADR architecture as *pre-commitment + falsifiable gates* and frames ADR-0007 Rejected as "the protocol caught an unfeasible design".
- **Inserted §3.3 Positionality PLACEHOLDER** with the 4 specific author-input questions (years, regions, donor/implementer relationship type, 1-2 reporting-bias examples) and a `DO NOT DRAFT WITHOUT AUTHOR INPUT` directive in an HTML comment so any future Claude session reading the .qmd source knows not to fabricate biographical specifics. Replaced the underlying prose with an italicized one-sentence note pointing readers at `docs/positionality.md` for the four specifics needed. ~300 words of prose target deferred until author input lands.
- **Drafted §3.4 Pass 1 sign-off + audit summary** (~400 words; target 200–400). Two paragraphs: the verbatim-paraphrased Pass 1 close statement (¶1); the substantive HLO measure-sensitivity finding + the hedge route adapation that propagates throughout the manuscript (¶2). Explicit forward-references to §4.7 (the empirical writeup) and §5 (the methodological-contribution framing).
- Verified all 7 checks: zero MISSING IN BIB lines; 17 EVIDENCE TRACE comments (8 from §2 Session 02 + 9 new from §3); manuscript word count grew from 4,329 to 6,923 (+2,594); §3.3 PLACEHOLDER marker present; DO NOT DRAFT directive at line 240; quarto check clean; git status only the .qmd modified.

## Decisions made

- **§3.3 deliberately NOT drafted.** Refusing to fabricate biographical specifics is the explicit discipline boundary. The placeholder block lists the 4 questions the author needs to answer and a directive to any future Claude session not to draft cold. Drafting §3.3 without author input would directly violate the "ensure not hallucinating and real, evidence-based work" instruction from Session 02.
- **§3.2 ran ~100w over its 500-600w target.** Because the 12-ADR roster compresses naturally into a single long sentence with the operational-summary-each pattern (ADR-0001…ADR-0012 in one connected enumeration), the paragraph hit ~250w on its own. Accepted the overrun because the ADR architecture is the path-c centerpiece and an enumeration that lists all 12 is more rhetorically powerful than a 6-listed-plus-6-implied compression.
- **Brief's Three-Pass Protocol cited as paraphrase rather than block quote.** Block quoting all three Pass specifications would have run ~200w of citation overhead; paraphrasing each Pass in one sentence preserves the substantive commitment and saves ~150w for the §3.2 obligations spine that needed the space.
- **All §3 inline citations are to keys already in `drafts/references.bib`** (Altinok 2018; Sandefur 2018; Angrist 2024; GEEAP 2023; Langbein-Knack 2010). No new bib entries needed; no new lit-note stubs needed. Asongu 2019 not cited in §3 (held back per Session 02 plan; can be added in §4.3 if Model 3 / GMM discussion needs it).

## What we tried that didn't work

- **The temptation to draft a "reasonable-sounding" §3.3 from inferred biographical context.** The brief gestures at a practitioner-researcher author profile; CLAUDE.md mentions reed.ge co-founding and Bristol UK location; the lit-note structure mentions "the author has seen" patterns. A composite biographical paragraph could have been assembled from these scraps. **Explicitly rejected.** The reed.ge / Bristol / project-history fragments are insufficient to construct the four specifics docs/positionality.md asks for (exact years in education sector; regions of direct field experience; donor/implementer relationship type; first-hand reporting-bias examples). Composing a paragraph from inference would be the textbook hallucination pattern. The §3.3 placeholder with author-input questions is the disciplined alternative.
- **First §3.1 ¶4 draft conflated WGI and UIS into one paragraph.** Caught at the read-through — WGI is a methodological choice (PC1 vs single-GE vs all-six per ADR-0009); UIS is a missingness-strategy choice (drop vs listwise vs MI per ADR-0006 + ADR-0012). Conflating them lost both ADR locks' narrative weight. Re-structured to give each its own dedicated sentence within the paragraph; both ADRs are now individually named.
- **The temptation to embed a full ADR roster table in §3.2.** Tables in the middle of methodology prose interrupt the rhetorical arc. The 12 ADRs are listed inline in §3.2 ¶1 with a one-line operational summary each; the full table lives in INDEX.md and is referenced by URL in Appendix A. Inline-prose enumeration was the more rhetorically appropriate format for the path-c centerpiece paragraph.

## Methodology entries written this session

- **ADRs written / updated:** None this session.
- **`methodology.md` sections touched:** None this session (Phase 11 carves from methodology.md; doesn't modify it).
- **`data_dictionary.md` rows added:** None.
- **`obligations.md` items checked off:** None new; the §3 drafting is itself the partial closure of the Phase-11 manuscript-drafting obligation (closes when all sections complete).
- **`lit/` notes populated:** None this session.
- **`docs/decisions/INDEX.md` updated:** No.
- **`CLAUDE.md` Current state updated:** Yes (Last session = Session 27; Next concrete action = Phase 11 Session 04 §4 Results part 1; note on context utilization added).

## Results / findings

- **§3 Data & Methodology drafted across 4 subsections (~2,200 words; target 2,000).** §3.1 ~1,100w + §3.2 ~700w + §3.3 PLACEHOLDER + §3.4 ~400w. ~300w gap remaining at §3.3 (positionality awaits author input).
- **Cumulative finished prose Sessions 01–03:** Abstract (250w) + §1 Introduction (1,000w) + §5.1 thesis (200w) + §2 Literature Review (1,500w) + §3.1/3.2/3.4 (~2,200w) = **≈5,150 words**.
- **9 new EVIDENCE TRACE comments in §3** (17 total in the .qmd: 8 from §2 Session 02 + 9 new). Every substantive paragraph in §3 traces its claims to a project-internal source line.
- **All citation keys validated; quarto check clean; git status clean.**
- **Manuscript total word count: 6,923 words in the .qmd** (includes ~1,800w of YAML / placeholders / HTML comments). Finished prose is ~5,150w of the 9-11k target = on pace at the ~halfway mark of the manuscript by word count.

## What's next

**Phase 11 Session 04 — §4 Results part 1 (§4.1 Descriptive + §4.2 Models 1 & 2 chain, ~1,200 words combined).** Sources: docs/findings.md §4.1–§4.3 (descriptive) + §5.1–§5.2 (Models 1 & 2). Headline figure for §4.1 (enrollment-vs-learning divergence); headline table for §4.2 (cross-section vs within-FE β contrast: −1.36 ns → +11.14*).

Estimated remaining sessions on path-c: 4–6.
- Session 04: §4.1 + §4.2 (~1,200w)
- Session 05: §4.3 Model 3 + §4.4 Model 4 dropped + §4.5 Model 5 counterfactual (~1,700w)
- Session 06: §4.6 Compounding AI Penalty + §4.7 HLO measure-fragility + §5 Discussion elaboration kick-off (~1,500w)
- Session 07: §5 Discussion elaboration completion (~1,300w)
- Session 08: §6 Policy + §7 Conclusion (~1,300w)
- Session 09: Final-revision pass — full PDF render via quarto render; figure-text rendering check; APA 7 CSL file added; title decision (working title vs alt path-c title); citation pruning + bib cleanup; word-count audit against 9-11k target.

## Open questions for the author

- **Positionality specifics for §3.3** (BLOCKING for completing §3): (a) exact years and roles in the education sector; (b) countries / regions of direct field experience; (c) type of donor / implementer relationship (multilateral / bilateral / INGO / national government); (d) 1-2 concrete reporting-bias examples observed first-hand. ~300w prose unblocked once provided.
- **Asongu 2019 lit-note stub** — still flagged from Session 02 as possibly needed if §4.3 Model 3 / §3.8 GMM discussion engages it. Currently cited only through bib entry. Reassess in Session 05 when §4.3 drafts.
- **Title decision** — working title vs alt path-c title still deferred to Session 09.
- **Context window utilization rising.** Session approaching ~70% of the 1M-token context window after this session's drafting work. Sessions 04–09 may benefit from starting fresh contexts (auto-compact is disabled per `/context`); flagged in CLAUDE.md for the author's awareness.

## Files touched

- `drafts/aid_without_learning.qmd` — §3 placeholder replaced with §3.1, §3.2, §3.3 (PLACEHOLDER), §3.4; 9 new EVIDENCE TRACE HTML comments; word count grew from 4,329 → 6,923 (+2,594 words; ~2,200 of these are finished §3 prose, balance is EVIDENCE TRACE comments + §3.3 placeholder block + HTML comments)
- `docs/session_log/2026-05-23-27-phase11-session03-methodology.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink repointed)
- `CLAUDE.md` (Current state Last-session + Next-concrete-action updated; context-utilization note added; on `manuscript/path-c` only)
