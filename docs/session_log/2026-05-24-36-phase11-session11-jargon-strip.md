---
date: 2026-05-24
session: 36
phase: 11 — Session 11 (jargon strip + flow tightening)
duration_min: ~120
---

## Goal

Author read the rendered DOCX and gave decisive feedback: *"flow is broken in manuscript. path-c, obligations.md and inner kitchen like those must not be exposed. its confusing. flow must be flawless, distilled, every word must fight its way into the manuscript, no place for extra junk."* Strip all project-internal vocabulary (branch names, file names, audit-pass labels) from visible prose and tighten 12 specific flow problems identified by parallel review-agent exploration.

## What we did

- **Phase 2 structural rewrites (6 paragraphs fully rewritten, ~750w trimmed):**
  - **§1 ¶2-¶3-¶4-¶5 (Issue 1):** condensed the three-gates restatement; eliminated double-announcement of the gates ("Three pre-committed gates... [paragraph break] Three pre-committed gates..."); merged setup-and-payoff into a single tight paragraph; stripped "the brief's" and "the paper's brief" mentions; rewrote Three-Pass Protocol sentence as "A pre-registered diagnostic battery and a post-draft adversarial review protocol add second and third tiers of pre-commitment."
  - **§3.2 ¶1 (path-c strip):** "The path-c framing" → "The pre-commitment framework" (the canonical replacement chosen in plan); minor word reshuffling.
  - **§3.2 ¶2-¶3 (Issue 5):** the ~450w Three-Pass + obligations-ledger pair rewritten to ~140w. Removed Pass 1/2/3 naming, "qualified pass", "Statistical Layer", "obligations.md" file reference, "Phase 10/12/13" scheduling, "24 obligations checked complete" project-management bookkeeping, "renv::restore" reproducibility-check forward-pointer. Kept the substantive frame: ADRs + pre-registered diagnostic battery + adversarial-review protocol = three-tier discipline.
  - **§3.3 (Issue 6):** the ~60w "Positionality statement to be drafted upon author input..." stub with internal file references replaced with a single 15-word sentence acknowledging the slot. HTML comment instructions preserved.
  - **§4.2 ¶4 (Issue 8):** the 285w qualifications paragraph compressed to ~140w by merging thin-N + listwise drop, merging small-T + GMM + Granger, and replacing the in-detail AAP-2018 sign-flip restatement with a §4.7 forward reference.
  - **§5.1 thesis (Issue 10):** the 360w thesis-restatement paragraph rewritten to ~170w. Eliminated the third restatement of the three findings (which had been narrated in §1 ¶3 and the abstract). New thesis opens with the three pre-committed gates as a list and pivots to the synthesis question.
  - **§5.2/§5.3/§5.4 closing sentences (Issue 11):** stripped the "§6 takes this up..." pointer-redundancy closers from all three subsections; the §5.3 closer's substantive measurement-redundancy claim was preserved in a recast form.
  - **§6.4 (Issue 12):** reordered to hedge-first / recommendation-second so the section closes on the positive policy claim, not on the caveat. Edited "tend to be more stable" framing throughout for consistency.
- **Phase 1 mechanical jargon strip (~20+ targeted Edits across §2, §3.4, §4.4, §4.5, §4.6, §4.7, §5.3, §5.4, §5.5, §6.2, §7, Appendix B):** removed 9 "path-c framing" / "path-c contribution" / "path-c framework" instances; 11 "the brief" / "brief's" / "brief-bridge" / "brief Statistical Layer" / "brief committed to" instances; 6 "Pass 1" mentions outside section headers; 2 "Phase 10 (2026-05-23)" date stamps; "qualified pass", "obligations-bookkeeping completion", "Statistical Layer" residuals. Renamed §3.4 heading from "Pass 1 statistical-validity sign-off" to "Statistical-validity audit summary".
- **Phase 3 polish (5 issues, ~120w net savings):**
  - **Issue 2 — §1 roadmap:** "The remainder of the paper proceeds as follows. §2 reviews..." (60w) compressed to "§2 anchors..., §3 describes..., §4 reports..." (45w) — punchier, single sentence.
  - **Issue 3 — §2.3 Sandefur circularity:** removed the litigated within-FE-defense interlude; rewrite lands on "Sandefur's critique extends to the within-country dimension as well — a hard-won finding for the literature" as the §2.3 closer pivoting to §4.7.
  - **Issue 4 — §3.1 over-documentation:** the WGI PC1 loadings detail and the SSA-vs-RoW UIS missingness percentages compressed; moved into Appendix B reference.
  - **Issue 9 — §4.4 audit-to-finding reframe:** opens with "The four-bucket intervention typology the policy literature expects to extract from OECD CRS metadata... is not extractable at any defensible inter-method agreement threshold" — the finding leads; the audit numbers follow as supporting evidence rather than as the lead.
  - **Issue 13 (NEW from self-review) — §4.5 → §4.6 transition bridge:** added a 50w explicit pivot sentence at start of §4.6 explaining why the section shifts from ODA-flow scenarios to structural-determinant analysis.
- **Phase 4 — Re-rendered DOCX:** zero warnings, 419KB DOCX, clean section structure unchanged. Copied to `drafts/aid_without_learning.docx`. Note: copy to `/mnt/c/Users/szura/Desktop/AID/SUBMISSION/aid_without_learning.docx` failed with permission denied — likely the file is open in Word on the author's machine. The fresh DOCX lives in the WSL repo at `drafts/aid_without_learning.docx` and is synced to `/mnt/c/Users/szura/Desktop/AID/mirror/drafts/aid_without_learning.docx` via the desktop sync script; author can manually overwrite `SUBMISSION/` once Word is closed.

