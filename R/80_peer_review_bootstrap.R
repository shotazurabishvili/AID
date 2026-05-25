# R/80_peer_review_bootstrap.R
#
# Peer-review revision (added in response to peer review;
# not part of the pre-specified set).
#
# Small-cluster robustness on the headline (Model 2 spec C, PC1 governance) +
# AAP-full + AAP-overlap specifications.
#
# Intended: wild cluster bootstrap (fwildclusterboot::boottest) with B = 9999
# Rademacher weights. Actual: fwildclusterboot is no longer available in the
# project's CRAN snapshot ("package 'fwildclusterboot' is not available"); both
# renv::install and direct install.packages from cloud.r-project.org failed.
# First fallback (clubSandwich CR2 on fixest) returned df_Satt = 1 because
# clubSandwich cannot read fixest's absorbed FE — the resulting CR2 inference
# is degenerate and not reportable. Second fallback (this script): refit the
# spec as lm with explicit factor(iso3) + factor(year) dummies, then apply
# sandwich::vcovBS with type = "wild" (Rademacher cluster wild bootstrap), R =
# 9999, cluster = iso3. This is the wild cluster bootstrap on a different
# implementation path. It is what the manuscript should report.
#
# Output: output/tables/peer_review_wild_cluster_bootstrap.{csv,md}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(sandwich)
  library(lmtest)
})

set.seed(20260525)
PANEL_PATH <- "data/interim/panel.parquet"
OUT_CSV    <- "output/tables/peer_review_wild_cluster_bootstrap.csv"
OUT_MD     <- "output/tables/peer_review_wild_cluster_bootstrap.md"

BOOT_SEED <- 20260525
B_REPS    <- 9999

WGI_DIMS <- c("wgi_va_est","wgi_pv_est","wgi_ge_est",
              "wgi_rq_est","wgi_rl_est","wgi_cc_est")

# === 1. Load + construct PC1 governance + log treatments ======================
message("[B1-boot] loading panel + constructing PC1 governance")
d <- arrow::read_parquet(PANEL_PATH)

