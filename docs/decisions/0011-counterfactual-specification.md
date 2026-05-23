# ADR-0011: Model 5 counterfactual specification

**Status:** Accepted
**Date:** 2026-05-23
**Phase:** 8 — Model 5 (counterfactual simulation)

## Context

The brief specifies Model 5 as:

> *"Redirect $1B from input-based to outcome-based programs; use effect sizes from Model 4; report best case, worst case, expected case across CI bounds; acknowledge limits."*

Two prior locks compress this specification:

1. **Model 4 dropped** ([ADR-0007](0007-oecd-crs-intervention-typology.md) Rejected 2026-05-23): the brief's pre-committed gate on the four-bucket intervention typology failed; we have no defensible Model-4 effect sizes. "Input-based vs outcome-based" has no quantitative referent in this paper's identified models.

2. **Model 2 static-FE small-T identification** ([ADR-0010](0010-identification-strategy-gmm.md) Accepted with caveats): the only β with a defensible identification story is Model 2 spec 2e's aggregate within-country coefficient on `crs_disburse_usd_defl_ma3_lag1` (**β = 11.136, SE = 5.518, p = 0.048, N = 143**; locked encoding per Phase 5 Sessions 03/04/05).

A literal "$1B injected into one country" applied through Model 2's β is a 17–20× shock above the median country's baseline ($59.7M annual CRS), which is an extrapolation far outside the within-country variation Model 2 was identified on (typical year-over-year Δlog(CRS) in the estimation sample is in the 0.1–0.5 band, not the ~3.0 a 20× shock would imply). Honoring the brief's nominal framing by extrapolating Model 2's coefficient that far is precisely the move ADR-0007 disciplined us against in a different guise.

## Options considered

1. **Literal $1B per-country shock through Model 2 β** — would deliver headline-grabbing numbers but they would be coefficient extrapolation beyond the support of the data. Rejected on the same epistemic-discipline ground as ADR-0007's Option 3 hand-coding rejection.

2. **Within-support % shocks on the median-baseline country, with the brief's $1B reported as a bridging context note** — chosen. Scenarios (+10%, +50%, +100%) stay near the support of the within-country log-CRS variation in the Model 2 estimation sample. The brief's $1B is honored by reporting what it actually means when distributed across the sample (≈$5.78M per country = ≈9.7% of the median baseline) and noting that this lands in the *low-shock* band, not the high-shock band.

3. **Country-quartile sensitivity table** — added alongside the headline as a robustness panel; same shock × β grid applied at Q1 / median / Q3 of baseline CRS. Confirms (mechanically, by log1p properties) that percentage shocks produce roughly invariant ΔHLO across baseline quartiles; cross-quartile contrast lives in absolute-dollar space, not percentage space.

4. **Sub-sector reallocation via OECD purpose codes** — considered as a Path-B alternative at planning; rejected because it would re-introduce the typology-axis ambition ADR-0007 disciplined out, split an already-thin small-T panel four ways, and contradict the §5.5 narrative. See `findings.md §5.5` and the session log.

## Decision

Lock the Option-2 specification. Concretely:

- **β source:** Model 2 spec 2e (HLO outcome, two-way FE country + year, country-clustered SE, locked encoding). Read from `output/tables/model2_fe_baseline_v2.csv` rather than re-estimated, so Phase 5 remains the source of truth.

- **Treatment shock magnitudes:** +10 %, +50 %, +100 % applied to the median country's `crs_disburse_usd_defl_ma3_lag1` baseline ($59.7M). These bracket the within-country Δlog(CRS) range observed in the estimation sample.

- **CI propagation:** plug-in {lower 95 %, point, upper 95 %} of the Model 2 β — `β_lo = 0.32`, `β_pt = 11.14`, `β_hi = 21.95`. Maps directly to brief's worst / expected / best scenarios. *Not* a full Monte Carlo over the joint regressor covariance — that would overreach the static-FE inference base.

- **LAYS translation:** identity-based ΔLAYS = EYS × ΔHLO / 625, holding EYS constant. Justification: the within-country β captures *learning-quality* improvement, not *access* expansion, so holding EYS constant isolates the learning channel. EYS is not in the production panel as a separate column; it is computed via the WB identity inversion EYS = LAYS × 625 / HLO on the estimation sample, then summarised at the p10, p50, p90 percentiles for the LAYS-uncertainty fan (estimation sample yields p10 = 7.25 yr, p50 = 11.57 yr, p90 = 13.18 yr; consistent with the methodology.md §3.4 spot-check of AFG ≈ 8.9, ALB ≈ 12.9, ARG ≈ 12.9, ARM ≈ 11.3, AGO ≈ 8.1).

