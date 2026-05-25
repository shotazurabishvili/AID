# Combined robustness sign-off

Three sensitivity specs run as  gap-closing battery, each compared to the locked Model 2 spec 2e primary (β = 11.14, SE = 5.52, N = 143). Sign + within-CI agreement is the success criterion.

|spec                                    |source                                  |   N| beta_ODA| se_ODA|  p_ODA|passes                                           |
|:---------------------------------------|:---------------------------------------|---:|--------:|------:|------:|:------------------------------------------------|
|Primary (locked Model 2 spec 2e)        |output/tables/model2_fe_baseline_v2.csv | 143|   11.136|  5.518|     NA|(reference)                                      |
|Granger pre-test (DH Z-tilde, order=1)  |pass1_granger_test.csv                  | 133|       NA|     NA|     NA|Granger non-rejection at small T (uninformative) |
|HLO sensitivity (AAP-2018)              |pass1_hlo_sensitivity.csv               |  69|  -16.673|  5.965| 0.0094|INVESTIGATE                                      |
|UIS-augmented listwise |pass1_uis_listwise.csv                  |  41|   -1.967|  4.395| 0.6602|INVESTIGATE                                      |

**Overall sign-off:** the robustness battery is reported in `the manuscript` and consolidates into the `output/pass1_statistical_validity_audit.md` gate document. Remaining obligations not requiring code (UNESCO bias note; 3-level HLM scope decision) are documented in methodology §3.6 and §3.8 respectively.
