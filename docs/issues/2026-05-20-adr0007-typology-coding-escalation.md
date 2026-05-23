# ADR-0007 typology coding — escalation request for external review

**Date:** 2026-05-20
**Project:** AID — Education ODA & Learning Outcomes paper (target: *World Development*, IF 5.4)
**Author:** Shota Zurabishvili (with research assistant Claude Opus 4.7)
**Phase:** Phase 7 Session 01 of 14
**Status:** Halted; lock decision deferred pending expert input

---

## 1. Context

The paper studies whether OECD DAC ODA disbursements to education predict country-level learning outcomes. Models 1–3 are complete:

- **Model 1** (cross-sectional OLS, country means): β_ODA on log(1+CRS_disburse) is **−1.36, p=0.584** — null/negative pattern, aid concentrates in poor-outcome countries.
- **Model 2** (within-country FE panel, locked encoding: strictly-past 3-yr MA + WGI PC1): β_ODA = **+11.14, p=0.048** — positive within-country effect; sign-flip from Model 1 + ~8× magnitude.
- **Model 3** (2-level country RE + year FE): β = **−1.32**, collapses onto Model 1; country-level **ICC = 91.2%** unconditional; manual Hausman **p=0.0098** rejects RE in favor of FE.

The Models 1–3 chain establishes that ODA predicts learning *within country* but is masked by between-country confounding. **Model 4 (Phase 7) is a one-way ANOVA on intervention typology**: do countries that received different *kinds* of education ODA show different learning gains? This requires classifying every CRS project into one of four mutually exclusive buckets, per the brief.

ADR-0007 (the coding-method choice) is the only Pending ADR in the project. **It is blocking the entire Phase 7 ANOVA.** We attempted to lock it this session; the empirical agreement between the two pre-committed classifiers came in too low to lock by our pre-specified criteria, so we are escalating.

---

## 2. The methodological question

How do we assign **537,586 CRS education-sector projects** (sectors 110/111/112/113/114, years 1995–2024) to one of four mutually exclusive intervention buckets — **infrastructure / teacher training / curriculum / budget support** — in a way that:

1. Is **defensible** to a hostile *World Development* referee (the brief explicitly flags this risk: "coding decision must be defended").
2. Is **reproducible** (deterministic; committed to git before any ANOVA is run).
3. Doesn't **gerrymander** the typology categories to favor a particular ANOVA result.
4. Meets the brief's pre-specified inter-method agreement check (**≥85%** between two independent methods).

---

## 3. Brief's specification (immutable)

From `docs/brief.md` lines 109–117:

```
### Model 4 — One-Way ANOVA: Intervention Typology
**Groups (mutually exclusive — coding decision must be defended):**
- Infrastructure aid
- Teacher training aid
- Curriculum / materials aid
- Budget support

**DV:** Learning outcome gains over 5-year window
**Required:** Levene's test (if violated → Welch's ANOVA), Tukey HSD post-hoc,
              η² and Cohen's d effect sizes for ALL pairwise comparisons
```

Phase 1's ADR-0007 (`docs/decisions/0007-oecd-crs-intervention-typology.md`) committed to a hybrid approach:
- **Option 1 (primary):** rule-based keyword regex on project text
- **Option 2 (robustness):** LLM-assisted classification
- **Option 3 (escalation):** hand-coded stratified sample → TF-IDF logistic regression
- **Lock criterion:** if rule-based vs LLM agreement is **<85%**, escalate to Option 3

The brief's four-bucket scheme is the binding commitment. We cannot drop categories or invent new ones without writing a defense.

---

## 4. OECD CRS data structure

`data/interim/oecd_crs.parquet`: 537,586 rows × 38 columns, filtered to education sectors 110–114.

**Available classification inputs per project:**

