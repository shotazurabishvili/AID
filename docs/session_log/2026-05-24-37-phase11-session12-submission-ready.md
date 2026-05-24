---
date: 2026-05-24
session: 37
phase: 11 — Session 12 (comprehensive submission-readiness pass)
duration_min: ~150
---

## Goal

Address all three external-reviewer flags + author's open decisions in one comprehensive pass: (1) strip CLAUDE.md + rename ADR→PAP for field-standard terminology; (2) split off §4.6 Compounding AI Penalty as standalone short-paper draft; (3) fill §3.3 positionality from CV + lock affiliation. Submission-ready package as deliverable.

## What we did

- **Phase 0 — CLAUDE.md strip (2 edits):** §4.7 line 269 "(CLAUDE.md)" → "no-fabrication discipline" + Appendix B intro line 454 "; CLAUDE.md" removed.
- **Phase 2A — Extracted §4.6 + §5.5 into `drafts/compounding_divergence_short.qmd`** (NEW file). Standalone short-paper draft with: own YAML; tentative title "The compounding AI penalty: a country-level operationalization of joint human-capital and AI-readiness exclusion"; stubs for abstract / §1 introduction / §2 methodology / §5 conclusion; verbatim §4.6 + §5.5 prose as §3 Results and §4 Discussion respectively; Table 1 (compound quadrant) and Figure 1 (compound scatter) embedded. Not currently rendered. Working draft for later separate submission (target: World Development Sketches, Economics Letters, or working-paper deposit).
- **Phase 2B+C — Deleted §4.6 + §5.5 + cross-references** from main paper: §4.6 (3-paragraph section + Table 5 + Figure 3 + 3 EVIDENCE TRACE blocks) deleted in one Edit, with §4.7 heading collapsed to the new §4.6; §5.5 (2-paragraph section + 2 EVIDENCE TRACE blocks) deleted; §1 abstract "Alongside these, the paper constructs a novel HCI × AI Readiness joint composite..." sentence deleted; §1 ¶5 fourth-analysis paragraph deleted entirely; §2.3 ¶3 compounding-divergence literature paragraph + EVIDENCE TRACE deleted; §5.1 thesis "HCI × AI-readiness joint composite" sentence deleted; §6.2 "donors and research-funding bodies should commission monitoring of outcomes in the §4.6 low-HCI ∩ low-AI-readiness double-excluded cell" sentence deleted; §7 ¶1 fully rewritten from 3-contribution structure to 2-contribution structure (pre-commitment methodology + within-country coefficient with measure-fragility); §7 ¶2 "Compounding AI Penalty is a snapshot characterization..." sentence deleted; Appendix A.6 deleted (heading + 2 include shortcodes); Appendix C variable register Oxford Insights GARI row deleted.
- **Phase 2C-i — §4.7 → §4.6 cross-reference renumbering** via `sed -i 's/§4\.7/§4.6/g'` — caught ~8-10 in-text references in §3.4, §4.2, §5.3, §6.4, §7. Verified post-sed: zero §4.7 in file.
- **Phase 2C-ii — Table 6 → Table 5 renumbering** (compound table 5 went with the split; old Table 6 now Table 5).
- **Phase 2C-iii — Figure 3 confirmation:** zero Figure 3 references remaining in main paper.
- **Phase 2D — Title change to alt title:** "Aid Without Learning: A Cross-Country Analysis of ODA Allocation, Structural Determinants, and the Measurement Failure at the Heart of Global Education Finance" → **"Measuring Aid for Learning: What Cross-Country Panel Evidence Can and Cannot Say"** (the single-thesis-aligned alt title the YAML had under consideration at Session 10).
- **Phase 2E — §7 ¶1 full rewrite** from 3 contributions to 2: now leads with pre-commitment methodological framework as principal contribution, anchors with the within-country coefficient + measure-dependence documentation as second contribution.
- **Phase 2F — Regenerated SUBMISSION docs** (3 of 4): cover_letter, highlights, title_page refreshed from updated `/tmp/*.md` sources reflecting single-thesis framing, PAP terminology, filled affiliation, new title, drop of §4.6 contribution; declarations.docx blocked by Word file-lock (author has it open) — author can manually copy from new `/tmp/declarations.md` source when convenient OR re-render after closing Word.
- **Phase 1 — ADR → PAP rename (~45 substitutions via two sed passes + grammar fixes):**
  - Pass 1 sed: ADR-0001 through ADR-0012 → PAP-0001 through PAP-0012 (12 substitutions); "Architecture Decision Records" → "pre-analysis plans"; "Architecture Decision Record (ADR)" → "pre-analysis plan (PAP)"; "Architecture Decision Record" → "pre-analysis plan"
  - Pass 2 sed: grammar/contextual fixes — "an pre-analysis plan" → "a pre-analysis plan"; "the missingness ADR" → "the missingness PAP"; "Each ADR names" → "Each PAP names"; "Twelve ADRs were written" → "Twelve PAPs were written"; "the single Rejected ADR" → "the single Rejected PAP"; "The ADR architecture" → "The pre-analysis plan apparatus"; "the ADR layer" → "the PAP layer"; "retired via documented ADR" → "retired via documented PAP"; "locked in an ADR" → "locked in a PAP"; "withdrawn per a documented ADR" → "withdrawn per a documented PAP"; "## A.1 ADR inventory" → "## A.1 Pre-analysis plan inventory"; "full ADR documents" → "full pre-analysis plan documents"; table header "| ADR | Title | Status |" → "| PAP | Title | Status |"
  - One residual Edit: "The pre-commit missingness ADR (PAP-0006, Phase 2)" → "The pre-commit missingness plan PAP-0006"
