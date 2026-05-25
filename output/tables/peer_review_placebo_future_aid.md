# B2 — Placebo / Falsification: future aid predicting current learning

**Added in response to peer review; not part of the pre-specified set.**

Seed: 20260525. Treatment construction: `future_3yr_ma = mean(crs_disburse_usd_defl_sum[t+1, t+2, t+3]) / 3`. log1p applied. Refit of the locked headline spec (PC1 governance, log GDP, PTR primary, ed_exp_%GDP) with future-aid substituted for past-aid (strictly-past 3-yr MA, lag1).

## Result

|spec                                                    |   N|   beta|    se|      p|  ci_lo| ci_hi|
|:-------------------------------------------------------|---:|------:|-----:|------:|------:|-----:|
|Headline (past 3-yr MA, lag1) on full headline sample   | 143| 11.136| 5.518| 0.0481|  0.320| 21.95|
|Headline (past 3-yr MA, lag1) on placebo-overlap sample | 143| 11.136| 5.518| 0.0481|  0.320| 21.95|
|Placebo (future 3-yr MA) on placebo-overlap sample      | 143|  4.616| 5.861| 0.4340| -6.871| 16.10|

## Reading

If the future-aid coefficient on the placebo-overlap sample is similar in magnitude and significance to the past-aid coefficient on the same sample, the directional interpretation of the headline is undermined: past aid does not uniquely predict current learning more than future aid does. If the future-aid coefficient is materially smaller or insignificant relative to past-aid on the same sample, the directional reading survives the falsification.
