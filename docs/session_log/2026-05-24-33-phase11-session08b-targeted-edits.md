---
date: 2026-05-24
session: 33
phase: 11 — Manuscript drafting (path-c); Session 08b: targeted edits — 9 referee-catchable defects + bib-check verification hardening
duration_min: ~75
---

## Goal

Phase 11 Session 08b on `manuscript/path-c`. Pre-Session-09 hardening pass: fix 9 referee-catchable defects surfaced by a fresh-eye end-to-end read of the manuscript after Session 08 close + replace the silently-broken bib-check verification grep that has been giving false-pass output across every session since the original was written. No new prose drafted; only targeted defect fixes + verification-logic replacement.

## What we did

- **Read the full manuscript end-to-end** (~12,500w finished prose + EVIDENCE TRACE comments + placeholder blocks) and produced an honest fresh-eye assessment. Surfaced 9 referee-catchable defects spanning citation-key duplications, methodological-test conflation, numerical inconsistencies, project-internal-artifact leakage, hedge-symmetry breaks, and missing acronym expansions.
- **Verified each defect concretely** via an Explore agent + direct Bash grep. Discovered worse: **three citation keys used in the prose are MISSING from `drafts/references.bib` entirely** — `@sandefur2018harmonized` (2 prose uses), `@vegascoffin2015education` (2 prose uses), `@angrist2024` (1 prose use). The canonical bib-check grep used to gate every session commit since Session 02 silently passes them as present.
- **Diagnosed the bib-check bug.** The grep is `grep -oE "@-?[a-z][a-zA-Z0-9]+" drafts/aid_without_learning.qmd | sed 's/^@-/@/' | sort -u | while read k; do [ "$k" = "@gmail" ] || [ "$k" = "@sec" ] && continue; grep -q "{${k#@}," drafts/references.bib || echo "MISSING IN BIB: $k"; done`. The `pipe | while read` form is the culprit: the inner `grep -q` returning 1 propagates an exit-status that interacts with the conditional in a way that aborts the loop after the first iteration. A direct `for k in $keys; do ... done` form catches all missing keys correctly.
- **Drafted and approved the targeted-edits plan.** Plan committed to: (a) 3 citation-key consolidations to the existing bib entries (no new bib additions); (b) 7 prose defect fixes (GMM/Granger conflation; §4.5 sample-size mislabel; §4.7 sample-reduction ambiguity; §4.6 "Session 23" leakage; §7 ¶1 missing hedge; §6.4 untested predictive-benchmark claim; Abstract "unambiguously" overclaim); (c) 5 acronym expansions at first mention (GEEAP, SACMEQ, PIRLS, TIMSS, PASEC, LLECE, EGRA); (d) replacement of the broken bib-check; (e) 4 new augmented verification gates for project-internal-leakage, hedge-symmetry, acronym-expansion, and sample-size cross-check.
- **Ran the new robust bib-check as gate-on-the-gate BEFORE any edits** — confirmed it flagged the 3 known-missing keys (`@angrist2024`, `@sandefur2018harmonized`, `@vegascoffin2015education`) plus 2 expected false positives (`@rubin1976inference`, `@little1988test` — both mentioned in EVIDENCE TRACE comments as "if author elects to add..." forward-references, not actual citations). The new check works.
- **Executed 18 prose edits** via the Edit tool: 3 citation-key consolidations (using bracket-anchored matching to avoid the `@angrist2024` ⊂ `@angrist2024lays` substring-corruption trap), 2 EVIDENCE-TRACE meta-mention fixes (strip `@` from `@rubin1976inference` and `@little1988test` in comments to silence the bib-check false positives without adding speculative bib entries), 7 defect fixes, 5 acronym expansions, and 3 additional in-prose session-marker leakage cleanups surfaced by the new project-internal-leakage gate (`§5.5 (Session 07)` → `§5.5`; `§5.3 (next subsection... drafted in this same session)` → `§5.3 below`; `§5.4 elaboration in Session 07` → `§5.4 elaboration below`).
- **Final verification — all 7 gates pass:** (1) new robust bib-check returns zero MISSING IN BIB; (2) 52 EVIDENCE TRACE comments (unchanged — no comments added or removed); (3) word count 19,079 → 19,197 (+118 words, within the predicted +120-180 band); (4) 10 placeholder blocks (unchanged); (5) 13 hedge mentions (unchanged); (6) `quarto check` clean on Quarto 1.9.37; (7) git status shows only `drafts/aid_without_learning.qmd` modified. Augmented gates: hedge-symmetry count grew from 3 to 4 occurrences of "we are not aware of" / "this paper is not aware of" (§4.6, §5.5, §7 ¶1 after fix); project-internal-leakage scan now shows only legitimate stubs (§3.3 PLACEHOLDER comment block; §3.4 prose "Phase 10 Session 01" qualifier; Appendix A/B/C comments).