| Field | NA rate | Avg length | Notes |
|---|---|---|---|
| `purpose_code` | 0% | 5-digit integer | OECD's official taxonomy |
| `purpose_name` | 0% | — | OECD-published code label |
| `project_title` | 6.4% | 53 chars | Short title |
| `short_description` | 1.4% | 49 chars | One-line summary |
| `long_description` | 18.8% | 341 chars | Full description (max 3999 chars) |
| `keywords` | 98.6% | — | Effectively unusable (sparse) |

**20 unique 5-digit purpose codes within education** (Phase 1 ingest preserves all):

| Code | Name | N projects | % | Bucket assigned (LLM) | Code type |
|---|---|---|---|---|---|
| 11420 | Higher education | 150,130 | 27.9% | budget_support | **level** |
| 11220 | Primary education | 78,229 | 14.6% | budget_support | **level** |
| 11110 | Education policy and admin mgmt | 68,369 | 12.7% | budget_support | **intervention** |
| 11120 | Education facilities and training | 63,673 | 11.8% | infrastructure | **intervention** |
| 11330 | Vocational training | 55,130 | 10.3% | budget_support | **level** |
| 11230 | Basic life skills for youth/adults | 28,071 | 5.2% | budget_support | **programmatic** |
| 11320 | Secondary education | 24,703 | 4.6% | budget_support | **level** |
| 11130 | Teacher training | 22,996 | 4.3% | teacher_training | **intervention** |
| 11430 | Advanced technical and managerial training | 19,520 | 3.6% | budget_support | **level** |
| 11240 | Early childhood education | 14,469 | 2.7% | budget_support | **level** |
| 11182 | Educational research | 4,700 | 0.9% | curriculum | **intervention** |
| 11231 | Basic life skills for youth | 4,147 | 0.8% | budget_support | **programmatic** |
| 11250 | School feeding | 1,636 | 0.3% | infrastructure | **intervention** |
| 11260 | Lower secondary education | 1,323 | 0.2% | budget_support | **level** |
| 11232 | Primary education facilities | 276 | 0.05% | infrastructure | **intervention** |
| 111–114 | 3-digit parents (level unspecified) | 214 | 0.04% | budget_support | **parent** |

**Structural problem:** Only ~4 of the 20 codes (11110, 11120, 11130, 11182) cleanly map to intervention types. The other 16 are **education-LEVEL codes** (primary, secondary, higher) that don't specify intervention type. **75%+ of projects sit under level codes that the LLM classifier defaults to "budget_support" by construction.**

---

## 5. Classifier 1 — rule-based (committed before running)

**File:** `R/lib/typology/keyword_rules_v1.csv` (in git).

Regex/keyword matching on `paste(project_title, short_description, long_description)` (lower-cased). **Priority cascade** (first match wins): teacher_training → curriculum → infrastructure → budget_support → unclassified.

**Priority rationale** (committed to ADR before running): more-specific-over-less-specific.

**Patterns per bucket (abbreviated; full list in CSV):**

- **teacher_training** (priority 1): `teacher[s]?`, `training of educator`, `professional development`, `in[- ]service training`, `pre[- ]service training`, `pedagogical`, `teacher quality`, `teacher effectiveness`, `headmaster training`, `principal training`
- **curriculum** (priority 2): `curricul(um|ar)`, `syllabus`, `learning standards`, `learning assessment`, `educational assessment`, `EMIS`, `learning content`, `pedagogy reform`, `educational research`
- **infrastructure** (priority 3): `construct(ion|ing)?`, `build(ing|ings)?`, `classroom`, `school building`, `facility|facilities`, `infrastructure`, `equipment`, `textbook[s]?`, `materials suppl(ied|ies)`, `school feeding`, `school meal`, `rehabilitation`, `furniture`, `desk[s]?`
- **budget_support** (priority 4, catch-all): `policy|policies`, `budget support`, `sector[- ]wide`, `SWAp`, `general education`, `administrative management`, `education administration`, `recurrent expenditure`, `salary support`, `ministry of education`, `governance of education`

---

## 6. Classifier 2 — LLM-via-purpose-code (committed before running)

**File:** `R/lib/typology/purpose_code_to_bucket_v1.csv` (in git, classifier-stamped).

