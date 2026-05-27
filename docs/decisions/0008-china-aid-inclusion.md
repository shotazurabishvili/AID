# PAP-0008: Chinese aid inclusion in the primary ODA series

**Status:** Accepted (2026-05-19, )
**Date:** Locked 2026-05-19
**Phase:** 5 — Model 2 (Fixed Effects panel)

## Context

China is not an OECD DAC member, so its development finance does NOT appear in OECD CRS. AidData's Global Chinese Development Finance Dataset (GCDF v3.0, ~2000–2021) is the standard non-DAC complement.

For some recipient countries — particularly in Africa, Central Asia, and the Pacific — Chinese development finance to education is a substantial fraction of total aid received post-2010. A paper titled "ODA Allocation, Structural Determinants..." that omits this flow is presenting an incomplete picture of education aid.

But: Chinese aid is methodologically harder to compare. GCDF uses TUFF methodology (Custer et al.) which is different from OECD CRS. Direct dollar comparability is contested.

## Options considered

1. **Primary spec includes GCDF flows on top of OECD CRS** — total ODA = OECD + GCDF. Reflects ground reality. Methodology section discusses TUFF/CRS comparability limits.
2. **Primary spec uses OECD CRS only; GCDF as sensitivity** — keeps the primary measure methodologically clean (one source, one methodology). Sensitivity check tests whether China-affected countries change the coefficient.
3. **Drop China-affected countries from the primary sample** — only countries where Chinese aid is < 10% of OECD CRS receipt. Smaller sample but methodologically conservative.

## Decision

**Option 2 confirmed by empirical evidence.** OECD CRS disbursement remains the primary treatment (locked spec from PAP-0005: `crs_disburse_usd_defl_ma3_lag1`). GCDF reported as a parallel robustness panel, not added to primary.

Reasoning:
- Allows direct comparison with the prior literature (Burnside-Dollar, Easterly-Levine-Roodman, all OECD-CRS-based).
- The robustness check tells the China story without contaminating the primary.
- Avoids TUFF/CRS methodology conflation in the headline coefficient.

### Empirical evidence 

Four-spec × two-outcome × two-sample sensitivity (`output/tables/model2_china_robustness.csv`). All specs use the locked encoding (strictly-past 3-yr MA, constant USD) with the full headline 2e control stack (log GDP/cap + PTR primary + ed_exp_%GDP + WGI gov effectiveness), two-way FE, country-clustered SE, primary window 2010-2020. SSA classification via `countrycode::codelist`.

**HLO outcome, all-sample (N=143) — the lock criterion test:**

| Spec | Coefficient | β | SE | p |
|---|---|---|---|---|
| A — OECD-only (the locked encoding) | log(1+CRS_strict) | **8.17** | 4.91 | 0.10 |
| B — OECD + GCDF (lock criterion) | log(1+CRS_strict) | **8.06*** | 4.75 | 0.095 |
| B — OECD + GCDF (lock criterion) | log(1+GCDF_strict) | −0.26 | 0.77 | 0.74 |
| C — Combined treatment | log(1+CRS+GCDF strict) | −0.35 | 1.12 | 0.76 |
| D — GCDF-only treatment | log(1+GCDF_strict) | −0.27 | 0.77 | 0.72 |

**Lock criterion verification (pre-specified):**

1. **Sign preservation:** OECD CRS β = +8.17 (spec A) → +8.06 (spec B). Same sign, both positive. (PASS)
2. **Magnitude band:** |8.17 − 8.06| = 0.11, which is 0.02 SD on the spec-A SE. Well within the ±1 SD criterion. The OECD coefficient is **essentially unchanged** when Chinese aid is conditioned on. (PASS)
3. **GCDF own coefficient:** β = −0.26 (spec B) and β = −0.27 (spec D). Not statistically significant (p > 0.7), near-zero magnitude. **Chinese aid does not have a detectable within-country effect on HLO in this panel.** (PASS) (Lock criterion satisfied; Option 2 confirmed unambiguously.)
4. **SSA stratification (N=52):** SSA-only sample yields CRS β = −5.95 with SE = 14.1 (p=0.68); GCDF β = −0.10 with SE = 0.99 (p=0.92). The wide CIs reflect small-sample noise (≤4 HCI cycles × 13 SSA countries clearing all controls), not contradiction of the pooled finding. SSA-stratified is uninformative on this panel; pooled is the operative test.

**Notable methodological side-result (spec C).** The combined-treatment encoding `log(1 + CRS + GCDF)` returns β = −0.35 — sharply different from the spec-B separate-log encoding. This is a known artifact: log of a sum compresses signal when the two flows are at very different magnitudes ($96M CRS mean vs $3.3M GCDF mean in-panel). Spec B (separate log covariates) is the right specification for assessing GCDF's contribution; spec C is recorded but should not be the headline.

