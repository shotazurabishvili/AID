---
date: 2026-05-24
session: 35
phase: 11 — Session 10 (DOCX render)
duration_min: ~45
---

## Goal

Render the locked manuscript to Word (DOCX) so the author can do the final-pass read in a familiar tool before submission. Install any dependencies needed. PDF is stretch-goal only — *World Development* accepts DOCX preferentially via Elsevier Editorial Manager.

## What we did

- **Phase 0 verification — render tooling.** Confirmed Quarto 1.9.37, Pandoc 3.1.3, R 4.3.3 with knitr + rmarkdown, Python 3.12.3 all installed. No installs required for DOCX path. LaTeX not installed; PDF would require `quarto install tinytex` (~250MB).
- **Phase 1 first render attempt** — `quarto render aid_without_learning.qmd --to docx` produced a valid 419KB DOCX with only one warning: an unresolved `@sec-methods` crossref in §2.1 line 56 (stray from an earlier draft using `@sec-` cross-reference IDs that the rest of the manuscript doesn't use).
- **Phase 2 issues surfaced from diagnostic render** (all expected per the plan's risk register):
  1. Stray `@sec-methods` crossref — replaced with plain `§3` reference (1 Edit).
  2. **Include-header dumping (the predicted big risk).** All 9 source `.md` files that started with `# heading` lines DID dump their headers into the manuscript as new top-level sections (Section 8 = "Model 3", Section 9 = "Model 5 — Counterfactual", ..., Section 17 = "Pass 1 — Granger test"), breaking the appendix numbering. **Fix:** pre-processed the 9 affected source files into `output/tables/_render_includes/` with all `#` headings demoted by 3 levels (`#` → `####`, `##` → `#####`) via `sed -E 's/^(#+ )/###\1/'`, then redirected the 10 affected includes (model3_re_specs, model5_counterfactual, compound_ai_penalty_quadrant, compound_ai_penalty_robustness, model2_fe_sensitivity, model2_wgi_specs, model2_china_robustness, pass1_hlo_sensitivity, pass1_uis_listwise, pass1_granger_test) to point at the demoted versions. The 2 includes whose source files already had no `# heading` (`model1_ols_baseline.md`, `model2_fe_baseline_v2.md`) point at originals unchanged.
  3. **Appendix subsection numbering inherited §7 numbering.** `## A.1 ADR inventory` rendered as "7.1 A.1 ADR inventory" because `# Appendix A {.unnumbered}` only unnumbers the top heading. **Fix:** added `{.unnumbered}` to all 13 appendix subsection headers (`## A.1`-`A.6`, `## B.1`-`B.7`) via single `sed` command.
  4. **Demoted include sub-headings still got ugly auto-numbers** like `7.0.0.1`, `7.0.0.1.1` because Quarto auto-numbers heading levels 1-N by default. **Fix:** added `number-depth: 2` to both `docx:` and `pdf:` YAML format blocks — only main §1-§7 and §X.Y get numbered; level 3+ headings remain unnumbered.
  5. **Bibliography rendered at the very end of the document** (after Appendix C) rather than at the `# References` heading — Pandoc's default with no explicit anchor. **Fix:** added `::: {#refs} :::` div under the References heading to anchor citeproc's bibliography output.
- **Phase 3 re-render** — `quarto render --to docx` produced a clean 419KB DOCX with zero warnings. Final section structure: §1 Introduction → §2 Literature Review (2.1, 2.2, 2.3) → §3 Data & Methodology (3.1-3.4) → §4 Results (4.1-4.7) → §5 Discussion (5.1-5.5) → §6 Policy Implications (6.1-6.4) → §7 Conclusion → References (full APA-formatted bibliography) → Appendix A (ADR inventory + 6 regression tables) → Appendix B (7 robustness sections) → Appendix C (variable register).
- **Phase 4 PDF stretch — declined.** PDF render failed with "No TeX installation detected." `quarto install tinytex` would fix this (~250MB) but user requested Word render specifically; not burning install time for an unrequested artifact. Path is documented for future Session 11 if author wants PDF.
- **Phase 5 verification:** robust bib-check passed (zero MISSING IN BIB); main-text 10,941w; EVIDENCE TRACE count 52 (unchanged); placeholder count 0 (was 1, but the §3.3 positionality grep no longer matches because the only remaining "PLACEHOLDER" text is inside an HTML comment); hedge mentions 13; "we are not aware of" 4. Added `drafts/*_files/` to `.gitignore` (Quarto auto-creates empty `aid_without_learning_files/mediabag/` during render).

## Decisions made

- **Pre-process source .md files via sed into `output/tables/_render_includes/`** rather than hardcoding tables inline in the .qmd — keeps the .qmd lean (~30KB saved vs hardcode approach), gives a clean reproducible build-pipeline boundary, and the demote-by-3-levels recipe is one bash line so future regenerated table sources can be re-processed with one command.
- **`number-depth: 2` chosen over per-heading `{.unnumbered}`** — single YAML line catches all level-3+ headings (including auto-generated demoted ones from `_render_includes/`) versus 30+ individual heading attribute edits.
- **`::: {#refs} :::` div anchor** rather than `{#refs}` attribute on the References heading — Quarto-idiomatic, and explicit-div is what Pandoc's citeproc looks for by convention.
- **PDF deferred to Session 11+** — user said "render in Word"; PDF needs TinyTeX install which is unrequested overhead. Decision documented; future revival is one `quarto install tinytex && quarto render --to pdf` away.

## What we tried that didn't work

- **First render with no fixes** — produced a DOCX with broken appendix structure (Appendix A subsections renumbered as 7.1, 7.2, 7.3, then sources 8, 9, 10... dumped as new top-level sections). Identified the 4 distinct render-time issues and fixed each in Phase 2.
- **First fix-iteration without `number-depth: 2`** — the appendix structure was correct (no more rogue Section 8/9/10) but demoted include sub-headings rendered as `7.0.0.1`, `7.0.0.1.1`, etc. — Quarto was still auto-numbering by depth. Added `number-depth: 2` to suppress level-3+ numbering globally; clean result.
- **First fix-iteration without `::: {#refs} :::` anchor** — the bibliography rendered at the very end of the document (after Appendix C) rather than at the `# References` heading. Pandoc's citeproc defaults to end-of-document placement unless an explicit `refs` div is present. Added the div; bibliography now sits between §7 Conclusion and Appendix A.

## Methodology entries written this session

- **ADRs written / updated:** —
- **`methodology.md` sections touched:** —
- **`data_dictionary.md` rows added:** —
- **`obligations.md` items checked off:** —
- **`lit/` notes populated:** —
- **`docs/decisions/INDEX.md` updated:** No
- **`CLAUDE.md` Current state updated:** Yes (Last-session line + Next-concrete-action set to Session 11 = author final-pass read + §3.3 positionality fill + submission prep)

## Results / findings

`drafts/aid_without_learning.docx` exists at 419KB. Final structure verified via `pandoc -t plain` round-trip:
- 10 sections in correct order (Title/Abstract → §1-§7 numbered → References (APA-formatted bibliography placed correctly) → Appendix A / B / C unnumbered)
- 3 figures embedded as inline PNG images in `word/media/`
- Tables rendered as Word tables (no literal `| col |` markdown leakage)
- 30+ inline citations rendered correctly per APA 7 style (e.g., `(Altinok et al., 2018)`, `Burnside and Dollar (2000)`, `Glewwe and Muralidharan's (2016)`)
- Full bibliography at References section with all cited works in APA format

## What's next

Phase 11 Session 11: author final-pass read of the rendered DOCX + §3.3 Positionality fill (4 specifics: years/roles, regions, donor relationship type, 1-2 reporting-bias examples) + submission package prep (OSF deposit + cover letter to *World Development* + Elsevier Editorial Manager submission). **Estimated sessions remaining after today: 1.**

## Open questions for the author

- §3.3 Positionality 4 specifics — known submission blocker.
- PDF render preference for submission: DOCX is enough for Elsevier Editorial Manager. Skip PDF unless you specifically want one for a separate purpose.
- Any framing-level edits surfacing from the rendered DOCX final-pass read? Bring to Session 11.

## Files touched

- `drafts/aid_without_learning.qmd` — YAML format block (added `number-depth: 2`); `@sec-methods` crossref fix; 13 appendix subsection `{.unnumbered}` additions; 10 include-path redirections to `_render_includes/`; `::: {#refs} :::` bibliography anchor div
- `output/tables/_render_includes/` (NEW DIRECTORY) — 10 pre-processed source .md files with heading levels demoted by 3
- `drafts/aid_without_learning.docx` (NEW) — rendered manuscript artifact, 419KB
- `.gitignore` — added `drafts/*_files/` (Quarto media bag auto-creates)
- `docs/session_log/2026-05-24-35-phase11-session10-docx-render.md` (NEW, this file)
- `docs/session_log/CURRENT.md` (symlink repoint)
- `CLAUDE.md` (Last-session + Next-concrete-action)
