# R/54_model2_china_robustness.R
#
# PAP-0008 lock — Chinese aid (AidData GCDF) inclusion
# sensitivity. Tests whether the locked treatment spec
# (`crs_disburse_usd_defl_ma3_lag1`) is robust to including Chinese
# development finance.
#
# Four specs × two outcomes × two samples (all / SSA-only) = 16 feols fits.
#
# Spec A — OECD-only baseline (the locked encoding):
#   HLO ~ log(1 + CRS_disburse_strict)
# Spec B — OECD + GCDF as separate covariate (lock criterion test):
#   HLO ~ log(1 + CRS_disburse_strict) + log(1 + GCDF_strict)
# Spec C — Combined treatment:
#   HLO ~ log(1 + CRS_disburse_strict + GCDF_strict)
# Spec D — GCDF-only treatment:
#   HLO ~ log(1 + GCDF_strict)
#
# All on full headline 2e control stack (log GDP/cap + PTR primary +
# ed_exp_%GDP + WGI gov effectiveness), two-way FE (iso3 + year),
# country-clustered SE, primary window 2010-2020.
#
# SSA classification: countrycode::codelist filter (same source as
# R/40_eda_audit.R:224-227).
#
# Outputs:
#   output/tables/model2_china_robustness.{csv,md}
#   output/figures/eda/model2_china_robustness_plot.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(countrycode)
})

PANEL_PATH    <- "data/interim/panel.parquet"
OUT_CSV       <- "output/tables/model2_china_robustness.csv"
OUT_MD        <- "output/tables/model2_china_robustness.md"
OUT_PLOT_PDF  <- "output/figures/eda/model2_china_robustness_plot.pdf"
OUT_PLOT_PNG  <- "output/figures/eda/model2_china_robustness_plot.png"

CRS_TREAT  <- "crs_disburse_usd_defl_ma3_lag1"        # the locked encoding
GCDF_TREAT <- "gcdf_amount_const2021_ma3_lag1"        # NEW the GCDF column

# === 1. Setup ================================================================
message("[m2-china] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

# SSA classification — same source as R/40_eda_audit.R
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |> na.omit() |> unique()

d <- d |> mutate(
  log_gdp_pc        = log(wdi_gdp_pc_usd),
  is_ssa            = iso3 %in% ssa_iso3,
  crs_strict        = .data[[CRS_TREAT]],
  gcdf_strict       = .data[[GCDF_TREAT]],
  combined_strict   = crs_strict + gcdf_strict,
  log_crs           = log1p(crs_strict),
  log_gcdf          = log1p(gcdf_strict),
  log_combined      = log1p(combined_strict)
)

n_ssa_in_universe <- sum(unique(d$iso3) %in% ssa_iso3)
message(sprintf("[m2-china] SSA countries in panel: %d / %d universe",
                n_ssa_in_universe, length(unique(d$iso3))))

# === 2. Spec definitions =====================================================
# Each spec: a custom RHS string for feols.
controls_rhs <- "log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_ge_est"

spec_defs <- tribble(
  ~spec_id, ~spec_label,                       ~treatment_rhs,
  "A",      "OECD-only (the locked encoding)",     "log_crs",
  "B",      "OECD + GCDF (lock criterion test)", "log_crs + log_gcdf",
  "C",      "Combined OECD+GCDF treatment",    "log_combined",
  "D",      "GCDF-only treatment",             "log_gcdf"
)

outcomes <- c("hlo_hlo_score", "hci_lays_overall")
samples  <- c("ALL", "SSA")

# === 3. Fit one cell =========================================================
# Returns one row per coefficient of interest. Spec B has 2 coefficients of
# interest (CRS and GCDF); all others have 1.
fit_cell <- function(spec_id, spec_label, treatment_rhs, outcome, sample_id, data) {
  d_use <- if (sample_id == "SSA") data |> filter(is_ssa) else data
  fml <- as.formula(sprintf("%s ~ %s + %s | iso3 + year",
                            outcome, treatment_rhs, controls_rhs))
  m <- feols(fml, data = d_use, vcov = ~iso3)

  # Coefficients of interest: log_crs, log_gcdf, log_combined (whichever appears in formula)
  coefs_of_interest <- intersect(c("log_crs", "log_gcdf", "log_combined"), names(coef(m)))
  bind_rows(lapply(coefs_of_interest, function(cn) {
    tibble(
      spec_id     = spec_id,
      spec_label  = spec_label,
      outcome     = outcome,
      sample      = sample_id,
      coef_name   = cn,
      N           = m$nobs,
      beta        = unname(coef(m)[cn]),
      se          = unname(sqrt(diag(vcov(m)))[cn]),
      p_value     = unname(fixest::pvalue(m)[cn])
    )
  }))
}

# === 4. Loop over (spec × outcome × sample) grid ============================
message("[m2-china] fitting 4 × 2 × 2 = 16 specs")

grid <- expand_grid(
  spec_defs,
  outcome = outcomes,
  sample  = samples
)

results <- pmap_dfr(
  list(grid$spec_id, grid$spec_label, grid$treatment_rhs,
       grid$outcome, grid$sample),
  function(spec_id, spec_label, treatment_rhs, outcome, sample) {
    fit_cell(spec_id, spec_label, treatment_rhs, outcome, sample, d)
  }
) |>
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
    ),
    coef_label = case_when(
      coef_name == "log_crs"      ~ "log(1+CRS_strict)",
      coef_name == "log_gcdf"     ~ "log(1+GCDF_strict)",
      coef_name == "log_combined" ~ "log(1+CRS+GCDF strict)"
    )
  ) |>
  select(spec_id, spec_label, outcome_label, sample, coef_label,
         N, beta, se, p_value, signif)

