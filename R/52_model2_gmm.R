# R/52_model2_gmm.R
#
# System GMM headline robustness + PAP-0010 lock.
#
# Purpose: triangulate the static-FE Model 2 result (β_FE = +10.95***, Session
# 14) against dynamic-panel identification strategies that address potential
# reverse causality (donors targeting deteriorating learning) and Nickell bias.
#
# Estimators run:
#   A. Pooled OLS with lagged DV    (Bond 2002 UPPER bound; biased upward)
#   B. Within FE with lagged DV (LSDV; Bond 2002 LOWER bound; Nickell bias downward)
#   C. Difference GMM (Arellano-Bond 1991)
#   D. System GMM (Blundell-Bond 1998)
#
# The TRUE persistence parameter lies between A and B (Bond 2002 consistency
# check). GMM estimates should fall in that range; if not, GMM is suspect.
#
# Time index: CYCLE INDEX (1=2010, 2=2017, 3=2018, 4=2020), not calendar year.
# Reason: HCI cycle spacing (2010→2017 = 7 yr; 2017→2018 = 1 yr) makes
# calendar-year lags meaningless. Cycle index treats each HCI cycle as the
# fundamental measurement period. Documented in the manuscript.
#
# Identification status (set at session end based on what runs):
#   Path 1: GMM clean   → PAP-0010 = Option 1 (System GMM as headline robustness)
#   Path 2: GMM ran but diagnostics fail → PAP-0010 = Option 1 with caveats
#   Path 3: GMM infeasible → PAP-0010 = Option 4 modified (static FE + Bond floor)
#
# Outputs:
#   output/tables/model2_bond_consistency.csv          (always)
#   output/tables/model2_gmm_diff.csv                  (if Diff GMM ran)
#   output/tables/model2_gmm_system.csv                (if System GMM ran)
#   output/tables/model2_gmm_diagnostics.csv           (always)
#   output/tables/model2_identification_triangulation.{csv,md}  (always -central deliverable)
#   output/figures/eda/model2_gmm_coefficient_plot.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(plm)
  library(fixest)
})

PANEL_PATH <- "data/interim/panel.parquet"

# === 1. Setup =================================================================
message("[gmm] loading production panel + cycle-restricting")

d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

cycle_years <- c(2010, 2017, 2018, 2020)
d_cycle <- d |>
  filter(year %in% cycle_years, !is.na(hlo_hlo_score)) |>
  mutate(
    cycle = match(year, cycle_years),
    log_crs_disb_ma3 = log1p(crs_disburse_usd_defl_ma3),
    log_gdp_pc       = log(wdi_gdp_pc_usd),
    log_gcdf_ma3     = log1p(gcdf_amount_const2021_ma3),
    covid_days_recode = ifelse(year < 2020 & is.na(covid_days_closed), 0, covid_days_closed)
  ) |>
  arrange(iso3, cycle)

# Drop singleton-HLO countries (<2 obs)
keep_iso <- names(table(d_cycle$iso3))[table(d_cycle$iso3) >= 2]
d_cycle <- d_cycle |> filter(iso3 %in% keep_iso)

message(sprintf("[gmm] cycle-restricted sample: %d rows × %d countries × %d cycles",
                nrow(d_cycle), dplyr::n_distinct(d_cycle$iso3),
                dplyr::n_distinct(d_cycle$cycle)))

# Two analytical samples:
#   MIN  = minimal control set (HLO + log_crs + log_gdp) -preserves all 4 cycles + 126 countries
#   FULL = full control set (+ ptr + wgi_ge + edu_exp)  -collapses to 3 cycles + ~61 countries
d_min <- d_cycle |>
  select(iso3, cycle, hlo_hlo_score, log_crs_disb_ma3, log_gdp_pc) |>
  na.omit()