- **Phase 3 — §3.3 Positionality drafted from CV (~370w):** practitioner-researcher framing grounded in CV-documented roles: UCL MA Education & International Development; 5 years of monitoring/evaluation/applied-research across donor architecture (USAID via RTI; U.S. Department of State via IREX; JICA monitoring lead; World Bank/Mathematica New School Model consortium; ETF/PIN/ENPARD EU-funded research; Ministry of Education and Science of Georgia; Reed (reed.ge) co-founder). Methodological priors (skepticism toward enrollment metrics, disbursement-over-commitment preference, UNESCO self-reporting caveat) framed as grounded in direct programme observation rather than asserted as personal anecdote. Reed positioning as instrument-layer redesign motivation for the §6 measurement-infrastructure recommendations. CV-inference guardrail held: no specific anecdotes attributed to the author beyond what CV documents explicitly.
- **Phase 4 — Affiliation lock-in:** YAML `affiliation: ""` → `affiliation: "Independent researcher / Co-founder, Reed (reed.ge); Bristol, United Kingdom"`. Cover_letter and title_page regenerated with same affiliation.
- **Phase 5 — Render + verify + commit + sync:** `quarto render --to docx` clean (zero warnings, 296KB DOCX). Full augmented verification suite all pass.

## Decisions made

- **Title switch to alt** ("Measuring Aid for Learning..."): aligns with single-thesis post-split framing; the alt title was the author's own under-consideration title from Session 10.
- **§7 ¶1 full rewrite** (not just sentence deletion): 3 contributions → 2 contributions; new ¶1 leads with the methodological framework as principal contribution.
- **PAP-0006 missingness plan phrasing** (`The pre-commit missingness plan PAP-0006`) rather than awkward sed variant ("The pre-commit missingness PAP PAP-0006") — manual Edit for grammar.
- **§3.3 length ~370w** (target was ~300w): the CV gives enough material to warrant 70w extra; cuts to under 300w would have forced removing either the donor list (which is what authorities the methodological priors) or the Reed positioning (which connects to §6 recommendations).
- **Affiliation phrasing:** "Independent researcher / Co-founder, Reed (reed.ge); Bristol, United Kingdom" — honest about both the independent-researcher status and the Reed co-founder role; Bristol UK residence per the CV's listed contact info.
- **Bib entries `@muthukrishna2025divergence`, `@mandon2025beyond`, `@ilo2026disruption` retained in `references.bib`** even though unused in main paper post-split — they are used by the split paper at `drafts/compounding_divergence_short.qmd`; bib-check verifies citations-have-entries (not the inverse), so unused bib entries cause no warnings.

## What we tried that didn't work