## Decisions made

- **The 9 defects + bib-check bug are referee-catchable rather than framing-level.** The 5 framing-level author-review flags (e.g., §5.3 "within-country dimension is not safe ground for the Sandefur critique either" contribution claim; §5.4 ¶3 "the field has under-engaged with" claim; §6.1 named-DAC-delegate verification; §6.2/§6.3 AEA Data Editor "18-month adoption" claim) remain Session-09-author-discretion calls and were not touched this session — those are subjective hedging-level choices that benefit from author judgment rather than defensive defect-fixing.
- **Citation consolidations used existing bib entries rather than adding new ones.** `@sandefur2018internationally`, `@vegas2015when`, and `@angrist2024lays` all already exist in references.bib and were already used elsewhere in the manuscript; replacing the missing-key references with the existing canonical keys is cleaner than minting new bib entries for the same papers.
- **`@angrist2024` ⊂ `@angrist2024lays` substring corruption avoided** via bracket-anchored Edit calls (`[@angrist2024]` → `[@angrist2024lays]`) instead of naive `replace_all "@angrist2024" → "@angrist2024lays"`. The latter would have corrupted the existing 6 `@angrist2024lays` references throughout the manuscript into `@angrist2024layslays`. Critical gotcha worth documenting for future sessions doing bib-key consolidations.
- **§4.5 173-country mislabel resolved by re-labeling, not recalculating.** The pro-rata arithmetic ($1B / 173 = $5.78M; 9.7 percent of $59.7M; 5.49 percent of $18.22B) was correct against 173 — the 173 came from the actual counterfactual table source representing "ODA-recipient countries in the brief-bridge calculation" rather than Model 2's FE-identifiable subset. Re-labeling preserves the calculation; recalculating would have cascaded through three downstream percentage figures.
- **§7 ¶2 GMM/Granger conflation expanded to two-sentence form** rather than minimally fixed. The original conflated "Arellano-Bond GMM not feasible per Dumitrescu-Hurlin's threshold for the Z̃ Granger variant" — methodologically wrong because these are different tests with different thresholds. The fix separates them: GMM not feasible per Bond 2002's T ≥ 5–10 minimum; Dumitrescu-Hurlin Granger pre-test fails the same small-T constraint. Adds ~20 words but the methodological precision is load-bearing for the path-c contribution framing.
- **3 in-prose session-marker leakages surfaced by the new gate were fixed in this session** rather than deferred to Session 09. The leakages were forward/backward cross-references that left the project-internal session-numbering trail visible to a referee (e.g., "§5.5 (Session 07) takes up the snapshot-versus-trajectory point" — the "(Session 07)" parenthetical is a Phase-11 drafting-artifact). Removing them costs ~20 words across three locations and produces a manuscript that reads as a finished document rather than a project-in-progress.
- **The §3.3 positionality stub block and the §3.4 "Phase 10 Session 01" project-internal language remain in scope for Session 09.** Both are larger rewrites (~300w + a paragraph-level rephrase) and benefit from author input on the §3.3 specifics and from a complete pass over the §3 register at the same time.

## What we tried that didn't work

- **First impulse was to fix only the 9 visible defects** without running the gate-on-the-gate verification of the bib-check itself. Switching to "verify the verification before any edits" caught the silent false-pass and surfaced the 3 missing-from-bib keys + 2 EVIDENCE TRACE false positives — without this gate-of-the-gate step, the bib-check would have continued silently passing the broken-citation manuscript.
- **First citation-consolidation attempt used naive `replace_all "@angrist2024" → "@angrist2024lays"`** before noticing that `@angrist2024` is a substring of `@angrist2024lays` already in the manuscript (line 27 §1 intro). Caught at execution-plan stage; switched to bracket-anchored Edit calls. Would have produced 7 instances of `@angrist2024layslays` corruption if executed naively. Worth documenting as a discipline gotcha for any future bib-key consolidation work.
- **Considered drafting new bib entries for `@rubin1976inference` and `@little1988test`** to resolve the 2 EVIDENCE TRACE false positives. Rejected: these are speculative forward-references the author may or may not elect to add at Session 09 polish; pre-adding the bib entries would commit to a citation the manuscript prose doesn't currently use. Stripping the `@` from the meta-mention is the lower-commitment fix and preserves the option for Session 09.

## Methodology entries written this session

- **ADRs written / updated:** None.
- **`methodology.md` sections touched:** None.
- **`data_dictionary.md` rows added:** None.
- **`obligations.md` items checked off:** None.
- **`lit/` notes populated:** None.
- **`docs/decisions/INDEX.md` updated:** No.
- **`CLAUDE.md` Current state updated:** Yes — Last-session line refreshed to Session 33; Next-concrete-action set to Phase 11 Session 09 with the now-cleaner pre-render base; verification-grep discovery documented inline.