A 20-row mapping of each OECD 5-digit purpose code to one of the four buckets, produced by Claude (opus-4-7, 1M context) based on each code's OECD-published description.

**Honesty framing in the ADR:** this is "LLM-classifier-on-OECD-taxonomy," not "LLM-classifier-on-per-project-text." A per-project LLM (537K API calls) was rejected on cost/reproducibility grounds. The LLM's analytical contribution is the **20-code → 4-bucket mapping**; each project inherits its purpose code's bucket deterministically.

**Mappings** (rationale in CSV `rationale` column):

| Bucket | Codes assigned |
|---|---|
| teacher_training | 11130 (Teacher training) |
| curriculum | 11182 (Educational research) |
| infrastructure | 11120, 11232 (facilities), 11250 (school feeding) |
| budget_support | All other 16 codes (level codes + policy/admin + 3-digit parents) |

By construction, LLM-via-purpose-code produces 0% unclassified. The bucket distribution is heavily skewed: **82.6% budget_support, 12.2% infrastructure, 4.3% teacher_training, 0.9% curriculum.**

---

## 7. Lock criteria (pre-specified, binding)

From `~/.claude/plans/plan-next-step-greedy-beacon.md` (committed before R/61 ran):

1. **Raw agreement ≥ 85% AND Cohen's κ ≥ 0.70** on joint-classified subsample → lock Option 1 primary, Option 2 robustness.
2. Either fails → **escalate to Option 3 (hand-coding)**. Do NOT tune the CSVs to push agreement up.
3. **Rule-based unclassified > 30%** → investigate; document. Don't silently extend keywords.

**No-tuning rule:** CSVs hardcoded in one pass; R/61 runs once; result accepted or escalated. No iteration on keyword list to maximize agreement.

---

## 8. Empirical results (this session)

### 8a. Bucket distributions (project-weighted, all 537,586 projects)

**Rule-based:**

| bucket | n | % |
|---|---|---|
| unclassified | 406,849 | 75.7% |
| infrastructure | 63,946 | 11.9% |
| teacher_training | 40,320 | 7.5% |
| budget_support | 22,494 | 4.2% |
| curriculum | 3,977 | 0.7% |

**LLM-via-purpose-code:**

| bucket | n | % |
|---|---|---|
| budget_support | 444,305 | 82.6% |
| infrastructure | 65,585 | 12.2% |
| teacher_training | 22,996 | 4.3% |
| curriculum | 4,700 | 0.9% |

### 8b. Lock criteria — all three FAIL

| Criterion | Value | Decision |
|---|---|---|
| Raw agreement ≥ 85% | **39.04%** | FAIL |
| Cohen's κ ≥ 0.70 | **0.190** (slight agreement on Landis-Koch scale) | FAIL |
| Unclassified < 30% | **75.68%** | FAIL |

### 8c. Confusion matrix (rule-based × LLM-via-purpose-code, joint-classified subsample N=130,737)

Rows: rule-based label. Columns: LLM-via-purpose-code label.

| | teacher_training | curriculum | infrastructure | budget_support |
|---|---|---|---|---|
| **teacher_training** | 7,732 | 306 | 4,801 | 27,481 |
| **curriculum** | 83 | 564 | 236 | 3,094 |
| **infrastructure** | 873 | 454 | 21,823 | 40,796 |
| **budget_support** | 419 | 257 | 900 | 20,918 |

**Reading the matrix:**

- **Rule says infrastructure → LLM says budget_support** (40,796 projects, 64% of infrastructure-rule cases). These are projects whose text mentions construction/facilities/equipment but whose purpose code is a level-of-education code (most likely 11420 Higher Education with project text about "research facility," "campus construction," or "equipment for university").
- **Rule says teacher_training → LLM says budget_support** (27,481, 68% of teacher-rule cases). Same pattern: text mentions teachers/training, but the purpose code is a level code (likely 11220 Primary, 11320 Secondary, or 11420 Higher) that the LLM mapped to budget_support.
- **Rule says budget_support → LLM says budget_support** (20,918, 93% of budget-rule cases). The cleanly aligned policy/admin projects.
- **Rule says curriculum** is so sparse (4K projects total) that little signal is recoverable from this method on curriculum content.

