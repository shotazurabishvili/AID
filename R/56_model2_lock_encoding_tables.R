# R/56_model2_lock_encoding_tables.R
#
# Phase 5 Session 06: refresh the manuscript headline tables (Session-14 spec
# progression 2a-2g + Model-1-vs-Model-2 contrast) on the post-lock encoding.
# Three substantive changes from Session-14 baseline (R/51_model2_fe.R):
#
#   1. Treatment (Session-03 lock, ADR-0005): `crs_disburse_usd_defl_ma3` →
#      `crs_disburse_usd_defl_ma3_lag1` (strictly-past 3-yr MA).
#   2. WGI control in 2e/2f/2g (Session-05 lock, ADR-0009): `wgi_ge_est` →
#      `wgi_pc1` (first PC of all six WGI dims, scaled, sign-flipped so GE
#      loads positive — same construction as R/55).
#   3. GCDF in 2f (methodological consistency with ADR-0005 strictly-past
#      reasoning; column added in Session 04, ADR-0008):
#      `gcdf_amount_const2021_ma3` → `gcdf_amount_const2021_ma3_lag1`.
#
# Model 1 (cross-sectional OLS, country means) uses single-GE for prior-
# literature comparability + raw annual disburse country means (no lag
# structure on a cross-section). Model 1 result expected to reproduce
# Phase-4 Session-13 exactly: β=-1.36, ns.
#
# DOES NOT modify R/51_model2_fe.R — preserves Session-14 reproducibility for
# audit. Outputs use `_v2` suffix.
#
# Outputs (manuscript-grade):
#   output/tables/model2_fe_baseline_v2.{csv,md}
#   output/tables/model2_fe_lays_outcome_v2.{csv,md}
#   output/tables/model2_fe_diagnostics_v2.csv
#   output/tables/model1_vs_model2_contrast_v2.{csv,md}
#   output/figures/eda/model2_coefficient_plot_v2.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(modelsummary)
  library(plm)
  library(lmtest)
  library(car)
})

PANEL_PATH       <- "data/interim/panel.parquet"
OUT_HLO_CSV      <- "output/tables/model2_fe_baseline_v2.csv"
OUT_HLO_MD       <- "output/tables/model2_fe_baseline_v2.md"
OUT_LAYS_CSV     <- "output/tables/model2_fe_lays_outcome_v2.csv"
OUT_LAYS_MD      <- "output/tables/model2_fe_lays_outcome_v2.md"
OUT_DIAG_CSV     <- "output/tables/model2_fe_diagnostics_v2.csv"
OUT_CONTRAST_CSV <- "output/tables/model1_vs_model2_contrast_v2.csv"
OUT_CONTRAST_MD  <- "output/tables/model1_vs_model2_contrast_v2.md"
OUT_PLOT_PDF     <- "output/figures/eda/model2_coefficient_plot_v2.pdf"
OUT_PLOT_PNG     <- "output/figures/eda/model2_coefficient_plot_v2.png"

WGI_DIMS <- c("wgi_va_est", "wgi_pv_est", "wgi_ge_est",
              "wgi_rq_est", "wgi_rl_est", "wgi_cc_est")

