---
date: 2026-05-19
session: 20
phase: 6 — Model 3 (2-level RE + time FE)
duration_min: ~75
---

## Goal

Estimate Model 3 (2-level country random intercepts + year FE per the Phase-2 external-review reframe in `methodology.md §3.8`); perform Hausman test of FE vs RE to justify Model 2's headline; compute country-level ICC; produce the three-way Model 1/2/3 contrast for the manuscript's Table 5.

## What we did

- Wrote `R/57_model3_re_panel.R`: mirrors R/56 setup (locked treatment + inline PC1 with sign-flip), but estimator is `lme4::lmer` with `(1|iso3)` random intercepts and `factor(year)` fixed effects. `REML=FALSE` (ML) for Hausman comparability with feols FE.
- Fit specs 3a-3e × HLO + LAYS = 10 lmer fits. **No singular fits** — `isSingular()` returned FALSE for all 10.
- Sample is N=173 at 3e (Model 2's N=143 + 30 extra single-obs countries that lmer can keep since random-intercept variance doesn't require multiple obs per group).
- **Manual univariate Cameron-Trivedi Hausman on β_ODA:** H = (b_FE − b_RE)² / (Var(b_FE) − Var(b_RE)) = (11.14 − (−1.32))² / (5.52² − 2.68²) = 6.67, df=1, **p=0.0098** — rejects RE at p<0.01.
- **`plm::phtest` failed** (Swamy-Arora RE not estimable on T_eff ≤ 3-4, same as Sessions 14/06). Manual Hausman is the operative test. Both branches reported in `output/tables/model3_hausman_test.csv`.
- **Country-level ICC via `performance::icc()`:** unconditional 91.2% (intercept-only model `hlo ~ 1 + (1|iso3)`); conditional 79.3% adjusted (full 3e). Both wrapped in `tryCatch`; both succeeded.
- Built the three-way Model 1/2/3 contrast: Model 1 OLS β=−1.36 ns (cross-section), Model 2 FE β=+11.14** (within), Model 3 RE β=−1.32 ns (collapsed onto Model 1).
- Wrote `docs/findings.md §5.4` from stub to full manuscript-grade writeup: three-way contrast table, spec progression, Hausman, ICC, substantive implications, convergent-evidence summary across five Phase-5/6 strands.
- Updated `docs/methodology.md §3.8` with empirical Hausman + ICC numbers (replaced "ADR locked at Phase 6 Session 1 start" placeholder).

## Decisions made

- **Hausman result: REJECT RE at p<0.01.** Manuscript Table 5 reports Model 2 FE as headline; Model 3 RE reported as transparency counterpart; explicit citation of the manual Hausman test in §3.8 / §4.
- **ICC interpretation:** 91% between-country is the *structural identification finding* — it explains why Model 3 RE collapses onto Model 1 OLS (variance-component weighting puts essentially all weight on between-country information), and why within-FE is *necessary* (not just preferred) to recover the ODA signal.
- **Model 3 sample N=173 vs Model 2 N=143** retained as informative: lmer can keep single-observation countries (random intercept = country mean for those countries); feols cannot (singleton-FE drop). The 30-country difference doesn't change the qualitative finding.
- **Random slopes on log_crs by country deliberately NOT attempted.** Plan flagged this as out-of-scope; the headline ICC + Hausman + three-way contrast is a complete Phase 6 Session 01 deliverable. Random slopes would be Phase 6 Session 02 if revisited.
- **Spec 3a HLO β=−5.19 (p=0.002)** documented in findings §5.4 as the unconditional cross-country aid→outcome pattern. Striking but interpretable — adding log(GDP) at 3b kills it, exactly as expected from the classical "aid concentrates in low-outcome countries" pattern.

## What we tried that didn't work

- **`plm::phtest` failed (predicted from Sessions 14/06).** Swamy-Arora RE estimator requires T > 3 effective time periods; HCI cycles give T_eff ≤ 4 on the post-listwise sample. Same error as before: `model not estimable: 6 coefficient(s) ... only 3 time(s)`. Manual univariate Hausman was prepared as the lead approach (plan); used as the operative test. plm::phtest reported as a tried-and-failed check in the output table for transparency.
- **No singularity issues encountered** — the lmer fits converged cleanly on all 10 specs. The "lmer may produce singular fits on T_eff ≤ 4" risk flagged in the plan didn't materialize. Likely because (a) `factor(year)` provides clean time-FE identification, (b) the random-intercept-only structure is parsimonious enough to identify on 173 obs / 156 countries.
- **Did NOT need to invoke the "denominator-negative" Hausman fallback** flagged in the plan. The empirical Var(b_FE) − Var(b_RE) = 23.27 > 0; standard formula applies.

