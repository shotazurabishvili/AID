#### Pass 1 — Granger causality test (panel)

**Direction:** `log_crs_strict → hlo_hlo_score` (one-cycle lag).
**Test:** Dumitrescu-Hurlin (2012) Z-tilde panel Granger (`plm::pgrangertest`).
**Caveat:** T_eff ≤ 4 HCI cycles per country in primary window — interpret as exploratory pre-test, not a definitive reverse-causality verdict.

|test                            |direction                      | order_lag| statistic| p_value| n_countries|note                                                           |
|:-------------------------------|:------------------------------|---------:|---------:|-------:|-----------:|:--------------------------------------------------------------|
|Dumitrescu-Hurlin panel Granger |log_crs_strict → hlo_hlo_score |         1|        NA|      NA|         133|pgrangertest failed; see stdout / consider lag-order reduction |

**Reading:** rejection of the null "log(CRS) does not Granger-cause HLO" provides exploratory support for the treatment-side direction of the within-country association. Non-rejection at small T is uninformative rather than evidence of no causality.
