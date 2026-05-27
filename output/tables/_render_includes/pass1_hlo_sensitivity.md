#### HLO measure-fragility sensitivity (PAP-0004 principal robustness)

Refit of Model 2 spec 2e on the locked encoding (strictly-past three-year moving average of constant-dollar CRS education disbursements; log GDP per capita; primary pupil-teacher ratio; education expenditure as percent of GDP; WGI PC1 governance composite; two-way country and year fixed effects; country-clustered standard errors) with the Altinok-Angrist-Patrinos (2018) harmonized learning outcome substituted for the World Bank HCI HLOS primary measure.

Two AAP-2018 specifications disentangle measure-choice from sample-window composition:

- **AAP full coverage**: N = 69 rows, 62 countries, year range 2005–2015 (5 AAP cycles).
- **AAP overlap window** (year ≥ 2010): N = 36 rows, 42 countries (2 AAP cycles in primary window).

|specification                          |learning measure | N |    β |  SE  | p     | 95% CI            |
|:--------------------------------------|:----------------|--:|-----:|-----:|------:|:------------------|
|Primary (2010–2020)                    |WB HCI HLOS      |143| 11.14| 5.52 | 0.048 | [ +0.32, +21.95]  |
|AAP-2018 full coverage (1995–2015)     |AAP-2018         | 69|−16.67| 5.97 | 0.009 | [−28.37,  −4.97]  |
|AAP-2018 overlap window (year ≥ 2010)  |AAP-2018         | 36| −3.94| 8.68 | 0.656 | [−20.95, +13.07]  |
|UIS-augmented listwise (PAP-0006 Rob 1)|WB HCI HLOS      | 41| −1.97| 4.40 | 0.660 | [−10.58,  +6.65]  |

The two AAP variants produce different readings. AAP full coverage sign-reverses the headline at conventional precision (β = −16.67, p = 0.009); the AAP overlap window restricted to the matched 2010–2020 country-years returns a non-significant null (β = −3.94, p = 0.66) that itself fails sign-agreement with the primary. If the two AAP rows had agreed in sign and magnitude, the failure would have isolated measure choice; if they had disagreed, it would have isolated sample-window composition. The AAP overlap-window null rules out sample-window composition as the sole driver, and the measure choice itself materially shapes the within-country coefficient.
