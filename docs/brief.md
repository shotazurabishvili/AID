# PROJECT BRIEF: Education Aid & Learning Outcomes Research Paper
## Continuation Document for Claude Code

---

## WHAT THIS IS

A full academic research paper targeting **World Development (Elsevier)** — impact factor 5.4.  
The paper is a cross-country quantitative analysis of whether international aid to education actually improves learning outcomes.  
The author is a **practitioner** (worked in the sector) building a statistically rigorous academic argument.  
Statistical depth: **Full** — actual regressions, ANOVA, model outputs embedded.

---

## WORKING TITLE

**"Aid Without Learning: A Cross-Country Analysis of ODA Allocation, Structural Determinants, and the Measurement Failure at the Heart of Global Education Finance"**

---

## CORE THESIS

> Official Development Assistance to education predicts enrollment but not learning outcomes, and the structural variables that actually drive learning are systematically ignored by donor allocation models.

This is **falsifiable, citable, and adversarial.** That is intentional.

---

## TARGET JOURNAL

**Primary:** World Development (Elsevier)  
**Backup 1:** International Journal of Educational Development  
**Backup 2:** Economics of Education Review

**Submission requirements to check before final draft:**
- Word count: 9,000–11,000 words + tables + figures
- Reference style: APA 7
- Reproducibility policy: Code + data deposit expected (OSF, GitHub, or Harvard Dataverse)
- Positionality statement: Expected in methodology section

---

## THE CORE PROVOCATION

The global monitoring architecture for education finance measures **inputs, not learning.**  
A child in Nigeria is "in school." A child in Bangladesh "completed primary." Both counted as successes. Neither can read.

**Learning poverty rate:** 57% of 10-year-olds globally cannot read a simple text (World Bank, pre-COVID). Post-COVID, likely worse.  
**The aid flows anyway.** The log frames track enrollment. The donor reports celebrate completion rates.  
**This paper quantifies the gap and its structural causes.**

---

## DATA STACK

All datasets are real, publicly accessible, and must be downloaded and cleaned.

| Dataset | Source | URL / Portal | Key Variables |
|---|---|---|---|
| Harmonized Learning Outcomes (HLO) | World Bank | datatopics.worldbank.org/education | Learning scores by country/year |
| PISA, TIMSS, PIRLS | OECD / IEA | oecd.org/pisa / timss.bc.edu | Harmonized test scores |
| ODA to Education | OECD DAC | stats.oecd.org (CRS database) | Aid flows by sector, recipient, year |
| AidData | AidData / W&M | aiddata.org | Geocoded aid, project-level data |
| EdStats | World Bank | datatopics.worldbank.org/education | Enrollment, expenditure, PTR, teacher salaries |
| World Development Indicators (WDI) | World Bank | databank.worldbank.org/source/world-development-indicators | GDP per capita, GNI, population |
| Worldwide Governance Indicators (WGI) | World Bank | info.worldbank.org/governance/wgi | Political stability, rule of law |
| UNESCO UIS | UNESCO | uis.unesco.org | Private expenditure, out-of-school rates |
| Human Capital Index (HCI) | World Bank | worldbank.org/en/publication/human-capital | Composite outcome variable |
| AI Readiness Index | Oxford Insights | oxfordinsights.com | For compounding AI penalty section |

**Panel target:** ~120 countries, 2000–2022. ~2,600 observations before listwise deletion.

---

## STATISTICAL ARCHITECTURE — FIVE MODELS

### Model 1 — OLS Baseline
```
Learning_Outcome_i = β0 + β1(ODA_Education_i) + β2(GDPpc_i) + β3(PTR_i) + ε
```
Purpose: Establish naive cross-sectional relationship. Baseline to be challenged.

---

### Model 2 — Fixed Effects Panel (PRIMARY MODEL)
```
Learning_it = β(ODA_it) + β(Expenditure_it) + β(Stability_it) + αi + λt + εit
```
- Country fixed effects (αi) + Year fixed effects (λt)
- Tests whether **within-country** increases in aid move learning outcomes
- This is the killer model. ODA coefficient here vs Model 1 is the central finding.
- **Required diagnostics:** Hausman test, Wooldridge test (autocorrelation), Breusch-Pagan (heteroskedasticity), cluster SE at country level, VIF table

---

