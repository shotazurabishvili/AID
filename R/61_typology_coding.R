# R/61_typology_coding.R
#
# Phase 7 Session 01: ADR-0007 lock — intervention typology coding.
#
# RAN: 2026-05-19 23:55. OUTCOME: ADR-0007 REJECTED on 2026-05-23 — all three
# pre-committed lock criteria failed (raw agreement 39.04%, κ=0.19,
# unclassified 75.68%). Model 4 dropped from the paper rather than escalate
# to Option 3 (hand-coding). Script + outputs retained as negative-evidence
# artifacts for the reproducibility package.
# See: docs/decisions/0007-oecd-crs-intervention-typology.md (Rejected),
#      docs/findings.md §5.5, docs/session_log/2026-05-23-21-model4-dropped.md.
#
# Two parallel classifiers on the 537,586-project CRS extract (education sectors
# 110/111/112/113/114). Both committed to git BEFORE this script runs (no-tuning rule).
#
#   1. Rule-based (Option 1, primary):
#        Regex/keyword cascade on paste(project_title, short_description, long_description).
#        Priority order: teacher_training > curriculum > infrastructure > budget_support.
#        Rules at R/lib/typology/keyword_rules_v1.csv.
#
#   2. LLM-via-purpose-code (Option 2, robustness):
#        Each project inherits its 5-digit purpose_code's bucket.
#        Mapping at R/lib/typology/purpose_code_to_bucket_v1.csv (Claude opus-4-7 [1m]
#        classification of OECD purpose-code descriptions, stamped 2026-05-19).
#
# Agreement: project-level Cohen's κ + raw % on joint-classified subsample
# (rows where rule-based produced a non-unclassified label).
#
# Lock criterion (binding per plan): ≥85% raw AND κ ≥ 0.70. Both required.
#
# Outputs:
#   data/interim/oecd_crs_typology.parquet        (project-level + 2 bucket labels)
#   data/interim/typology_country_year.parquet    (iso3 × year × bucket × USD)
#   output/tables/typology_method_agreement.{csv,md}
#   output/tables/typology_country_dominant.csv
#   output/tables/typology_country_shares.csv
#   output/tables/typology_bucket_distribution.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
})

CRS_PATH         <- "data/interim/oecd_crs.parquet"
RULES_PATH       <- "R/lib/typology/keyword_rules_v1.csv"
CODE_MAP_PATH    <- "R/lib/typology/purpose_code_to_bucket_v1.csv"

OUT_TYPOLOGY     <- "data/interim/oecd_crs_typology.parquet"
OUT_CY_PANEL     <- "data/interim/typology_country_year.parquet"
OUT_AGREE_CSV    <- "output/tables/typology_method_agreement.csv"
OUT_AGREE_MD     <- "output/tables/typology_method_agreement.md"
OUT_DOMINANT     <- "output/tables/typology_country_dominant.csv"
OUT_SHARES       <- "output/tables/typology_country_shares.csv"
OUT_BUCKET_DIST  <- "output/tables/typology_bucket_distribution.csv"

# === 1. Load inputs ===========================================================
message("[typology] loading CRS + rule files")
crs <- arrow::read_parquet(CRS_PATH)
rules <- readr::read_csv(RULES_PATH, show_col_types = FALSE)
code_map <- readr::read_csv(CODE_MAP_PATH, show_col_types = FALSE)

stopifnot(nrow(rules) > 0)
stopifnot(nrow(code_map) == 20)
stopifnot(all(c("priority", "bucket", "pattern") %in% names(rules)))
stopifnot(all(c("purpose_code", "bucket") %in% names(code_map)))

cat(sprintf("[typology] CRS: %d rows; rules: %d patterns; code_map: %d codes\n",
            nrow(crs), nrow(rules), nrow(code_map)))

# === 2. Rule-based classifier (priority cascade on text) =====================
message("\n[typology] running rule-based classifier")

# Concat text fields (NA → empty for fail-soft regex matching).
crs <- crs |> mutate(
  text_blob = paste(
    coalesce(project_title, ""),
    coalesce(short_description, ""),
    coalesce(long_description, ""),
    sep = " "
  ) |> str_to_lower()
)

# For each priority tier, compile patterns; any-of-pattern hit assigns the bucket.
# Cascade order: priority 1 → 2 → 3 → 4. First hit wins.
rules <- rules |> arrange(priority, bucket)
priority_order <- rules |>
  distinct(priority, bucket) |>
  arrange(priority)