## Methodology entries written this session

- **ADRs written / updated:** None. Methodology.md §3.8 already locked the Phase-2 reframe; this session adds the empirical numbers (Hausman + ICC) to that paragraph. No new ADR needed since the reframe was already documented in methodology.
- **`methodology.md` sections touched:** §3.8 (Model 3) — added empirical Hausman + ICC paragraph.
- **`data_dictionary.md` rows added:** —
- **`obligations.md` items checked off:** No explicit Phase-6 obligation row; methodology §3.8 reframe paragraph is now empirically backed.
- **`lit/` notes populated:** —
- **`docs/decisions/INDEX.md` updated:** No new ADR; no status changes.
- **`CLAUDE.md` Current state updated:** yes (Phase 6 Session 1 done; Models 1-2-3 chain closed).

## Results / findings

**Three-way contrast (manuscript Table 5):**

| Model | Identification | N | β_ODA | SE | p |
|---|---|---|---|---|---|
| Model 1 OLS (cross-sectional country means, full spec 1e) | Between-country only | 120 | −1.36 | 2.48 | 0.584 |
| **Model 2 v2 FE (within-country, locked 2e)** | **Within-country only** | **143** | **+11.14** | **5.52** | **0.048** |
| Model 3 RE (random intercepts + year FE, locked 3e) | Weighted between + within | 173 | −1.32 | 2.68 | 0.622 |

**Hausman: H=6.67, df=1, p=0.0098 — rejects RE.** Manual univariate Cameron-Trivedi. plm::phtest not estimable.

**ICC: unconditional 91.2% / conditional 79.3% adjusted.** Country-level variance dominates HLO; cross-sectional and RE estimators are mechanically dominated by country-quality confounding. Within-FE is required.

**Spec 3a HLO bivariate: β=−5.19, p=0.002.** Unconditional cross-country aid→learning is strongly negative. GDP control (3b) absorbs it. This is the classical aid-skeptic finding that Model 2 FE was designed to escape.

**Substantive close on Models 1-3:** the three estimators converge on a coherent story. Cross-section/RE: aid concentrates in poor-outcome countries (negative pattern, dominated by country quality). Within: aid increases predict outcome increases (positive within-country effect, p<0.05). The two patterns are reconcilable via the 91% ICC structure; Hausman p<0.01 formally validates this reading.

## What's next

Phase 6 Session 01 is the structural close of the Models 1-3 chain. Two viable next sessions:

**Option α — Phase 7 Session 01 (Model 4, ANOVA on intervention typology).** Per the brief's roadmap. Requires [ADR-0007](decisions/0007-oecd-crs-intervention-typology.md) lock (CRS intervention typology coding: rule-based keyword vs LLM-assisted). Levene + Tukey HSD + η² + Cohen's d per the obligations. This closes the only remaining Pending ADR in the project.

**Option β — §6 framing reframe** (paths a/b/c per `findings.md §5.2.1`). Author judgment task. Five independent strands now support positive within-country ODA→learning (Sessions 03/04/05/06 + this session). The brief's pre-Phase-5 framing is structurally outdated; §6 narrative needs to commit to a successor framing before Phase 11 manuscript drafting begins in earnest.

**Recommended:** Option α first (it's structural model-stack work, doesn't depend on framing), then Option β. Author judgment welcome on the ordering.

## Open questions for the author

- **Phase 7 vs framing reframe ordering** — see above.
- **Random slopes (Phase 6 Session 02)** — methodology.md §3.8 doesn't commit to them; T_eff ≤ 4 makes them risky. Worth attempting if author thinks the heterogeneity story is load-bearing for the manuscript; deferrable otherwise.
- **PDF font fix** still deferred (em-dash + β rendering). Phase 11 manuscript figure production is the natural place.

## Files touched

- `R/57_model3_re_panel.R` (NEW)
- `output/tables/model3_re_specs.{csv,md}` (NEW)
- `output/tables/model3_hausman_test.csv` (NEW)
- `output/tables/model3_icc.csv` (NEW)
- `output/tables/model123_three_way_contrast.{csv,md}` (NEW)
- `output/figures/eda/model3_coefficient_plot.{pdf,png}` (NEW)
- `docs/findings.md` §5.4 (stub → full writeup)
- `docs/methodology.md` §3.8 (empirical Hausman + ICC paragraph added)
- `docs/session_log/2026-05-19-20-model3-re-panel.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink)
- `CLAUDE.md` Current state
