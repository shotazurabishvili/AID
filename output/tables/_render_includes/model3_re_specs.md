#### Model 3 — 2-level country RE + year FE (locked encoding)

Random intercept by country; year FE; locked treatment (`crs_disburse_usd_defl_ma3_lag1`) + WGI PC1. Estimator: `lme4::lmer` with REML=FALSE (ML, for Hausman comparability). Stars: ***p<0.01, **p<0.05, *p<0.1.

##### HLO outcome

|spec |   N| beta_oda| se_oda|  p_oda|signif | sigma_country| sigma_resid|is_singular |
|:----|---:|--------:|------:|------:|:------|-------------:|-----------:|:-----------|
|3a   | 447|  -5.1885|  1.659| 0.0019|***    |         47.53|       15.59|FALSE       |
|3b   | 443|  -1.8000|  1.601| 0.2615|       |         38.44|       15.64|FALSE       |
|3c   | 206|  -0.5847|  2.371| 0.8056|       |         37.28|       18.63|FALSE       |
|3d   | 173|  -2.7624|  2.605| 0.2909|       |         36.77|       19.47|FALSE       |
|3e   | 173|  -1.3224|  2.679| 0.6225|       |         37.05|       18.95|FALSE       |

##### LAYS outcome

|spec |   N| beta_oda| se_oda|  p_oda|signif | sigma_country| sigma_resid|is_singular |
|:----|---:|--------:|------:|------:|:------|-------------:|-----------:|:-----------|
|3a   | 443|  -0.0892| 0.0466| 0.0566|*      |         2.106|      0.3494|FALSE       |
|3b   | 439|  -0.0735| 0.0444| 0.0985|*      |         1.388|      0.3701|FALSE       |
|3c   | 204|   0.0318| 0.0672| 0.6367|       |         1.214|      0.4129|FALSE       |
|3d   | 171|   0.0003| 0.0734| 0.9965|       |         1.197|      0.4107|FALSE       |
|3e   | 171|   0.0641| 0.0739| 0.3874|       |         1.214|      0.3790|FALSE       |