# === 1. Setup =================================================================
message("[m2-v2] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

# Compute PC1 with the same convention as R/55 (Session-05 lock).
wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
complete_rows <- complete.cases(wgi_mat)
pca <- prcomp(wgi_mat[complete_rows, ], scale. = TRUE, center = TRUE)
if (pca$rotation["wgi_ge_est", "PC1"] < 0) {
  pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
  pca$x[, "PC1"]        <- -pca$x[, "PC1"]
}
d$wgi_pc1 <- NA_real_
d$wgi_pc1[complete_rows] <- pca$x[, "PC1"]
message(sprintf("[m2-v2] PC1 attached: %d / %d rows with all-6 WGI present (var=%.3f)",
                sum(complete_rows), nrow(d), (pca$sdev^2)[1] / sum(pca$sdev^2)))

# COVID NA→0 recode for pre-2020 years (same as Session 14)
d <- d |> mutate(
  covid_days_recode = ifelse(year < 2020 & is.na(covid_days_closed),
                              0, covid_days_closed),
  log_crs_disb_strict = log1p(crs_disburse_usd_defl_ma3_lag1),  # Session-03 lock
  log_gdp_pc          = log(wdi_gdp_pc_usd),
  log_gcdf_strict     = log1p(gcdf_amount_const2021_ma3_lag1)   # Session-04 column, strictly-past
)

message(sprintf("[m2-v2] panel: %d rows × %d cols (primary window)",
                nrow(d), ncol(d)))

# Pre-flight sample audit
hlo_obs <- d |> filter(!is.na(hlo_hlo_score))
hlo_per_country <- hlo_obs |> count(iso3)
cat(sprintf("[m2-v2] HLO obs: %d across %d countries\n",
            nrow(hlo_obs), nrow(hlo_per_country)))
cat(sprintf("[m2-v2] FE-identifiable (≥2 obs/country): %d countries; %d total obs\n",
            sum(hlo_per_country$n >= 2),
            sum(hlo_per_country$n[hlo_per_country$n >= 2])))

# === 2. Run 7 HLO-outcome FE specs (locked encoding) ==========================
message("\n[m2-v2] fitting HLO-outcome specs on locked encoding")

m_hlo <- list()
m_hlo[["2a (bivariate)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2b (+log GDP/cap)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2c (+PTR)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2d (+ed exp; brief spec)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2e (+WGI PC1; full)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2f (+log GCDF strict; China-robust)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_pc1 + log_gcdf_strict | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2g (+conflict + COVID)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_pc1 + log_gcdf_strict +
          ucdp_in_conflict + covid_days_recode | iso3 + year,
        data = d, vcov = ~iso3)

# === 3. Parallel LAYS-outcome specs ==========================================
message("[m2-v2] fitting LAYS-outcome specs")
m_lays <- list()
m_lays[["2a"]] <- feols(hci_lays_overall ~ log_crs_disb_strict | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2b"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2c"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2d"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2e"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2f"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_pc1 + log_gcdf_strict | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2g"]] <- feols(hci_lays_overall ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_pc1 + log_gcdf_strict +
                          ucdp_in_conflict + covid_days_recode | iso3 + year,
                        data = d, vcov = ~iso3)

# === 4. Diagnostics on locked 2e =============================================
message("\n[m2-v2] diagnostics on locked full spec (2e)")

plm_d <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_disb_strict, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_pc1) |>
  as.data.frame() |>
  na.omit()
plm_d <- pdata.frame(plm_d, index = c("iso3", "year"))

m_plm_fe <- plm(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1,
                data = plm_d, model = "within", effect = "twoways")
m_plm_re <- tryCatch(
  plm(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
        wdi_edu_exp_pct_gdp + wgi_pc1,
      data = plm_d, model = "random", effect = "twoways"),
  error = function(e) { message("[m2-v2] RE failed: ", conditionMessage(e)); NULL }
)
hausman_res <- if (!is.null(m_plm_re)) {
  tryCatch(plm::phtest(m_plm_fe, m_plm_re),
           error = function(e) { message("[m2-v2] Hausman failed: ", conditionMessage(e)); NULL })
} else NULL

wooldridge_res <- tryCatch(plm::pwartest(m_plm_fe),
                            error = function(e) { message("[m2-v2] Wooldridge failed: ", conditionMessage(e)); NULL })

lm_data <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_disb_strict, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_pc1) |>
  na.omit()
m_lm <- lm(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
             wdi_edu_exp_pct_gdp + wgi_pc1 + factor(iso3) + factor(year),
           data = lm_data)