## Decisions made

- **Canonical replacement for "path-c": "pre-commitment framework"** chosen as the single consistent replacement term per plan's self-review. One term, used consistently across §3.2, §5.3, §5.4, §5.5, §7, Appendix B intro.
- **§3.2 ¶3 fully rewritten too** even though only ¶2 was named in the plan — ¶3 was about `obligations.md` directly and was even more jargon-laden than ¶2; rewriting both together produced a tighter three-tier exposition.
- **§3.4 heading renamed** from "Pass 1 statistical-validity sign-off" to "Statistical-validity audit summary" — "Pass 1" as a project-pass label leaked too obviously even at heading level.
- **AAP-2018 detailed restatement in §4.2 ¶4 dropped** in favor of "§4.7 reports the full sensitivity" — the numbers appear in §4.7 and Table 6 with full context; restating them in §4.2 was redundant.
- **§4.5 → §4.6 transition bridge added** as a 50w opening sentence in §4.6 explaining the analytical pivot. The original draft had a hard topic-switch from "ODA scenarios" to "HCI × AI Readiness" without signposting; reviewers would have stumbled.
- **The §5.6 inclusion question remains deferred** — Session 07 user decision was to skip §5.6, Session 09 reaffirmed; §5.5 → §6 transition is now cleaner after the §5.1 rewrite and the §5.2-5.4 closer-strip.

## What we tried that didn't work

- **First attempt at "every word fights" target:** plan estimated ~1,200-1,400w trim; actual trim landed at ~668w (10,941 → 10,273). The shortfall is because (a) several "compression" rewrites were actually flow-improvements that traded one set of words for cleaner ones rather than net-cutting, (b) the Issue 13 transition bridge added ~50w deliberately, and (c) some paragraphs were already tight from Sessions 08b + 09. Net result is still 728 words under the 11k ceiling — comfortable headroom for the §3.3 positionality fill.
- **`cp` to `/mnt/c/Users/szura/Desktop/AID/SUBMISSION/aid_without_learning.docx` failed with permission denied** — likely the file is open in Word on the Windows side. Fallback: the fresh DOCX is in `drafts/aid_without_learning.docx` and lands in `mirror/drafts/` via desktop sync; the author can manually overwrite SUBMISSION/ once Word releases the file lock.
- **Considered renaming "Pass 1" → "validation pass" throughout** but settled on dropping the "Pass" label entirely where possible (e.g., "The audit executed..." instead of "Pass 1 executed..."). "Pass 1" leaked too strongly as a project-internal review-stage name.

## Methodology entries written this session

- **ADRs written / updated:** —
- **`methodology.md` sections touched:** —
- **`data_dictionary.md` rows added:** —
- **`obligations.md` items checked off:** —
- **`lit/` notes populated:** —
- **`docs/decisions/INDEX.md` updated:** No
- **`CLAUDE.md` Current state updated:** Yes (Last-session line + Next-concrete-action set to Session 12 = author final-pass read of the cleaned DOCX + §3.3 positionality fill + submission prep)

## Results / findings

- Main-text wordcount: **10,941 → 10,273** (−668w trim; 727w under 11k ceiling)
- Zero rendered occurrences of: `path-c`, `obligations.md`, `obligations-bookkeeping`, `qualified pass`, `Statistical Layer`, `Three-Pass`, `Pass 2`, `Pass 3`, `the brief's`, `brief committed`, `brief Statistical`, `brief-bridge`, plus `Phase 1X Session NN` paranoia patterns
- 52 EVIDENCE TRACE comments unchanged
- 0 placeholders (only §3.3 positionality, now a 15-word stub vs prior 50-word note)
- 13 hedge mentions unchanged; 4 "we are not aware of" hedges unchanged
- Robust bib-check: zero MISSING IN BIB
- `quarto render --to docx` clean (zero warnings; 419KB DOCX)
- Section structure unchanged: §1-§7 numbered → References (full APA bibliography) → Appendix A/B/C unnumbered

## What's next

Phase 11 Session 12: author final-pass read of the cleaned DOCX + §3.3 Positionality fill (4 author specifics: years/roles, regions, donor relationship type, 1-2 reporting-bias examples) + submission package prep (OSF deposit + cover letter to *World Development* + Elsevier Editorial Manager submission). **Estimated sessions remaining after today: 1.**

## Open questions for the author

- §3.3 Positionality 4 specifics — known submission blocker.
- Does the cleaned DOCX flow now meet "flawless, distilled, every word fights" — read end-to-end and flag any remaining issues.
- The §4.5 → §4.6 transition bridge is a 50w addition that explains the pivot; verify it's substantively correct (specifically the claim that §4.2 panel "dominates learning-outcome variation" — that's leading toward §6.4 structural-determinant point).

## Files touched

- `drafts/aid_without_learning.qmd` — 6 paragraph rewrites + ~20 mechanical jargon edits + 5 polish edits + §3.4 heading rename + §1 roadmap compression + §2.3 Sandefur reorder + §3.1 ¶4 compression + §4.4 reframe + §4.5→§4.6 transition bridge
- `drafts/aid_without_learning.docx` — re-rendered artifact (419KB)
- `docs/session_log/2026-05-24-36-phase11-session11-jargon-strip.md` (NEW, this file)
- `docs/session_log/CURRENT.md` (symlink repoint)
- `CLAUDE.md` (Last-session + Next-concrete-action)

`/mnt/c/Users/szura/Desktop/AID/SUBMISSION/aid_without_learning.docx` not refreshed in this session due to Windows file lock; will be refreshed by next sync_to_desktop.sh run if Word is closed, OR by manual copy from the user when convenient.
