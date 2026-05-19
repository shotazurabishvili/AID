**Table 5. Model 2 -Identification triangulation (ADR-0010 evidence).**

Coefficient on `log(1 + CRS_disburse_defl_MA3)` across estimators. All on cycle-indexed HCI panel.

|Estimator                                    |      β|    SE|      p|   N| Hansen p| AR(1) p| AR(2) p|status             |
|:--------------------------------------------|------:|-----:|------:|---:|--------:|-------:|-------:|:------------------|
|Static FE Model 2 (Session 14, full 2e)      | 10.950|  3.60| 0.0030| 143|       NA|      NA|      NA|estimated          |
|Static FE Model 2 (Session 14, +conf/COV)    | 10.830|  4.03| 0.0090| 143|       NA|      NA|      NA|estimated          |
|(A) Pooled OLS w/ lagged DV -MIN spec        |  0.000|  0.00| 0.8705| 437|       NA|      NA|      NA|estimated          |
|(A) Pooled OLS w/ lagged DV -FULL spec       |  0.000|  0.00| 0.9616| 143|       NA|      NA|      NA|estimated          |
|(B) Within FE w/ lagged DV (LSDV) -MIN spec  |  0.000|  0.00| 0.9422| 437|       NA|      NA|      NA|estimated          |
|(B) Within FE w/ lagged DV (LSDV) -FULL spec |  0.000|  0.00| 0.8656| 143|       NA|      NA|      NA|estimated          |
|(C) Difference GMM -MIN spec                 |  0.601| 10.55| 0.9546|   2|   0.4979|  0.1045|      NA|estimated          |
|(C) Difference GMM -FULL spec                |     NA|    NA|     NA|  NA|       NA|      NA|      NA|summary_failed     |
|(D) System GMM -MIN spec                     | -0.923|  0.81| 0.2544|   5|   0.0221|  0.0969|      NA|estimated          |
|(D) System GMM -FULL spec                    |     NA|    NA|     NA|  NA|       NA|      NA|      NA|failed_to_estimate |

**Reading:** Bond (2002) consistency bound -true persistence parameter ρ lies between (A) Pooled OLS w/ lagged DV (upward biased by ignored heterogeneity) and (B) Within FE w/ lagged DV (downward biased by Nickell). If GMM β on log(1+CRS) sits within the Bond range for the ODA effect, GMM is credible.

**Diagnostic targets per Roodman (2009):** Hansen p ∈ (0.10, 0.99); AR(1) p < 0.05; AR(2) p > 0.10; instrument count < N.

GMM identification: 
- Hansen p < 0.10 = instrument over-identification rejected (GMM unreliable)
- AR(2) p < 0.10 = second-order autocorrelation in differences (lagged-DV instruments invalid)
- NA on AR(2) = test could not compute (typically T_eff too small)

Cycle index used because HCI cycle calendar-year spacing is non-uniform (2010→2017 = 7yr; 2017→2018 = 1yr); calendar-year lag operators produce all-NA results on the cycle-restricted panel.