# === 5. Validation: spec A reproduces the locked encoding ========================
baseline_cell <- results |>
  filter(spec_id == "A", outcome_label == "HLO", sample == "ALL")
cat("\n=== Validation: spec A (OECD-only, all-sample, HLO) ===\n")
cat(sprintf("the locked encoding:   β=8.170,  SE=4.912, p=0.1015, N=143\n"))
cat(sprintf("New spec A:        β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            baseline_cell$beta, baseline_cell$se, baseline_cell$p_value, baseline_cell$N))

# === 6. Write tables =========================================================
dir.create(dirname(OUT_CSV), recursive = TRUE, showWarnings = FALSE)

results_round <- results |>
  mutate(
    beta    = round(beta, 3),
    se      = round(se, 3),
    p_value = round(p_value, 4)
  )
readr::write_csv(results_round, OUT_CSV)
message(sprintf("[m2-china] wrote %s", OUT_CSV))

# Markdown view: 1 table per outcome × sample combo
md_lines <- c(
  "# Model 2 FE — Chinese aid robustness (PAP-0008 lock)",
  "",
  "Within-country two-way FE (iso3 + year). Country-clustered SE. Controls: log(GDP/cap), PTR primary, ed_exp_%GDP, WGI gov effectiveness. Primary window 2010-2020. Treatment columns enter as `log(1 + x)`; all use the locked encoding encoding (strictly-past 3-yr MA, constant USD).",
  "",
  "Stars: ***p<0.01, **p<0.05, *p<0.1.",
  ""
)
for (oc_lab in c("HLO", "LAYS")) {
  for (smp in c("ALL", "SSA")) {
    md_lines <- c(md_lines,
      sprintf("## %s outcome — %s sample", oc_lab, smp),
      "",
      knitr::kable(
        results_round |>
          filter(outcome_label == oc_lab, sample == smp) |>
          select(spec_id, spec_label, coef_label, N, beta, se, p_value, signif),
        format = "pipe",
        align  = c("l", "l", "l", "r", "r", "r", "r", "l")
      ),
      ""
    )
  }
}
writeLines(md_lines, OUT_MD)
message(sprintf("[m2-china] wrote %s", OUT_MD))

# === 7. Coefficient plot =====================================================
message("[m2-china] building coefficient plot")

plot_df <- results |>
  mutate(
    spec_id    = factor(spec_id, levels = c("A", "B", "C", "D")),
    coef_label = factor(coef_label,
                        levels = c("log(1+CRS_strict)",
                                   "log(1+GCDF_strict)",
                                   "log(1+CRS+GCDF strict)")),
    sample     = factor(sample, levels = c("ALL", "SSA")),
    ci_lo      = beta - 1.96 * se,
    ci_hi      = beta + 1.96 * se
  )

p_coef <- ggplot(plot_df,
                 aes(x = beta, y = interaction(coef_label, spec_id, sep = " | "),
                     color = sample, shape = sample)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.5),
                   size = 0.4, linewidth = 0.6) +
  facet_wrap(~ outcome_label, scales = "free_x", ncol = 2,
             labeller = labeller(outcome_label = c(HLO = "HLO outcome",
                                                    LAYS = "LAYS outcome"))) +
  scale_color_manual(values = c("ALL" = "#1B7837", "SSA" = "#762A83")) +
  scale_shape_manual(values = c("ALL" = 16, "SSA" = 17)) +
  labs(
    title    = "PAP-0008 lock: Chinese aid inclusion sensitivity (Model 2 FE)",
    subtitle = "All vs SSA-only samples; 95% CIs (country-clustered SE). Specs A/B/C/D on the locked treatment encoding.",
    x        = "Coefficient (HLO points or LAYS years per unit log treatment)",
    y        = "Coefficient | Spec",
    color    = "Sample",
    shape    = "Sample",
    caption  = "A=OECD-only (lock), B=OECD+GCDF, C=combined treatment, D=GCDF-only. SSA via countrycode::codelist."
  ) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 12, height = 7)
ggsave(OUT_PLOT_PNG, p_coef, width = 12, height = 7, dpi = 150)
message(sprintf("[m2-china] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 8. Summary to stdout ===================================================
cat("\n=== HLO — ALL sample ===\n")
print(results_round |> filter(outcome_label == "HLO", sample == "ALL") |>
        select(spec_id, coef_label, N, beta, se, p_value, signif), n = 10)
cat("\n=== HLO — SSA sample ===\n")
print(results_round |> filter(outcome_label == "HLO", sample == "SSA") |>
        select(spec_id, coef_label, N, beta, se, p_value, signif), n = 10)
cat("\n=== LAYS — ALL sample ===\n")
print(results_round |> filter(outcome_label == "LAYS", sample == "ALL") |>
        select(spec_id, coef_label, N, beta, se, p_value, signif), n = 10)
cat("\n=== LAYS — SSA sample ===\n")
print(results_round |> filter(outcome_label == "LAYS", sample == "SSA") |>
        select(spec_id, coef_label, N, beta, se, p_value, signif), n = 10)

message("\n[m2-china] complete.")