stopifnot(identical(priority_order$bucket,
                    c("teacher_training", "curriculum", "infrastructure", "budget_support")))

# Build a single regex per bucket (OR-joined; case-insensitive via lower-casing above).
bucket_regex <- rules |>
  group_by(bucket) |>
  summarise(combined = paste(pattern, collapse = "|"), .groups = "drop") |>
  inner_join(priority_order, by = "bucket") |>
  arrange(priority)

cat("Bucket regex sizes (chars):\n")
print(bucket_regex |> mutate(n_chars = nchar(combined)) |> select(priority, bucket, n_chars))

# Cascade
crs$bucket_rule <- NA_character_
for (i in seq_len(nrow(bucket_regex))) {
  bucket <- bucket_regex$bucket[i]
  re     <- bucket_regex$combined[i]
  needs_match <- is.na(crs$bucket_rule)
  hits <- str_detect(crs$text_blob[needs_match], re)
  crs$bucket_rule[needs_match][hits] <- bucket
  cat(sprintf("  priority %d (%s): %d new hits (cumulative %d non-NA)\n",
              bucket_regex$priority[i], bucket,
              sum(hits, na.rm = TRUE),
              sum(!is.na(crs$bucket_rule))))
}
crs$bucket_rule[is.na(crs$bucket_rule)] <- "unclassified"

# === 3. LLM-via-purpose-code classifier =====================================
message("\n[typology] applying LLM-via-purpose-code classifier")

# code_map has purpose_code (integer in CRS; CSV may store as int)
code_map <- code_map |> mutate(purpose_code = as.integer(purpose_code))
crs <- crs |>
  left_join(code_map |> select(purpose_code, bucket_llm = bucket),
            by = "purpose_code")
n_unmatched_llm <- sum(is.na(crs$bucket_llm))
if (n_unmatched_llm > 0) {
  warning(sprintf("[typology] %d projects with no purpose_code match in code_map (will be NA in bucket_llm)",
                   n_unmatched_llm))
}

# === 4. Distribution + agreement ============================================
cat("\n=== Rule-based bucket distribution ===\n")
rule_dist <- crs |> count(bucket_rule) |> mutate(pct = round(100 * n / sum(n), 2)) |>
  arrange(desc(n))
print(rule_dist)

cat("\n=== LLM-via-purpose-code bucket distribution ===\n")
llm_dist <- crs |> count(bucket_llm) |> mutate(pct = round(100 * n / sum(n), 2)) |>
  arrange(desc(n))
print(llm_dist)

unclassified_pct_rule <- 100 * sum(crs$bucket_rule == "unclassified") / nrow(crs)
cat(sprintf("\n[typology] Rule-based unclassified: %.2f%% (threshold: must stay below 30%%)\n",
            unclassified_pct_rule))

# Joint-classified subsample for agreement
joint <- crs |>
  filter(bucket_rule != "unclassified", !is.na(bucket_llm))
n_joint <- nrow(joint)
cat(sprintf("[typology] Joint-classified subsample: %d / %d (%.1f%% of total CRS rows)\n",
            n_joint, nrow(crs), 100 * n_joint / nrow(crs)))

raw_agreement <- mean(joint$bucket_rule == joint$bucket_llm)
cat(sprintf("[typology] Raw agreement on joint subsample: %.4f (%.2f%%)\n",
            raw_agreement, 100 * raw_agreement))

# Cohen's κ
buckets <- c("teacher_training", "curriculum", "infrastructure", "budget_support")
joint <- joint |>
  mutate(bucket_rule = factor(bucket_rule, levels = buckets),
         bucket_llm  = factor(bucket_llm,  levels = buckets))
ct <- table(joint$bucket_rule, joint$bucket_llm)
p_o <- sum(diag(ct)) / sum(ct)
p_e <- sum(rowSums(ct) * colSums(ct)) / sum(ct)^2
kappa <- (p_o - p_e) / (1 - p_e)
cat(sprintf("[typology] Cohen's κ: %.4f (Landis-Koch ≥0.70 = substantial; ≥0.81 = almost perfect)\n",
            kappa))

cat("\n=== Confusion matrix (rule vs LLM, joint-classified) ===\n")
print(ct)

# Lock criterion check (binding: ≥85% AND κ≥0.70)
agree_pass <- raw_agreement >= 0.85
kappa_pass <- kappa >= 0.70
both_pass  <- agree_pass && kappa_pass
unclassified_pass <- unclassified_pct_rule < 30

