#### Pass 1 — HLO measure sensitivity (ADR-0004 principal robustness)

Refit of Model 2 spec 2e (locked encoding: log_crs_strict + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_pc1; two-way FE country + year; country-clustered SE) with the AAP-2018 harmonized learning outcome (`aap_hlo_aap`) substituted for the WB primary measure.

**Two AAP-2018 specifications** to disentangle measure-choice vs sample-window effects:

- **AAP full coverage** — N = 69 rows, 62 countries, year range 2005-2015 (5 AAP cycles).
- **AAP overlap window (year ≥ 2010)** — N = 36 rows, 42 countries (2 AAP cycles in primary window).

|spec                                   |outcome       |   N|    beta|    se| p_value|
|:--------------------------------------|:-------------|---:|-------:|-----:|-------:|
|Primary (WB HD.HCI.HLOS, 2010-2020)    |hlo_hlo_score | 143|  11.136| 5.518|      NA|
|AAP-2018 full coverage (1995-2015)     |aap_hlo_aap   |  69| -16.673| 5.965|  0.0094|
|AAP-2018 overlap window (year >= 2010) |aap_hlo_aap   |  36|  -3.941| 8.682|  0.6556|

**Sign agreement (primary vs AAP full):** ✗ DIFFERENT SIGN
**Within-CI agreement (full):** ✗ outside-CI
**Sign agreement (primary vs AAP overlap-window):** ✗ DIFFERENT SIGN

**Reading per methodology §3.4:** "the within-country coefficient must be the same sign and within-CI magnitude across the primary and AAP-2018 specifications for the headline claim to stand."  The two AAP variants test whether any sign disagreement is driven by *measure choice* (AAP harmonization vs WB HCI) or by *sample-window composition* (AAP's pre-2010 epoch vs primary's 2010-2020). If full-AAP and overlap-AAP agree → measure-effect. If they disagree → window-effect.
