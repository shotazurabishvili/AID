# R/52_model2_fe_sensitivity.R
#
# PAP-0005 lock — sensitivity of Model 2 (within-country FE)
# to treatment encoding. Sixteen treatment columns:
#
#     commit  | disburse  ×  current USD | constant USD  ×  {raw, lag1, ma3, ma3_lag1}
#
# Where ma3 = trailing-inclusive (mean of t-2,t-1,t) and ma3_lag1 = strictly-past
# (mean of t-3,t-2,t-1). All controls match Session-14 spec 2e (full controls,
# pre-conflict/COVID): log(GDP/cap) + PTR primary + ed_exp_%GDP + WGI gov_effect.
# Two outcomes: hlo_hlo_score (primary, lock surface) + hci_lays_overall
# (secondary robustness panel).
#
# Outputs:
#   output/tables/model2_fe_sensitivity.{csv,md}   (32 rows: 16 specs × 2 outcomes)
#   output/figures/eda/model2_fe_sensitivity_plot.{pdf,png}
#
# Does NOT modify R/51_model2_fe.R. Session-14 baseline outputs remain intact;
# this script's `disburse × constant USD × ma3 × HLO` cell must reproduce the
# Session-14 2e coefficient to 3 decimals (validation check).

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
})

PANEL_PATH    <- "data/interim/panel.parquet"
OUT_CSV       <- "output/tables/model2_fe_sensitivity.csv"
OUT_MD        <- "output/tables/model2_fe_sensitivity.md"
OUT_PLOT_PDF  <- "output/figures/eda/model2_fe_sensitivity_plot.pdf"
OUT_PLOT_PNG  <- "output/figures/eda/model2_fe_sensitivity_plot.png"

