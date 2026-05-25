# R/50_model1_ols.R
#
# Model 1 — Cross-sectional OLS baseline.
#
# Purpose: establish the naive between-country association between education
# ODA and learning outcomes. This is the coefficient that the analysis Model 2
# (within-country FE) will challenge — the β_OLS vs β_FE contrast is the
# headline empirical story of the paper.
#
# Specification (sequential add):
#   1a: HLO ~ log(1+CRS_disburse)                                       (bivariate)
#   1b: + log(GDP/cap)
#   1c: + PTR primary
#   1d: + ed_exp_%GDP                                                   (brief's spec)
#   1e: + Gov_effect (WGI)                                              (full Model 1)
#   1f: + log(1+GCDF)                                                   (China robust)
#
# Parallel set with `hci_lays_overall` (LAYS) as outcome.
#
# SE: HC robust (one observation per country → cluster-robust = HC robust).
# VIF: parallel lm() fit; expect VIF > 5 on log(GDP/cap) + Gov_effect per
# r = 0.79 finding.
#
# Inputs:  data/interim/panel.parquet
# Outputs: output/tables/model1_ols_baseline.{csv,md}        (HLO outcome)
#          output/tables/model1_ols_lays_outcome.{csv,md}   (LAYS outcome)
#          output/tables/model1_vif.csv                     (VIF per spec)
#          output/figures/eda/model1_coefficient_plot.{pdf,png}
#
# ADR linkage: PAP-0002 universe, PAP-0003 primary window, PAP-0005 (Pending,
# disburse_defl primary intent), PAP-0006 (UIS controls dropped — Option 3).

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(modelsummary)
  library(car)
})

PANEL_PATH    <- "data/interim/panel.parquet"
OUT_HLO_CSV   <- "output/tables/model1_ols_baseline.csv"
OUT_HLO_MD    <- "output/tables/model1_ols_baseline.md"
OUT_LAYS_CSV  <- "output/tables/model1_ols_lays_outcome.csv"
OUT_LAYS_MD   <- "output/tables/model1_ols_lays_outcome.md"
OUT_VIF_CSV   <- "output/tables/model1_vif.csv"
OUT_PLOT_PDF  <- "output/figures/eda/model1_coefficient_plot.pdf"
OUT_PLOT_PNG  <- "output/figures/eda/model1_coefficient_plot.png"

# === 1. Setup: build country-level summary ====================================
message("[model1] loading production panel")
panel <- arrow::read_parquet(PANEL_PATH) |>
  filter(in_primary_window)

