**Table 5. Three-way Model 1 / Model 2 / Model 3 contrast — manuscript Table 5 candidate.**

Three estimators on the same locked-encoding HLO outcome, primary window 2010-2020.

|Model                                                           |Identification                                                                      |   N| beta_ODA|    SE| p_value|
|:---------------------------------------------------------------|:-----------------------------------------------------------------------------------|---:|--------:|-----:|-------:|
|Model 1 OLS — full spec 1e (cross-sectional)                    |Between-country variation only (country-mean averaging eliminates within variation) | 120|   -1.361| 2.477|  0.5837|
|Model 2 v2 FE — full spec 2e (within-country, locked)           |Within-country variation only (country FE eliminates between variation)             | 143|   11.136| 5.518|  0.0481|
|Model 3 RE — full spec 3e (random intercepts + year FE, locked) |Weighted combination of between + within (RE with country random intercepts)        | 173|   -1.322| 2.679|  0.6225|

**Hausman test (manual univariate Cameron-Trivedi, β_ODA):** H=6.669, df=1, p=0.0098. Reject RE; prefer FE.

**ICC at country level (unconditional):** 91.2% — share of HLO variance attributable to between-country differences.

**Reading:** Model 1's cross-sectional β is essentially zero (the between-country signal is captured by the controls). Model 2's within-country β is positive and crosses conventional significance under the locked encoding. Model 3's RE β is a weighted average of these two — its position between OLS and FE reflects the relative weight the variance-component structure places on between- vs within-country information.