### Model 3 — Multilevel / Hierarchical Linear Model
```
Level 1: Student outcomes ~ teacher quality, class size
Level 2: School ~ private/public, urban/rural  
Level 3: Country ~ aid intensity, governance, expenditure
```
- Report ICC at each level
- Random intercepts (justify if adding random slopes)
- Check 30/30 rule — minimum units at each level
- Convergence diagnostics required

---

### Model 4 — One-Way ANOVA: Intervention Typology
**Groups (mutually exclusive — coding decision must be defended):**
- Infrastructure aid
- Teacher training aid
- Curriculum / materials aid
- Budget support

**DV:** Learning outcome gains over 5-year window  
**Required:** Levene's test (if violated → Welch's ANOVA), Tukey HSD post-hoc, η² and Cohen's d effect sizes for ALL pairwise comparisons (not just significant ones)

---

### Model 5 — Counterfactual Simulation
- Redirect $1B from input-based to outcome-based programs
- Use effect sizes from Model 4
- Report: best case, worst case, expected case across CI bounds
- Acknowledge limits: implementation quality, political economy, absorptive capacity

---

## ARTICLE STRUCTURE

```
Abstract                                          250 words
1. Introduction — The measurement illusion        ~1,000 words
2. Literature Review                              ~1,500 words
3. Data & Methodology                             ~2,000 words
4. Results
   4.1 Descriptive: Enrollment/learning divergence
   4.2 Models 1 & 2: Aid → Enrollment vs Aid → Learning
   4.3 Model 3: Structural determinants of learning
   4.4 Model 4: ANOVA on intervention typology
   4.5 Model 5: The counterfactual
5. Discussion — Why the system perpetuates itself ~1,500 words
6. Policy Implications                            ~800 words
7. Conclusion                                     ~500 words
References (APA 7)
Appendix A: Full regression tables
Appendix B: Robustness checks
Appendix C: Variable operationalization
```

---

## WHAT MAKES THIS GROUNDBREAKING

1. **First paper to run fixed-effects panel regression on ODA-to-learning linkage across 120 countries post-2015 SDG baseline.** Most prior studies are cross-sectional or single-region.

2. **ANOVA on intervention typology** — the field argues about aid *amounts*. This paper argues about aid *composition* with statistical evidence.

3. **The compounding AI penalty** — novel section quantifying how low-learning countries face double exclusion from AI-augmented labor markets. Constructed variable: Human Capital Index × AI Readiness Index. No prior paper has done this.

4. **Practitioner voice in Discussion** — positionality is a methodological asset, not a weakness. The author has seen the incentive structures from inside.

---

## LITERATURE — MUST CITE AND ENGAGE (NOT JUST LIST)

| Author(s) | Year | Why It Matters |
|---|---|---|
| Hanushek & Woessmann | 2008, 2015 | Foundational framework — learning quality and human capital. Your argument extends this. |
| Burnside & Dollar | 2000 | Aid effectiveness baseline. Your paper is the education-specific version. |
| Easterly, Levine & Roodman | 2004 | Challenged Burnside & Dollar. Know the debate. |
| Glewwe & Muralidharan | 2016 | Most comprehensive review of what works in education in developing countries. |
| Pritchett | 2013 | *The Rebirth of Education* — closest intellectual ancestor. Cannot be ignored. |
| Vegas & Coffin | 2015 | When education expenditure matters. Directly relevant. |
| Altinok, Angrist & Patrinos | 2018 | The HLO dataset methodology. Cite the paper, not just the data. |
| Langbein & Knack | 2010 | WGI aggregation problems. Cite when using WGI. |

---

## SELF-REVIEW PROTOCOL (STATISTICAL LAYER)

Run these before writing. Document results privately. Face every weakness before a reviewer does.

### Causal Identification Checks
- [ ] Verify all causal language is precise (association vs causation)
- [ ] Identify time-varying confounders (conflict, COVID, political transitions)
- [ ] Test for reverse causality: Granger causality test on panel
- [ ] Characterize selection bias from missing-data countries explicitly

### Data Integrity Checks
- [ ] ODA: commitment vs disbursement — choose and justify
- [ ] HLO: cite Altinok et al. harmonization methodology and its critics
- [ ] UNESCO enrollment: flag self-reporting incentive bias
- [ ] WGI: cite Langbein & Knack aggregation critique
- [ ] Private expenditure: document missing data rate, especially SSA
- [ ] Missingness strategy: test MCAR, choose MI or listwise deletion, run sensitivity analysis both ways