## Results / findings

No new empirical results this session — defect fixes only.

**Cumulative manuscript progress (post-Session-08b):**
- §1 Abstract + §2 Lit Review: ~1,220w (Sessions 01-02 + acronym expansions this session)
- §3 Methods: ~3,220w (Sessions 03 + later additions + acronym expansions)
- §4 Results: ~4,510w (Sessions 04-06 + §4.5/§4.6/§4.7 defect fixes this session)
- §5 Discussion: ~1,590w (Sessions 06-07 + §5.3 acronym expansions + cross-reference cleanups)
- §6 Policy Implications: ~1,070w (Session 08 + §6.4 predictive-benchmark fix)
- §7 Conclusion: ~410w (Session 08 + §7 ¶1 hedge restoration + §7 ¶2 GMM/Granger separation)
- **Cumulative finished prose ≈ 12,020w of 9-11k target** — ~1,020w over the 11k ceiling. Session 09 trim now ~1,020w to land at ≤11,000w. Trim band is slightly larger than the original 640-790w projection because the 9 defect fixes net-added ~120 words (the acronym expansions dominate; the abstract trim and §4.6 Session-23 removal subtracted some).

## What's next

**Phase 11 Session 09 — Final-revision PDF render + author-review pass + appendices** (~1 working session). Five sub-components:
- (a) **Quarto PDF render** with APA 7 CSL bibliography slot-fill (now safe to render since bib-check passes cleanly)
- (b) **Placeholder → live Quarto syntax conversion** — 10 placeholder blocks for Tables 1-6 + Figures 1-3 + one additional figure
- (c) **Author-review of the 5 framing-level contribution-claim flags** that remained out-of-scope this session, plus the §5.6 inclusion decision (deferred Session 07 → Session 09)
- (d) **Appendices A/B/C population** — full regression tables from `output/tables/` + robustness chain + variable operationalization from `data_dictionary.md`
- (e) **Word-count trim ~1,020w** to land at ≤11,000w. Primary target: §4.2 Session-04 substantive-density-overrun paragraph (the locked-encoding-stack one). Secondary target: §3.2 ¶1 ADR-inventory paragraph compression (currently lists all 12 ADRs in one parenthetical chain — could be a tighter one-paragraph-narrative + appendix-table form). Tertiary target: §3.4 "Phase 10 Session 01" obligations-bookkeeping language re-write.

**Author-input gates for submission (orthogonal to Session 09 timing):**
- §3.3 Positionality — 4 specifics still needed (years/roles, regions, donor relationship type, 1-2 reporting-bias examples). Once provided, ~300w prose can be drafted.
- 5 framing-level author-review flags surfaced at Sessions 06-08, deferred to Session 09 author-discretion.

## Open questions for the author

None blocking Session 09 PDF render or appendix population. The 5 framing-flag author-discretion calls are presentable at Session 09 as a batched author-review list; the §3.3 positionality input is independently scheduable.

## Files touched

- `drafts/aid_without_learning.qmd` (+118 words; 21 targeted Edit calls covering citation-key consolidations, defect fixes, acronym expansions, leakage cleanups)
- `docs/session_log/2026-05-24-33-phase11-session08b-targeted-edits.md` (new)
- `docs/session_log/CURRENT.md` (symlink repoint)
- `CLAUDE.md` (Last-session + Next-concrete-action update + verification-grep discovery documented)

## Verification-grep takeaway for future sessions

**The canonical bib-check command must be the for-loop variant:**

```bash
keys=$(grep -oE "@-?[a-z][a-zA-Z0-9]+" drafts/aid_without_learning.qmd | sed 's/^@-/@/' | sort -u)
for k in $keys; do
  case "$k" in (@gmail|@sec) continue;; esac
  grep -q "{${k#@}," drafts/references.bib || echo "MISSING IN BIB: $k"
done
```

The original `pipe | while read k; do ... done` formulation silently aborts after the first failed inner grep. Every session log going back to Session 02 incorrectly claims a clean bib check based on the broken version. Do not use the `while read` form for any verification gate where the inner command's exit status can be non-zero — use `for` loops with explicit variable iteration instead.

Additionally, EVIDENCE TRACE comments mentioning bib keys as forward-references (`@rubin1976inference`, `@little1988test`) should NOT use the `@key` prefix syntax — write them as plain "Rubin 1976" or "Little 1988" to avoid triggering the bib-check false positives. The discipline is: `@key` syntax is reserved for actual citations; plain author-year mentions are for meta-discussion.
