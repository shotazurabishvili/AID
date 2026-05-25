# Lit Note: Oxford Insights (2026)

**Full cite (APA 7):** Oxford Insights. (2026). *Government AI Readiness Index 2025*. Oxford Insights. https://oxfordinsights.com/ (PDF release dated 2026-01-29.)

## What the index measures

The Government AI Readiness Index (GARI) scores 195 countries on government preparedness to deploy AI in the public sector. Each country score is the aggregate of **six pillars**, scored 0–100:

1. **Policy Capacity** — strategy documents, regulatory frameworks, dedicated AI bodies
2. **AI Infrastructure** — compute, broadband, data centers, digital public infrastructure
3. **Governance** — ethics frameworks, accountability, oversight mechanisms
4. **Public Sector Adoption** — actual AI deployments in government services
5. **Development & Diffusion** — domestic AI research ecosystem, talent pipeline
6. **Resilience** — cybersecurity, supply-chain robustness, redundancy

GARI is **annual** and **cross-sectional** in each edition. The 2025 edition is what this paper uses.

## Method (Oxford's)

Pillar scores from a mix of public-sector data, internal coding, and proprietary inputs. The full Oxford methodology is published in the report PDF (pp. 50–55 of the 2026 release). Oxford publishes per-pillar scores and a rank, but **does not publish a single aggregate composite score** (or if it does, the weights are not directly machine-readable from the table extract).

## Our use

Ingested at `data/interim/ai_readiness.parquet` from  via `pdfplumber` (PDF-only release; no machine-readable export). We derive `ai_readiness_score_mean` as the **equally-weighted mean of the six pillar scores** for use as a single aggregate. This derivation is documented at `docs/the manuscript methodology section` ("Supplementary measure: Oxford Insights AI Readiness") and clearly labeled as project-derived (not Oxford's official composite). normalizes this to [0,1] via `gari_norm = ai_readiness_score_mean / 100` and constructs the brief's "HCI × AI Readiness Index" composite as `compound_index = HCI × gari_norm`.

## Novelty-claim audit (2026-05-23, )

The brief asserts (§1 line 159): *"Constructed variable: Human Capital Index × AI Readiness Index. No prior paper has done this."*

Five-minute scholar / web pass surfaces the following adjacent or partially-overlapping work:

- **Brookings — "The Next Great Divergence: How AI could split the world again"** (2024–2025). Articulates the compounding-divergence thesis at country level: AI could split the world the way the Industrial Revolution did, with low-HCI / low-readiness countries falling further behind. Conceptual rather than empirical; no explicit joint composite. Closest theoretical antecedent.
- **World Bank — *Beyond the AI Divide* (Policy Research Working Paper 11073).** Uses Oxford GARI alongside other measures for a multi-country comparison; this is the closest practitioner-side antecedent to what we're doing. Needs to be cited in §6 if not in §2 (Lit Review).
- **ILO — *Disruption without dividend?* and *Buffer or Bottleneck?* (2024–2025).** Documents the digital-divide × AI-exposure compounding pattern at employment level, particularly for Latin America and low-income countries. Different unit of analysis (employment exposure, not country composite) but same underlying compounding logic.
- **Nature *Humanities & Social Sciences Communications* — "AI for Low-Income Countries"** (2024–2025). General framework piece; touches HCI-adjacent constraints.
- **Tandfonline / *Cogent Social Sciences* (2026)** — A study of 68 upper-middle-income countries using AI readiness + knowledge diffusion as predictors with HCI as the dependent variable. **Different direction** (treats AI readiness as predictor of HCI rather than constructing a joint composite); not the same construction but adjacent and worth citing as "the field has begun to treat these as jointly relevant."
- **Practitioner tools — symbio6.nl AI Readiness Map; Salesforce Global AI Readiness Index 2025.** Both compare GARI + HCI + adjacent indices for 188+ countries in dashboard form. Suggests that the *practical* joint-composite construction is already happening in the policy / consulting space, even if not yet as a peer-reviewed academic finding.

**Verdict.** The brief's "no prior paper has done this" claim is **overstated**. What appears genuinely novel in our §5.7 contribution:

1. Constructing an explicit `HCI × GARI` joint composite at country-cross-section,
2. Quantifying the SSA over-representation in the double-excluded cell (≈ 2× over-representation), and
3. Publishing this as a peer-reviewed *World Development* result rather than a practitioner dashboard,

— in the specific framing of *educational-aid effectiveness* (which is our paper's overall argument). The compounding-divergence *thesis* is widely articulated; the specific *operationalization* on the brief's exact axes appears not to have been done in the peer-reviewed academic literature we've surfaced, but we should hedge ("we are not aware of a prior peer-reviewed paper that …") rather than claim outright novelty.

## Status

- [x] PDF release ingested ()
- [x] Pillar derivation documented (the manuscript methodology section)
- [x] §5.7 empirical writeup
- [ ] Full Oxford methodology read (pp. 50–55 of the report PDF) — defer to manuscript drafting when §2 Lit Review and §3 Methodology need the technical detail
- [ ] *Beyond the AI Divide* (WBG WP 11073) read and engaged — 
- [ ] Brookings *Next Great Divergence* read and engaged — 
