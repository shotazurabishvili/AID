# R/55_model2_wgi_operationalization.R
#
# Phase 5 Session 05: ADR-0009 lock — WGI operationalization sensitivity.
#
# Four specs × two outcomes = 8 feols fits. All on the Session-03 locked
# treatment: log(1 + crs_disburse_usd_defl_ma3_lag1). Base controls:
# log(GDP/cap) + PTR primary + ed_exp_%GDP. WGI representation varies:
#
#   A — Single composite:  wgi_ge_est  (Session-03 baseline; current default)
#   B — All six aggregates: VA + PV + GE + RQ + RL + CC
#   C — PCA-collapsed:      wgi_pc1 (first PC of the six, scaled, sign-flipped
#                                     so wgi_ge_est loading is positive)
#   D — No WGI control:    drop WGI from RHS
#
# Engages Langbein & Knack (2010): "WGI dimensions collapse to essentially one
# factor; reporting all six is largely redundant." We test this empirically:
# PC1 variance share + per-dimension VIF on spec B (demeaned) + β_ODA stability
# across representations.
#
# Outputs:
#   output/tables/model2_wgi_specs.{csv,md}      — 8-row sensitivity table
#   output/tables/model2_wgi_vif.csv             — VIF audit on spec B
#   output/tables/model2_wgi_pca_loadings.csv    — PC1 loadings + variance share
#   output/figures/eda/model2_wgi_plot.{pdf,png} — coefficient plot

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(car)
})

PANEL_PATH       <- "data/interim/panel.parquet"
OUT_SPECS_CSV    <- "output/tables/model2_wgi_specs.csv"
OUT_SPECS_MD     <- "output/tables/model2_wgi_specs.md"
OUT_VIF_CSV      <- "output/tables/model2_wgi_vif.csv"
OUT_LOADINGS_CSV <- "output/tables/model2_wgi_pca_loadings.csv"
OUT_PLOT_PDF     <- "output/figures/eda/model2_wgi_plot.pdf"
OUT_PLOT_PNG     <- "output/figures/eda/model2_wgi_plot.png"

CRS_TREAT <- "crs_disburse_usd_defl_ma3_lag1"   # Session-03 lock
WGI_DIMS  <- c("wgi_va_est", "wgi_pv_est", "wgi_ge_est",
               "wgi_rq_est", "wgi_rl_est", "wgi_cc_est")

