# R/81_peer_review_placebo.R
#
# Peer-review revision (added in response to peer review;
# not part of the pre-specified set).
#
# Falsification / placebo test: does FUTURE aid predict CURRENT learning?
# Under the strictly-past identification used in the headline (Model 2 spec C,
# PC1 governance), strictly-future aid should not predict current learning.
# If it does — at magnitude comparable to past aid — the directional
# interpretation of the headline collapses.
#
# Construction: strictly-future 3-yr MA of CRS disbursements per iso3,
# year-sorted, = mean(crs_disburse_usd_defl[t+1, t+2, t+3]). Substitute
# log1p(future_3yr_ma) for log1p(crs_disburse_usd_defl_ma3_lag1) in the
# locked headline spec. Refit on the same primary window.
#
# Output: output/tables/peer_review_placebo_future_aid.{csv,md}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
})

set.seed(20260525)
PANEL_PATH <- "data/interim/panel.parquet"
OUT_CSV    <- "output/tables/peer_review_placebo_future_aid.csv"
OUT_MD     <- "output/tables/peer_review_placebo_future_aid.md"

WGI_DIMS <- c("wgi_va_est","wgi_pv_est","wgi_ge_est",
              "wgi_rq_est","wgi_rl_est","wgi_cc_est")

# === 1. Load + construct PC1 governance (same as headline spec C) =============
message("[B2-placebo] loading panel + constructing PC1 governance")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

d <- d |> mutate(
  log_gdp_pc = log(wdi_gdp_pc_usd)
)

wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
cr <- complete.cases(wgi_mat)
pca <- prcomp(wgi_mat[cr, ], scale. = TRUE, center = TRUE)
if (pca$rotation["wgi_ge_est", "PC1"] < 0) {
  pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
  pca$x[, "PC1"]        <- -pca$x[, "PC1"]
}
d$wgi_pc1 <- NA_real_
d$wgi_pc1[cr] <- pca$x[, "PC1"]

# === 2. Construct strictly-FUTURE 3-yr MA =====================================
# For each iso3, sort by year, compute future_3yr_ma = mean(disburse[t+1..t+3])
# using lead-by-1, lead-by-2, lead-by-3. NA where any of those leads is NA.
# Use the FULL crs_disburse panel BEFORE the primary-window filter is applied,
# because year+3 may fall outside the primary window even when t is inside.
# Re-read the panel without the in_primary_window filter to recover the leads.
message("[B2-placebo] constructing strictly-future 3-yr MA from full panel")
d_full <- arrow::read_parquet(PANEL_PATH)

d_full <- d_full |>
  arrange(iso3, year) |>
  group_by(iso3) |>
  mutate(
    future_3yr_sum = lead(crs_disburse_usd_defl_sum, 1) +
                     lead(crs_disburse_usd_defl_sum, 2) +
                     lead(crs_disburse_usd_defl_sum, 3),
    future_3yr_ma  = future_3yr_sum / 3,
    log_future_3yr = log1p(future_3yr_ma)
  ) |>
  ungroup() |>
  select(iso3, year, future_3yr_ma, log_future_3yr)

d <- d |> left_join(d_full, by = c("iso3", "year"))

n_with_future <- sum(!is.na(d$log_future_3yr) & !is.na(d$hlo_hlo_score))
cat(sprintf("[B2-placebo] non-NA future-MA cells with HLO: %d / %d\n",
            n_with_future, nrow(d)))

# === 3. Refit headline spec with future-aid treatment =========================
message("\n[B2-placebo] fitting placebo spec: future-aid → current HLO")

m_placebo <- feols(
  hlo_hlo_score ~ log_future_3yr + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d, vcov = ~iso3
)

# Refit headline (past-aid) on the SAME sample where future-aid is observed,
# for an apples-to-apples comparison.
d_overlap <- d |> filter(!is.na(log_future_3yr),
                          !is.na(hlo_hlo_score),
                          !is.na(log_gdp_pc),
                          !is.na(wdi_ptr_primary),
                          !is.na(wdi_edu_exp_pct_gdp),
                          !is.na(wgi_pc1),
                          !is.na(crs_disburse_usd_defl_ma3_lag1)) |>
  mutate(log_past_ma3_lag1 = log1p(crs_disburse_usd_defl_ma3_lag1))