The disagreement is **structural**, not noise. The two classifiers literally look at different information layers and can't agree at 85% by construction.

### 8d. Country-level dominant bucket (rule-based, 2010–2020 window, USD-disbursement-defl weighted)

| dominant_bucket | n_countries | % of 151 universe |
|---|---|---|
| infrastructure | 93 | 61.6% |
| budget_support | 29 | 19.2% |
| teacher_training | 28 | 18.5% |
| curriculum | 1 | 0.7% |

Caveat: this is based on the 24% of projects that *aren't* unclassified by rule-based. So it's biased toward projects with infrastructure-rich text (large projects with detailed descriptions). The country-level dominant assignment may be more stable than the per-project agreement suggests — but it's built on a non-random subsample.

---

## 9. Why agreement is low — diagnostic interpretation

The brief's four-bucket scheme assumes **intervention-type** information per project. OECD's actual taxonomy is mostly **education-level** information:

- 4 of 20 codes carry intervention-type signal (11110 policy, 11120 facilities, 11130 teacher training, 11182 research)
- 16 of 20 codes carry education-level or programmatic signal (primary, secondary, higher, vocational, early childhood, life skills)

The 4 intervention-type codes account for ~30% of projects (159,738 / 537,586); the 16 level codes account for ~70% (377,634 / 537,586).

**Mechanism of disagreement:**

1. **LLM-via-purpose-code** can only access the code; for the 70% of projects under level codes, it must default to a catch-all → "budget_support."
2. **Rule-based** can access project text; for projects whose descriptions mention construction/teachers/curriculum, it recovers intervention-type signal *regardless* of the level code. E.g., a Higher Education (11420) project titled "Construction of engineering labs at University of X" → rule-based: **infrastructure**; LLM-via-purpose-code: **budget_support**.

This isn't a bug — it's the honest reflection of what's knowable from each information layer. The two methods are NOT designed to agree; they answer two different questions:

- Rule-based: "what does this project's text say it does?"
- LLM-via-purpose-code: "what does this project's bureaucratic category say it falls under?"

The brief's "≥85% agreement" criterion implicitly assumed both methods were noisy estimates of the same latent intervention-type label. They aren't.

---

## 10. What's at stake downstream

**Model 4 ANOVA** depends on this typology. The DV (per brief): "Learning outcome gains over 5-year window." The IV: country's dominant intervention type. The test: do countries grouped by intervention type show different ΔHLO?

If classification is unreliable, the ANOVA is meaningless — Tukey HSD comparisons can't separate true intervention effects from classification noise.

**Downstream impact on the paper:**
- Section 4.5 (Model 4 results) currently a stub
- Section 6 Discussion needs the intervention-type story to substantiate the paper's structural-determinants thesis
- The brief commits the paper to Model 4 as one of the "five empirical models" framing

**It is methodologically defensible to abandon Model 4** if the typology can't be made rigorous — the paper still has Models 1, 2, 3, 5 (counterfactual sim), and the AI-readiness extension. But that's an author-judgment call.

---

## 11. Options under consideration

### Option A — Hand-coded stratified sample (the formal Option 3 escalation)

1. Stratify CRS by purpose_code (proportional to project count).
2. Hand-classify a sample of ~1,000 projects using project_title + short_description + long_description.
3. Train a TF-IDF + logistic regression (or fine-tune a small classifier) on the labeled set.
4. Apply the trained classifier to all 537K projects.
5. Re-compute agreement vs the rule-based classifier; if better than rule-vs-LLM agreement, lock Option 3 as primary.

**Pros:**
- Most rigorous; produces actual ground truth on a sample
- Defensible against any referee
- Can quote inter-coder reliability if two coders independently label the sample

