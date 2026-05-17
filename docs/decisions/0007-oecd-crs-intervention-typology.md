# ADR-0007: OECD CRS intervention typology coding

**Status:** Pending — locked in Phase 7 (Model 4 ANOVA on intervention typology)
**Date:** —
**Phase:** 7 — Model 4

## Context

The brief's Model 4 specification:

> *"One-Way ANOVA: Intervention Typology — Groups (mutually exclusive — coding decision must be defended): Infrastructure aid / Teacher training aid / Curriculum / materials aid / Budget support"*

OECD CRS purpose codes (5-digit) like 11110, 11220, 11230, 11240, 11320, 11420 tag broad sub-sectors but **do not map cleanly** to these four buckets. The actual typology has to be inferred from project descriptions (the `short_description` and `long_description` text fields in CRS), which means:

- The mapping is a methodological choice
- A mistaken or biased coding could drive a spurious ANOVA result
- The brief explicitly warns: *"Groups (mutually exclusive — coding decision must be defended)"*

## Options considered

1. **Rule-based keyword coding** — regex patterns on description text. Transparent, deterministic, defensible. Slow to develop and may miss edge cases.
2. **LLM-assisted classification with rule-based audit** — use an LLM to classify each project description into one of the 4 buckets; sample-check 10% manually + run keyword sanity checks. Faster, may catch nuance keywords miss.
3. **Hand-coding of a stratified sample** — manually code 1000 projects across the 4 buckets, then train a simple classifier (logistic regression on TF-IDF) on that as the production coder. Highest rigor but expensive in time.

## Decision (Pending)

To be locked in Phase 7. Working plan:
- Phase 1 Session 05 ingests the full CRS extract with description text retained — no classification attempted there.
- Phase 7 implements rule-based keyword coding as the primary (Option 1), with LLM-assisted classification as the robustness comparator (Option 2).
- Agreement rate between the two methods is reported. If agreement < 85%, escalate to hand-coding (Option 3).

## Consequences

- Model 4 results depend on this coding. Bias in the coding → bias in the ANOVA → bias in the Phase 8 counterfactual.
- The full coding logic (regex patterns, keyword lists) gets deposited with the reproducibility package.
- The methodology section explicitly reports inter-method agreement as evidence of robustness.

## How a referee might attack this

*"Your typology is post-hoc — you decided which projects count as 'teacher training' after seeing the data."*

Response: The 4 categories are pre-specified in the research design (the brief, fixed before any ingestion). The keyword rules are committed to git BEFORE the ANOVA is run and not modified after the result is seen. Full inter-coder reliability stats reported.

*"LLM classification is a black box, not science."*

Response: LLM is the *secondary* method; the primary method is fully transparent rule-based keyword coding. We report agreement rates and openly publish all rules + LLM prompts.
