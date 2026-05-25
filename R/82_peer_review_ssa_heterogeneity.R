# R/82_peer_review_ssa_heterogeneity.R
#
# Peer-review revision (added in response to peer review;
# not part of the pre-specified set).
#
# SSA heterogeneity: is the headline β = +11.14 driven by sub-Saharan Africa?
# 42 of 133 countries in the panel are SSA per descriptive Table 1; SSA
# dominates both the aid treatment and the low-learning outcome.
#
# Three refits of the locked headline spec (Model 2 spec C, PC1 governance):
#   (i)   excluding SSA countries entirely
#   (ii)  on SSA subsample only
#   (iii) pooled with treatment × is_ssa interaction
#
# SSA membership derived from countrycode::countrycode(iso3, "iso3c", "region23")
# matching "Sub-Saharan Africa".
#
# Output: output/tables/peer_review_ssa_heterogeneity.{csv,md}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(countrycode)
})

set.seed(20260525)
PANEL_PATH <- "data/interim/panel.parquet"
OUT_CSV    <- "output/tables/peer_review_ssa_heterogeneity.csv"
OUT_MD     <- "output/tables/peer_review_ssa_heterogeneity.md"

WGI_DIMS <- c("wgi_va_est","wgi_pv_est","wgi_ge_est",
              "wgi_rq_est","wgi_rl_est","wgi_cc_est")

# === 1. Load + construct PC1 governance + SSA flag ============================
message("[B3-ssa] loading panel + constructing PC1 + SSA flag")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

d <- d |> mutate(
  log_crs    = log1p(crs_disburse_usd_defl_ma3_lag1),
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

# SSA flag — World Bank region from countrycode
d$wb_region <- countrycode(d$iso3, "iso3c", "region",
                            custom_match = c("XKX" = "Europe & Central Asia"))
d$is_ssa <- !is.na(d$wb_region) & d$wb_region == "Sub-Saharan Africa"

n_iso_ssa <- d |> filter(is_ssa) |> pull(iso3) |> n_distinct()
n_iso_non <- d |> filter(!is_ssa) |> pull(iso3) |> n_distinct()
cat(sprintf("[B3-ssa] SSA countries in primary panel: %d | non-SSA: %d\n",
            n_iso_ssa, n_iso_non))

ci95 <- function(m, coef_name) {
  est <- coef(m)[coef_name]
  s   <- se(m)[coef_name]
  c(lo = est - 1.96 * s, hi = est + 1.96 * s)
}

# === 2. Three refits ==========================================================
message("\n[B3-ssa] fitting three SSA-heterogeneity specs")

# (i) Excluding SSA
m_excl <- feols(
  hlo_hlo_score ~ log_crs + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d |> filter(!is_ssa), vcov = ~iso3
)

# (ii) SSA only
m_only <- feols(
  hlo_hlo_score ~ log_crs + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d |> filter(is_ssa), vcov = ~iso3
)

# (iii) Pooled with treatment × is_ssa interaction
m_inter <- feols(
  hlo_hlo_score ~ log_crs * is_ssa + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d, vcov = ~iso3
)

# Also the full headline for reference
m_full <- feols(
  hlo_hlo_score ~ log_crs + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d, vcov = ~iso3
)

# === 3. Assemble results ======================================================
get_row <- function(m, label, n_countries, coef_name = "log_crs") {
  tibble(
    spec = label,
    N_obs = nobs(m),
    N_countries = n_countries,
    beta = unname(coef(m)[coef_name]),
    se   = unname(se(m)[coef_name]),
    p    = unname(pvalue(m)[coef_name]),
    ci_lo = unname(ci95(m, coef_name)[1]),
    ci_hi = unname(ci95(m, coef_name)[2])
  )
}

results <- bind_rows(
  get_row(m_full, "Headline (full panel, reference)",
          d |> pull(iso3) |> n_distinct()),
  get_row(m_excl, "(i) Excluding SSA", n_iso_non),
  get_row(m_only, "(ii) SSA only", n_iso_ssa),
  get_row(m_inter, "(iii) Pooled with log_crs × is_ssa — main effect",
          d |> pull(iso3) |> n_distinct(), coef_name = "log_crs"),
  get_row(m_inter, "(iii) Pooled with log_crs × is_ssa — interaction",
          d |> pull(iso3) |> n_distinct(), coef_name = "log_crs:is_ssaTRUE")
)

write_csv(results, OUT_CSV)

md_lines <- c(
  "# B3 — SSA heterogeneity: is the headline driven by sub-Saharan Africa?",
  "",
  "**Added in response to peer review; not part of the pre-specified set.**",
  "",
  sprintf("Seed: %d. SSA membership: World Bank region from `countrycode::countrycode(iso3, \"iso3c\", \"region23\")`. Locked headline spec (PC1 governance, log GDP, PTR primary, ed_exp_%%GDP; two-way FE iso3 + year; country-clustered SE) refit on three subsamples.", 20260525L),
  "",
  "## Result",
  "",
  knitr::kable(results |> mutate(across(c(beta, se, ci_lo, ci_hi), ~round(.x, 3)),
                                  p = round(p, 4)),
               format = "markdown"),
  "",
  "## Reading",
  "",
  "If the (i) non-SSA β is close to zero or sign-flipped while (ii) SSA-only β is large, the pooled headline is SSA-driven. The (iii) interaction coefficient gives a formal test: a significant interaction confirms differential aid response in SSA vs non-SSA."
)
writeLines(md_lines, OUT_MD)

# === 4. Console summary =======================================================
cat("\n=== B3 SSA-HETEROGENEITY SUMMARY ===\n")
print(results |> mutate(across(c(beta, se, ci_lo, ci_hi), ~round(.x, 3)),
                         p = round(p, 4)))
cat(sprintf("\nWrote %s and %s\n", OUT_CSV, OUT_MD))