bp_res <- tryCatch(lmtest::bptest(m_lm),
                    error = function(e) { message("[m2-v2] BP failed: ", conditionMessage(e)); NULL })

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
vif_data <- lm_data
vif_demean <- demean(vif_data, c("iso3","year"),
                      c("log_crs_disb_strict","log_gdp_pc","wdi_ptr_primary",
                        "wdi_edu_exp_pct_gdp","wgi_pc1"))
m_lm_demean <- lm(hlo_hlo_score ~ log_crs_disb_strict + log_gdp_pc + wdi_ptr_primary +
                    wdi_edu_exp_pct_gdp + wgi_pc1,
                  data = vif_demean)
vifs <- tryCatch(car::vif(m_lm_demean),
                  error = function(e) { message("[m2-v2] VIF failed: ", conditionMessage(e)); NULL })

diag_rows <- list()
if (!is.null(hausman_res)) {
  diag_rows[["Hausman"]] <- tibble(
    test = "Hausman (FE vs RE)",
    statistic = round(unname(hausman_res$statistic), 3),
    df = hausman_res$parameter,
    p_value = format.pval(hausman_res$p.value),
    interpretation = ifelse(hausman_res$p.value < 0.05,
                            "Reject RE; prefer FE",
                            "Cannot reject RE")
  )
}
if (!is.null(wooldridge_res)) {
  diag_rows[["Wooldridge"]] <- tibble(
    test = "Wooldridge AR(1) on FE residuals",
    statistic = round(unname(wooldridge_res$statistic), 3),
    df = unname(wooldridge_res$parameter[1]),
    p_value = format.pval(wooldridge_res$p.value),
    interpretation = ifelse(wooldridge_res$p.value < 0.05,
                            "AR(1) present; cluster-robust SE warranted",
                            "No AR(1) detected")
  )
}
if (!is.null(bp_res)) {
  diag_rows[["BP"]] <- tibble(
    test = "Breusch-Pagan heteroskedasticity",
    statistic = round(unname(bp_res$statistic), 3),
    df = unname(bp_res$parameter),
    p_value = format.pval(bp_res$p.value),
    interpretation = ifelse(bp_res$p.value < 0.05,
                            "Heteroskedasticity present; HC-robust SE warranted",
                            "Homoskedastic residuals")
  )
}
if (!is.null(vifs)) {
  diag_rows[["VIF"]] <- tibble(
    test = "VIF (demeaned regressors) max",
    statistic = round(max(vifs), 3),
    df = NA_integer_,
    p_value = NA_character_,
    interpretation = paste0("Max VIF = ", round(max(vifs), 2),
                            "; threshold: flag > 10. Variable: ", names(vifs)[which.max(vifs)])
  )
}
diag_df <- bind_rows(diag_rows)
cat("\n=== Locked 2e diagnostics ===\n")
print(diag_df)
dir.create(dirname(OUT_DIAG_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(diag_df, OUT_DIAG_CSV)
message(sprintf("[m2-v2] wrote %s", OUT_DIAG_CSV))

# === 5. Headline numbers to stdout (reproducibility canary) ==================
oda_coef <- function(m) coef(m)["log_crs_disb_strict"]
oda_se   <- function(m) sqrt(diag(vcov(m)))["log_crs_disb_strict"]
oda_p    <- function(m) fixest::pvalue(m)["log_crs_disb_strict"]

m_full <- m_hlo[["2e (+WGI PC1; full)"]]
m_biv  <- m_hlo[["2a (bivariate)"]]
m_all  <- m_hlo[["2g (+conflict + COVID)"]]
m_chn  <- m_hlo[["2f (+log GCDF strict; China-robust)"]]

cat("\n=== Model 2 v2 headline (HLO outcome, locked encoding) ===\n")
cat(sprintf("Bivariate (2a):             N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_biv$nobs, oda_coef(m_biv), oda_se(m_biv), oda_p(m_biv)))
cat(sprintf("Full PC1 (2e — HEADLINE):   N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_full$nobs, oda_coef(m_full), oda_se(m_full), oda_p(m_full)))
cat(sprintf("+GCDF strict (2f):          N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_chn$nobs, oda_coef(m_chn), oda_se(m_chn), oda_p(m_chn)))
cat(sprintf("+conflict + COVID (2g):     N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_all$nobs, oda_coef(m_all), oda_se(m_all), oda_p(m_all)))
cat(sprintf("\nReproducibility canary — must match Session-05 spec C exactly:\n"))
cat(sprintf("  Expected: β=11.142, SE=5.521, p=0.0481, N=143\n"))
cat(sprintf("  Got 2e:   β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            oda_coef(m_full), oda_se(m_full), oda_p(m_full), m_full$nobs))

# === 6. modelsummary tables ==================================================
coef_map <- c(
  "log_crs_disb_strict" = "log(1 + CRS disburse strict-past MA3)",
  "log_gdp_pc"          = "log(GDP per capita)",
  "wdi_ptr_primary"     = "PTR (primary)",
  "wdi_edu_exp_pct_gdp" = "Ed expenditure (% GDP)",
  "wgi_pc1"             = "WGI PC1 (governance composite)",
  "log_gcdf_strict"     = "log(1 + GCDF strict-past MA3)",
  "ucdp_in_conflict"    = "In active conflict",
  "covid_days_recode"   = "COVID days closed (recoded)"
)
gm <- tibble::tribble(
  ~raw,           ~clean,        ~fmt,
  "nobs",         "N",           0,
  "r.squared",    "R^2",         3,
  "adj.r.squared","Adj R^2",     3
)

diag_note <- paste0(
  "Two-way (country + year) FE; country-clustered SE. ",
  "Treatment: log(1 + CRS_disburse_defl_ma3_lag1) — Session-03 lock (ADR-0005). ",
  "WGI: PC1 of six aggregates (76.4% variance) — Session-05 lock (ADR-0009). ",
  "GCDF in 2f: strictly-past MA3 — methodological consistency with ADR-0005. ",
  if (!is.null(hausman_res)) sprintf("Hausman χ²=%.1f (p=%s). ",
                                     hausman_res$statistic, format.pval(hausman_res$p.value)) else "",
  if (!is.null(wooldridge_res)) sprintf("Wooldridge AR(1) F=%.1f (p=%s). ",
                                        wooldridge_res$statistic, format.pval(wooldridge_res$p.value)) else "",
  if (!is.null(bp_res)) sprintf("Breusch-Pagan χ²=%.1f (p=%s). ",
                                bp_res$statistic, format.pval(bp_res$p.value)) else "",
  if (!is.null(vifs)) sprintf("Max VIF (demeaned) = %.2f. ", max(vifs)) else "",
  "Stars: ***p<0.01, **p<0.05, *p<0.1. ",
  "Singleton-FE countries auto-dropped by feols. ",
  "COVID days recoded NA→0 for pre-2020 years."
)

modelsummary(
  m_hlo,
  output = OUT_HLO_MD,
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3,
  notes = diag_note,
  title = "Table 3 (v2). Model 2 — Within-country FE panel, HLO outcome, LOCKED ENCODING."
)
ms_hlo_df <- modelsummary(m_hlo, output = "data.frame", coef_map = coef_map, gof_map = gm,
                          stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01), fmt = 3)
readr::write_csv(ms_hlo_df, OUT_HLO_CSV)
message(sprintf("[m2-v2] wrote %s and %s", OUT_HLO_CSV, OUT_HLO_MD))

modelsummary(
  m_lays,
  output = OUT_LAYS_MD,
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3,
  notes = paste0(diag_note, " LAYS = EYS x HLO/625; LAYS-FE captures EYS within-country variation in addition to HLO variation."),
  title = "Table 3B (v2). Model 2 — LAYS outcome, parallel two-way FE specifications, LOCKED ENCODING."
)
ms_lays_df <- modelsummary(m_lays, output = "data.frame", coef_map = coef_map, gof_map = gm,
                           stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01), fmt = 3)
readr::write_csv(ms_lays_df, OUT_LAYS_CSV)
message(sprintf("[m2-v2] wrote %s and %s", OUT_LAYS_CSV, OUT_LAYS_MD))

# === 7. Model 1 vs Model 2 contrast (locked encoding) ========================
message("\n[m2-v2] building Model 1 vs Model 2 contrast (manuscript Table 4)")

# Re-fit Model 1 full spec on country-level means + single GE (prior-lit
# comparability). This should reproduce Phase-4 Session-13's β = -1.36, ns.
m1_cm <- d |>
  group_by(iso3) |>
  summarise(across(c(hlo_hlo_score, hci_lays_overall, crs_disburse_usd_defl_sum,
                     wdi_gdp_pc_usd, wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est),
                   ~ mean(., na.rm = TRUE))) |>
  mutate(across(everything(), ~ ifelse(is.nan(.), NA_real_, .))) |>
  mutate(log_crs = log1p(crs_disburse_usd_defl_sum),
         log_gdp = log(wdi_gdp_pc_usd))

m1_full <- feols(hlo_hlo_score ~ log_crs + log_gdp + wdi_ptr_primary +
                   wdi_edu_exp_pct_gdp + wgi_ge_est,
                 data = m1_cm, vcov = "hetero")

contrast_df <- tibble(
  Model = c("Model 1 (cross-sectional OLS, full spec 1e)",
            "Model 2 v2 (within-country FE, locked encoding 2e)",
            "Model 2 v2 (locked + conflict + COVID, 2g)"),
  N = c(m1_full$nobs, m_full$nobs, m_all$nobs),
  beta_ODA = c(round(coef(m1_full)["log_crs"], 3),
               round(oda_coef(m_full), 3),
               round(oda_coef(m_all), 3)),
  SE = c(round(sqrt(diag(vcov(m1_full)))["log_crs"], 3),
         round(oda_se(m_full), 3),
         round(oda_se(m_all), 3)),
  p_value = c(round(fixest::pvalue(m1_full)["log_crs"], 4),
              round(oda_p(m_full), 4),
              round(oda_p(m_all), 4)),
  SE_type = c("HC robust", "Country-clustered", "Country-clustered"),
  Sample = c("Country-level means; one row per country",
             "Country-year panel; HLO non-NA cells; singleton-FE countries dropped",
             "Same + non-NA on conflict/COVID")
)

print(contrast_df)
readr::write_csv(contrast_df, OUT_CONTRAST_CSV)

contrast_md <- c(
  "**Table 4 (v2). Model 1 vs Model 2 — ODA coefficient contrast (manuscript headline, LOCKED ENCODING).**",
  "",
  "Effect of `log(1 + CRS_disburse_defl_sum)` (Model 1, country means) and `log(1 + CRS_disburse_defl_ma3_lag1)` (Model 2 v2, panel) on HLO score.",
  "",
  knitr::kable(contrast_df, format = "pipe",
               align = c("l", "r", "r", "r", "r", "l", "l")),
  "",
  "**Reading:** Model 1's coefficient is the cross-sectional association between country-mean CRS disbursement and country-mean HLO. Model 2's coefficient is the within-country effect — does within-country variation in CRS over time predict within-country variation in HLO? Sign-flip + ~8× magnitude under within-FE is the manuscript's central empirical claim.",
  "",
  "Stars: ***p<0.01, **p<0.05, *p<0.1.",
  paste0("Model 1 spec: HLO_i = β0 + β1 log(1+CRS)_i + β2 log(GDP/cap)_i + β3 PTR_i + β4 EdExp_i + β5 WGI_GE_i + ε_i."),
  paste0("Model 2 v2 spec: HLO_it = β1 log(1+CRS_ma3_lag1)_it + β2 log(GDP/cap)_it + β3 PTR_it + β4 EdExp_it + β5 WGI_PC1_it + α_i + λ_t + ε_it."),
  paste0("Treatment differs: Model 1 uses country-mean of annual CRS disbursement; Model 2 uses 3-yr strictly-past MA (mean of t-3,t-2,t-1) per ADR-0005 lock. WGI differs: Model 1 uses single Government Effectiveness (prior-literature comparability); Model 2 uses PC1 of six WGI dimensions per ADR-0009 lock (76.4% variance; Langbein-Knack engagement).")
)
writeLines(contrast_md, OUT_CONTRAST_MD)
message(sprintf("[m2-v2] wrote %s and %s", OUT_CONTRAST_CSV, OUT_CONTRAST_MD))

# === 8. Coefficient plot =====================================================
message("[m2-v2] building coefficient plot")

m1_specs <- list(
  "1a (bivariate)" = feols(hlo_hlo_score ~ log_crs, data = m1_cm, vcov = "hetero"),
  "1b" = feols(hlo_hlo_score ~ log_crs + log_gdp, data = m1_cm, vcov = "hetero"),
  "1c" = feols(hlo_hlo_score ~ log_crs + log_gdp + wdi_ptr_primary, data = m1_cm, vcov = "hetero"),
  "1d" = feols(hlo_hlo_score ~ log_crs + log_gdp + wdi_ptr_primary + wdi_edu_exp_pct_gdp,
               data = m1_cm, vcov = "hetero"),
  "1e (full)" = feols(hlo_hlo_score ~ log_crs + log_gdp + wdi_ptr_primary +
                       wdi_edu_exp_pct_gdp + wgi_ge_est, data = m1_cm, vcov = "hetero")
)

extract_oda <- function(m, label, model_type, oda_var) {
  est <- coef(m)[oda_var]
  se  <- sqrt(diag(vcov(m)))[oda_var]
  tibble(spec = label, model = model_type, est = est, se = se,
         ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)
}

m1_coefs <- map2_dfr(m1_specs, names(m1_specs),
                     \(m, l) extract_oda(m, l, "Model 1 (OLS, cross-section)", "log_crs"))
m2_coefs <- map2_dfr(m_hlo, names(m_hlo),
                     \(m, l) extract_oda(m, sub(" \\(.*", "", l), "Model 2 v2 (FE panel, locked)", "log_crs_disb_strict"))

spec_align <- c("a" = "Bivariate", "b" = "+ log(GDP/cap)", "c" = "+ PTR",
                "d" = "+ ed exp", "e" = "+ WGI / GE-or-PC1 (full)", "f" = "+ log GCDF strict",
                "g" = "+ conflict + COVID")
m1_coefs$spec_letter <- substr(m1_coefs$spec, 2, 2)
m2_coefs$spec_letter <- substr(m2_coefs$spec, 2, 2)
m1_coefs$spec_label <- spec_align[m1_coefs$spec_letter]
m2_coefs$spec_label <- spec_align[m2_coefs$spec_letter]

coef_all <- bind_rows(m1_coefs, m2_coefs) |>
  mutate(spec_label = factor(spec_label, levels = rev(spec_align)))

p_coef <- ggplot(coef_all, aes(x = est, y = spec_label, color = model)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.5),
                   size = 0.5, linewidth = 0.7) +
  scale_color_manual(values = c("Model 1 (OLS, cross-section)" = "#1B7837",
                                  "Model 2 v2 (FE panel, locked)" = "#762A83")) +
  labs(title = "Model 1 vs Model 2 v2 (locked encoding): ODA coefficient on HLO",
       subtitle = "log(1 + CRS disbursement) effect; 95% CIs (HC for OLS, country-clustered for FE)",
       x = "Coefficient (HLO score points per unit log CRS)", y = NULL,
       color = NULL,
       caption = "Model 2 v2 uses Session-03 strictly-past 3-yr MA treatment + Session-05 WGI PC1 control. Dashed line: zero effect.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 10, height = 6)
ggsave(OUT_PLOT_PNG, p_coef, width = 10, height = 6, dpi = 150)
message(sprintf("[m2-v2] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

message("\n[m2-v2] complete.")