**Cons:**
- ~3 hours of careful labeling effort (or longer for two-coder reliability)
- TF-IDF classifiers can be brittle if hand-coding sample doesn't span purpose codes evenly
- Requires committing to specific labeling guidelines BEFORE seeing data (else gerrymandering risk)

**Expert input needed on Option A:**
- Sample size: is 1,000 enough? Should it be 2,000 or 3,000?
- Stratification: proportional to purpose code, or oversample under-represented codes?
- Two-coder reliability target: Cohen's κ ≥ 0.70 between coders? Higher?
- Classifier choice: TF-IDF + logistic regression (per ADR), or fine-tuned BERT, or zero-shot LLM with structured prompt?

### Option B — Reframe the ANOVA grouping along OECD's natural taxonomy

Drop the brief's four-bucket scheme. Group by purpose-code clusters that the data actually supports:
- **Group 1: Intervention-specific** — codes 11110, 11120, 11130, 11182
- **Group 2: Level-of-education programs** — codes 11220, 11240, 11260, 11320, 11420, 11430 (and others)
- **Group 3: Programmatic** — codes 11230, 11231 (basic life skills)
- **Group 4: Operational** — 11250 (school feeding)

Or some other defensible cut.

**Pros:**
- Honest reflection of the data
- No classifier disagreement (purpose codes are unambiguous)
- ANOVA groups are well-defined

**Cons:**
- Abandons the brief's pre-committed scheme — requires writing a defense paragraph
- Loses the "interventional theory" framing the brief built around (the four-bucket scheme was tied to a substantive learning-theory story: "which type of capital matters?")
- Could be seen as making the spec post-hoc to match the data

**Expert input needed on Option B:**
- Is dropping the brief's four-bucket scheme defensible at this stage, given that the brief explicitly committed to it?
- Are there better natural groupings of OECD codes for an aid-effectiveness ANOVA?
- Does this approach have precedent in published aid-effectiveness papers?

### Option C — Accept the disagreement; report both classifiers separately

Lock ADR-0007 as "two classifiers, two answers, transparent disagreement." Model 4 ANOVA Session 02 runs the ANOVA twice:
- Under rule-based classifier (5 groups including unclassified, or 4 dropping unclassified)
- Under LLM-via-purpose-code (heavily skewed to budget_support)

Report both results side-by-side as a "Model 4 (a) and Model 4 (b)" robustness exercise. The classifier-choice sensitivity becomes part of the §6 Discussion.

**Pros:**
- No new labeling work
- Methodologically honest about the disagreement
- Adds a 6th convergent-evidence strand if both ANOVAs give consistent qualitative findings

**Cons:**
- Two ANOVAs with disagreeing classifiers is a weak headline — referees may say "you couldn't even agree with yourself on what the categories are"
- Conditioned on the brief's "≥85% agreement" rule, this looks like moving the goalposts
- Heavy "unclassified" share (76% rule-based) is a coverage problem the manuscript would have to defend

**Expert input needed on Option C:**
- Is reporting two disagreeing classifiers defensible for a top-tier journal?
- Does it count as compliance with the brief's "≥85%" rule, or as abandonment?

### Option D — Drop Model 4 from the paper

Abandon the intervention-typology ANOVA entirely. Justify on the grounds that OECD CRS taxonomy doesn't support the brief's four-bucket scheme without unreliable classification effort. Lean harder on Models 1–3 (already strong) and Model 5 (counterfactual sim, Phase 8).

**Pros:**
- Honest; removes a weak link from the paper
- Models 1–3 + 5 are already a complete five-empirical-models story if Model 5 is treated as the "fifth" rather than Model 4
- Avoids gerrymandering risk entirely

**Cons:**
- Loses the intervention-effect story for §6 Discussion
- Brief committed to ANOVA in Phase 7; abandoning is a meaningful scope change
- A reviewer who reads the brief alongside the paper might ask why Model 4 was dropped

