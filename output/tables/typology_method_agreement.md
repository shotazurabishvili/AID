# Typology classifier agreement (PAP-0007 lock evidence)

**Joint-classified subsample:** 130737 projects (24.32% of 537586 total CRS rows)
**Raw agreement:** 0.3904 (39.04%)
**Cohen's κ:** 0.1902
**Rule-based unclassified:** 75.68%

## Lock criteria (binding, pre-specified)

- Raw agreement ≥ 85%: **FAIL**
- Cohen's κ ≥ 0.70:    **FAIL**
- Unclassified < 30%:  **FAIL**

**Decision: ESCALATE to Option 3 (hand-coding)**

## Confusion matrix (rows: rule-based, cols: LLM-via-purpose-code)

|                 | teacher_training| curriculum| infrastructure| budget_support|
|:----------------|----------------:|----------:|--------------:|--------------:|
|teacher_training |             7732|        306|           4801|          27481|
|curriculum       |               83|        564|            236|           3094|
|infrastructure   |              873|        454|          21823|          40796|
|budget_support   |              419|        257|            900|          20918|

## Bucket distributions

### Rule-based
|bucket_rule      |      n|   pct|
|:----------------|------:|-----:|
|unclassified     | 406849| 75.68|
|infrastructure   |  63946| 11.90|
|teacher_training |  40320|  7.50|
|budget_support   |  22494|  4.18|
|curriculum       |   3977|  0.74|

### LLM-via-purpose-code
|bucket_llm       |      n|   pct|
|:----------------|------:|-----:|
|budget_support   | 444305| 82.65|
|infrastructure   |  65585| 12.20|
|teacher_training |  22996|  4.28|
|curriculum       |   4700|  0.87|
