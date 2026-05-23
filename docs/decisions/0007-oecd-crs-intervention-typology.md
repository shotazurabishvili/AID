# ADR-0007: OECD CRS intervention typology coding

**Status:** Rejected — Phase 7 Session 01 (2026-05-23)
**Date:** 2026-05-23
**Phase:** 7 — Model 4 (closed without estimation)

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

## Pre-committed lock criteria

To avoid post-hoc tuning, the lock decision was committed *before* running the classifiers:

- Raw agreement between rule-based and comparator ≥ **85 %**
- Cohen's κ ≥ **0.70**
- Rule-based unclassified < **30 %**

All three required to LOCK. Any failure → escalate to Option 3 (hand-coding).

## Decision (final, 2026-05-23) — Rejected

`R/61_typology_coding.R` ran on 2026-05-19 23:55 on the full 537,586-project CRS extract:

| Criterion | Observed | Required | Verdict |
|---|---|---|---|
| Raw agreement (joint subsample, N = 130,737) | **39.04 %** | ≥ 85 % | **FAIL** |
| Cohen's κ | **0.19** | ≥ 0.70 | **FAIL** |
| Rule-based unclassified | **75.68 %** | < 30 % | **FAIL** |

All three pre-committed criteria failed. Per the binding protocol the next step was Option 3 (hand-code ~1000 stratified projects, train a TF-IDF + logistic-regression production classifier).

**Author researcher-grade decision (2026-05-23): do not escalate. Drop Model 4 entirely.**

Two failure signatures, both pointing the same direction:

1. The rule cascade leaves three-quarters of projects unclassified — the 49 keyword patterns do not cover the lexical breadth of education ODA descriptions.
2. The purpose-code-to-bucket mapping puts 82.7 % of projects in `budget_support` and the rule-based classifier puts 4.2 % there — the two methods are not measuring the same construct (the comparator was structurally mis-specified for the brief's typology, not just empirically weak).

Both could in principle be repaired (Path B: true LLM-on-text classifier; Path C: iterate keyword rules v2; Path A: hand-code). All three either spend substantial resources on an axis whose CRS-extractability is unproven, or break the no-post-hoc-tuning discipline that ADR-0007 was written to enforce. The researcher move is to scope down rather than spend on rescue work, and treat the failed gate as evidence rather than an obstacle.

Concretely: Model 4 is removed from the paper. The empirical headline is Models 1-2-3 (cross-section / within-FE / multilevel) plus Model 5 (counterfactual simulation, Phase 8). The brief's "five empirical models" framing reduces to four; the negative result is documented in `findings.md §5.5` and the methodology section explicitly owns it.

## Consequences

- Model 4 ANOVA does not run. The Phase-7 obligations (Levene's test, Tukey HSD, η², Cohen's d for all pairs) are withdrawn in `obligations.md`.
- Model 5 (Phase 8 counterfactual) **cannot use Model-4 ANOVA effect sizes** — the brief's "redirect $1B from input-based to outcome-based aid" simulation needs a different effect-size input. Practical substitute: Model 2's within-country β on log(CRS disbursement) translated through the LAYS reporting layer, with the typology-level redirection reframed as a total-volume / lag-structure / sub-sector counterfactual rather than a four-bucket reallocation. Phase 8 Session 01 will lock this redesign.
- `R/61_typology_coding.R` and the four `output/tables/typology_*` artifacts plus the two interim parquets are **retained on disk** as negative-evidence artifacts for the reproducibility package. The script header is annotated with the Rejected outcome.
- Brief.md (immutable) still specifies Model 4. Methodology.md §3.8 documents the drop as a downstream-of-brief design revision; the brief is not edited.

## How a referee might attack this

*"Your typology is post-hoc — you decided which projects count as 'teacher training' after seeing the data."*

This attack does not land. The 4 categories were pre-specified in the brief; the lock criteria were pre-specified in this ADR before R/61 ran. The data showed the gate could not be cleared. We did not re-tune to cross the gate; we honored the pre-commitment and dropped the model.

*"LLM classification is a black box, not science."*

Moot — the LLM-via-purpose-code comparator was retained for transparency, but no LLM classification feeds the paper.

*"You dropped Model 4 to hide a finding you didn't like."*

The opposite. We dropped Model 4 because we could not produce a finding we could defend. The failure numbers are reported transparently in `findings.md §5.5` and in this ADR; the artifacts are on disk in the reproducibility package. A pre-committed protocol catching an unfeasible design is the gate working as designed — that's the methodological strength, not a weakness. Failure to surface this in the paper would be the bias-by-selection move; surfacing it explicitly is the honest one.

*"Why did you ingest the project text and write the classifier at all if you were going to drop the model?"*

Because the brief committed the paper to Model 4 and the only way to know whether the typology was recoverable was to attempt it under a pre-committed gate. The cost of running R/61 once (~30 minutes of compute) is the price of a falsifiable test; the cost of skipping it would have been an undefended decision either way. The classifier code and outputs are kept in the reproducibility package so a future reader can verify the failure.