cat(sprintf("\n=== LOCK CRITERIA ===\n"))
cat(sprintf("Raw agreement ≥ 85%%: %.2f%% %s\n",
            100 * raw_agreement, ifelse(agree_pass, "PASS", "FAIL")))
cat(sprintf("Cohen's κ ≥ 0.70:    %.4f %s\n",
            kappa, ifelse(kappa_pass, "PASS", "FAIL")))
cat(sprintf("Unclassified < 30%%:  %.2f%% %s\n",
            unclassified_pct_rule, ifelse(unclassified_pass, "PASS", "FAIL")))
cat(sprintf("\nOverall lock decision: %s\n",
            ifelse(both_pass && unclassified_pass, "LOCK (ADR-0007 → Accepted)",
                   "ESCALATE (Option 3 hand-coding required)")))

# === 5. Write agreement table ===============================================
dir.create(dirname(OUT_AGREE_CSV), recursive = TRUE, showWarnings = FALSE)
agree_df <- tibble(
  metric = c("Raw agreement (joint-classified subsample)",
             "Cohen's kappa",
             "Joint subsample N",
             "Total CRS rows",
             "Rule-based unclassified %",
             "Lock criterion ≥85% met",
             "Lock criterion κ≥0.70 met",
             "Lock criterion unclassified<30% met",
             "Overall lock outcome"),
  value = c(sprintf("%.4f", raw_agreement),
            sprintf("%.4f", kappa),
            sprintf("%d", n_joint),
            sprintf("%d", nrow(crs)),
            sprintf("%.2f%%", unclassified_pct_rule),
            ifelse(agree_pass, "PASS", "FAIL"),
            ifelse(kappa_pass, "PASS", "FAIL"),
            ifelse(unclassified_pass, "PASS", "FAIL"),
            ifelse(both_pass && unclassified_pass, "LOCK", "ESCALATE"))
)
readr::write_csv(agree_df, OUT_AGREE_CSV)

md_lines <- c(
  "# Typology classifier agreement (ADR-0007 lock evidence)",
  "",
  sprintf("**Joint-classified subsample:** %d projects (%.2f%% of %d total CRS rows)",
          n_joint, 100 * n_joint / nrow(crs), nrow(crs)),
  sprintf("**Raw agreement:** %.4f (%.2f%%)", raw_agreement, 100 * raw_agreement),
  sprintf("**Cohen's κ:** %.4f", kappa),
  sprintf("**Rule-based unclassified:** %.2f%%", unclassified_pct_rule),
  "",
  "## Lock criteria (binding, pre-specified)",
  "",
  sprintf("- Raw agreement ≥ 85%%: %s", ifelse(agree_pass, "**PASS**", "**FAIL**")),
  sprintf("- Cohen's κ ≥ 0.70:    %s", ifelse(kappa_pass, "**PASS**", "**FAIL**")),
  sprintf("- Unclassified < 30%%:  %s", ifelse(unclassified_pass, "**PASS**", "**FAIL**")),
  "",
  sprintf("**Decision: %s**",
          ifelse(both_pass && unclassified_pass, "LOCK ADR-0007 → Accepted",
                 "ESCALATE to Option 3 (hand-coding)")),
  "",
  "## Confusion matrix (rows: rule-based, cols: LLM-via-purpose-code)",
  "",
  knitr::kable(as.data.frame.matrix(ct), format = "pipe"),
  "",
  "## Bucket distributions",
  "",
  "### Rule-based",
  knitr::kable(rule_dist, format = "pipe"),
  "",
  "### LLM-via-purpose-code",
  knitr::kable(llm_dist, format = "pipe")
)
writeLines(md_lines, OUT_AGREE_MD)
message(sprintf("[typology] wrote %s and %s", OUT_AGREE_CSV, OUT_AGREE_MD))

# === 6. Write project-level parquet =========================================
crs_out <- crs |>
  select(year, iso3, recipient_code, donor_code, purpose_code, purpose_name,
         usd_disbursement, usd_disbursement_defl, usd_commitment, usd_commitment_defl,
         project_title, short_description,
         bucket_rule, bucket_llm)
arrow::write_parquet(crs_out, OUT_TYPOLOGY)
message(sprintf("[typology] wrote %s (%d rows × %d cols)",
                OUT_TYPOLOGY, nrow(crs_out), ncol(crs_out)))

