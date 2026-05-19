# R/53_model2_lock_diagnostics.R
#
# Phase 5 Session 03: diagnostics on ADR-0005 lock candidate only.
# Lock spec (per session decision):
#   HLO ~ log(1 + crs_disburse_usd_defl_ma3_lag1) + log(GDP/cap) + PTR primary +
#         ed_exp_%GDP + WGI gov effectiveness  |  iso3 + year
#
# Tests (parallel to Session-14 spec-2e diagnostics, applied to locked treatment):
#   - Hausman (FE vs RE) via plm::phtest
#   - Wooldridge AR(1) on FE residuals via plm::pwartest
#   - Breusch-Pagan heteroskedasticity via lmtest::bptest on parallel lm
#   - VIF on within-transformed regressors via car::vif on demeaned lm
#
# Why locked-spec only: running these on all 32 sensitivity cells would add no
# information — encoding doesn't change residual structure shape. The lock
# candidate is the spec that needs defending against referee.
#
# Output:
#   output/tables/model2_fe_sensitivity_diagnostics.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(plm)
  library(lmtest)
  library(car)
})

PANEL_PATH  <- "data/interim/panel.parquet"
OUT_CSV     <- "output/tables/model2_fe_sensitivity_diagnostics.csv"

TREATMENT_COL <- "crs_disburse_usd_defl_ma3_lag1"  # ADR-0005 lock candidate

# === 1. Setup ================================================================
message("[model2-lock] loading panel + applying lock spec")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)
d$log_treatment <- log1p(d[[TREATMENT_COL]])
d$log_gdp_pc    <- log(d$wdi_gdp_pc_usd)

# === 2. Fit locked-spec FE via feols (sanity baseline) =======================
m_feols <- feols(
  hlo_hlo_score ~ log_treatment + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_ge_est | iso3 + year,
  data = d, vcov = ~iso3
)

cat(sprintf("\n[lock spec] N=%d  β=%.3f  SE=%.3f  p=%.4f\n",
            m_feols$nobs,
            unname(coef(m_feols)["log_treatment"]),
            unname(sqrt(diag(vcov(m_feols)))["log_treatment"]),
            unname(fixest::pvalue(m_feols)["log_treatment"])))

# === 3. Hausman + Wooldridge via plm =========================================
plm_d <- d |>
  select(iso3, year, hlo_hlo_score, log_treatment, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  as.data.frame() |>
  na.omit()
plm_d <- pdata.frame(plm_d, index = c("iso3", "year"))

m_plm_fe <- plm(hlo_hlo_score ~ log_treatment + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_ge_est,
                data = plm_d, model = "within", effect = "twoways")
m_plm_re <- tryCatch(
  plm(hlo_hlo_score ~ log_treatment + log_gdp_pc + wdi_ptr_primary +
        wdi_edu_exp_pct_gdp + wgi_ge_est,
      data = plm_d, model = "random", effect = "twoways"),
  error = function(e) { message("[lock] RE estimation failed: ", conditionMessage(e)); NULL }
)
hausman_res <- if (!is.null(m_plm_re)) {
  tryCatch(plm::phtest(m_plm_fe, m_plm_re),
           error = function(e) { message("[lock] Hausman failed: ", conditionMessage(e)); NULL })
} else NULL

wooldridge_res <- tryCatch(plm::pwartest(m_plm_fe),
                            error = function(e) { message("[lock] Wooldridge failed: ", conditionMessage(e)); NULL })

# === 4. Breusch-Pagan via parallel lm with FE dummies ========================
lm_data <- d |>
  select(iso3, year, hlo_hlo_score, log_treatment, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  na.omit()
m_lm <- lm(hlo_hlo_score ~ log_treatment + log_gdp_pc + wdi_ptr_primary +
             wdi_edu_exp_pct_gdp + wgi_ge_est + factor(iso3) + factor(year),
           data = lm_data)
bp_res <- tryCatch(lmtest::bptest(m_lm),
                    error = function(e) { message("[lock] BP failed: ", conditionMessage(e)); NULL })

# === 5. VIF on demeaned regressors ==========================================
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
  select(iso3, year, hlo_hlo_score, log_treatment, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est) |>
  na.omit()
vif_demean <- demean(vif_data |> as.data.frame(), c("iso3","year"),
                      c("log_treatment","log_gdp_pc","wdi_ptr_primary",
                        "wdi_edu_exp_pct_gdp","wgi_ge_est"))
m_lm_demean <- lm(hlo_hlo_score ~ log_treatment + log_gdp_pc + wdi_ptr_primary +
                    wdi_edu_exp_pct_gdp + wgi_ge_est,
                  data = vif_demean)
vifs <- tryCatch(car::vif(m_lm_demean),
                  error = function(e) { message("[lock] VIF failed: ", conditionMessage(e)); NULL })

# === 6. Compile + write diagnostics table ====================================
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
cat("\n=== Lock-spec diagnostics ===\n")
print(diag_df)
dir.create(dirname(OUT_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(diag_df, OUT_CSV)
message(sprintf("[model2-lock] wrote %s", OUT_CSV))

message("\n[model2-lock] complete.")