### Model Diagnostics Checklist
- [ ] Hausman test (FE vs RE) — report result
- [ ] Year fixed effects included in panel model
- [ ] Breusch-Pagan heteroskedasticity test
- [ ] Wooldridge test for serial autocorrelation
- [ ] Cluster standard errors at country level
- [ ] VIF table — flag any VIF > 10
- [ ] Levene's test before ANOVA
- [ ] ICC at all three multilevel model levels
- [ ] Convergence diagnostics for HLM
- [ ] Effect sizes (η², Cohen's d) for all ANOVA comparisons

---

## SELF-REVIEW PROTOCOL (ARGUMENTATIVE LAYER)

### Three Passes (in order, non-negotiable)

**Pass 1 — Statistical Validity** *(before any writing)*  
Run every diagnostic. Write results in a private document. No paper until this is done.

**Pass 2 — Argumentative Coherence** *(after full draft)*  
Read only: Abstract → Introduction → Discussion → Conclusion. Skip all results sections.  
Does the argument hold without the numbers? If not, the framing is broken.

**Pass 3 — Adversarial Read** *(48 hours after final draft)*  
Read as a skeptical World Development referee who works at the World Bank and has seen practitioners overreach.  
Mark every sentence where you would write: *"The authors claim X but have not demonstrated X."*  
Fix each one or reframe the claim.

---

## POSITIONALITY STATEMENT (DRAFT — REFINE WITH AUTHOR)

> "The author's [X years] working within [specific institutional context] informs the qualitative interpretation of model findings, particularly regarding aid disbursement mechanisms and recipient government reporting incentives that are not captured in administrative datasets."

Place in: Section 3 (Data & Methodology). Not an apology — a methodological asset declaration.

---

## PRESENTATION STANDARDS

### Regression Tables (non-negotiable)
- Every table: N, R², adjusted R², F-statistic, clustered SE, significance stars with explicit legend
- Report: Coefficient + SE + 95% CI (not stars only)
- Table notes explain every variable operationalization

### Figures
- Coefficient plots preferred over raw regression tables for communicating to mixed audiences
- Predicted margins plots for multilevel model (show country-level variance visually)
- Every figure must carry information a table cannot. If it doesn't — cut it.

### Reproducibility
- All code (R or Python) deposited: OSF / GitHub / Harvard Dataverse
- Data sources cited with access dates and version numbers
- World Development increasingly expects this. It also signals confidence.

---

## RECOMMENDED TECH STACK

```
Language:     R (preferred for panel econometrics and HLM) or Python
Panel FE:     R → fixest package (fast, clustered SE built in)
              Python → linearmodels
HLM:          R → lme4 / lmerTest
              Python → statsmodels MixedLM
ANOVA:        R → base aov() + car::Anova() + rstatix
Data wrangling: tidyverse (R) / pandas (Python)
Visualization: ggplot2 (R) / matplotlib + seaborn (Python)
Tables:       modelsummary (R) / stargazer (R) / statsmodels summary (Python)
Reproducibility: R Markdown / Quarto / Jupyter Notebook
```

---

## THE FINAL INTEGRITY CHECK

Before submission, answer this question honestly:

> *"If my core finding is wrong — if aid type actually doesn't matter, if governance is the only real predictor — does this paper still contribute something durable to the literature?"*

**If yes:** robust paper.  
**If no:** advocacy dressed as research. Rebuild.

---

## IMMEDIATE NEXT STEPS FOR CLAUDE CODE

1. **Download and audit all datasets listed above** — check coverage, missingness rates, year ranges
2. **Build the panel dataset** — merge on ISO3 country code + year, document join losses
3. **Exploratory data analysis** — enrollment vs learning divergence plots by region and income group
4. **Run Model 1 (OLS baseline)** — establish naive result
5. **Run Model 2 (Fixed Effects)** — the central finding
6. **Run all diagnostics** — document every test result before proceeding
7. **Then write.** Data first, narrative second.

---

*Document generated from conversation with Claude (claude.ai). Author: practitioner-researcher. Project status: Pre-data, architecture complete. Ready to execute.*
