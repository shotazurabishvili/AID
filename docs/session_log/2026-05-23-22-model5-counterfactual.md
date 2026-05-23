---
date: 2026-05-23
session: 22
phase: 8 — Model 5 (counterfactual simulation, locked)
duration_min: ~75
---

## Goal

Lock Model 5 (the brief's "five empirical models" closer): a counterfactual simulation on the within-country aid-to-learning channel, given that the brief's "$1B redirect using Model-4 effect sizes" framing was vacated by today's earlier Model 4 drop (Session 21, ADR-0007 Rejected).

## What we did

- Read `R/57_model3_re_panel.R` for the table+figure+stdout pattern; read `output/tables/model2_fe_baseline_v2.csv` to confirm the locked Model 2 spec 2e numbers (β=11.136, SE=5.518, N=143) and column structure. Verified that `hci_lays_overall` is in `data/interim/panel.parquet` but `hci_eys_overall` is **not** — EYS has to be derived from the WB identity inversion EYS = LAYS × 625 / HLO (consistent with methodology.md §3.4's spot-check approach).
- Reframed the counterfactual scope after a feasibility check. Applying the brief's literal $1B to a single country (median baseline ≈ $59.7M annual CRS) is a 17× shock — far outside the within-country log-CRS support Model 2 was identified on (typical year-over-year Δlog ≈ 0.1–0.5, not the ≈ 2.9 a 17× shock implies). Honoring the brief's nominal framing by extrapolating β that far is the same kind of methodological convenience ADR-0007 disciplined out for the Model-4 typology. Substituted **within-support % shocks** (+10 %, +50 %, +100 %) on the median country, with the brief's $1B reported as a *bridging context note* — what it actually means when distributed across the sample (≈ 9.7 % of the median baseline; lands in the low-shock band). This is the honest face of the Model-4 drop carried into Model 5.
- Wrote `R/70_model5_counterfactual.R`. Pattern mirrors R/57 (suppressPackageStartupMessages + library block; numbered file constants; `arrow::read_parquet`; csv + md output pairs; ggplot figure; stdout summary). Reads locked Model 2 coefficients from `output/tables/model2_fe_baseline_v2.csv` rather than re-estimating — keeps Phase 5 as source of truth, prevents accidental re-estimation drift. Builds Model 2 PC1 the same way R/57 does (PCA on six WGI dims, sign-flipped to align with `wgi_ge_est`) to reconstruct the estimation sample for baseline summaries. Three shock × three β scenario grid × three implied-EYS percentiles for the LAYS fan. Quartile-baseline sensitivity panel. Brief-bridge context paragraph appended to the headline md.
- Ran `R/70`. Output: β = 11.14, 95 % CI [0.32, 21.95]; median baseline $59.69M annual CRS; implied EYS percentiles 7.25 / 11.57 / 13.18 yr; headline scenarios ranging from +0.03 HLO (worst, +10 % shock) to +15.0 HLO (best, +100 % shock); LAYS from +0.0006 yr (worst) to +0.28 yr (best). Six artifacts produced.
- Drafted ADR-0011 (`docs/decisions/0011-counterfactual-specification.md`) with full options-considered, decision-rationale, consequences, and four-attack referee-defense sections. Status: Accepted 2026-05-23. INDEX.md updated.
- Rewrote methodology.md §3.8 Model 5 paragraph (from yesterday's redesign-hook into today's empirical writeup with the actual numbers). Added the brief-bridge translation as a dedicated paragraph, and rolled the locked limits inventory inline.
- Wrote findings.md §5.6 (previously a "to be populated" stub). Scenario table inline; brief-bridge paragraph; GEEAP / Angrist comparison; §6 Discussion hook framing Model 5 as a *floor* on the policy-realistic channel rather than a ceiling.
- Checked off the LAYS reporting layer obligation in `obligations.md` (was `[~]` from Phase 3 Session 01, now `[x]` with evidence pointer to §5.6 and R/70).

## Decisions made

- **ADR-0011 Accepted: within-support % shocks with brief-bridge translation.** Single substantive lock of the session. Rejected literal $1B injection (extrapolation beyond data support); rejected purpose-code-disaggregated Model-4-redux (re-introduces the typology ambition ADR-0007 disciplined out); rejected full Monte Carlo over joint covariance (overreaches the static-FE inference base).
- **β reading from locked table rather than re-estimation.** `output/tables/model2_fe_baseline_v2.csv` is the source of truth; Phase 8 does not re-run Model 2. Drift-prevention.
- **LAYS translation via WB identity, EYS held constant.** The within-country β was estimated on HLO, not EYS; the brief's intervention question is about learning quality, not access. Holding EYS constant isolates the learning channel; sensitivity to EYS reported across p10/p50/p90 of implied EYS.
- **N=173 baseline-distribution sample retained (vs feols' N=143).** The 30-country gap is feols singleton-FE dropping. The wider N=173 sample is more representative of the population the counterfactual policy would reach (countries with ≥ 1 HCI cycle in the panel + complete controls), even though β itself is identified on N=143. Documented in ADR-0011.

## What we tried that didn't work

- **Literal $1B per-country shock through Model 2 β.** Considered as the obvious brief-compliance path. Rejected at planning: a 17× shock above the median baseline is a coefficient extrapolation 6× beyond the largest within-country log-change in the estimation sample. Honoring the brief's nominal arithmetic at the cost of supporting it with data would be the same methodological convenience this paper has been explicit about not making (cf. ADR-0007 Rejected for the parallel discipline call on Model 4). Replaced by: within-support % shocks with the brief's $1B reported as a bridging context note.
- **Purpose-code-disaggregated re-estimation (Path B at planning).** Use OECD's pre-coded 5-digit purpose codes (basic / secondary / post-secondary / vocational — sectors 111/112/113/114) as a "defensible typology", re-estimate Model 2 with per-bucket treatments, then run Model 5 on the resulting per-bucket βs. Rejected: this is Model-4-redux with a different typology axis, contradicts §5.5's commitment that the composition question is unanswerable from CRS at panel scale, and splits an already-thin small-T panel (N=143, T_eff ≤ 4) four ways into per-bucket specs that wouldn't be defensibly identified. Replaced by: aggregate-β counterfactual with the composition question explicitly *owned as unanswered* in §5.6 / §6.
- **Full Monte Carlo over the joint regressor covariance.** Considered for the CI propagation step. Rejected: would propagate uncertainty from log-GDP, PTR, ed-expenditure-share, and WGI PC1 alongside β. The static-FE clustered-SE inference base is already at the edge of what small-T cross-country panel data supports; stacking another inference layer is the wrong response to "we have weak identification". Replaced by: plug-in {lower 95%, point, upper 95%} of β only — documented as a limit in ADR-0011 with the input ingredients (β + SE in the locked table) on disk in case a referee asks for the Monte Carlo at revise-and-resubmit.
- **patchwork-required `p_hlo / p_lays` syntax.** Initial figure-stacking code used `/` before checking patchwork availability. Caught in a pre-run read-through; rewrote as a `requireNamespace` cascade (patchwork → gridExtra → HLO-only fallback). patchwork was available; cascade never had to fall back.

## Methodology entries written this session

- **ADRs written / updated:** **ADR-0011 NEW (Accepted 2026-05-23)** — Model 5 counterfactual specification. INDEX.md updated.
- **`methodology.md` sections touched:** §3.8 Model 5 paragraph replaced (yesterday's redesign-hook → today's empirical writeup with actual numbers, brief-bridge paragraph, and locked limits inventory inline).
- **`data_dictionary.md` rows added:** None. EYS is *implied* from the LAYS/HLO identity at analysis time, not stored as a panel column. The LAYS / HLO / CRS columns documented in Phase 3 are sufficient.
- **`obligations.md` items checked off:** LAYS reporting layer (line 55) flipped from `[~]` to `[x]` with evidence pointer to §5.6 and R/70.
- **`lit/` notes populated:** None this session. (Glewwe-Muralidharan and Vegas-Coffin were reframed yesterday; they are cited in the §5.6 §6-Discussion hook but their lit notes don't need further edits.)
- **`docs/decisions/INDEX.md` updated:** yes (0011 row added).
- **`CLAUDE.md` Current state updated:** yes (Phase 8 closed; Model 5 locked per ADR-0011; Next concrete action = Phase 9 Session 01 compounding AI penalty section).

## Results / findings

**Headline scenario table** (median country baseline = $59.7M annual CRS; locked Model 2 spec 2e β = 11.14, SE = 5.52, p = 0.048, 95% CI [0.32, 21.95]):

| Shock | Worst (β lower 95 %) | Expected (β point) | Best (β upper 95 %) |
|---|---|---|---|
| +10 % | +0.03 HLO / +0.001 LAYS | +1.04 HLO / +0.019 LAYS | +2.06 HLO / +0.038 LAYS |
| +50 % | +0.13 HLO / +0.002 LAYS | +4.45 HLO / +0.082 LAYS | +8.78 HLO / +0.163 LAYS |
| +100 % | +0.22 HLO / +0.004 LAYS | +7.63 HLO / +0.141 LAYS | +15.0 HLO / +0.278 LAYS |

LAYS at median implied EYS (11.57 yr); fan over p10 (7.25 yr) / p90 (13.18 yr) in `output/tables/model5_counterfactual.md`.

**Brief-bridge:** $1B distributed across the 173-country reconstructed estimation sample = $5.78M per country (≈ 9.7 % of median baseline; ≈ 5.49 % of total annual sample CRS $18.22B). Lands in the *low-shock band* of the headline table. Literal $1B-to-one-country = 17× baseline shock, outside data support, not projected.

**Substantive read for §6:** the within-country aid-to-learning channel, identified at the only specification the data supports, is *modest in absolute magnitude* at policy-realistic shock sizes — even the +100% expected scenario produces only ~7.6 HLO points (out of a 300-625 scale) and ~0.14 LAYS years. The worst-case scenario (β lower 95% bound) is essentially zero. This is the honest face of "aggregate cross-country panel aid effectiveness" given the data we have; the §6 Discussion frames it as a calibration of expectations downward at the cross-country panel level, while leaving open — by reference to the GEEAP / Glewwe-Muralidharan literatures — that program-level targeting (which we explicitly cannot evaluate from CRS metadata per §5.5) is where the larger gains plausibly live.

**Models 1-2-3-5 chain now structurally closed.** The paper's empirical headline is complete. Phase 9 (compounding AI penalty section) is the next standalone deliverable.

## What's next

**Phase 9 Session 01 — Compounding AI penalty section.** Per plan.md row 9. Constructs the HCI × AI Readiness composite, documents the novel finding, produces the figure. Standalone — does not require any earlier model output. Likely a single session given the AI Readiness data is already ingested (`data/interim/ai_readiness.parquet`).

## Open questions for the author

- **Manuscript framing reframe (paths a/b/c per `findings.md §5.2.1`)** — still open, off critical path. The §5.5 (Model 4 drop) + §5.6 (modest counterfactual) results are *both* finalized now, which makes the framing decision more concrete: the paper's empirical headline is "positive within-country effect, modest absolute magnitude, composition unanswered." Author judgment on whether to lead with the within-country positive finding (path a), the cross-country/within-country contrast (path b), or the methodological-discipline arc (path c, in which §5.5 and §5.6 become first-class narrative beats rather than caveats) is the next framing decision before Phase 11 drafting.
- **PDF font fix** (Δ + β rendering in figure titles) still produces console warnings on R/70 as it did on R/57. Cosmetic; deferred to Phase 11 figure production as noted in prior sessions.
- **Full Monte Carlo CI propagation** — kept on the shelf as a possible revise-and-resubmit response if a referee asks. Input ingredients (β, SE, full joint VCV from feols if needed) are on disk; not a Session-01 priority.

## Files touched

- `R/70_model5_counterfactual.R` (NEW)
- `output/tables/model5_counterfactual.{csv,md}` (NEW)
- `output/tables/model5_baseline_quartile_sensitivity.{csv,md}` (NEW)
- `output/figures/model5_scenario_plot.{pdf,png}` (NEW)
- `docs/decisions/0011-counterfactual-specification.md` (NEW)
- `docs/decisions/INDEX.md` (0011 row added)
- `docs/methodology.md` (§3.8 Model 5 paragraph replaced with empirical writeup)
- `docs/findings.md` (§5.6 stub → full writeup)
- `docs/obligations.md` (LAYS reporting layer obligation checked off)
- `docs/session_log/2026-05-23-22-model5-counterfactual.md` (THIS)
- `docs/session_log/CURRENT.md` (symlink repointed)
- `CLAUDE.md` (Current state block updated)