d_full <- d_cycle |>
  select(iso3, cycle, hlo_hlo_score, log_crs_disb_ma3, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  na.omit()

# Re-drop singletons after listwise
d_min <- d_min |> group_by(iso3) |> filter(dplyr::n() >= 2) |> ungroup()
d_full <- d_full |> group_by(iso3) |> filter(dplyr::n() >= 2) |> ungroup()

message(sprintf("[gmm] minimal-spec sample: %d obs × %d countries", nrow(d_min), dplyr::n_distinct(d_min$iso3)))
message(sprintf("[gmm] full-spec sample:    %d obs × %d countries", nrow(d_full), dplyr::n_distinct(d_full$iso3)))

# === 2. Build lagged DV inline for Bond consistency (A + B) ===================
add_lag <- function(df) {
  df |> group_by(iso3) |> arrange(cycle, .by_group = TRUE) |>
    mutate(lag_hlo = lag(hlo_hlo_score, n = 1)) |>
    ungroup()
}
d_min_lag  <- add_lag(d_min)
d_full_lag <- add_lag(d_full)

# === 3. Bond (2002) consistency bounds: A. Pooled OLS-LDV, B. LSDV ============
message("\n[gmm] Bond (2002) consistency bounds (always reportable)")

# (A) Pooled OLS with lagged DV -upper bound
m_pooled_min  <- lm(hlo_hlo_score ~ lag_hlo + log_crs_disb_ma3 + log_gdp_pc,
                    data = d_min_lag |> filter(!is.na(lag_hlo)))
m_pooled_full <- lm(hlo_hlo_score ~ lag_hlo + log_crs_disb_ma3 + log_gdp_pc +
                      wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est,
                    data = d_full_lag |> filter(!is.na(lag_hlo)))

# (B) Within FE with lagged DV (LSDV) -lower bound (Nickell bias)
m_lsdv_min  <- lm(hlo_hlo_score ~ lag_hlo + log_crs_disb_ma3 + log_gdp_pc +
                    factor(iso3) + factor(cycle),
                  data = d_min_lag |> filter(!is.na(lag_hlo)))
m_lsdv_full <- lm(hlo_hlo_score ~ lag_hlo + log_crs_disb_ma3 + log_gdp_pc +
                    wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est +
                    factor(iso3) + factor(cycle),
                  data = d_full_lag |> filter(!is.na(lag_hlo)))

extract_coef <- function(m, var) {
  c(beta = unname(coef(m)[var]),
    se   = unname(sqrt(diag(vcov(m)))[var]),
    p    = unname(summary(m)$coefficients[var, "Pr(>|t|)"]),
    n    = length(m$fitted.values))
}

bond_df <- bind_rows(
  tibble(estimator = "(A) Pooled OLS w/ lagged DV -MIN spec",
         !!!extract_coef(m_pooled_min, "log_crs_disb_ma3"),
         lag_hlo = round(coef(m_pooled_min)["lag_hlo"], 3)),
  tibble(estimator = "(A) Pooled OLS w/ lagged DV -FULL spec",
         !!!extract_coef(m_pooled_full, "log_crs_disb_ma3"),
         lag_hlo = round(coef(m_pooled_full)["lag_hlo"], 3)),
  tibble(estimator = "(B) Within FE w/ lagged DV (LSDV) -MIN spec",
         !!!extract_coef(m_lsdv_min, "log_crs_disb_ma3"),
         lag_hlo = round(coef(m_lsdv_min)["lag_hlo"], 3)),
  tibble(estimator = "(B) Within FE w/ lagged DV (LSDV) -FULL spec",
         !!!extract_coef(m_lsdv_full, "log_crs_disb_ma3"),
         lag_hlo = round(coef(m_lsdv_full)["lag_hlo"], 3))
) |>
  mutate(across(c(beta, se), \(x) round(x, 3)),
         p = round(p, 4))

print(bond_df)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(bond_df, "output/tables/model2_bond_consistency.csv")
message("[gmm] wrote model2_bond_consistency.csv")

# === 4. GMM attempts ==========================================================
message("\n[gmm] Difference GMM (Arellano-Bond) + System GMM (Blundell-Bond)")

build_pdata <- function(df) {
  pdata.frame(as.data.frame(df), index = c("iso3", "cycle"))
}

safe_gmm <- function(pd, formula_str, transform, label) {
  message(sprintf("  [%s] estimating...", label))
  m <- tryCatch(
    pgmm(as.formula(formula_str), data = pd, effect = "twoways",
         model = "twosteps", transformation = transform, collapse = TRUE),
    error = function(e) {
      message(sprintf("  [%s] FAILED: %s", label, conditionMessage(e)))
      return(NULL)
    },
    warning = function(w) {
      message(sprintf("  [%s] warning: %s", label, conditionMessage(w)))
      tryCatch(
        pgmm(as.formula(formula_str), data = pd, effect = "twoways",
             model = "twosteps", transformation = transform, collapse = TRUE),
        error = function(e) NULL
      )
    }
  )
  m
}

safe_round <- function(x, digits = 4) {
  if (is.null(x) || length(x) == 0) return(NA_real_)
  if (!is.numeric(x) || is.na(x) || is.nan(x)) return(NA_real_)
  round(x, digits)
}

extract_gmm <- function(m, label) {
  if (is.null(m)) return(tibble(estimator = label, beta = NA_real_, se = NA_real_,
                                 p = NA_real_, hansen_p = NA_real_,
                                 ar1_p = NA_real_, ar2_p = NA_real_,
                                 n = NA_integer_, status = "failed_to_estimate"))
  s <- tryCatch(summary(m), error = function(e) NULL)
  if (is.null(s)) return(tibble(estimator = label, beta = NA_real_, se = NA_real_,
                                 p = NA_real_, hansen_p = NA_real_,
                                 ar1_p = NA_real_, ar2_p = NA_real_,
                                 n = NA_integer_, status = "summary_failed"))

  coef_row_idx <- which(rownames(s$coefficients) == "log_crs_disb_ma3")
  beta <- if (length(coef_row_idx) > 0) s$coefficients[coef_row_idx, 1] else NA_real_
  se   <- if (length(coef_row_idx) > 0) s$coefficients[coef_row_idx, 2] else NA_real_
  p_val <- if (length(coef_row_idx) > 0) s$coefficients[coef_row_idx, 4] else NA_real_

  hansen_p <- tryCatch(s$sargan$p.value, error = function(e) NA_real_)
  ar1_p    <- tryCatch(s$m1$p.value, error = function(e) NA_real_)
  ar2_p    <- tryCatch(s$m2$p.value, error = function(e) NA_real_)

  n_obs <- tryCatch(nrow(m$model[[1]]), error = function(e) NA_integer_)

  tibble(estimator = label,
         beta = safe_round(beta, 3), se = safe_round(se, 3), p = safe_round(p_val, 4),
         hansen_p = safe_round(hansen_p, 4),
         ar1_p = safe_round(ar1_p, 4),
         ar2_p = safe_round(ar2_p, 4),
         n = n_obs, status = "estimated")
}

pd_min  <- build_pdata(d_min)
pd_full <- build_pdata(d_full)

m_diff_min  <- safe_gmm(pd_min,
  "hlo_hlo_score ~ lag(hlo_hlo_score, 1) + log_crs_disb_ma3 + log_gdp_pc | lag(hlo_hlo_score, 2:99)",
  "d", "Diff GMM MIN")
m_diff_full <- safe_gmm(pd_full,
  "hlo_hlo_score ~ lag(hlo_hlo_score, 1) + log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est | lag(hlo_hlo_score, 2:99)",
  "d", "Diff GMM FULL")
m_sys_min   <- safe_gmm(pd_min,
  "hlo_hlo_score ~ lag(hlo_hlo_score, 1) + log_crs_disb_ma3 + log_gdp_pc | lag(hlo_hlo_score, 2:99)",
  "ld", "System GMM MIN")
m_sys_full  <- safe_gmm(pd_full,
  "hlo_hlo_score ~ lag(hlo_hlo_score, 1) + log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est | lag(hlo_hlo_score, 2:99)",
  "ld", "System GMM FULL")

gmm_results <- bind_rows(
  extract_gmm(m_diff_min,  "(C) Difference GMM -MIN spec"),
  extract_gmm(m_diff_full, "(C) Difference GMM -FULL spec"),
  extract_gmm(m_sys_min,   "(D) System GMM -MIN spec"),
  extract_gmm(m_sys_full,  "(D) System GMM -FULL spec")
)

print(gmm_results)
readr::write_csv(gmm_results, "output/tables/model2_gmm_diagnostics.csv")
message("[gmm] wrote model2_gmm_diagnostics.csv")

# Write per-estimator GMM tables if estimated
if (any(!is.na(gmm_results$beta[1:2]))) {
  readr::write_csv(gmm_results[1:2, ], "output/tables/model2_gmm_diff.csv")
  message("[gmm] wrote model2_gmm_diff.csv")
}
if (any(!is.na(gmm_results$beta[3:4]))) {
  readr::write_csv(gmm_results[3:4, ], "output/tables/model2_gmm_system.csv")
  message("[gmm] wrote model2_gmm_system.csv")
}

# === 5. Triangulation table ===================================================
message("\n[gmm] building identification triangulation table")

# Static FE results from the corresponding step (hardcoded for reference; can re-fit if needed)
static_fe <- tribble(
  ~estimator,                                ~beta,  ~se,   ~p,     ~n,    ~hansen_p, ~ar1_p, ~ar2_p, ~status,
  "Static FE Model 2 (full 2e)", 10.95,  3.60,  0.003, 143L,  NA_real_,  NA_real_, NA_real_, "estimated",
  "Static FE Model 2 (+conf/COV)", 10.83,  4.03,  0.009, 143L,  NA_real_,  NA_real_, NA_real_, "estimated"
)

# Combine Bond bounds + static FE + GMM
bond_tri <- bond_df |>
  mutate(hansen_p = NA_real_, ar1_p = NA_real_, ar2_p = NA_real_, status = "estimated") |>
  select(estimator, beta, se, p, n, hansen_p, ar1_p, ar2_p, status)

triangulation <- bind_rows(static_fe, bond_tri, gmm_results) |>
  mutate(across(c(beta, se), \(x) round(x, 3)),
         p = round(p, 4))

print(triangulation)
readr::write_csv(triangulation, "output/tables/model2_identification_triangulation.csv")

# Markdown version
tri_md <- c(
  "**Table 5. Model 2 -Identification triangulation (PAP-0010 evidence).**",
  "",
  "Coefficient on `log(1 + CRS_disburse_defl_MA3)` across estimators. All on cycle-indexed HCI panel.",
  "",
  knitr::kable(triangulation, format = "pipe",
               col.names = c("Estimator", "β", "SE", "p", "N", "Hansen p", "AR(1) p", "AR(2) p", "status")),
  "",
  "**Reading:** Bond (2002) consistency bound -true persistence parameter ρ lies between (A) Pooled OLS w/ lagged DV (upward biased by ignored heterogeneity) and (B) Within FE w/ lagged DV (downward biased by Nickell). If GMM β on log(1+CRS) sits within the Bond range for the ODA effect, GMM is credible.",
  "",
  "**Diagnostic targets per Roodman (2009):** Hansen p ∈ (0.10, 0.99); AR(1) p < 0.05; AR(2) p > 0.10; instrument count < N.",
  "",
  "GMM identification: " ,
  "- Hansen p < 0.10 = instrument over-identification rejected (GMM unreliable)",
  "- AR(2) p < 0.10 = second-order autocorrelation in differences (lagged-DV instruments invalid)",
  "- NA on AR(2) = test could not compute (typically T_eff too small)",
  "",
  "Cycle index used because HCI cycle calendar-year spacing is non-uniform (2010→2017 = 7yr; 2017→2018 = 1yr); calendar-year lag operators produce all-NA results on the cycle-restricted panel."
)
writeLines(tri_md, "output/tables/model2_identification_triangulation.md")
message("[gmm] wrote model2_identification_triangulation.{csv,md}")

# === 6. Coefficient plot ======================================================
message("\n[gmm] building coefficient plot")

plot_data <- triangulation |>
  filter(!is.na(beta)) |>
  mutate(
    ci_lo = beta - 1.96 * se,
    ci_hi = beta + 1.96 * se,
    estimator = factor(estimator, levels = rev(estimator))
  )

p <- ggplot(plot_data, aes(x = beta, y = estimator)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi), size = 0.4, linewidth = 0.6,
                   color = "#762A83") +
  labs(title = "Model 2 identification triangulation",
       subtitle = "Coefficient on log(1 + CRS_disburse_defl_MA3) across estimators; 95% CIs",
       x = "Coefficient (HLO score points per unit log CRS)", y = NULL,
       caption = "Static FE = the headline baseline; Bond bounds = OLS-LDV (upper) + LSDV (lower); GMM = Difference + System (cycle-indexed).") +
  theme_minimal(base_size = 10) +
  theme(plot.subtitle = element_text(color = "grey30", size = 9),
        plot.caption = element_text(color = "grey40", size = 8, hjust = 0))

