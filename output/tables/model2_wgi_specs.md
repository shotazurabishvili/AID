# Model 2 FE — WGI operationalization sensitivity

Within-country two-way FE (iso3 + year). Country-clustered SE. Treatment: `log(1 + crs_disburse_usd_defl_ma3_lag1)` (). Base controls: log(GDP/cap) + PTR primary + ed_exp_%GDP. WGI varies across specs A-D. Primary window 2010-2020.

PC1 variance share: 0.764. All six PC1 loadings positive after sign-flip: TRUE.

## ODA coefficient across WGI representations

### HLO outcome

|spec_id |spec_label                             |   N| beta_oda| se_oda|  p_oda|signif | r2_within|
|:-------|:--------------------------------------|---:|--------:|------:|------:|:------|---------:|
|A       |Single composite (the baseline) | 143|    8.170|  4.912| 0.1015|       |    0.1396|
|B       |All six WGI aggregates                 | 143|   10.331|  5.211| 0.0520|*      |    0.2536|
|C       |PCA-collapsed (PC1, scale=TRUE)        | 143|   11.136|  5.518| 0.0481|**     |    0.1255|
|D       |No WGI control                         | 143|    8.754|  5.322| 0.1052|       |    0.0540|

### LAYS outcome

|spec_id |spec_label                             |   N| beta_oda| se_oda|  p_oda|signif | r2_within|
|:-------|:--------------------------------------|---:|--------:|------:|------:|:------|---------:|
|A       |Single composite (the baseline) | 139|    0.104|  0.121| 0.3940|       |    0.2185|
|B       |All six WGI aggregates                 | 139|    0.158|  0.106| 0.1439|       |    0.4609|
|C       |PCA-collapsed (PC1, scale=TRUE)        | 139|    0.179|  0.145| 0.2205|       |    0.1743|
|D       |No WGI control                         | 139|    0.139|  0.159| 0.3855|       |    0.0880|

## Per-dimension WGI coefficients in spec B (HLO)

|dimension  |    beta|    se| p_value|signif |
|:----------|-------:|-----:|-------:|:------|
|wgi_va_est | -26.245| 16.44|  0.1156|       |
|wgi_pv_est |   2.314| 13.00|  0.8593|       |
|wgi_ge_est |   9.910| 25.95|  0.7039|       |
|wgi_rq_est |  44.927| 30.76|  0.1494|       |
|wgi_rl_est |  -9.414| 26.56|  0.7243|       |
|wgi_cc_est |  32.742| 21.36|  0.1305|       |