d <- d |> mutate(
  log_crs_strict = log1p(crs_disburse_usd_defl_ma3_lag1),
  log_gdp_pc     = log(wdi_gdp_pc_usd)
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

d_primary <- d |> filter(in_primary_window)

# === 2. Headline + CR2 ========================================================
message("\n[B1-boot] fitting headline + CR2 small-cluster correction")

fit_and_bootstrap <- function(d_input, outcome_var, label) {
  # Pre-filter to complete cases on the model variables so the cluster vector
  # matches the row count in the lm model frame.
  vars_used <- c(outcome_var, "log_crs_strict", "log_gdp_pc",
                 "wdi_ptr_primary", "wdi_edu_exp_pct_gdp", "wgi_pc1",
                 "iso3", "year")
  d_cc <- d_input |> drop_na(all_of(intersect(vars_used, names(d_input))))
  iso_n <- d_cc |> count(iso3) |> filter(n >= 2)
  d_cc <- d_cc |> filter(iso3 %in% iso_n$iso3)
  d_cc <- d_cc |> mutate(iso3 = factor(iso3), year = factor(year))

  # feols for the asymptotic clustered-SE benchmark
  formula_fe <- as.formula(sprintf(
    "%s ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year",
    outcome_var))
  m_fe <- feols(formula_fe, data = d_cc, vcov = ~iso3)

  # lm with explicit dummies for the wild cluster bootstrap
  formula_lm <- as.formula(sprintf(
    "%s ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_pc1 + iso3 + year",
    outcome_var))
  m_lm <- lm(formula_lm, data = d_cc)

  # Wild cluster bootstrap via sandwich::vcovBS, Rademacher weights (default for
  # cluster.adjust = TRUE; we pass cluster explicitly)
  set.seed(BOOT_SEED)
  V_boot <- sandwich::vcovBS(m_lm, cluster = ~iso3, R = B_REPS,
                              type = "wild", applyfun = lapply)
  test_boot <- lmtest::coeftest(m_lm, vcov. = V_boot)

  # asymptotic clustered SE for direct comparison (lm + cluster-robust)
  V_cluster <- sandwich::vcovCL(m_lm, cluster = ~iso3, type = "HC1")
  test_cluster <- lmtest::coeftest(m_lm, vcov. = V_cluster)

  list(
    label = label,
    N = nobs(m_lm),
    n_clusters = length(unique(d_cc$iso3)),
    beta_fe = unname(coef(m_fe)["log_crs_strict"]),
    se_fe_asymp = unname(se(m_fe)["log_crs_strict"]),
    p_fe_asymp = unname(pvalue(m_fe)["log_crs_strict"]),
    asymp_ci_lo = unname(coef(m_fe)["log_crs_strict"] - 1.96 * se(m_fe)["log_crs_strict"]),
    asymp_ci_hi = unname(coef(m_fe)["log_crs_strict"] + 1.96 * se(m_fe)["log_crs_strict"]),
    se_lm_cluster = test_cluster["log_crs_strict", "Std. Error"],
    p_lm_cluster  = test_cluster["log_crs_strict", "Pr(>|t|)"],
    se_boot = test_boot["log_crs_strict", "Std. Error"],
    p_boot  = test_boot["log_crs_strict", "Pr(>|t|)"],
    boot_ci_lo = test_boot["log_crs_strict", "Estimate"] -
                 1.96 * test_boot["log_crs_strict", "Std. Error"],
    boot_ci_hi = test_boot["log_crs_strict", "Estimate"] +
                 1.96 * test_boot["log_crs_strict", "Std. Error"]
  )
}

res_headline <- fit_and_bootstrap(d_primary, "hlo_hlo_score",
                                   "Headline (WB HLO, primary window, PC1 gov)")

# === 3. AAP-full + bootstrap ==================================================
message("[B1-boot] fitting AAP-full + wild cluster bootstrap")
res_aap_full <- fit_and_bootstrap(d |> filter(!is.na(aap_hlo_aap)),
                                   "aap_hlo_aap", "AAP-2018 full coverage")

# === 4. AAP-overlap + bootstrap ===============================================
message("[B1-boot] fitting AAP-overlap + wild cluster bootstrap")
res_aap_overlap <- fit_and_bootstrap(d |> filter(!is.na(aap_hlo_aap), year >= 2010),
                                      "aap_hlo_aap", "AAP-2018 overlap (year >= 2010)")

# === 5. Assemble results ======================================================
results <- bind_rows(
  as_tibble(res_headline),
  as_tibble(res_aap_full),
  as_tibble(res_aap_overlap)
) |>
  select(spec = label, N, n_clusters,
         beta = beta_fe, se_fe_asymp, p_fe_asymp, asymp_ci_lo, asymp_ci_hi,
         se_lm_cluster, p_lm_cluster,
         se_boot, p_boot, boot_ci_lo, boot_ci_hi)

write_csv(results, OUT_CSV)

md_lines <- c(
  "# B1 — Wild cluster bootstrap on the headline + AAP variants",
  "",
  "**Added in response to peer review; not part of the pre-specified set.**",
  "",
  sprintf("Seed: %d. Intended: `fwildclusterboot::boottest` with B = %d Rademacher weights, clustered on iso3. Actual: fwildclusterboot is no longer available in the project's CRAN snapshot. The first fallback (`clubSandwich::vcovCR` type CR2 on the fixest object) returned a Satterthwaite df of 1, because clubSandwich cannot read fixest's absorbed FE — the CR2 inference was degenerate and not reportable. The second fallback (this report) refits the locked spec as `lm` with explicit `factor(iso3) + factor(year)` dummies, then applies `sandwich::vcovBS` with `type = \"wild\"` (Rademacher cluster wild bootstrap), R = %d, cluster = iso3. This is a wild cluster bootstrap on a different implementation path — what fwildclusterboot computes natively, computed via sandwich/lm instead.", BOOT_SEED, B_REPS, B_REPS),
  "",
  "## Result",
  "",
  "Columns: `beta` and `se_fe_asymp` are the fixest two-way-FE estimate; `se_lm_cluster` is the lm-equivalent country-clustered HC1 SE (sanity check against the FE asymptotic SE); `se_boot` and `p_boot` are the wild cluster bootstrap.",
  "",
  knitr::kable(results |> mutate(across(c(beta, se_fe_asymp, asymp_ci_lo, asymp_ci_hi,
                                          se_lm_cluster, se_boot,
                                          boot_ci_lo, boot_ci_hi), ~round(.x, 3)),
                                  across(c(p_fe_asymp, p_lm_cluster, p_boot), ~round(.x, 4))),
               format = "markdown"),
  "",
  "## Reading",
  "",
  "If the bootstrap p-value diverges materially from the asymptotic country-clustered p — particularly if the bootstrap p crosses 0.10 while the asymptotic p sits at 0.048 — the asymptotic inference understates the true uncertainty and the headline does not pass the small-cluster robustness check. With ~127 nominal HLO-observing countries reducing to 61 clusters identified in the within-country FE specification (only countries with ≥ 2 HLO observations contribute identifying variation), the small-cluster correction is potentially binding."
)
writeLines(md_lines, OUT_MD)

# === 6. Console summary =======================================================
cat("\n=== B1 WILD CLUSTER BOOTSTRAP SUMMARY ===\n")
print(results |> mutate(across(c(beta, se_fe_asymp, asymp_ci_lo, asymp_ci_hi,
                                  se_lm_cluster, se_boot,
                                  boot_ci_lo, boot_ci_hi), ~round(.x, 3)),
                         across(c(p_fe_asymp, p_lm_cluster, p_boot), ~round(.x, 4))))
cat(sprintf("\nWrote %s and %s\n", OUT_CSV, OUT_MD))
