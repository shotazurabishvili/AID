# B1 — Wild cluster bootstrap on the headline + AAP variants

**Added in response to peer review; not part of the pre-specified set.**

Seed: 20260525. Intended: `fwildclusterboot::boottest` with B = 9999 Rademacher weights, clustered on iso3. Actual: fwildclusterboot is no longer available in the project's CRAN snapshot. The first fallback (`clubSandwich::vcovCR` type CR2 on the fixest object) returned a Satterthwaite df of 1, because clubSandwich cannot read fixest's absorbed FE — the CR2 inference was degenerate and not reportable. The second fallback (this report) refits the locked spec as `lm` with explicit `factor(iso3) + factor(year)` dummies, then applies `sandwich::vcovBS` with `type = "wild"` (Rademacher cluster wild bootstrap), R = 9999, cluster = iso3. This is a wild cluster bootstrap on a different implementation path — what fwildclusterboot computes natively, computed via sandwich/lm instead.

## Result

Columns: `beta` and `se_fe_asymp` are the fixest two-way-FE estimate; `se_lm_cluster` is the lm-equivalent country-clustered HC1 SE (sanity check against the FE asymptotic SE); `se_boot` and `p_boot` are the wild cluster bootstrap.

|spec                                       |   N| n_clusters|    beta| se_fe_asymp| p_fe_asymp| asymp_ci_lo| asymp_ci_hi| se_lm_cluster| p_lm_cluster| se_boot| p_boot| boot_ci_lo| boot_ci_hi|
|:------------------------------------------|---:|----------:|-------:|-----------:|----------:|-----------:|-----------:|-------------:|------------:|-------:|------:|----------:|----------:|
|Headline (WB HLO, primary window, PC1 gov) | 143|         61|  11.117|       5.514|     0.0483|       0.309|      21.924|         7.398|       0.1371|   5.343| 0.0409|      0.644|     21.589|
|AAP-2018 full coverage                     |  69|         28| -16.673|       5.965|     0.0094|     -28.364|      -4.982|         7.990|       0.0445|   5.548| 0.0050|    -27.547|     -5.799|
|AAP-2018 overlap (year >= 2010)            |  36|         18|  -3.941|       8.682|     0.6556|     -20.958|      13.076|        13.497|       0.7753|   7.724| 0.6192|    -19.081|     11.199|

## Reading

If the bootstrap p-value diverges materially from the asymptotic country-clustered p — particularly if the bootstrap p crosses 0.10 while the asymptotic p sits at 0.048 — the asymptotic inference understates the true uncertainty and the headline does not pass the small-cluster robustness check. With ~127 nominal HLO-observing countries reducing to 61 clusters identified in the within-country FE specification (only countries with ≥ 2 HLO observations contribute identifying variation), the small-cluster correction is potentially binding.