**Expert input needed on Option D:**
- At this stage of the project (Phase 7 of 14), is dropping a planned model phase a reasonable scope correction or a red flag?
- Are there minimum-viable alternatives that preserve some intervention-effect analysis without the ANOVA?

---

## 12. Specific questions for the expert

In order of urgency:

1. **Is the brief's four-bucket scheme salvageable on OECD CRS data alone?** Or does it require external taxonomic mapping (e.g., AidData's TUFF coding scheme, or a non-OECD typology like UIS's IPEDS-equivalent)?

2. **If Option A (hand-coding) is pursued, what's the minimum credible labeling design?** Sample size, stratification, inter-coder reliability target, classifier choice.

3. **Is Option B (reframe along OECD taxonomy) compatible with the brief's commitment, or does it require formally amending the brief?**

4. **Have similar studies in the aid-effectiveness literature solved this problem?** Specifically: Asongu (2019), Yogo (2017), Burnside-Dollar, Easterly-Levine-Roodman — any of these face the same OECD-taxonomy mismatch on Model-4-like specifications? What did they do?

5. **Is the per-project agreement metric (Cohen's κ on the full 537K rows) the right validity check?** Or should we be looking at country-level agreement on dominant-bucket assignment — which appears more stable than per-project (61.6% infrastructure-dominant under rule-based; would need to compute under LLM too)?

6. **What's the strongest defense against a referee who asks "you classified 537K projects via regex on 49-char descriptions, that's not a serious typology"?** Is hand-coding (Option A) the only defense, or are there published precedents for keyword-based aid typologies?

---

## 13. Files to consult

### Code

- `R/61_typology_coding.R` — the classification driver (this session)
- `R/lib/typology/keyword_rules_v1.csv` — committed rule set
- `R/lib/typology/purpose_code_to_bucket_v1.csv` — committed code-to-bucket mapping

### Outputs from this session

- `output/tables/typology_method_agreement.{csv,md}` — agreement statistics + confusion matrix
- `output/tables/typology_country_dominant.csv` — per-country dominant bucket
- `output/tables/typology_country_shares.csv` — per-country share of each bucket
- `output/tables/typology_bucket_distribution.csv` — country dominant-bucket distribution
- `data/interim/oecd_crs_typology.parquet` — project-level with both bucket labels (537,586 × 14)
- `data/interim/typology_country_year.parquet` — country-year × bucket × USD panel (29,387 rows)

### Documentation

- `docs/brief.md` — original research design (lines 109–117 for Model 4 spec)
- `docs/decisions/0007-oecd-crs-intervention-typology.md` — ADR (currently Pending)
- `docs/methodology.md` §3.10 — current methodological stance
- `docs/findings.md` §§5.1–5.4 — Models 1–3 results (Phase 5–6)
- `docs/plan.md` row 7 — phase-level deliverable for Model 4

### Source data

- `data/interim/oecd_crs.parquet` — 537,586 projects × 38 cols (full CRS extract, education sectors only)

---

## 14. What's NOT in scope for the expert

- Models 1–3 results (locked; published in findings.md §§5.1–5.4)
- ADR-0005 (commit vs disburse; locked Phase 5 Session 03)
- ADR-0008 (China aid; locked Phase 5 Session 04)
- ADR-0009 (WGI operationalization; locked Phase 5 Session 05)
- ADR-0010 (System GMM identification; locked Phase 5 Session 02)
- §6 manuscript framing (separate author-judgment task; deferred to Phase 11)

The expert's domain is **just Model 4 typology** — what coding strategy survives a *World Development* refereeing on this CRS data structure.

---

## 15. Author's preferred direction (tentative)

If the expert has no strong opinion, my current lean is **Option A (hand-coded stratified sample → trained classifier)** as the rigorous path, with **Option B (reframe along OECD taxonomy)** as a defensible fallback if the expert says the brief's scheme is unsalvageable. I want to avoid Options C (report two disagreeing classifiers) and D (drop Model 4) unless the expert says one of them is clearly the right call given the field's standards.

A 1-page memo with a recommendation + 2-3 lines of justification would be sufficient.