# === 7. Country-year × bucket panel =========================================
message("\n[typology] aggregating to country-year × bucket")
# Use rule-based as primary; LLM-derived bucket as secondary panel for robustness
cy_rule <- crs_out |>
  filter(!is.na(iso3)) |>
  group_by(iso3, year, bucket = bucket_rule) |>
  summarise(usd_disburse_defl = sum(usd_disbursement_defl, na.rm = TRUE),
            n_projects = n(),
            .groups = "drop") |>
  mutate(classifier = "rule_based")

cy_llm <- crs_out |>
  filter(!is.na(iso3), !is.na(bucket_llm)) |>
  group_by(iso3, year, bucket = bucket_llm) |>
  summarise(usd_disburse_defl = sum(usd_disbursement_defl, na.rm = TRUE),
            n_projects = n(),
            .groups = "drop") |>
  mutate(classifier = "llm_purpose_code")

cy_panel <- bind_rows(cy_rule, cy_llm)
arrow::write_parquet(cy_panel, OUT_CY_PANEL)
message(sprintf("[typology] wrote %s (%d rows)", OUT_CY_PANEL, nrow(cy_panel)))

# Sanity check: rule-based bucket totals per (iso3, year) sum to full CRS total
crs_panel_totals <- crs_out |>
  filter(!is.na(iso3)) |>
  group_by(iso3, year) |>
  summarise(total_disburse_defl = sum(usd_disbursement_defl, na.rm = TRUE), .groups = "drop")
cy_rule_totals <- cy_rule |>
  group_by(iso3, year) |>
  summarise(total_disburse_defl_buckets = sum(usd_disburse_defl), .groups = "drop")
check <- inner_join(crs_panel_totals, cy_rule_totals, by = c("iso3", "year"))
max_diff <- max(abs(check$total_disburse_defl - check$total_disburse_defl_buckets), na.rm = TRUE)
cat(sprintf("\n[typology] Country-year aggregation sanity: max |bucket_sum - total_sum| = %.6f\n", max_diff))
stopifnot(max_diff < 1e-6)

# === 8. Country-level dominant bucket + shares (primary window 2010-2020) ====
message("\n[typology] computing country-level dominant bucket (2010-2020 window)")

country_buckets <- cy_rule |>
  filter(year %in% 2010:2020) |>
  group_by(iso3, bucket) |>
  summarise(usd_total = sum(usd_disburse_defl), .groups = "drop") |>
  group_by(iso3) |>
  mutate(country_total = sum(usd_total),
         share = ifelse(country_total > 0, usd_total / country_total, 0)) |>
  ungroup()

# Wide format: one row per country, columns = bucket shares
shares_wide <- country_buckets |>
  filter(country_total > 0) |>  # drop countries with no education ODA in window
  select(iso3, bucket, share) |>
  pivot_wider(names_from = bucket, values_from = share, values_fill = 0)
readr::write_csv(shares_wide, OUT_SHARES)

# Dominant: argmax across the 4 main buckets (treat unclassified as residual)
dominant <- country_buckets |>
  filter(country_total > 0, bucket != "unclassified") |>
  group_by(iso3) |>
  slice_max(share, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(iso3, dominant_bucket = bucket, dominant_share = share, country_total_usd_defl = country_total)
readr::write_csv(dominant, OUT_DOMINANT)

cat("\n=== Country dominant-bucket distribution (rule-based, 2010-2020) ===\n")
dom_dist <- dominant |> count(dominant_bucket) |> mutate(pct = round(100*n/sum(n), 1)) |> arrange(desc(n))
print(dom_dist)
readr::write_csv(dom_dist, OUT_BUCKET_DIST)

message(sprintf("[typology] wrote %s", OUT_DOMINANT))
message(sprintf("[typology] wrote %s", OUT_SHARES))
message(sprintf("[typology] wrote %s", OUT_BUCKET_DIST))

# === 9. Final stdout summary =================================================
cat("\n=== Phase 7 Session 01 summary ===\n")
cat(sprintf("Rule-based bucket distribution (project-weighted):\n"))
print(rule_dist)
cat(sprintf("\nLLM-via-purpose-code bucket distribution:\n"))
print(llm_dist)
cat(sprintf("\nAgreement: raw=%.2f%%, κ=%.4f\n", 100 * raw_agreement, kappa))
cat(sprintf("Lock decision: %s\n",
            ifelse(both_pass && unclassified_pass, "LOCK", "ESCALATE")))
cat(sprintf("\nDominant-bucket distribution (countries, 2010-2020):\n"))
print(dom_dist)

message("\n[typology] complete.")