- **Scenario aggregation:** single illustrative *median aid-receiving country* baseline as the manuscript headline; quartile sensitivity table reports the same scenario set at Q1 / Q2 / Q3 baseline-CRS. *Not* a global-budget allocation algorithm — that's a separate optimization paper.

- **Time horizon:** one HCI cycle (≈ 5 yr) marginal projection. Consistent with the Model 2 estimation rhythm (3-yr-MA × strictly-past lag → ≈ 2-yr-ahead HLO cycle resolution). No inter-temporal discounting. Documented as a within-cycle marginal projection, not a steady-state forecast.

- **Estimation-sample reconstruction:** the script reconstructs the Model 2 spec 2e complete-case sample for baseline summaries. Reconstruction yields N = 173 vs the locked feols N = 143; the 30-country gap is feols' singleton-FE-dropping (countries with only one HCI cycle in the panel). The wider N = 173 is retained as the baseline-distribution sample because the counterfactual cares about the population the policy reaches, not just countries with within-country FE identification. β itself is the locked N = 143 estimate — the script does *not* re-estimate.

- **Brief-bridge note:** $1B distributed pro-rata across the 173-country sample = $5.78 M per country average = **9.7 % of the median baseline** = **5.49 % of the sample's total annual education aid** ($18.22B). The brief's headline number lands in the *low-shock* band of the headline table, not the high-shock band. Reported as a paragraph in `output/tables/model5_counterfactual.md` and quoted in `findings.md §5.6`.

## Consequences

- Model 5 produces three CSV + two MD + two figure artifacts under `output/tables/model5_*` and `output/figures/model5_*`. R/70 is the only Phase-8 analysis script.

- The headline empirical claim of Model 5 is **modest by design**: at the median country, a +10 % CRS shock produces an expected +1.04 HLO points (+0.019 LAYS years at median EYS); a +100 % shock produces +7.63 HLO (+0.141 LAYS). Best/worst cases span roughly a 65× ratio at the median EYS, reflecting the wide Model 2 CI (β lower bound is essentially zero).

- The brief's "$1B redirect" framing is *honored by translation and limit-acknowledgment*, not by literal arithmetic. §5.6 makes this transparent; the manuscript's §6 Discussion paragraph on Model 5 will own this directly.

- Phase 8 closes in one session. Phase 9 (compounding AI penalty section) becomes the next active phase.

## How a referee might attack this

*"Why not just apply $1B per-country to Model 2's β as the brief specified?"*

Because that's a coefficient extrapolation outside the support of the data. Model 2's β is identified on within-country year-over-year Δlog(CRS) values in the 0.1–0.5 range; a $1B per-country shock implies Δlog ≈ 2.9 on the median country, which is 6× the largest within-country log-change in the estimation sample. The β is a marginal effect, not an unbounded linear coefficient. Honoring the brief's nominal $1B framing by ignoring the data-support constraint would be the kind of methodological convenience this paper has been explicit about not making (see ADR-0007 Rejected for the parallel discipline call on Model 4).

*"Your scenarios are too modest to be policy-relevant."*

That's the point. The headline finding of Model 5 is not "redirecting $1B produces X LAYS" — it is "the within-country aid-to-learning channel, identified at the only specification the data supports, is modest in absolute magnitude at policy-realistic shock sizes, and the confidence interval is wide enough that the worst-case (β lower 95 %) is essentially zero." A more dramatic-looking number would require either (a) extrapolating beyond support or (b) re-introducing the typology disaggregation we already disciplined out via ADR-0007. Neither survives a *World Development* referee read.

*"Why holding EYS constant rather than fitting a separate EYS regression?"*

The within-country β was estimated on HLO, not on EYS. The brief's intervention question is about learning quality, not schooling access. Holding EYS constant isolates the channel being identified; a separate EYS-equation would introduce a new identification problem (donor allocation responds differently to enrollment shortfalls vs learning shortfalls) that we are not equipped to address in this paper. Sensitivity to the EYS assumption is reported in the p10/p50/p90 fan.

*"Plug-in CI propagation under-states uncertainty."*

Plausibly. It does not propagate joint covariance with the controls (log-GDP, PTR, ed-expenditure-share, WGI PC1); it captures only the marginal SE on β. A Bayesian or Monte Carlo treatment with the full Σ̂ would widen the bands. The plug-in choice is documented as a limit; it was chosen because the static-FE clustered-SE inference base is already at the edge of what small-T cross-country panel data supports, and stacking another inference layer on top would overreach. A revise-and-resubmit response could implement a Monte Carlo if the editor asks; the input ingredients are in `output/tables/model2_fe_baseline_v2.csv`.