# === 1. Setup =================================================================
message("[m2-wgi] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

d <- d |> mutate(
  log_crs    = log1p(.data[[CRS_TREAT]]),
  log_gdp_pc = log(wdi_gdp_pc_usd)
)

message(sprintf("[m2-wgi] panel: %d rows × %d cols (primary window)",
                nrow(d), ncol(d)))

# === 2. Compute PC1 of the six WGI dimensions ================================
# Use rows where all 6 dimensions are non-NA. The joint-population pre-check
# (Session-05 plan verification) found 1462/1463 primary-window rows have all 6.
wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
complete_rows <- complete.cases(wgi_mat)
cat(sprintf("\n[m2-wgi] WGI joint-availability: %d / %d primary-window rows\n",
            sum(complete_rows), nrow(d)))

pca_input <- wgi_mat[complete_rows, ]
pca <- prcomp(pca_input, scale. = TRUE, center = TRUE)
var_share <- (pca$sdev^2) / sum(pca$sdev^2)

# Conventional sign-flip: ensure wgi_ge_est has POSITIVE loading on PC1
ge_loading_pc1 <- pca$rotation["wgi_ge_est", "PC1"]
if (ge_loading_pc1 < 0) {
  message("[m2-wgi] flipping PC1 sign so wgi_ge_est loading is positive")
  pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
  pca$x[, "PC1"]        <- -pca$x[, "PC1"]
}

# Verify all loadings on PC1 are same-sign after flip
pc1_loadings <- pca$rotation[, "PC1"]
all_positive <- all(pc1_loadings > 0)
cat(sprintf("[m2-wgi] PC1 variance share: %.3f  | all loadings positive after sign-flip: %s\n",
            var_share[1], all_positive))

# Attach PC1 scores back to d (NA for any row missing any dimension)
d$wgi_pc1 <- NA_real_
d$wgi_pc1[complete_rows] <- pca$x[, "PC1"]

# Loadings + variance share table
loadings_df <- tibble(
  dimension     = rownames(pca$rotation),
  pc1_loading   = round(pc1_loadings, 4),
  pc2_loading   = round(pca$rotation[, "PC2"], 4),
  pc3_loading   = round(pca$rotation[, "PC3"], 4)
)
var_share_df <- tibble(
  component   = paste0("PC", 1:6),
  variance    = round(pca$sdev^2, 4),
  prop_var    = round(var_share, 4),
  cum_prop    = round(cumsum(var_share), 4)
)
dir.create(dirname(OUT_LOADINGS_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(loadings_df, OUT_LOADINGS_CSV)
readr::write_csv(var_share_df,
                 sub("\\.csv$", "_variance.csv", OUT_LOADINGS_CSV))
cat("\n=== PC1 loadings (post sign-flip) ===\n")
print(loadings_df)
cat("\n=== Variance share by PC ===\n")
print(var_share_df)

# === 3. Spec definitions ======================================================
controls_base <- "log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp"

spec_defs <- tribble(
  ~spec_id, ~spec_label,                                    ~wgi_rhs,
  "A",      "Single composite (Session-03 baseline)",       "wgi_ge_est",
  "B",      "All six WGI aggregates",                       paste(WGI_DIMS, collapse = " + "),
  "C",      "PCA-collapsed (PC1, scale=TRUE)",              "wgi_pc1",
  "D",      "No WGI control",                               NA_character_
)
outcomes <- c("hlo_hlo_score", "hci_lays_overall")

# === 4. Fit one cell ==========================================================
fit_cell <- function(spec_id, spec_label, wgi_rhs, outcome, data) {
  rhs_terms <- c("log_crs", controls_base)
  if (!is.na(wgi_rhs)) rhs_terms <- c(rhs_terms, wgi_rhs)
  fml <- as.formula(sprintf("%s ~ %s | iso3 + year",
                            outcome, paste(rhs_terms, collapse = " + ")))
  m <- feols(fml, data = data, vcov = ~iso3)

  tibble(
    spec_id    = spec_id,
    spec_label = spec_label,
    outcome    = outcome,
    N          = m$nobs,
    beta_oda   = unname(coef(m)["log_crs"]),
    se_oda     = unname(sqrt(diag(vcov(m)))["log_crs"]),
    p_oda      = unname(fixest::pvalue(m)["log_crs"]),
    r2_within  = unname(fitstat(m, "wr2", verbose = FALSE)$wr2)
  )
}

# === 5. Loop over (spec × outcome) grid ======================================
message("\n[m2-wgi] fitting 4 × 2 = 8 specs")

grid <- expand_grid(spec_defs, outcome = outcomes)

results <- pmap_dfr(
  list(grid$spec_id, grid$spec_label, grid$wgi_rhs, grid$outcome),
  function(spec_id, spec_label, wgi_rhs, outcome) {
    fit_cell(spec_id, spec_label, wgi_rhs, outcome, d)
  }
) |>
  mutate(
    signif = case_when(
      p_oda < 0.01 ~ "***",
      p_oda < 0.05 ~ "**",
      p_oda < 0.10 ~ "*",
      TRUE         ~ ""
    ),
    outcome_label = case_when(
      outcome == "hlo_hlo_score"    ~ "HLO",
      outcome == "hci_lays_overall" ~ "LAYS"
    )
  ) |>
  select(spec_id, spec_label, outcome_label,
         N, beta_oda, se_oda, p_oda, signif, r2_within)

# === 6. Spec A reproducibility check =========================================
spec_a_hlo <- results |> filter(spec_id == "A", outcome_label == "HLO")
cat("\n=== Validation: spec A (single GE, HLO) ===\n")
cat(sprintf("Session-03 lock:   β=8.170, SE=4.912, p=0.1015, N=143\n"))
cat(sprintf("New spec A:        β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            spec_a_hlo$beta_oda, spec_a_hlo$se_oda, spec_a_hlo$p_oda, spec_a_hlo$N))

# === 7. VIF audit on spec B (all six WGI dimensions) =========================
# Mirror Session-14 pattern: demean by country + year, then lm + car::vif on
# demeaned regressors.
demean <- function(df, group_cols, value_cols) {
  for (col in value_cols) {
    grand_mean <- mean(df[[col]], na.rm = TRUE)
    df[[col]] <- df[[col]] -
      ave(df[[col]], df[[group_cols[1]]], FUN = function(x) mean(x, na.rm = TRUE)) -
      ave(df[[col]], df[[group_cols[2]]], FUN = function(x) mean(x, na.rm = TRUE)) +
      grand_mean
  }
  df
}

regressors_b <- c("log_crs", "log_gdp_pc", "wdi_ptr_primary",
                  "wdi_edu_exp_pct_gdp", WGI_DIMS)
vif_data <- d |>
  select(iso3, year, hlo_hlo_score, all_of(regressors_b)) |>
  na.omit() |>
  as.data.frame()
vif_demean <- demean(vif_data, c("iso3","year"), regressors_b)
m_lm_demean <- lm(as.formula(paste("hlo_hlo_score ~",
                                    paste(regressors_b, collapse = " + "))),
                  data = vif_demean)
vifs <- tryCatch(car::vif(m_lm_demean),
                  error = function(e) {
                    message("[m2-wgi] VIF on spec B failed: ", conditionMessage(e))
                    NULL
                  })

if (!is.null(vifs)) {
  vif_df <- tibble(variable = names(vifs), vif_demeaned = round(vifs, 3)) |>
    arrange(desc(vif_demeaned))
  cat("\n=== VIF audit on spec B (all six WGI dimensions, demeaned) ===\n")
  print(vif_df)
  readr::write_csv(vif_df, OUT_VIF_CSV)
  message(sprintf("[m2-wgi] wrote %s", OUT_VIF_CSV))
  cat(sprintf("\n[m2-wgi] Max VIF on spec B (demeaned): %.3f (variable: %s)\n",
              max(vifs), names(vifs)[which.max(vifs)]))
}

# === 8. Per-dimension WGI coefficients in spec B =============================
# Pull from a refit of spec B on the full data sample (feols already does this)
m_b_hlo <- feols(
  as.formula(paste("hlo_hlo_score ~ log_crs +", controls_base, "+",
                   paste(WGI_DIMS, collapse = " + "),
                   "| iso3 + year")),
  data = d, vcov = ~iso3
)
wgi_coefs_b <- tibble(
  dimension = WGI_DIMS,
  beta      = round(unname(coef(m_b_hlo)[WGI_DIMS]), 3),
  se        = round(unname(sqrt(diag(vcov(m_b_hlo)))[WGI_DIMS]), 3),
  p_value   = round(unname(fixest::pvalue(m_b_hlo)[WGI_DIMS]), 4)
) |>
  mutate(signif = case_when(
    p_value < 0.01 ~ "***",
    p_value < 0.05 ~ "**",
    p_value < 0.10 ~ "*",
    TRUE           ~ ""
  ))

cat("\n=== Spec B: per-dimension WGI coefficients on HLO ===\n")
print(wgi_coefs_b)
readr::write_csv(wgi_coefs_b,
                 sub("\\.csv$", "_dim_coefs.csv", OUT_VIF_CSV))

# === 9. Write specs table ====================================================
results_round <- results |>
  mutate(
    beta_oda  = round(beta_oda, 3),
    se_oda    = round(se_oda, 3),
    p_oda     = round(p_oda, 4),
    r2_within = round(r2_within, 4)
  )
readr::write_csv(results_round, OUT_SPECS_CSV)
message(sprintf("\n[m2-wgi] wrote %s", OUT_SPECS_CSV))

md_lines <- c(
  "# Model 2 FE — WGI operationalization sensitivity (ADR-0009 lock)",
  "",
  "Within-country two-way FE (iso3 + year). Country-clustered SE. Treatment: `log(1 + crs_disburse_usd_defl_ma3_lag1)` (Session-03 lock). Base controls: log(GDP/cap) + PTR primary + ed_exp_%GDP. WGI varies across specs A-D. Primary window 2010-2020.",
  "",
  sprintf("PC1 variance share: %.3f. All six PC1 loadings positive after sign-flip: %s.",
          var_share[1], all_positive),
  "",
  "## ODA coefficient across WGI representations",
  ""
)
for (oc_lab in c("HLO", "LAYS")) {
  md_lines <- c(md_lines,
    sprintf("### %s outcome", oc_lab),
    "",
    knitr::kable(
      results_round |> filter(outcome_label == oc_lab) |>
        select(spec_id, spec_label, N, beta_oda, se_oda, p_oda, signif, r2_within),
      format = "pipe",
      align  = c("l", "l", "r", "r", "r", "r", "l", "r")
    ),
    ""
  )
}
md_lines <- c(md_lines,
  "## Per-dimension WGI coefficients in spec B (HLO)",
  "",
  knitr::kable(wgi_coefs_b, format = "pipe",
               align = c("l", "r", "r", "r", "l")),
  ""
)
writeLines(md_lines, OUT_SPECS_MD)
message(sprintf("[m2-wgi] wrote %s", OUT_SPECS_MD))

# === 10. Coefficient plot ====================================================
plot_df <- results |>
  mutate(
    spec_label_short = case_when(
      spec_id == "A" ~ "A — Single GE",
      spec_id == "B" ~ "B — All six WGI",
      spec_id == "C" ~ "C — PCA (PC1)",
      spec_id == "D" ~ "D — No WGI"
    ),
    spec_label_short = factor(spec_label_short,
                              levels = c("A — Single GE", "B — All six WGI",
                                         "C — PCA (PC1)", "D — No WGI")),
    ci_lo = beta_oda - 1.96 * se_oda,
    ci_hi = beta_oda + 1.96 * se_oda
  )

p_coef <- ggplot(plot_df,
                 aes(x = beta_oda, y = spec_label_short, color = outcome_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.4),
                   size = 0.5, linewidth = 0.7) +
  scale_color_manual(values = c("HLO" = "#1B7837", "LAYS" = "#762A83")) +
  labs(
    title    = "ADR-0009 lock: WGI operationalization sensitivity (Model 2 FE)",
    subtitle = "β on log(1+CRS_strict) across 4 WGI specs; 95% CIs (country-clustered SE)",
    x        = "ODA coefficient",
    y        = "WGI representation",
    color    = "Outcome",
    caption  = sprintf("Specs: A single GE, B all six, C PC1 (var=%.0f%%), D no WGI. Session-03 lock treatment.",
                       var_share[1] * 100)
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 10, height = 5)
ggsave(OUT_PLOT_PNG, p_coef, width = 10, height = 5, dpi = 150)
message(sprintf("[m2-wgi] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 11. Summary to stdout ===================================================
cat("\n=== HLO outcome (primary lock surface) ===\n")
print(results_round |> filter(outcome_label == "HLO") |>
        select(spec_id, spec_label, N, beta_oda, se_oda, p_oda, signif), n = 4)

cat("\n=== LAYS outcome (robustness) ===\n")
print(results_round |> filter(outcome_label == "LAYS") |>
        select(spec_id, spec_label, N, beta_oda, se_oda, p_oda, signif), n = 4)

message("\n[m2-wgi] complete.")