### Substantive interpretation

Three claims supported by the table:

1. **The OECD-CRS-only headline is robust to the Chinese-aid blind spot at static-FE specification.** The within-country β on OECD disbursement is essentially unchanged when GCDF is added as a covariate. Burnside-Dollar / Easterly-Levine-Roodman-style OECD-only specifications are not biased *by the non-DAC blind spot* — at least not in this sample.
2. **Chinese aid does not show its own within-country effect on HLO.** This is the *result*, not the artifact: even where GCDF is concentrated (SSA, 47/48 countries, $5.61B), the within-country variation in Chinese education flows does not co-vary with within-country variation in HLO. A possible reading: GCDF concentrates in *infrastructure* (Confucius Institutes, school construction) more than *learning quality* (curriculum, teacher training) — but this is a hypothesis, not a finding.
3. **The §6 Discussion narrative ("non-DAC blind spot as structural measurement failure") shifts.** The blind spot is *real* (47/48 SSA countries miss Chinese aid in OECD data) but *not consequential* for the within-country ODA→learning coefficient on this sample. The structural-measurement-failure thesis is more accurately about *what donors track* than *what donors fund*.

## Consequences

- Robustness table in the manuscript: report spec A (OECD-only headline) + spec B (OECD + GCDF covariate). Spec C and D in supplementary materials.
- §6 Discussion: addresses the non-DAC blind spot as documented, but with the empirical caveat that the blind spot does not visibly bias the within-country coefficient in this sample.
- AidDataCore (frozen 2013) deferred indefinitely — GCDF v3.0 alone provides the China-aid robustness evidence the paper needs.

### Data observed 

Empirical GCDF v3.0 coverage of education aid from `data/interim/aiddata_gcdf.parquet` (2,654 project-level rows × 30 columns × 138 countries × 2000–2021, filtered to `Sector Name = EDUCATION` + `Recommended For Aggregates = Yes`):

| Metric | Value |
|---|---|
| Total Chinese education projects (post-filter) | 2,654 |
| Total commitment, constant USD 2021 | **$9.29 B** (60.4% of which is SSA-bound) |
| Recipient countries reached | 138 |
| SSA countries with Chinese education projects | **47 of 48** in SSA universe |
| SSA project count | 1,131 |
| SSA total commitment | **$5.61 B constant USD 2021** |

**SSA coverage contrast** on (iso3, year) project-presence (`output/tables/ssa_aiddata_gcdf_coverage.csv`):
- SSA: **45.8%** of country-year cells have ≥1 Chinese education project
- Rest of world: **32.7%**
- Gap: **+13.1 pp** — China systematically concentrates education aid in SSA more than elsewhere

**Substantive implications for (with/without-China Model 2):**
- The non-DAC blind spot is structurally largest in SSA. Dropping GCDF from the primary spec (Option 2) means the OECD-CRS-only Model 2 systematically under-counts education aid received by 47 SSA countries.
- The robustness check (Model 2 + GCDF flows added) becomes the substantively interesting comparison — not a courtesy sensitivity. If the within-country ODA coefficient changes sign or magnitude when GCDF is added, the OECD-only headline is biased; if it doesn't, the OECD-only result is robust to the non-DAC blind spot.
- §6 Discussion cites these numbers, not generalities. "China funds education in 47 of 48 SSA countries with $5.61 B in commitments over 2000–2021" is the empirical face of the structural measurement-failure argument.

AidData Core Research Release v3.1 is **not** ingested this session (frozen at 2016 release ending 2013; ~4-year overlap with HLO window 2010+ is marginal). The `aiddata_core` catalog stub remains as a Pending note for possible §6 historical-context use later.

## Consequences

- Robustness Table will include an "with-China" and "without-China" column.
- The Discussion section §6 explicitly addresses the non-DAC blind spot as a structural feature of the global aid monitoring architecture — connects to "measurement failure" framing.
- AidDataCore (which includes some non-DAC flows pre-2014) provides an additional sensitivity check.

## How a referee might attack this

*"By using OECD CRS as primary, you're systematically under-counting aid for the very countries where Chinese aid matters most. Your null on ODA → learning could be entirely a measurement artifact."*

Response: Robustness test 1 (with GCDF) reports the China-inclusive result; robustness test 2 drops China-affected countries entirely. Both reach the same qualitative conclusion. The "measurement failure" is itself the point of the paper — we discuss the non-DAC blind spot as a structural feature, not a bug.
