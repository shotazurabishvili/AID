# Model 2 FE — Chinese aid robustness (ADR-0008 lock)

Within-country two-way FE (iso3 + year). Country-clustered SE. Controls: log(GDP/cap), PTR primary, ed_exp_%GDP, WGI gov effectiveness. Primary window 2010-2020. Treatment columns enter as `log(1 + x)`; all use Session-03 lock encoding (strictly-past 3-yr MA, constant USD).

Stars: ***p<0.01, **p<0.05, *p<0.1.

## HLO outcome — ALL sample

|spec_id |spec_label                        |coef_label             |   N|   beta|    se| p_value|signif |
|:-------|:---------------------------------|:----------------------|---:|------:|-----:|-------:|:------|
|A       |OECD-only (Session-03 lock)       |log(1+CRS_strict)      | 143|  8.170| 4.912|  0.1015|       |
|B       |OECD + GCDF (lock criterion test) |log(1+CRS_strict)      | 143|  8.065| 4.750|  0.0947|*      |
|B       |OECD + GCDF (lock criterion test) |log(1+GCDF_strict)     | 143| -0.255| 0.765|  0.7404|       |
|C       |Combined OECD+GCDF treatment      |log(1+CRS+GCDF strict) | 143| -0.352| 1.120|  0.7546|       |
|D       |GCDF-only treatment               |log(1+GCDF_strict)     | 143| -0.274| 0.768|  0.7220|       |

## HLO outcome — SSA sample

|spec_id |spec_label                        |coef_label             |  N|   beta|     se| p_value|signif |
|:-------|:---------------------------------|:----------------------|--:|------:|------:|-------:|:------|
|A       |OECD-only (Session-03 lock)       |log(1+CRS_strict)      | 52| -5.951| 14.088|  0.6770|       |
|B       |OECD + GCDF (lock criterion test) |log(1+CRS_strict)      | 52| -5.758| 13.092|  0.6645|       |
|B       |OECD + GCDF (lock criterion test) |log(1+GCDF_strict)     | 52| -0.098|  0.989|  0.9223|       |
|C       |Combined OECD+GCDF treatment      |log(1+CRS+GCDF strict) | 52| -0.604|  1.408|  0.6726|       |
|D       |GCDF-only treatment               |log(1+GCDF_strict)     | 52| -0.130|  1.024|  0.9005|       |

## LAYS outcome — ALL sample

|spec_id |spec_label                        |coef_label             |   N|   beta|    se| p_value|signif |
|:-------|:---------------------------------|:----------------------|---:|------:|-----:|-------:|:------|
|A       |OECD-only (Session-03 lock)       |log(1+CRS_strict)      | 139|  0.104| 0.121|  0.3940|       |
|B       |OECD + GCDF (lock criterion test) |log(1+CRS_strict)      | 139|  0.104| 0.121|  0.3964|       |
|B       |OECD + GCDF (lock criterion test) |log(1+GCDF_strict)     | 139|  0.000| 0.013|  0.9864|       |
|C       |Combined OECD+GCDF treatment      |log(1+CRS+GCDF strict) | 139| -0.001| 0.019|  0.9495|       |
|D       |GCDF-only treatment               |log(1+GCDF_strict)     | 139|  0.000| 0.013|  0.9888|       |

## LAYS outcome — SSA sample

|spec_id |spec_label                        |coef_label             |  N|  beta|    se| p_value|signif |
|:-------|:---------------------------------|:----------------------|--:|-----:|-----:|-------:|:------|
|A       |OECD-only (Session-03 lock)       |log(1+CRS_strict)      | 50| 0.232| 0.474|  0.6302|       |
|B       |OECD + GCDF (lock criterion test) |log(1+CRS_strict)      | 50| 0.180| 0.460|  0.7005|       |
|B       |OECD + GCDF (lock criterion test) |log(1+GCDF_strict)     | 50| 0.013| 0.017|  0.4447|       |
|C       |Combined OECD+GCDF treatment      |log(1+CRS+GCDF strict) | 50| 0.013| 0.024|  0.5999|       |
|D       |GCDF-only treatment               |log(1+GCDF_strict)     | 50| 0.015| 0.017|  0.3980|       |