- **First sed pass for ADR → PAP** caught the bulk but left grammar issues: "in an Architecture Decision Record" became "in an pre-analysis plan" (article-agreement error). Pass 2 sed added grammar fixes ("an pre-analysis plan" → "a pre-analysis plan"). Final manual Edit was the residual missingness-ADR phrasing where the sed pattern was ambiguous.
- **`declarations.docx` regeneration blocked by Windows file lock** (Word held the file open from the author's machine). Author will need to close Word and either re-run the pandoc command or I can refresh in next session. Cover_letter, highlights, title_page refreshed cleanly. Same fallback as Session 11.
- **Quarto include-shortcode behavior for the deleted Appendix A.6 includes** was a non-issue: the include shortcodes were deleted along with the heading. The underlying `output/tables/_render_includes/compound_ai_penalty_*.md` files still exist for the split paper's later use.

## Methodology entries written this session

- **ADRs/PAPs written / updated:** —
- **`methodology.md` sections touched:** — (would benefit from sweep in a future session to align terminology, but not required for this submission)
- **`data_dictionary.md` rows added:** —
- **`obligations.md` items checked off:** —
- **`lit/` notes populated:** —
- **`docs/decisions/INDEX.md` updated:** No (the underlying ADR repository files keep their names; only manuscript display labels were renamed to PAP)
- **`CLAUDE.md` Current state updated:** Yes

## Results / findings

- Main-text wordcount: **10,273 → 9,367 (−906w)** — 727w under 11k ceiling; ~600w headroom for any final author edits
- File total: 18,685w → 16,148w (−2,537w from main-paper §4.6/§5.5/AppendixA.6 deletion + reduction in jargon and cross-references)
- Zero CLAUDE.md / Architecture Decision Record / ADR / path-c / obligations.md / qualified pass / Statistical Layer / Three-Pass / Pass 2 / Pass 3 / the brief's / brief-bridge in visible prose
- Zero §4.6/§5.5 residue (Compounding AI Penalty / HCI × GARI / double-excluded cell / compound_index / joint composite / Figure 3 / Oxford Insights)
- Zero stale §4.7 references (all updated to new §4.6 via sed)
- 0 placeholders (§3.3 positionality filled to 370w)
- 46 EVIDENCE TRACE comments (was 52; 6 removed with the deleted §4.6/§5.5/AppendixA.6 sections)
- Title: "Measuring Aid for Learning: What Cross-Country Panel Evidence Can and Cannot Say"
- Affiliation: "Independent researcher / Co-founder, Reed (reed.ge); Bristol, United Kingdom"
- Quarto render --to docx clean (zero warnings; 296KB DOCX)
- Bib-check: zero MISSING IN BIB

## What's next

Phase 11 Session 13 (if needed): author final-read of the submission package + Editorial Manager submission. If the read surfaces substantive edits, those apply in Session 13. Otherwise this session leaves the package complete and ready.

**Estimated sessions remaining: 0-1.** The package is submission-ready except for: (a) §3.3 positionality is drafted from CV — author should verify the framing matches their intended self-presentation; (b) `declarations.docx` needs refresh from `/tmp/declarations.md` once Word is closed; (c) OSF DOI to add once author runs the repository deposit.

## Open questions for the author

- **§3.3 positionality:** drafted from CV (370w). Does the framing accurately represent how you want to be seen? Specific items to verify: (1) "Independent researcher / Co-founder, Reed" as the affiliation; (2) the donor list (USAID, JICA, World Bank/Mathematica, ETF, PIN, ENPARD, MoES, IREX) — accurate? complete?; (3) Reed positioning as instrument-layer redesign motivation for §6 — does this match how you'd describe Reed?
- **Title switch to "Measuring Aid for Learning: What Cross-Country Panel Evidence Can and Cannot Say"** — confirms the single-thesis post-split framing. Acceptable, or revert to the original?
- **§7 ¶1 rewrite** — confirms the 2-contribution structure (methodological framework + measure-dependence documentation). Reads cleanly without the §4.6 contribution?
- **OSF deposit DOI** — need to deposit the repo and replace placeholders in cover_letter / title_page / declarations before final submission.

## Files touched

- `drafts/aid_without_learning.qmd` — Phase 0 + Phase 1 (~45 substitutions) + Phase 2 (§4.6/§5.5 deletion + 10+ cross-ref edits + title change + §7 ¶1 rewrite) + Phase 3 (§3.3 fill) + Phase 4 (affiliation)
- `drafts/aid_without_learning.docx` — re-rendered (296KB, was 419KB before §4.6 split)
- `drafts/compounding_divergence_short.qmd` (NEW) — standalone short-paper draft preserving §4.6 + §5.5 content
- `/tmp/cover_letter.md`, `/tmp/highlights.md`, `/tmp/title_page.md`, `/tmp/declarations.md` — refreshed markdown sources
- `SUBMISSION/cover_letter.docx`, `highlights.docx`, `title_page.docx` — regenerated DOCX (declarations.docx blocked by Word file-lock)
- `SUBMISSION/aid_without_learning.docx` — refreshed render (296KB)
- `docs/session_log/2026-05-24-37-phase11-session12-submission-ready.md` (NEW, this file)
- `docs/session_log/CURRENT.md` (symlink repoint)
- `CLAUDE.md` (Last-session + Next-concrete-action)
