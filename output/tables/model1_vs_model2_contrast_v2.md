**Table 4 (v2). Model 1 vs Model 2 — ODA coefficient contrast (manuscript headline, LOCKED ENCODING).**

Effect of `log(1 + CRS_disburse_defl_sum)` (Model 1, country means) and `log(1 + CRS_disburse_defl_ma3_lag1)` (Model 2 v2, panel) on HLO score.

|Model                                              |   N| beta_ODA|    SE| p_value|SE_type           |Sample                                                               |
|:--------------------------------------------------|---:|--------:|-----:|-------:|:-----------------|:--------------------------------------------------------------------|
|Model 1 (cross-sectional OLS, full spec 1e)        | 120|   -1.361| 2.477|  0.5837|HC robust         |Country-level means; one row per country                             |
|Model 2 v2 (within-country FE, locked encoding 2e) | 143|   11.136| 5.518|  0.0481|Country-clustered |Country-year panel; HLO non-NA cells; singleton-FE countries dropped |
|Model 2 v2 (locked + conflict + COVID, 2g)         | 143|    9.613| 5.438|  0.0822|Country-clustered |Same + non-NA on conflict/COVID                                      |

**Reading:** Model 1's coefficient is the cross-sectional association between country-mean CRS disbursement and country-mean HLO. Model 2's coefficient is the within-country effect — does within-country variation in CRS over time predict within-country variation in HLO? Sign-flip + ~8× magnitude under within-FE is the manuscript's central empirical claim.

Stars: ***p<0.01, **p<0.05, *p<0.1.
Model 1 spec: HLO_i = β0 + β1 log(1+CRS)_i + β2 log(GDP/cap)_i + β3 PTR_i + β4 EdExp_i + β5 WGI_GE_i + ε_i.
Model 2 v2 spec: HLO_it = β1 log(1+CRS_ma3_lag1)_it + β2 log(GDP/cap)_it + β3 PTR_it + β4 EdExp_it + β5 WGI_PC1_it + α_i + λ_t + ε_it.
Treatment differs: Model 1 uses country-mean of annual CRS disbursement; Model 2 uses 3-yr strictly-past MA (mean of t-3,t-2,t-1) per the locked encoding. WGI differs: Model 1 uses single Government Effectiveness (prior-literature comparability); Model 2 uses PC1 of six WGI dimensions per the locked encoding (76.4% variance; Langbein-Knack engagement).
