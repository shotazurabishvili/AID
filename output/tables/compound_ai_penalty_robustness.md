# Compounding AI penalty — robustness panel

Three alternative specifications for the 'double-excluded' country set.  `jaccard_vs_headline` is the intersection-over-union of each set with the headline median-split set — closer to 1 means more stable.

|specification                                            | n_double_excluded| jaccard_vs_headline|
|:--------------------------------------------------------|-----------------:|-------------------:|
|Median-split (HEADLINE, N=132)                           |                47|               1.000|
|Tercile-split (N=132; double-excluded = low/low tercile) |                25|               0.532|
|HCI-2018-only median-split (N=126)                       |                46|               0.938|

## Country sets per specification

**Median-split (headline):** `AFG; AGO; BDI; BFA; BWA; CAF; CMR; COD; COG; COM; GAB; GIN; GMB; GTM; GUY; HND; HTI; IRQ; KHM; KIR; LAO; LBR; LSO; MDG; MHL; MLI; MMR; MOZ; MRT; MWI; NAM; NER; PNG; SDN; SLB; SLE; SSD; SWZ; TCD; TGO; TJK; TLS; TUV; UGA; VUT; YEM; ZWE`

**Tercile-split (low/low):** `AFG; AGO; BDI; CAF; COD; COG; COM; GIN; GMB; HTI; LBR; MDG; MHL; MLI; MOZ; MWI; NER; PNG; SDN; SLB; SLE; SSD; SWZ; TCD; YEM`

**HCI-2018-only median-split:** `AFG; AGO; BDI; BFA; BWA; CMR; COD; COG; COM; GAB; GIN; GMB; GTM; GUY; HND; HTI; IRQ; KHM; KIR; LAO; LBR; LSO; MDG; MHL; MLI; MMR; MOZ; MRT; MWI; NAM; NER; NIC; PNG; SDN; SLB; SLE; SSD; SWZ; TCD; TGO; TLS; TUV; UGA; VUT; YEM; ZWE`
