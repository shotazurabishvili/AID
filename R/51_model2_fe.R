# R/51_model2_fe.R
#
# Model 2 — within-country fixed-effects panel.
# THE HEADLINE SESSION. The β_OLS vs β_FE contrast (the analysis result of −1.36 ns
# vs the result here) is the manuscript's central empirical claim.
#
# Specification (sequential add, mirroring Model 1):
#   2a: HLO ~ log(1+CRS_disburse_defl_MA3)                              | iso3 + year
#   2b: + log(GDP/cap)
#   2c: + PTR primary
#   2d: + ed_exp_%GDP                                                   (per spec)
#   2e: + Gov_effect (WGI)                                              (full Model 2)
#   2f: + log(1+GCDF_MA3)                                               (China-robust preview)
#   2g: + in_conflict + COVID_days_closed_recode                        (time-varying confounders)
#
# Parallel set with `hci_lays_overall` (LAYS) as outcome.
#
# COVID NA→0 recode: covid_days_closed is non-NA only in 2020-2022 (UNESCO).
# For pre-2020 years (2010-2019) we code 0 — pre-pandemic = no closure exposure.
# This is a substantive modeling choice extending the production panel's NA→0
# convention from aid flows to COVID exposure. See manuscript §3.
#
# SE: country-clustered. FE: two-way (country + year). feols auto-drops
# singleton-FE countries (6 countries with 1 HLO obs each).
#
# Diagnostics on full spec (2e):
#   - Hausman test (FE vs RE) via plm::phtest
#   - Wooldridge serial autocorrelation via plm::pwartest
#   - Breusch-Pagan heteroskedasticity via lmtest::bptest on parallel lm
#   - VIF on within-transformed (demeaned) regressors via car::vif on lm
#
# Outputs:
#   output/tables/model2_fe_baseline.{csv,md}        (HLO outcome, 7 specs)
#   output/tables/model2_fe_lays_outcome.{csv,md}    (LAYS outcome parallel)
#   output/tables/model2_fe_diagnostics.csv          (Hausman, Wooldridge, BP, VIF)
#   output/tables/model1_vs_model2_contrast.{csv,md} (the headline)
#   output/figures/eda/model2_coefficient_plot.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(modelsummary)
  library(plm)
  library(lmtest)
  library(car)
})

PANEL_PATH    <- "data/interim/panel.parquet"
OUT_HLO_CSV   <- "output/tables/model2_fe_baseline.csv"
OUT_HLO_MD    <- "output/tables/model2_fe_baseline.md"
OUT_LAYS_CSV  <- "output/tables/model2_fe_lays_outcome.csv"
OUT_LAYS_MD   <- "output/tables/model2_fe_lays_outcome.md"
OUT_DIAG_CSV  <- "output/tables/model2_fe_diagnostics.csv"
OUT_CONTRAST_CSV <- "output/tables/model1_vs_model2_contrast.csv"
OUT_CONTRAST_MD  <- "output/tables/model1_vs_model2_contrast.md"
OUT_PLOT_PDF  <- "output/figures/eda/model2_coefficient_plot.pdf"
OUT_PLOT_PNG  <- "output/figures/eda/model2_coefficient_plot.png"

