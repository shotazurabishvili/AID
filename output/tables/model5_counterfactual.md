# Model 5 — Counterfactual (within-support headline scenarios)

**Source:** locked Model 2 spec 2e (HLO outcome, two-way FE country + year, country-clustered SE). β = 
11.1360 (SE 5.5180, N = 143). 95% CI = [0.3207, 21.9513].

**Baseline:** median annual CRS disbursement (MA3-lag1, constant USD millions) across the Model 2 estimation sample = **$59.7M**. Q1 = $23.7M; Q3 = $123.7M.

**Shocks:** within-support percentage increases applied to the median country's annual disbursement. These stay near the support of the within-country log-CRS variation Model 2 was estimated on; a literal $1B injection to a single country (~20-50× baseline) would be a wild extrapolation beyond that support — see PAP-0011 and the note below.

**LAYS translation** via the WB identity ΔLAYS = EYS × ΔHLO / 625, holding EYS constant. Implied-EYS percentiles on the estimation sample: 
p10 = 7.25 yr; p50 = 11.57 yr; p90 = 13.18 yr.

|shock              |scenario                         | baseline_usd_M| shock_usd_M| delta_log_crs| beta_value| delta_hlo_pts| delta_lays_p10| delta_lays_p50| delta_lays_p90|
|:------------------|:--------------------------------|--------------:|-----------:|-------------:|----------:|-------------:|--------------:|--------------:|--------------:|
|+10% (low-shock)   |Worst case (β lower 95% CI)      |          59.69|        5.97|        0.0938|     0.3207|         0.030|         0.0003|         0.0006|         0.0006|
|+10% (low-shock)   |Expected case (β point estimate) |          59.69|        5.97|        0.0938|    11.1360|         1.045|         0.0121|         0.0193|         0.0220|
|+10% (low-shock)   |Best case (β upper 95% CI)       |          59.69|        5.97|        0.0938|    21.9513|         2.059|         0.0239|         0.0381|         0.0434|
|+100% (high-shock) |Worst case (β lower 95% CI)      |          59.69|       59.69|        0.6849|     0.3207|         0.220|         0.0025|         0.0041|         0.0046|
|+100% (high-shock) |Expected case (β point estimate) |          59.69|       59.69|        0.6849|    11.1360|         7.627|         0.0885|         0.1412|         0.1609|
|+100% (high-shock) |Best case (β upper 95% CI)       |          59.69|       59.69|        0.6849|    21.9513|        15.034|         0.1744|         0.2783|         0.3171|
|+50% (mid-shock)   |Worst case (β lower 95% CI)      |          59.69|       29.84|        0.4000|     0.3207|         0.128|         0.0015|         0.0024|         0.0027|
|+50% (mid-shock)   |Expected case (β point estimate) |          59.69|       29.84|        0.4000|    11.1360|         4.454|         0.0517|         0.0824|         0.0940|
|+50% (mid-shock)   |Best case (β upper 95% CI)       |          59.69|       29.84|        0.4000|    21.9513|         8.780|         0.1019|         0.1625|         0.1852|

## Counterfactual at the $1B high-shock end

A $1B annual increase distributed across the 173-country Model 2 estimation sample = **$5.78M per country on average**, which is **9.7%** of the median baseline ($59.7M) and **5.49%** of the sample's total annual education aid ($18.2B). This lands in the low-shock band of the headline table; the $1B figure is *not* well-described by the highest-shock scenarios above. Applying the entire $1B to a single country would push that country 18× above its baseline — outside the data support Model 2 was identified on, and we do not project there.

## Limits acknowledged (per the corresponding pre-analysis plan)

- **Identification:** Model 2 is static FE on small-T (T_eff ≤ 4 HCI cycles per country); GMM unavailable (PAP-0010). β is identified within-country over time but does not preclude unmeasured time-varying confounding.
- **Composition:** counterfactual is on aggregate CRS disbursement only. The input-vs-outcome typology question is unanswered.
- **Single-cycle marginal projection** (one HCI cycle ≈ 5 yr); no inter-temporal discounting; not a steady-state forecast.
- **Plug-in CI propagation** on β only (does not propagate joint regressor covariance) — chosen as the honest match for the static-FE inference base; a full Monte Carlo would overreach.
- **LAYS identity holds EYS constant**, isolating the learning-quality channel; sensitivity to EYS across p10/p50/p90 is reported in-table.
- **Implementation quality / political economy / absorptive capacity** caveats per manuscript §2.