dir.create("output/figures/eda", recursive = TRUE, showWarnings = FALSE)
ggsave("output/figures/eda/model2_gmm_coefficient_plot.pdf", p, width = 10, height = 6)
ggsave("output/figures/eda/model2_gmm_coefficient_plot.png", p, width = 10, height = 6, dpi = 150)
message("[gmm] wrote model2_gmm_coefficient_plot.{pdf,png}")

# === 7. PAP-0010 path determination ===========================================
message("\n[gmm] determining PAP-0010 lock path")

clean_gmm_count <- sum(gmm_results$status == "estimated" &
                        !is.na(gmm_results$hansen_p) &
                        gmm_results$hansen_p > 0.10 &
                        gmm_results$hansen_p < 0.99 &
                        !is.na(gmm_results$ar2_p) &
                        gmm_results$ar2_p > 0.10, na.rm = TRUE)
estimated_count <- sum(gmm_results$status == "estimated", na.rm = TRUE)

cat("\n=== PAP-0010 lock evidence ===\n")
cat("GMM specifications that ran:", estimated_count, "of 4\n")
cat("GMM specs passing diagnostic targets (Hansen ∈ (0.10, 0.99) AND AR(2) > 0.10):", clean_gmm_count, "\n")

if (clean_gmm_count >= 2) {
  adr_path <- "Path 1: GMM clean -Option 1 (System GMM as headline robustness)"
} else if (estimated_count >= 1) {
  adr_path <- "Path 2: GMM ran but diagnostics fail -Option 1 with caveats"
} else {
  adr_path <- "Path 3: GMM infeasible -Option 4 modified (static FE + Bond floor as identification defense)"
}
cat("→ PAP-0010 lock path:", adr_path, "\n")

# Print headline numbers
cat("\n=== Headline triangulation numbers (for the manuscript) ===\n")
print(triangulation |> select(estimator, beta, se, p, hansen_p, ar2_p))

message("\n[gmm] complete.")