# === 1. Setup =================================================================
message("[model2] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

# COVID NA→0 recode for pre-2020 years
d <- d |> mutate(
  covid_days_recode = ifelse(year < 2020 & is.na(covid_days_closed), 0, covid_days_closed),
  log_crs_disb_ma3 = log1p(crs_disburse_usd_defl_ma3),
  log_gdp_pc       = log(wdi_gdp_pc_usd),
  log_gcdf_ma3     = log1p(gcdf_amount_const2021_ma3)
)

message(sprintf("[model2] panel: %d rows × %d cols (primary window)", nrow(d), ncol(d)))

# Pre-flight sample audit
hlo_obs <- d |> filter(!is.na(hlo_hlo_score))
hlo_per_country <- hlo_obs |> count(iso3)
cat(sprintf("[model2] HLO obs: %d across %d countries\n",
            nrow(hlo_obs), nrow(hlo_per_country)))
cat(sprintf("[model2] FE-identifiable (≥2 obs/country): %d countries; %d total obs\n",
            sum(hlo_per_country$n >= 2),
            sum(hlo_per_country$n[hlo_per_country$n >= 2])))

# === 2. Run 7 HLO-outcome FE specs ============================================
message("\n[model2] fitting HLO-outcome specs")

m_hlo <- list()
m_hlo[["2a (bivariate)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2b (+log GDP/cap)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2c (+PTR)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2d (+ed exp; ed-exp spec)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2e (+gov effect; full)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_ge_est | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2f (+log GCDF; China-robust)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_ge_est + log_gcdf_ma3 | iso3 + year,
        data = d, vcov = ~iso3)
m_hlo[["2g (+conflict + COVID)"]] <-
  feols(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
          wdi_edu_exp_pct_gdp + wgi_ge_est + log_gcdf_ma3 +
          ucdp_in_conflict + covid_days_recode | iso3 + year,
        data = d, vcov = ~iso3)

# === 3. Parallel LAYS-outcome specs ===========================================
message("[model2] fitting LAYS-outcome specs")
m_lays <- list()
m_lays[["2a"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2b"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2c"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary | iso3 + year,
                         data = d, vcov = ~iso3)
m_lays[["2d"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2e"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_ge_est | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2f"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_ge_est + log_gcdf_ma3 | iso3 + year,
                        data = d, vcov = ~iso3)
m_lays[["2g"]] <- feols(hci_lays_overall ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                          wdi_edu_exp_pct_gdp + wgi_ge_est + log_gcdf_ma3 +
                          ucdp_in_conflict + covid_days_recode | iso3 + year,
                        data = d, vcov = ~iso3)

# === 4. Diagnostics on full spec (2e) =========================================
message("\n[model2] diagnostics on full spec (2e)")

# Hausman: parallel FE and RE via plm
plm_d <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_disb_ma3, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  as.data.frame() |>
  na.omit()
plm_d <- pdata.frame(plm_d, index = c("iso3", "year"))

m_plm_fe <- plm(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_ge_est,
                data = plm_d, model = "within", effect = "twoways")
m_plm_re <- tryCatch(
  plm(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
        wdi_edu_exp_pct_gdp + wgi_ge_est,
      data = plm_d, model = "random", effect = "twoways"),
  error = function(e) { message("[model2] RE estimation failed: ", conditionMessage(e)); NULL }
)

hausman_res <- if (!is.null(m_plm_re)) {
  tryCatch(plm::phtest(m_plm_fe, m_plm_re),
           error = function(e) { message("[model2] Hausman failed: ", conditionMessage(e)); NULL })
} else NULL

# Wooldridge AR(1) on FE residuals
wooldridge_res <- tryCatch(plm::pwartest(m_plm_fe),
                            error = function(e) { message("[model2] Wooldridge failed: ", conditionMessage(e)); NULL })

# Breusch-Pagan on parallel lm with dummies
lm_data <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_disb_ma3, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  na.omit()
m_lm <- lm(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
             wdi_edu_exp_pct_gdp + wgi_ge_est + factor(iso3) + factor(year),
           data = lm_data)
bp_res <- tryCatch(lmtest::bptest(m_lm),
                    error = function(e) { message("[model2] BP failed: ", conditionMessage(e)); NULL })

# VIF on within-transformed (demean by country + year) regressors
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

vif_data <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_disb_ma3, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  na.omit()
vif_demean <- demean(vif_data |> as.data.frame(), c("iso3","year"),
                      c("log_crs_disb_ma3","log_gdp_pc","wdi_ptr_primary",
                        "wdi_edu_exp_pct_gdp","wgi_ge_est"))
m_lm_demean <- lm(hlo_hlo_score ~ log_crs_disb_ma3 + log_gdp_pc + wdi_ptr_primary +
                    wdi_edu_exp_pct_gdp + wgi_ge_est,
                  data = vif_demean)
vifs <- tryCatch(car::vif(m_lm_demean),
                  error = function(e) { message("[model2] VIF failed: ", conditionMessage(e)); NULL })

# Compile diagnostics
diag_rows <- list()
if (!is.null(hausman_res)) {
  diag_rows[["Hausman (FE vs RE)"]] <- tibble(
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
  diag_rows[["Wooldridge AR(1)"]] <- tibble(
    test = "Wooldridge AR(1) serial autocorrelation",
    statistic = round(unname(wooldridge_res$statistic), 3),
    df = unname(wooldridge_res$parameter[1]),
    p_value = format.pval(wooldridge_res$p.value),
    interpretation = ifelse(wooldridge_res$p.value < 0.05,
                            "AR(1) present; motivates System GMM ",
                            "No AR(1) detected")
  )
}
if (!is.null(bp_res)) {
  diag_rows[["Breusch-Pagan"]] <- tibble(
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
  diag_rows[["VIF max"]] <- tibble(
    test = "VIF (on demeaned regressors) max",
    statistic = round(max(vifs), 3),
    df = NA_integer_,
    p_value = NA_character_,
    interpretation = paste0("Max VIF = ", round(max(vifs), 2),
                            "; threshold: flag > 10. Variable: ", names(vifs)[which.max(vifs)])
  )
}

diag_df <- bind_rows(diag_rows)
print(diag_df)
dir.create(dirname(OUT_DIAG_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(diag_df, OUT_DIAG_CSV)
message(sprintf("[model2] wrote %s", OUT_DIAG_CSV))

# Also save full VIF table
if (!is.null(vifs)) {
  vif_full_df <- tibble(variable = names(vifs), vif_demeaned = round(vifs, 3))
  readr::write_csv(vif_full_df, "output/tables/model2_fe_vif_demeaned.csv")
}

# === 5. Headline numbers for stdout ===========================================
m_full <- m_hlo[["2e (+gov effect; full)"]]
m_biv  <- m_hlo[["2a (bivariate)"]]
m_all  <- m_hlo[["2g (+conflict + COVID)"]]

oda_coef <- function(m) coef(m)["log_crs_disb_ma3"]
oda_se   <- function(m) sqrt(diag(vcov(m)))["log_crs_disb_ma3"]
oda_p    <- function(m) fixest::pvalue(m)["log_crs_disb_ma3"]

cat("\n=== Model 2 headline (HLO outcome, two-way FE) ===\n")
cat(sprintf("Bivariate (2a):  N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_biv$nobs, oda_coef(m_biv), oda_se(m_biv), oda_p(m_biv)))
cat(sprintf("Brief spec (2d): N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_hlo[["2d (+ed exp; ed-exp spec)"]]$nobs,
            oda_coef(m_hlo[["2d (+ed exp; ed-exp spec)"]]),
            oda_se(m_hlo[["2d (+ed exp; ed-exp spec)"]]),
            oda_p(m_hlo[["2d (+ed exp; ed-exp spec)"]])))
cat(sprintf("Full (2e):       N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_full$nobs, oda_coef(m_full), oda_se(m_full), oda_p(m_full)))
cat(sprintf("Full+conf+COVID (2g):  N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_all$nobs, oda_coef(m_all), oda_se(m_all), oda_p(m_all)))

# === 6. modelsummary tables ===================================================
coef_map <- c(
  "log_crs_disb_ma3"      = "log(1 + CRS disburse MA3)",
  "log_gdp_pc"            = "log(GDP per capita)",
  "wdi_ptr_primary"       = "PTR (primary)",
  "wdi_edu_exp_pct_gdp"   = "Ed expenditure (% GDP)",
  "wgi_ge_est"            = "Govt effectiveness (WGI)",
  "log_gcdf_ma3"          = "log(1 + GCDF MA3)",
  "ucdp_in_conflict"      = "In active conflict",
  "covid_days_recode"     = "COVID days closed (recoded)"
)
gm <- tibble::tribble(
  ~raw,           ~clean,        ~fmt,
  "nobs",         "N",           0,
  "r.squared",    "R^2",         3,
  "adj.r.squared","Adj R^2",     3
)

diag_note <- paste0(
  "Two-way (country + year) FE; country-clustered SE. ",
  if (!is.null(hausman_res)) sprintf("Hausman χ²=%.1f (p=%s). ",
                                     hausman_res$statistic, format.pval(hausman_res$p.value)) else "",
  if (!is.null(wooldridge_res)) sprintf("Wooldridge AR(1) F=%.1f (p=%s). ",
                                        wooldridge_res$statistic, format.pval(wooldridge_res$p.value)) else "",
  if (!is.null(bp_res)) sprintf("Breusch-Pagan χ²=%.1f (p=%s). ",
                                bp_res$statistic, format.pval(bp_res$p.value)) else "",
  if (!is.null(vifs)) sprintf("Max VIF (demeaned regressors) = %.2f. ", max(vifs)) else "",
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
  title = "Table 3. Model 2 — Within-country FE panel, HLO outcome (two-way FE; country-clustered SE)."
)
ms_hlo_df <- modelsummary(m_hlo, output = "data.frame", coef_map = coef_map, gof_map = gm,
                          stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01), fmt = 3)
readr::write_csv(ms_hlo_df, OUT_HLO_CSV)
message(sprintf("[model2] wrote %s and %s", OUT_HLO_CSV, OUT_HLO_MD))

modelsummary(
  m_lays,
  output = OUT_LAYS_MD,
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  fmt = 3,
  notes = paste0(diag_note, " LAYS = EYS x HLO/625; LAYS-FE captures EYS within-country variation in addition to HLO variation."),
  title = "Table 3B. Model 2 — LAYS outcome, parallel two-way FE specifications."
)
ms_lays_df <- modelsummary(m_lays, output = "data.frame", coef_map = coef_map, gof_map = gm,
                           stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01), fmt = 3)
readr::write_csv(ms_lays_df, OUT_LAYS_CSV)
message(sprintf("[model2] wrote %s and %s", OUT_LAYS_CSV, OUT_LAYS_MD))

# === 7. Model 1 vs Model 2 contrast table =====================================
message("\n[model2] building Model 1 vs Model 2 contrast")

# Load Model 1 full-spec coefficient from saved CSV
# Format: rows are statistics, columns are spec labels
m1_table <- readr::read_csv(OUT_HLO_CSV |> str_replace("model2_fe_baseline", "model1_ols_baseline"),
                             show_col_types = FALSE)

# Re-fit Model 1 full spec to get exact β + SE
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
            "Model 2 (within-country FE, full spec 2e)",
            "Model 2 (full + conflict + COVID, spec 2g)"),
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
  "**Table 4. Model 1 vs Model 2 — ODA coefficient contrast (manuscript headline).**",
  "",
  "Effect of `log(1 + CRS_disburse_defl_sum)` (Model 1, country means) and `log(1 + CRS_disburse_defl_MA3)` (Model 2, panel) on HLO score.",
  "",
  knitr::kable(contrast_df, format = "pipe",
               align = c("l", "r", "r", "r", "r", "l", "l")),
  "",
  "**Reading:** Model 1's coefficient is the cross-sectional association between country-mean CRS disbursement and country-mean HLO. Model 2's coefficient is the within-country effect — does within-country variation in CRS over time predict within-country variation in HLO?",
  "",
  "Stars: ***p<0.01, **p<0.05, *p<0.1.",
  paste0("Model 1 spec: HLO_i = β0 + β1 log(1+CRS)_i + β2 log(GDP/cap)_i + β3 PTR_i + β4 EdExp_i + β5 WGI_i + ε_i."),
  paste0("Model 2 spec: HLO_it = β1 log(1+CRS_MA3)_it + β2 log(GDP/cap)_it + β3 PTR_it + β4 EdExp_it + β5 WGI_it + α_i + λ_t + ε_it."),
  paste0("Treatment differs: Model 1 uses country-mean of annual CRS disbursement; Model 2 uses 3-yr trailing MA of annual values (per PAP-0005 working preference).")
)
writeLines(contrast_md, OUT_CONTRAST_MD)
message(sprintf("[model2] wrote %s and %s", OUT_CONTRAST_CSV, OUT_CONTRAST_MD))

# === 8. Coefficient plot ======================================================
message("[model2] building coefficient plot")

# Re-fit Model 1 full set for plot
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
                     \(m, l) extract_oda(m, sub(" \\(.*", "", l), "Model 2 (FE panel)", "log_crs_disb_ma3"))

# Align spec labels (1a/2a, 1b/2b, etc.)
spec_align <- c("a" = "Bivariate", "b" = "+ log(GDP/cap)", "c" = "+ PTR",
                "d" = "+ ed exp", "e" = "+ Gov effect (full)", "f" = "+ log GCDF",
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
                                  "Model 2 (FE panel)" = "#762A83")) +
  labs(title = "Model 1 vs Model 2: ODA coefficient on HLO across specifications",
       subtitle = "Coefficient on log(1 + CRS disbursement); 95% CIs (HC for OLS, country-clustered for FE)",
       x = "Coefficient (HLO score points per unit log CRS)", y = NULL,
       color = NULL,
       caption = "Model 1 N=120-133 (country-level means); Model 2 N=143-441 (country-year cells). Dashed line: zero effect.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 10, height = 6)
ggsave(OUT_PLOT_PNG, p_coef, width = 10, height = 6, dpi = 150)
message(sprintf("[model2] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

message("\n[model2] complete.")