# === 1. Setup =================================================================
message("[model2-sens] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

d <- d |> mutate(
  covid_days_recode = ifelse(year < 2020 & is.na(covid_days_closed), 0, covid_days_closed),
  log_gdp_pc        = log(wdi_gdp_pc_usd)
)

message(sprintf("[model2-sens] panel: %d rows × %d cols (primary window)",
                nrow(d), ncol(d)))

# === 2. Spec grid =============================================================
spec_grid <- tribble(
  ~family,    ~usd_basis,   ~transform,    ~treatment_col,
  "commit",   "current",    "raw",         "crs_commit_usd_sum",
  "commit",   "constant",   "raw",         "crs_commit_usd_defl_sum",
  "commit",   "current",    "lag1",        "crs_commit_usd_lag1",
  "commit",   "constant",   "lag1",        "crs_commit_usd_defl_lag1",
  "commit",   "current",    "ma3",         "crs_commit_usd_ma3",
  "commit",   "constant",   "ma3",         "crs_commit_usd_defl_ma3",
  "commit",   "current",    "ma3_lag1",    "crs_commit_usd_ma3_lag1",
  "commit",   "constant",   "ma3_lag1",    "crs_commit_usd_defl_ma3_lag1",
  "disburse", "current",    "raw",         "crs_disburse_usd_sum",
  "disburse", "constant",   "raw",         "crs_disburse_usd_defl_sum",
  "disburse", "current",    "lag1",        "crs_disburse_usd_lag1",
  "disburse", "constant",   "lag1",        "crs_disburse_usd_defl_lag1",
  "disburse", "current",    "ma3",         "crs_disburse_usd_ma3",
  "disburse", "constant",   "ma3",         "crs_disburse_usd_defl_ma3",
  "disburse", "current",    "ma3_lag1",    "crs_disburse_usd_ma3_lag1",
  "disburse", "constant",   "ma3_lag1",    "crs_disburse_usd_defl_ma3_lag1"
)

stopifnot(all(spec_grid$treatment_col %in% names(d)))
message(sprintf("[model2-sens] 16-cell grid validated against panel columns"))

# === 3. Fit one cell ==========================================================
# Full controls = Session-14 spec 2e. No conflict/COVID — those are time-varying
# confounders relevant to 2g; for the encoding-sensitivity question we keep the
# control stack fixed at 2e to isolate treatment-side variance.
fit_cell <- function(treatment_col, outcome_col, data) {
  data$log_treatment <- log1p(data[[treatment_col]])
  fml <- as.formula(sprintf(
    "%s ~ log_treatment + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est | iso3 + year",
    outcome_col
  ))
  m <- feols(fml, data = data, vcov = ~iso3)
  tibble(
    N         = m$nobs,
    beta      = unname(coef(m)["log_treatment"]),
    se        = unname(sqrt(diag(vcov(m)))["log_treatment"]),
    p_value   = unname(fixest::pvalue(m)["log_treatment"]),
    r2_within = unname(fitstat(m, "wr2", verbose = FALSE)$wr2),
    r2        = unname(fitstat(m, "r2",  verbose = FALSE)$r2)
  )
}

# === 4. Loop over (spec × outcome) grid =======================================
message("[model2-sens] fitting 16 × 2 = 32 specs")

outcomes <- c("hlo_hlo_score", "hci_lays_overall")

results <- expand_grid(spec_grid, outcome = outcomes) |>
  mutate(fit = pmap(list(treatment_col, outcome),
                    \(tc, oc) fit_cell(tc, oc, d))) |>
  unnest(fit) |>
  mutate(
    signif = case_when(
      p_value < 0.01 ~ "***",
      p_value < 0.05 ~ "**",
      p_value < 0.10 ~ "*",
      TRUE           ~ ""
    ),
    outcome_label = case_when(
      outcome == "hlo_hlo_score"    ~ "HLO",
      outcome == "hci_lays_overall" ~ "LAYS"
    )
  ) |>
  select(outcome_label, family, usd_basis, transform, treatment_col,
         N, beta, se, p_value, signif, r2_within, r2)

message("[model2-sens] all 32 specs fitted")

# === 5. Validation: baseline reproduces =======================================
# Session-14 spec 2e uses disburse × constant USD × ma3 × HLO.
baseline_cell <- results |>
  filter(outcome_label == "HLO",
         family == "disburse",
         usd_basis == "constant",
         transform == "ma3")

cat("\n=== Baseline reproducibility check ===\n")
cat(sprintf("Session-14 2e: β=10.953, SE=3.521, p=0.0030, N=143 (per output/tables/model2_fe_baseline.csv row 2e)\n"))
cat(sprintf("New (52) cell: β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            baseline_cell$beta, baseline_cell$se, baseline_cell$p_value, baseline_cell$N))

# === 6. Write tables ==========================================================
dir.create(dirname(OUT_CSV), recursive = TRUE, showWarnings = FALSE)

results_round <- results |>
  mutate(
    beta      = round(beta, 3),
    se        = round(se, 3),
    p_value   = round(p_value, 4),
    r2_within = round(r2_within, 4),
    r2        = round(r2, 4)
  )

readr::write_csv(results_round, OUT_CSV)
message(sprintf("[model2-sens] wrote %s", OUT_CSV))

# Markdown view: 16-row table per outcome
md_lines <- c(
  "# Model 2 FE — Treatment-encoding sensitivity (PAP-0005 lock)",
  "",
  "Within-country two-way FE (iso3 + year). Country-clustered SE. Controls: log(GDP/cap), PTR primary, ed_exp_%GDP, WGI gov effectiveness. Primary window 2010-2020.",
  "",
  "Treatment enters as `log(1 + x)`. Stars: ***p<0.01, **p<0.05, *p<0.1.",
  ""
)
for (oc_lab in c("HLO", "LAYS")) {
  md_lines <- c(md_lines,
    sprintf("## %s outcome", oc_lab),
    "",
    knitr::kable(
      results_round |> filter(outcome_label == oc_lab) |>
        select(family, usd_basis, transform, N, beta, se, p_value, signif, r2_within),
      format = "pipe",
      align  = c("l", "l", "l", "r", "r", "r", "r", "l", "r")
    ),
    ""
  )
}
writeLines(md_lines, OUT_MD)
message(sprintf("[model2-sens] wrote %s", OUT_MD))

# === 7. Coefficient plot ======================================================
message("[model2-sens] building coefficient plot")

# Order transforms with theoretical-defensibility ordering left→right
trans_levels <- c("raw", "ma3", "lag1", "ma3_lag1")
trans_labels <- c("raw" = "Raw (annual)",
                  "ma3" = "3-yr MA (trailing-inclusive)",
                  "lag1" = "1-yr lag",
                  "ma3_lag1" = "3-yr MA (strictly past)")

plot_df <- results |>
  mutate(
    transform = factor(transform, levels = trans_levels, labels = trans_labels[trans_levels]),
    family    = factor(family, levels = c("disburse", "commit"),
                       labels = c("Disbursement", "Commitment")),
    usd_basis = factor(usd_basis, levels = c("constant", "current"),
                       labels = c("Constant USD", "Current USD")),
    ci_lo = beta - 1.96 * se,
    ci_hi = beta + 1.96 * se
  )

p_coef <- ggplot(plot_df,
                 aes(x = beta, y = transform, color = family, shape = usd_basis)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.6),
                   size = 0.4, linewidth = 0.6) +
  facet_wrap(~ outcome_label, scales = "free_x", ncol = 2,
             labeller = labeller(outcome_label = c(HLO = "HLO outcome",
                                                    LAYS = "LAYS outcome"))) +
  scale_color_manual(values = c("Disbursement" = "#1B7837", "Commitment" = "#762A83")) +
  scale_shape_manual(values = c("Constant USD" = 16, "Current USD" = 1)) +
  labs(
    title    = "PAP-0005 sensitivity: Model 2 FE coefficient by treatment encoding",
    subtitle = "16 specs per outcome (2 families × 2 USD bases × 4 temporal transforms); 95% CIs (country-clustered SE)",
    x        = "ODA coefficient (HLO points or LAYS years per unit log treatment)",
    y        = NULL,
    color    = "Aid measure",
    shape    = "USD basis",
    caption  = "Controls: log(GDP/cap), PTR primary, ed_exp_%GDP, WGI gov effectiveness. Two-way FE (iso3 + year). N varies with treatment NA pattern."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 11, height = 6)
ggsave(OUT_PLOT_PNG, p_coef, width = 11, height = 6, dpi = 150)
message(sprintf("[model2-sens] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 8. Summary to stdout =====================================================
cat("\n=== HLO outcome (primary lock surface) ===\n")
hlo_view <- results_round |> filter(outcome_label == "HLO") |>
  select(family, usd_basis, transform, N, beta, se, p_value, signif)
print(hlo_view, n = 20)

cat("\n=== LAYS outcome (robustness panel) ===\n")
lays_view <- results_round |> filter(outcome_label == "LAYS") |>
  select(family, usd_basis, transform, N, beta, se, p_value, signif)
print(lays_view, n = 20)

message("\n[model2-sens] complete.")
