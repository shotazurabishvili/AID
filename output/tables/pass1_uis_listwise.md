#  UIS-augmented listwise (PAP-0006 Robustness 1)

Refit of Model 2 spec 2e with `uis_priv_exp_pct_gdp` added to the regressor stack. Listwise-complete subset on the 2010-2020 primary window. Per PAP-0006, this is *Robustness 1* of three originally committed (Robustness 2 = MI, now retired per PAP-0012; Robustness 3 = the primary UIS-dropped spec).

**UIS-augmented listwise N = 41** vs primary N = 143 (~71% sample loss adding UIS).

|spec                                     |   N| beta_ODA| se_ODA| ci_lo_ODA| ci_hi_ODA|  p_ODA| beta_UIS| se_UIS|  p_UIS|
|:----------------------------------------|---:|--------:|------:|---------:|---------:|------:|--------:|------:|------:|
|Primary (UIS dropped, PAP-0006 Option 3) | 143|   11.136|  5.518|    0.3207|    21.951|     NA|       NA|     NA|     NA|
|Robustness 1 (UIS-augmented listwise)    |  41|   -1.967|  4.395|  -10.5812|     6.648| 0.6602|    24.15|  17.37| 0.1825|

**ODA-coefficient sign agreement:** ✗ DIFFERENT SIGN — investigate
**ODA-coefficient within-CI agreement:** ✗ outside-CI — investigate

**Reading per PAP-0006:** if primary, listwise-UIS, and (former) MI-UIS all give the same sign and within-CI magnitude, the result is robust to the UIS-inclusion choice. With MI retired by PAP-0012, the listwise vs primary comparison carries the full robustness burden in that direction.