cm <- panel |>
  group_by(iso3) |>
  summarise(
    hlo                       = mean(hlo_hlo_score,              na.rm = TRUE),
    lays                      = mean(hci_lays_overall,           na.rm = TRUE),
    crs_disburse_defl_sum     = mean(crs_disburse_usd_defl_sum,  na.rm = TRUE),
    gcdf_amount_const2021_sum = mean(gcdf_amount_const2021_sum,  na.rm = TRUE),
    gdp_pc_usd                = mean(wdi_gdp_pc_usd,             na.rm = TRUE),
    ptr_primary               = mean(wdi_ptr_primary,            na.rm = TRUE),
    edu_exp_pct_gdp           = mean(wdi_edu_exp_pct_gdp,        na.rm = TRUE),
    wgi_ge_est                = mean(wgi_ge_est,                 na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(across(everything(), \(x) if (is.numeric(x)) ifelse(is.nan(x), NA_real_, x) else x))

# Log transforms
cm <- cm |>
  mutate(
    log_crs_disb = log1p(crs_disburse_defl_sum),
    log_gcdf     = log1p(gcdf_amount_const2021_sum),
    log_gdp_pc   = log(gdp_pc_usd)
  )

message(sprintf("[model1] country-level summary: %d countries", nrow(cm)))

# === 2. Run six HLO-outcome specs =============================================
message("[model1] fitting HLO-outcome specs")
m_hlo <- list()
m_hlo[["1a (bivariate)"]] <- feols(hlo ~ log_crs_disb,
                                    data = cm, vcov = "hetero")
m_hlo[["1b (+log GDP/cap)"]] <- feols(hlo ~ log_crs_disb + log_gdp_pc,
                                       data = cm, vcov = "hetero")
m_hlo[["1c (+PTR)"]]   <- feols(hlo ~ log_crs_disb + log_gdp_pc + ptr_primary,
                                 data = cm, vcov = "hetero")
m_hlo[["1d (+ed exp; brief spec)"]] <-
  feols(hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp,
        data = cm, vcov = "hetero")
m_hlo[["1e (+gov effect; full)"]] <-
  feols(hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est,
        data = cm, vcov = "hetero")
m_hlo[["1f (+log GCDF; China-robust)"]] <-
  feols(hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est + log_gcdf,
        data = cm, vcov = "hetero")

# === 3. Run parallel LAYS-outcome specs =======================================
message("[model1] fitting LAYS-outcome specs")
m_lays <- list()
m_lays[["1a"]] <- feols(lays ~ log_crs_disb, data = cm, vcov = "hetero")
m_lays[["1b"]] <- feols(lays ~ log_crs_disb + log_gdp_pc, data = cm, vcov = "hetero")
m_lays[["1c"]] <- feols(lays ~ log_crs_disb + log_gdp_pc + ptr_primary,
                         data = cm, vcov = "hetero")
m_lays[["1d"]] <- feols(lays ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp,
                         data = cm, vcov = "hetero")
m_lays[["1e"]] <- feols(lays ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est,
                         data = cm, vcov = "hetero")
m_lays[["1f"]] <- feols(lays ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est + log_gcdf,
                         data = cm, vcov = "hetero")

# === 4. VIF: parallel lm() fit per spec =======================================
message("[model1] computing VIFs (via parallel lm())")
specs <- list(
  "1b" = hlo ~ log_crs_disb + log_gdp_pc,
  "1c" = hlo ~ log_crs_disb + log_gdp_pc + ptr_primary,
  "1d" = hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp,
  "1e" = hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est,
  "1f" = hlo ~ log_crs_disb + log_gdp_pc + ptr_primary + edu_exp_pct_gdp + wgi_ge_est + log_gcdf
)
vif_table <- map_dfr(names(specs), function(s) {
  m <- lm(specs[[s]], data = cm)
  v <- car::vif(m)
  tibble(spec = s, variable = names(v), vif = round(unname(v), 2))
})
print(vif_table)
dir.create(dirname(OUT_VIF_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(vif_table, OUT_VIF_CSV)
message(sprintf("[model1] wrote %s", OUT_VIF_CSV))

max_vif <- max(vif_table$vif, na.rm = TRUE)
message(sprintf("[model1] max VIF across specs: %.2f", max_vif))

# === 5. Headline numbers for stdout ===========================================
m_full <- m_hlo[["1e (+gov effect; full)"]]
m_biv  <- m_hlo[["1a (bivariate)"]]

cat("\n=== Model 1 headline (HLO outcome) ===\n")
cat(sprintf("Bivariate spec (1a):  ODA β = %.3f (SE %.3f), p = %.4f, N = %d, R^2 = %.3f\n",
            coef(m_biv)["log_crs_disb"],
            sqrt(diag(m_biv$cov.scaled))["log_crs_disb"],
            fixest::pvalue(m_biv)["log_crs_disb"],
            m_biv$nobs,
            fitstat(m_biv, "r2")$r2))
cat(sprintf("Full spec (1e):       ODA β = %.3f (SE %.3f), p = %.4f, N = %d, Adj R^2 = %.3f\n",
            coef(m_full)["log_crs_disb"],
            sqrt(diag(m_full$cov.scaled))["log_crs_disb"],
            fixest::pvalue(m_full)["log_crs_disb"],
            m_full$nobs,
            fitstat(m_full, "ar2")$ar2))

# === 6. modelsummary tables ====================================================
coef_map <- c(
  "log_crs_disb"    = "log(1 + CRS disbursement, USD M)",
  "log_gdp_pc"      = "log(GDP per capita, USD)",
  "ptr_primary"     = "Pupil-teacher ratio (primary)",
  "edu_exp_pct_gdp" = "Govt education expenditure (% GDP)",
  "wgi_ge_est"      = "Govt effectiveness (WGI)",
  "log_gcdf"        = "log(1 + GCDF Chinese aid, USD)",
  "(Intercept)"     = "(Intercept)"
)
gm <- tibble::tribble(
  ~raw,           ~clean,     ~fmt,
  "nobs",         "N",        0,
  "r.squared",    "R^2",      3,
  "adj.r.squared","Adj R^2",  3,
  "F",            "F",        2
)

note_text <- paste0(
  "HC-robust SE in parentheses. Stars: ***p<0.01, **p<0.05, *p<0.1. ",
  "Sample: 133-country PAP-0002 universe, primary window 2010-2020 (PAP-0003); ",
  "country-level means across primary window. N varies by listwise completeness. ",
  sprintf("Max VIF across specs 1b-1f: %.2f.", max_vif),
  if (max_vif > 5) " VIF > 5 on log(GDP/cap) × Gov effectiveness (Pearson r = 0.79; ); PAP-0009 governs WGI operationalization." else ""
)

# HLO outcome table — write directly to files via modelsummary's output arg
dir.create(dirname(OUT_HLO_MD), recursive = TRUE, showWarnings = FALSE)
modelsummary(
  m_hlo,
  output = OUT_HLO_MD,
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3,
  notes = note_text,
  title = "Table 2. Model 1 — Cross-sectional OLS, HLO outcome (133 universe, primary window 2010-2020)."
)
ms_hlo_df <- modelsummary(
  m_hlo,
  output = "data.frame",
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3
)
readr::write_csv(ms_hlo_df, OUT_HLO_CSV)
message(sprintf("[model1] wrote %s and %s", OUT_HLO_CSV, OUT_HLO_MD))

# LAYS outcome table
modelsummary(
  m_lays,
  output = OUT_LAYS_MD,
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3,
  notes = paste0(note_text, " LAYS = EYS x HLO/625 (WB methodology); LAYS-outcome regressions are a metric translation of HLO-outcome results, not independent evidence."),
  title = "Table 2B. Model 1 — LAYS outcome (years), parallel specifications."
)
ms_lays_df <- modelsummary(
  m_lays,
  output = "data.frame",
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3
)
readr::write_csv(ms_lays_df, OUT_LAYS_CSV)
message(sprintf("[model1] wrote %s and %s", OUT_LAYS_CSV, OUT_LAYS_MD))

# === 7. Coefficient plot on log(1+CRS) =====================================
message("[model1] building coefficient plot")
coef_df <- map_dfr(names(m_hlo), function(nm) {
  m <- m_hlo[[nm]]
  est <- coef(m)["log_crs_disb"]
  se  <- sqrt(diag(m$cov.scaled))["log_crs_disb"]
  tibble(spec = nm, est = est, se = se,
         ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se,
         outcome = "HLO")
})
coef_df_lays <- map_dfr(names(m_lays), function(nm) {
  m <- m_lays[[nm]]
  est <- coef(m)["log_crs_disb"]
  se  <- sqrt(diag(m$cov.scaled))["log_crs_disb"]
  tibble(spec = nm, est = est, se = se,
         ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se,
         outcome = "LAYS (years)")
})
coef_df_lays$spec <- sub("(?<=^1[a-f]).*", "", coef_df_lays$spec, perl = TRUE)
coef_df_lays$spec <- names(m_hlo)[match(coef_df_lays$spec, c("1a","1b","1c","1d","1e","1f"))]
coef_df_all <- bind_rows(coef_df, coef_df_lays) |>
  mutate(spec = factor(spec, levels = rev(names(m_hlo))))

p_coef <- ggplot(coef_df_all, aes(x = est, y = spec, color = outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.4),
                   size = 0.4, linewidth = 0.6) +
  scale_color_manual(values = c("HLO" = "#1B7837", "LAYS (years)" = "#762A83")) +
  labs(title = "Model 1: ODA coefficient across specifications",
       subtitle = "Coefficient on log(1 + CRS_disburse_defl_sum); 95% CIs (HC-robust)",
       x = "Coefficient on log(1 + CRS disburse, USD M)", y = NULL,
       color = "Outcome",
       caption = "n varies by spec (120-133). Dashed line: zero effect.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(OUT_PLOT_PDF, p_coef, width = 9, height = 5)
ggsave(OUT_PLOT_PNG, p_coef, width = 9, height = 5, dpi = 150)
message(sprintf("[model1] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

message("\n[model1] complete.")
