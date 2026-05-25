# B3 — SSA heterogeneity: is the headline driven by sub-Saharan Africa?

**Added in response to peer review; not part of the pre-specified set.**

Seed: 20260525. SSA membership: World Bank region from `countrycode::countrycode(iso3, "iso3c", "region23")`. Locked headline spec (PC1 governance, log GDP, PTR primary, ed_exp_%GDP; two-way FE iso3 + year; country-clustered SE) refit on three subsamples.

## Result

|spec                                             | N_obs| N_countries|    beta|     se|      p|  ci_lo| ci_hi|
|:------------------------------------------------|-----:|-----------:|-------:|------:|------:|------:|-----:|
|Headline (full panel, reference)                 |   143|         133|  11.136|  5.518| 0.0481|   0.32| 21.95|
|(i) Excluding SSA                                |    91|          91|   4.709|  4.923| 0.3449|  -4.94| 14.36|
|(ii) SSA only                                    |    52|          42| -12.345| 13.850| 0.3828| -39.49| 14.80|
|(iii) Pooled with log_crs × is_ssa — main effect |   143|         133|  12.715|  6.574| 0.0578|  -0.17| 25.60|
|(iii) Pooled with log_crs × is_ssa — interaction |   143|         133|  -8.773| 11.243| 0.4383| -30.81| 13.26|

## Reading

If the (i) non-SSA β is close to zero or sign-flipped while (ii) SSA-only β is large, the pooled headline is SSA-driven. The (iii) interaction coefficient gives a formal test: a significant interaction confirms differential aid response in SSA vs non-SSA.