m_past_on_overlap <- feols(
  hlo_hlo_score ~ log_past_ma3_lag1 + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d_overlap, vcov = ~iso3
)

# Also refit the headline on its full sample for context
d_headline <- d |>
  mutate(log_past_ma3_lag1 = log1p(crs_disburse_usd_defl_ma3_lag1))

m_headline <- feols(
  hlo_hlo_score ~ log_past_ma3_lag1 + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d_headline, vcov = ~iso3
)

# === 4. Assemble results ======================================================
ci95 <- function(m, coef_name) {
  est <- coef(m)[coef_name]
  s   <- se(m)[coef_name]
  c(lo = est - 1.96 * s, hi = est + 1.96 * s)
}

results <- tibble(
  spec = c("Headline (past 3-yr MA, lag1) on full headline sample",
           "Headline (past 3-yr MA, lag1) on placebo-overlap sample",
           "Placebo (future 3-yr MA) on placebo-overlap sample"),
  N    = c(nobs(m_headline), nobs(m_past_on_overlap), nobs(m_placebo)),
  beta = c(coef(m_headline)["log_past_ma3_lag1"],
           coef(m_past_on_overlap)["log_past_ma3_lag1"],
           coef(m_placebo)["log_future_3yr"]),
  se   = c(se(m_headline)["log_past_ma3_lag1"],
           se(m_past_on_overlap)["log_past_ma3_lag1"],
           se(m_placebo)["log_future_3yr"]),
  p    = c(pvalue(m_headline)["log_past_ma3_lag1"],
           pvalue(m_past_on_overlap)["log_past_ma3_lag1"],
           pvalue(m_placebo)["log_future_3yr"]),
  ci_lo = c(ci95(m_headline, "log_past_ma3_lag1")[1],
            ci95(m_past_on_overlap, "log_past_ma3_lag1")[1],
            ci95(m_placebo, "log_future_3yr")[1]),
  ci_hi = c(ci95(m_headline, "log_past_ma3_lag1")[2],
            ci95(m_past_on_overlap, "log_past_ma3_lag1")[2],
            ci95(m_placebo, "log_future_3yr")[2])
)

write_csv(results, OUT_CSV)

md_lines <- c(
  "# B2 — Placebo / Falsification: future aid predicting current learning",
  "",
  "**Added in response to peer review; not part of the pre-specified set.**",
  "",
  sprintf("Seed: %d. Treatment construction: `future_3yr_ma = mean(crs_disburse_usd_defl_sum[t+1, t+2, t+3]) / 3`. log1p applied. Refit of the locked headline spec (PC1 governance, log GDP, PTR primary, ed_exp_%%GDP) with future-aid substituted for past-aid (strictly-past 3-yr MA, lag1).", 20260525L),
  "",
  "## Result",
  "",
  knitr::kable(results |> mutate(across(c(beta, se, ci_lo, ci_hi), ~round(.x, 3)),
                                  p = round(p, 4)),
               format = "markdown"),
  "",
  "## Reading",
  "",
  "If the future-aid coefficient on the placebo-overlap sample is similar in magnitude and significance to the past-aid coefficient on the same sample, the directional interpretation of the headline is undermined: past aid does not uniquely predict current learning more than future aid does. If the future-aid coefficient is materially smaller or insignificant relative to past-aid on the same sample, the directional reading survives the falsification."
)
writeLines(md_lines, OUT_MD)

# === 5. Console summary =======================================================
cat("\n=== B2 PLACEBO SUMMARY ===\n")
print(results |> mutate(across(c(beta, se, ci_lo, ci_hi), ~round(.x, 3)),
                         p = round(p, 4)))
cat(sprintf("\nWrote %s and %s\n", OUT_CSV, OUT_MD))
