**Table 4. Model 1 vs Model 2 — ODA coefficient contrast (manuscript headline).**

Effect of `log(1 + CRS_disburse_defl_sum)` (Model 1, country means) and `log(1 + CRS_disburse_defl_MA3)` (Model 2, panel) on HLO score.

|Model                                       |   N| beta_ODA|    SE| p_value|SE_type           |Sample                                                               |
|:-------------------------------------------|---:|--------:|-----:|-------:|:-----------------|:--------------------------------------------------------------------|
|Model 1 (cross-sectional OLS, full spec 1e) | 120|   -1.361| 2.477|  0.5837|HC robust         |Country-level means; one row per country                             |
|Model 2 (within-country FE, full spec 2e)   | 143|   10.947| 3.595|  0.0034|Country-clustered |Country-year panel; HLO non-NA cells; singleton-FE countries dropped |
|Model 2 (full + conflict + COVID, spec 2g)  | 143|   10.833| 4.034|  0.0094|Country-clustered |Same + non-NA on conflict/COVID                                      |

**Reading:** Model 1's coefficient is the cross-sectional association between country-mean CRS disbursement and country-mean HLO. Model 2's coefficient is the within-country effect — does within-country variation in CRS over time predict within-country variation in HLO?

Stars: ***p<0.01, **p<0.05, *p<0.1.
Model 1 spec: HLO_i = β0 + β1 log(1+CRS)_i + β2 log(GDP/cap)_i + β3 PTR_i + β4 EdExp_i + β5 WGI_i + ε_i.
Model 2 spec: HLO_it = β1 log(1+CRS_MA3)_it + β2 log(GDP/cap)_it + β3 PTR_it + β4 EdExp_it + β5 WGI_it + α_i + λ_t + ε_it.
Treatment differs: Model 1 uses country-mean of annual CRS disbursement; Model 2 uses 3-yr trailing MA of annual values (per ADR-0005 working preference).
