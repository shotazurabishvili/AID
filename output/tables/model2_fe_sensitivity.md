# Model 2 FE — Treatment-encoding sensitivity

Within-country two-way FE (iso3 + year). Country-clustered SE. Controls: log(GDP/cap), PTR primary, ed_exp_%GDP, WGI gov effectiveness. Primary window 2010-2020.

Treatment enters as `log(1 + x)`. Stars: ***p<0.01, **p<0.05, *p<0.1.

## HLO outcome

|family   |usd_basis |transform |   N|   beta|    se| p_value|signif | r2_within|
|:--------|:---------|:---------|---:|------:|-----:|-------:|:------|---------:|
|commit   |current   |raw       | 143| -0.358| 2.953|  0.9038|       |    0.1165|
|commit   |constant  |raw       | 143| -0.184| 2.932|  0.9503|       |    0.1164|
|commit   |current   |lag1      | 143|  3.230| 1.939|  0.1009|       |    0.1301|
|commit   |constant  |lag1      | 143|  2.990| 1.885|  0.1178|       |    0.1286|
|commit   |current   |ma3       | 143|  9.881| 4.213|  0.0223|**     |    0.1574|
|commit   |constant  |ma3       | 143|  9.278| 4.274|  0.0339|**     |    0.1535|
|commit   |current   |ma3_lag1  | 143| 12.750| 4.643|  0.0079|***    |    0.1816|
|commit   |constant  |ma3_lag1  | 143| 11.867| 4.526|  0.0111|**     |    0.1750|
|disburse |current   |raw       | 143|  8.273| 2.851|  0.0052|***    |    0.1465|
|disburse |constant  |raw       | 143|  8.202| 2.696|  0.0035|***    |    0.1472|
|disburse |current   |lag1      | 143|  2.644| 2.471|  0.2888|       |    0.1210|
|disburse |constant  |lag1      | 143|  2.471| 2.428|  0.3128|       |    0.1205|
|disburse |current   |ma3       | 143| 11.442| 3.943|  0.0052|***    |    0.1560|
|disburse |constant  |ma3       | 143| 10.947| 3.595|  0.0034|***    |    0.1541|
|disburse |current   |ma3_lag1  | 143|  8.537| 5.209|  0.1065|       |    0.1407|
|disburse |constant  |ma3_lag1  | 143|  8.170| 4.912|  0.1015|       |    0.1396|

## LAYS outcome

|family   |usd_basis |transform |   N|  beta|    se| p_value|signif | r2_within|
|:--------|:---------|:---------|---:|-----:|-----:|-------:|:------|---------:|
|commit   |current   |raw       | 139| 0.081| 0.059|  0.1739|       |    0.2260|
|commit   |constant  |raw       | 139| 0.075| 0.058|  0.1966|       |    0.2238|
|commit   |current   |lag1      | 139| 0.029| 0.048|  0.5459|       |    0.2113|
|commit   |constant  |lag1      | 139| 0.026| 0.046|  0.5735|       |    0.2107|
|commit   |current   |ma3       | 139| 0.255| 0.081|  0.0026|***    |    0.2870|
|commit   |constant  |ma3       | 139| 0.237| 0.080|  0.0045|***    |    0.2783|
|commit   |current   |ma3_lag1  | 139| 0.202| 0.082|  0.0167|**     |    0.2548|
|commit   |constant  |ma3_lag1  | 139| 0.190| 0.079|  0.0189|**     |    0.2508|
|disburse |current   |raw       | 139| 0.089| 0.090|  0.3278|       |    0.2175|
|disburse |constant  |raw       | 139| 0.084| 0.086|  0.3349|       |    0.2169|
|disburse |current   |lag1      | 139| 0.066| 0.081|  0.4203|       |    0.2160|
|disburse |constant  |lag1      | 139| 0.060| 0.080|  0.4554|       |    0.2149|
|disburse |current   |ma3       | 139| 0.162| 0.091|  0.0814|*      |    0.2291|
|disburse |constant  |ma3       | 139| 0.148| 0.087|  0.0958|*      |    0.2264|
|disburse |current   |ma3_lag1  | 139| 0.110| 0.125|  0.3849|       |    0.2192|
|disburse |constant  |ma3_lag1  | 139| 0.104| 0.121|  0.3940|       |    0.2185|

