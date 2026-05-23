# Model 5 — Baseline-quartile sensitivity

Same shock × β scenario grid as the headline table, but applied at the Q1 / median / Q3 of baseline CRS across the Model 2 estimation sample. ΔLAYS uses the median implied-EYS only (the headline table shows the full p10/p50/p90 fan).

|baseline             |shock              |scenario                         | baseline_usd_M| delta_log_crs| delta_hlo_pts| delta_lays_p50|
|:--------------------|:------------------|:--------------------------------|--------------:|-------------:|-------------:|--------------:|
|Q1 (25th pctile)     |+10% (low-shock)   |Worst case (β lower 95% CI)      |          23.75|        0.0916|         0.029|         0.0005|
|Q1 (25th pctile)     |+10% (low-shock)   |Expected case (β point estimate) |          23.75|        0.0916|         1.020|         0.0189|
|Q1 (25th pctile)     |+10% (low-shock)   |Best case (β upper 95% CI)       |          23.75|        0.0916|         2.011|         0.0372|
|Q1 (25th pctile)     |+50% (mid-shock)   |Worst case (β lower 95% CI)      |          23.75|        0.3919|         0.126|         0.0023|
|Q1 (25th pctile)     |+50% (mid-shock)   |Expected case (β point estimate) |          23.75|        0.3919|         4.364|         0.0808|
|Q1 (25th pctile)     |+50% (mid-shock)   |Best case (β upper 95% CI)       |          23.75|        0.3919|         8.603|         0.1593|
|Q1 (25th pctile)     |+100% (high-shock) |Worst case (β lower 95% CI)      |          23.75|        0.6727|         0.216|         0.0040|
|Q1 (25th pctile)     |+100% (high-shock) |Expected case (β point estimate) |          23.75|        0.6727|         7.492|         0.1387|
|Q1 (25th pctile)     |+100% (high-shock) |Best case (β upper 95% CI)       |          23.75|        0.6727|        14.767|         0.2734|
|Median (50th pctile) |+10% (low-shock)   |Worst case (β lower 95% CI)      |          59.69|        0.0938|         0.030|         0.0006|
|Median (50th pctile) |+10% (low-shock)   |Expected case (β point estimate) |          59.69|        0.0938|         1.045|         0.0193|
|Median (50th pctile) |+10% (low-shock)   |Best case (β upper 95% CI)       |          59.69|        0.0938|         2.059|         0.0381|
|Median (50th pctile) |+50% (mid-shock)   |Worst case (β lower 95% CI)      |          59.69|        0.4000|         0.128|         0.0024|
|Median (50th pctile) |+50% (mid-shock)   |Expected case (β point estimate) |          59.69|        0.4000|         4.454|         0.0824|
|Median (50th pctile) |+50% (mid-shock)   |Best case (β upper 95% CI)       |          59.69|        0.4000|         8.780|         0.1625|
|Median (50th pctile) |+100% (high-shock) |Worst case (β lower 95% CI)      |          59.69|        0.6849|         0.220|         0.0041|
|Median (50th pctile) |+100% (high-shock) |Expected case (β point estimate) |          59.69|        0.6849|         7.627|         0.1412|
|Median (50th pctile) |+100% (high-shock) |Best case (β upper 95% CI)       |          59.69|        0.6849|        15.034|         0.2783|
|Q3 (75th pctile)     |+10% (low-shock)   |Worst case (β lower 95% CI)      |         123.75|        0.0946|         0.030|         0.0006|
|Q3 (75th pctile)     |+10% (low-shock)   |Expected case (β point estimate) |         123.75|        0.0946|         1.053|         0.0195|
|Q3 (75th pctile)     |+10% (low-shock)   |Best case (β upper 95% CI)       |         123.75|        0.0946|         2.076|         0.0384|
|Q3 (75th pctile)     |+50% (mid-shock)   |Worst case (β lower 95% CI)      |         123.75|        0.4028|         0.129|         0.0024|
|Q3 (75th pctile)     |+50% (mid-shock)   |Expected case (β point estimate) |         123.75|        0.4028|         4.485|         0.0830|
|Q3 (75th pctile)     |+50% (mid-shock)   |Best case (β upper 95% CI)       |         123.75|        0.4028|         8.842|         0.1637|
|Q3 (75th pctile)     |+100% (high-shock) |Worst case (β lower 95% CI)      |         123.75|        0.6891|         0.221|         0.0041|
|Q3 (75th pctile)     |+100% (high-shock) |Expected case (β point estimate) |         123.75|        0.6891|         7.674|         0.1421|
|Q3 (75th pctile)     |+100% (high-shock) |Best case (β upper 95% CI)       |         123.75|        0.6891|        15.127|         0.2800|

**Reading:** marginal ΔHLO from a given *percentage* shock is roughly invariant across baseline-CRS quartiles in log-space (this is a structural property of log1p, not a substantive finding) — at very low baselines the absolute $-shock for a fixed-% shock is small but the log-difference is large, and vice versa. The cross-quartile contrast becomes substantive only when expressed in absolute dollars rather than percentages.

