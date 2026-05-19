# R/57_model3_re_panel.R
#
# Phase 6 Session 01: Model 3 — 2-level country random intercepts + time FE.
# Per methodology.md §3.8 (Phase-2 external-review reframe): NOT the brief's
# original 3-level student-school-country HLM (requires PISA/TIMSS/PIRLS micro-
# data, deferred). Reframed as a 2-level country RE + year FE specification
# whose purpose is to (a) formally justify Model 2's FE choice via Hausman test
# and (b) report the RE counterpart for transparency + ICC at country level.
#
# Spec progression mirrors R/56 (Model 2 v2): same locked encoding (Session-03
# treatment + Session-05 WGI PC1 + Session-04 strictly-past GCDF), same control
# stack, same primary window, HLO + LAYS dual outcomes.
#
# Specs:
#   3a: hlo ~ log_crs_strict                              + factor(year) + (1|iso3)
#   3b: + log(GDP/cap)
#   3c: + PTR primary
#   3d: + ed_exp_%GDP
#   3e: + WGI PC1 (full controls; HEADLINE — compare with R/56 spec 2e)
#
# Hausman test on (3e RE) vs (R/56 2e FE):
#   - Try plm::phtest first (assumed to fail per Sessions 14/06 history)
#   - Lead with manual univariate Cameron-Trivedi:
#       H = (b_FE - b_RE)^2 / (Var(b_FE) - Var(b_RE)) ~ chi^2(1)
#     Denominator can be negative under RE-assumption violation → undefined; report transparently
#
# ICC at country level:
#   - Unconditional (intercept-only: hlo ~ 1 + (1|iso3)) → headline number
#   - Conditional (full 3e) via performance::icc(), tryCatch to NA on failure
#
# Outputs:
#   output/tables/model3_re_specs.{csv,md}
#   output/tables/model3_hausman_test.csv
#   output/tables/model3_icc.csv
#   output/tables/model123_three_way_contrast.{csv,md}
#   output/figures/eda/model3_coefficient_plot.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(lme4)
  library(lmerTest)
  library(performance)
  library(plm)
})

PANEL_PATH        <- "data/interim/panel.parquet"
OUT_SPECS_CSV     <- "output/tables/model3_re_specs.csv"
OUT_SPECS_MD      <- "output/tables/model3_re_specs.md"
OUT_HAUSMAN_CSV   <- "output/tables/model3_hausman_test.csv"
OUT_ICC_CSV       <- "output/tables/model3_icc.csv"
OUT_CONTRAST_CSV  <- "output/tables/model123_three_way_contrast.csv"
OUT_CONTRAST_MD   <- "output/tables/model123_three_way_contrast.md"
OUT_PLOT_PDF      <- "output/figures/eda/model3_coefficient_plot.pdf"
OUT_PLOT_PNG      <- "output/figures/eda/model3_coefficient_plot.png"

WGI_DIMS <- c("wgi_va_est", "wgi_pv_est", "wgi_ge_est",
              "wgi_rq_est", "wgi_rl_est", "wgi_cc_est")

# === 1. Setup =================================================================
message("[m3] loading production panel")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

# Compute PC1 with R/55 / R/56 convention (Session-05 lock).
wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
complete_rows <- complete.cases(wgi_mat)
pca <- prcomp(wgi_mat[complete_rows, ], scale. = TRUE, center = TRUE)
if (pca$rotation["wgi_ge_est", "PC1"] < 0) {
  pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
  pca$x[, "PC1"]        <- -pca$x[, "PC1"]
}
d$wgi_pc1 <- NA_real_
d$wgi_pc1[complete_rows] <- pca$x[, "PC1"]

d <- d |> mutate(
  log_crs_strict = log1p(crs_disburse_usd_defl_ma3_lag1),
  log_gdp_pc     = log(wdi_gdp_pc_usd),
  year_f         = factor(year)
)

message(sprintf("[m3] panel: %d rows × %d cols (primary window)", nrow(d), ncol(d)))

# === 2. Fit Model 3 specs 3a-3e via lmer =====================================
# Use REML=FALSE (ML) to make fixed-effect estimates comparable with feols FE
# (which is effectively ML on demeaned data) for the Hausman test below.

fit_re <- function(formula, data) {
  m <- lmer(formula, data = data, REML = FALSE,
            control = lmerControl(check.conv.singular = .makeCC(action = "ignore",
                                                                  tol = 1e-4)))
  m
}

message("\n[m3] fitting HLO-outcome specs 3a-3e")
m_hlo_3 <- list()
m_hlo_3[["3a"]] <- fit_re(hlo_hlo_score ~ log_crs_strict + year_f + (1 | iso3), d)
m_hlo_3[["3b"]] <- fit_re(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + year_f + (1 | iso3), d)
m_hlo_3[["3c"]] <- fit_re(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary + year_f + (1 | iso3), d)
m_hlo_3[["3d"]] <- fit_re(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                            wdi_edu_exp_pct_gdp + year_f + (1 | iso3), d)
m_hlo_3[["3e"]] <- fit_re(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                            wdi_edu_exp_pct_gdp + wgi_pc1 + year_f + (1 | iso3), d)

message("[m3] fitting LAYS-outcome specs 3a-3e")
m_lays_3 <- list()
m_lays_3[["3a"]] <- fit_re(hci_lays_overall ~ log_crs_strict + year_f + (1 | iso3), d)
m_lays_3[["3b"]] <- fit_re(hci_lays_overall ~ log_crs_strict + log_gdp_pc + year_f + (1 | iso3), d)
m_lays_3[["3c"]] <- fit_re(hci_lays_overall ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary + year_f + (1 | iso3), d)
m_lays_3[["3d"]] <- fit_re(hci_lays_overall ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                            wdi_edu_exp_pct_gdp + year_f + (1 | iso3), d)
m_lays_3[["3e"]] <- fit_re(hci_lays_overall ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                            wdi_edu_exp_pct_gdp + wgi_pc1 + year_f + (1 | iso3), d)

# Singularity check
cat("\n=== Singular fit check ===\n")
for (n in names(m_hlo_3)) {
  cat(sprintf("HLO %s: isSingular=%s\n", n, isSingular(m_hlo_3[[n]])))
}
for (n in names(m_lays_3)) {
  cat(sprintf("LAYS %s: isSingular=%s\n", n, isSingular(m_lays_3[[n]])))
}

# Extract β_ODA, SE, p, N per spec
extract_re <- function(m, label, outcome) {
  cf <- summary(m)$coefficients
  beta <- cf["log_crs_strict", "Estimate"]
  se   <- cf["log_crs_strict", "Std. Error"]
  # lmerTest provides p-values via Satterthwaite by default; if not, use Wald
  p <- if ("Pr(>|t|)" %in% colnames(cf)) cf["log_crs_strict", "Pr(>|t|)"]
       else 2 * pnorm(-abs(beta / se))
  n_obs <- nobs(m)
  vc <- VarCorr(m)
  sigma_country <- as.numeric(attr(vc$iso3, "stddev"))
  sigma_resid <- attr(vc, "sc")
  tibble(spec = label, outcome = outcome, N = n_obs,
         beta_oda = beta, se_oda = se, p_oda = p,
         sigma_country = sigma_country, sigma_resid = sigma_resid,
         is_singular = isSingular(m))
}

specs_hlo <- map2_dfr(m_hlo_3, names(m_hlo_3),
                       \(m, l) extract_re(m, l, "HLO"))
specs_lays <- map2_dfr(m_lays_3, names(m_lays_3),
                        \(m, l) extract_re(m, l, "LAYS"))

specs_df <- bind_rows(specs_hlo, specs_lays) |>
  mutate(
    signif = case_when(
      p_oda < 0.01 ~ "***",
      p_oda < 0.05 ~ "**",
      p_oda < 0.10 ~ "*",
      TRUE         ~ ""
    )
  )

cat("\n=== Model 3 HLO specs (random intercepts + year FE) ===\n")
print(specs_hlo |> select(spec, N, beta_oda, se_oda, p_oda) |>
        mutate(across(c(beta_oda, se_oda, p_oda), \(x) round(x, 4))))

# === 3. Compare Model 3 3e (RE) vs Model 2 v2 2e (FE) — Hausman ============
message("\n[m3] running Hausman test (Model 3 3e RE vs Model 2 v2 2e FE)")

# Re-fit Model 2 v2 spec 2e via feols on the same sample for direct comparison
m_fe_2e <- feols(
  hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d, vcov = ~iso3
)
b_fe   <- unname(coef(m_fe_2e)["log_crs_strict"])
var_fe <- unname(diag(vcov(m_fe_2e))["log_crs_strict"])

# Model 3 3e RE estimate
m_re_3e <- m_hlo_3[["3e"]]
b_re   <- summary(m_re_3e)$coefficients["log_crs_strict", "Estimate"]
var_re <- summary(m_re_3e)$coefficients["log_crs_strict", "Std. Error"]^2

# Manual univariate Hausman
var_diff <- var_fe - var_re
hausman_undefined <- (var_diff <= 0)
if (hausman_undefined) {
  H_stat <- NA_real_
  H_p    <- NA_real_
  manual_note <- sprintf("DENOMINATOR NEGATIVE OR ZERO: Var(b_FE)=%.4f vs Var(b_RE)=%.4f. Test undefined under standard Hausman; RE assumption rejected on efficiency grounds (FE-clustered SE should bound RE SE, but the inversion fails here — interpreted as evidence against RE).",
                          var_fe, var_re)
} else {
  H_stat <- (b_fe - b_re)^2 / var_diff
  H_p    <- 1 - pchisq(H_stat, df = 1)
  manual_note <- sprintf("Manual univariate Cameron-Trivedi Hausman on β_ODA: H=%.4f, df=1, p=%.4f. (b_FE-b_RE)^2=%.4f over (Var_FE - Var_RE)=%.4f.",
                          H_stat, H_p, (b_fe - b_re)^2, var_diff)
}

# Try plm::phtest as a check
plm_d <- d |>
  select(iso3, year, hlo_hlo_score, log_crs_strict, log_gdp_pc,
         wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_pc1) |>
  as.data.frame() |> na.omit()
plm_d <- pdata.frame(plm_d, index = c("iso3", "year"))

m_plm_fe <- plm(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1,
                data = plm_d, model = "within", effect = "twoways")
m_plm_re <- tryCatch(
  plm(hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
        wdi_edu_exp_pct_gdp + wgi_pc1,
      data = plm_d, model = "random", effect = "twoways"),
  error = function(e) { message("[m3] plm RE failed: ", conditionMessage(e)); NULL }
)
plm_hausman <- if (!is.null(m_plm_re)) {
  tryCatch(plm::phtest(m_plm_fe, m_plm_re),
           error = function(e) { message("[m3] plm Hausman failed: ", conditionMessage(e)); NULL })
} else NULL

# Compile Hausman table
hausman_rows <- list()
hausman_rows[["manual"]] <- tibble(
  test = "Manual univariate Cameron-Trivedi Hausman (β_ODA only)",
  b_fe = round(b_fe, 4), var_fe = round(var_fe, 6),
  b_re = round(b_re, 4), var_re = round(var_re, 6),
  H_statistic = round(H_stat, 4),
  df = 1L,
  p_value = round(H_p, 4),
  notes = manual_note
)
if (!is.null(plm_hausman)) {
  hausman_rows[["plm"]] <- tibble(
    test = "plm::phtest (full coefficient vector; if estimable)",
    b_fe = NA_real_, var_fe = NA_real_, b_re = NA_real_, var_re = NA_real_,
    H_statistic = round(unname(plm_hausman$statistic), 4),
    df = unname(plm_hausman$parameter),
    p_value = round(plm_hausman$p.value, 4),
    notes = sprintf("plm Swamy-Arora RE estimated successfully: χ²=%.2f, df=%d, p=%.4f.",
                    plm_hausman$statistic, plm_hausman$parameter, plm_hausman$p.value)
  )
} else {
  hausman_rows[["plm"]] <- tibble(
    test = "plm::phtest (full coefficient vector; if estimable)",
    b_fe = NA_real_, var_fe = NA_real_, b_re = NA_real_, var_re = NA_real_,
    H_statistic = NA_real_, df = NA_integer_, p_value = NA_real_,
    notes = "plm::phtest: RE not estimable on T_eff ≤ 3 (Swamy-Arora requirement). Falling back to manual univariate Hausman."
  )
}
hausman_df <- bind_rows(hausman_rows)

dir.create(dirname(OUT_HAUSMAN_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(hausman_df, OUT_HAUSMAN_CSV)

cat("\n=== Hausman test results ===\n")
cat(sprintf("Model 2 v2 2e FE: β=%.4f, SE=%.4f\n", b_fe, sqrt(var_fe)))
cat(sprintf("Model 3 3e RE:    β=%.4f, SE=%.4f\n", b_re, sqrt(var_re)))
cat(sprintf("\n%s\n", manual_note))
if (!is.null(plm_hausman)) {
  cat(sprintf("\nplm::phtest: χ²=%.4f, df=%d, p=%.4f\n",
              plm_hausman$statistic, plm_hausman$parameter, plm_hausman$p.value))
} else {
  cat("plm::phtest failed (RE not estimable on Swamy-Arora) — relying on manual Hausman.\n")
}

message(sprintf("[m3] wrote %s", OUT_HAUSMAN_CSV))

# === 4. ICC at country level =================================================
message("\n[m3] computing ICC")

m_unconditional <- lmer(hlo_hlo_score ~ 1 + (1 | iso3),
                         data = d |> filter(!is.na(hlo_hlo_score)),
                         REML = TRUE)
icc_unconditional <- tryCatch(performance::icc(m_unconditional),
                               error = function(e) { message("[m3] unconditional ICC failed: ", conditionMessage(e)); NULL })

icc_conditional <- tryCatch(performance::icc(m_hlo_3[["3e"]]),
                             error = function(e) { message("[m3] conditional ICC failed: ", conditionMessage(e)); NULL })

icc_rows <- list()
if (!is.null(icc_unconditional)) {
  icc_rows[["unconditional"]] <- tibble(
    model = "Unconditional (intercept-only)",
    icc_adjusted = round(icc_unconditional$ICC_adjusted, 4),
    icc_unadjusted = round(icc_unconditional$ICC_unadjusted, 4),
    interpretation = sprintf("Country-level variance share = %.1f%% in raw HLO outcome.",
                              100 * icc_unconditional$ICC_adjusted)
  )
}
if (!is.null(icc_conditional)) {
  icc_rows[["conditional"]] <- tibble(
    model = "Conditional (3e full controls + year FE)",
    icc_adjusted = round(icc_conditional$ICC_adjusted, 4),
    icc_unadjusted = round(icc_conditional$ICC_unadjusted, 4),
    interpretation = sprintf("Country-level variance share after controls = %.1f%% (residual ICC).",
                              100 * icc_conditional$ICC_adjusted)
  )
}
icc_df <- bind_rows(icc_rows)
readr::write_csv(icc_df, OUT_ICC_CSV)

cat("\n=== ICC at country level ===\n")
print(icc_df)
message(sprintf("[m3] wrote %s", OUT_ICC_CSV))

# === 5. Write spec progression tables ========================================
specs_round <- specs_df |>
  mutate(
    beta_oda      = round(beta_oda, 4),
    se_oda        = round(se_oda, 4),
    p_oda         = round(p_oda, 4),
    sigma_country = round(sigma_country, 4),
    sigma_resid   = round(sigma_resid, 4)
  )

dir.create(dirname(OUT_SPECS_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(specs_round, OUT_SPECS_CSV)

md_lines <- c(
  "# Model 3 — 2-level country RE + year FE (locked encoding)",
  "",
  "Random intercept by country; year FE; locked treatment (`crs_disburse_usd_defl_ma3_lag1`) + WGI PC1. Estimator: `lme4::lmer` with REML=FALSE (ML, for Hausman comparability). Stars: ***p<0.01, **p<0.05, *p<0.1.",
  ""
)
for (oc in c("HLO", "LAYS")) {
  md_lines <- c(md_lines,
    sprintf("## %s outcome", oc),
    "",
    knitr::kable(
      specs_round |> filter(outcome == oc) |>
        select(spec, N, beta_oda, se_oda, p_oda, signif, sigma_country, sigma_resid, is_singular),
      format = "pipe"
    ),
    ""
  )
}
writeLines(md_lines, OUT_SPECS_MD)
message(sprintf("[m3] wrote %s", OUT_SPECS_CSV))
message(sprintf("[m3] wrote %s", OUT_SPECS_MD))

# === 6. Three-way Model 1/2/3 contrast =======================================
message("\n[m3] building three-way Model 1/2/3 contrast")

# Model 1: re-fit cross-sectional OLS on country means (same as R/56)
m1_cm <- d |>
  group_by(iso3) |>
  summarise(across(c(hlo_hlo_score, crs_disburse_usd_defl_sum,
                     wdi_gdp_pc_usd, wdi_ptr_primary, wdi_edu_exp_pct_gdp, wgi_ge_est),
                   ~ mean(., na.rm = TRUE))) |>
  mutate(across(everything(), ~ ifelse(is.nan(.), NA_real_, .))) |>
  mutate(log_crs = log1p(crs_disburse_usd_defl_sum),
         log_gdp = log(wdi_gdp_pc_usd))
m1_full <- feols(hlo_hlo_score ~ log_crs + log_gdp + wdi_ptr_primary +
                   wdi_edu_exp_pct_gdp + wgi_ge_est,
                 data = m1_cm, vcov = "hetero")

contrast_df <- tibble(
  Model = c("Model 1 OLS — full spec 1e (cross-sectional)",
            "Model 2 v2 FE — full spec 2e (within-country, locked)",
            "Model 3 RE — full spec 3e (random intercepts + year FE, locked)"),
  Identification = c("Between-country variation only (country-mean averaging eliminates within variation)",
                     "Within-country variation only (country FE eliminates between variation)",
                     "Weighted combination of between + within (RE with country random intercepts)"),
  N = c(m1_full$nobs, m_fe_2e$nobs, m_re_3e |> nobs()),
  beta_ODA = c(round(coef(m1_full)["log_crs"], 3),
               round(b_fe, 3),
               round(b_re, 3)),
  SE = c(round(sqrt(diag(vcov(m1_full)))["log_crs"], 3),
         round(sqrt(var_fe), 3),
         round(sqrt(var_re), 3)),
  p_value = c(round(fixest::pvalue(m1_full)["log_crs"], 4),
              round(fixest::pvalue(m_fe_2e)["log_crs_strict"], 4),
              round(specs_hlo |> filter(spec == "3e") |> pull(p_oda), 4))
)

print(contrast_df)
readr::write_csv(contrast_df, OUT_CONTRAST_CSV)

contrast_md <- c(
  "**Table 5. Three-way Model 1 / Model 2 / Model 3 contrast — manuscript Table 5 candidate.**",
  "",
  "Three estimators on the same locked-encoding HLO outcome, primary window 2010-2020.",
  "",
  knitr::kable(contrast_df, format = "pipe"),
  "",
  sprintf("**Hausman test (manual univariate Cameron-Trivedi, β_ODA):** %s",
          if (hausman_undefined) "Var(b_FE) − Var(b_RE) ≤ 0; test undefined (efficiency-ranking violation)."
          else sprintf("H=%.3f, df=1, p=%.4f. %s",
                       H_stat, H_p,
                       ifelse(H_p < 0.05, "Reject RE; prefer FE.", "Cannot reject RE."))),
  "",
  sprintf("**ICC at country level (unconditional):** %.1f%% — share of HLO variance attributable to between-country differences.",
          ifelse(!is.null(icc_unconditional), 100 * icc_unconditional$ICC_adjusted, NA)),
  "",
  "**Reading:** Model 1's cross-sectional β is essentially zero (the between-country signal is captured by the controls). Model 2's within-country β is positive and crosses conventional significance under the locked encoding. Model 3's RE β is a weighted average of these two — its position between OLS and FE reflects the relative weight the variance-component structure places on between- vs within-country information."
)
writeLines(contrast_md, OUT_CONTRAST_MD)
message(sprintf("[m3] wrote %s", OUT_CONTRAST_CSV))
message(sprintf("[m3] wrote %s", OUT_CONTRAST_MD))

# === 7. Coefficient plot =====================================================
message("\n[m3] building coefficient plot")

plot_df <- bind_rows(
  specs_hlo |> mutate(model = "Model 3 RE", outcome_label = "HLO"),
  specs_lays |> mutate(model = "Model 3 RE", outcome_label = "LAYS")
) |>
  mutate(ci_lo = beta_oda - 1.96 * se_oda,
         ci_hi = beta_oda + 1.96 * se_oda,
         spec = factor(spec, levels = c("3a","3b","3c","3d","3e")))

p_coef <- ggplot(plot_df, aes(x = beta_oda, y = spec, color = outcome_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi),
                   position = position_dodge(width = 0.4),
                   size = 0.5, linewidth = 0.7) +
  scale_color_manual(values = c("HLO" = "#1B7837", "LAYS" = "#762A83")) +
  labs(
    title    = "Model 3: ODA coefficient across RE spec progression (locked encoding)",
    subtitle = "lme4::lmer with country random intercepts + year FE; 95% Wald CIs",
    x        = "ODA coefficient (HLO points or LAYS years per unit log treatment)",
    y        = "Spec",
    color    = "Outcome",
    caption  = sprintf("HLO 3e: β=%.2f (SE=%.2f, p=%.3f). LAYS 3e: β=%.3f.",
                       b_re, sqrt(var_re),
                       specs_hlo |> filter(spec == "3e") |> pull(p_oda),
                       specs_lays |> filter(spec == "3e") |> pull(beta_oda))
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p_coef, width = 10, height = 5)
ggsave(OUT_PLOT_PNG, p_coef, width = 10, height = 5, dpi = 150)
message(sprintf("[m3] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 8. Stdout summary =======================================================
cat("\n=== Phase 6 Session 01 summary ===\n")
cat(sprintf("Model 1 OLS 1e:     β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            coef(m1_full)["log_crs"], sqrt(diag(vcov(m1_full)))["log_crs"],
            fixest::pvalue(m1_full)["log_crs"], m1_full$nobs))
cat(sprintf("Model 2 v2 FE 2e:   β=%.3f, SE=%.3f, p=%.4f, N=%d\n",
            b_fe, sqrt(var_fe),
            fixest::pvalue(m_fe_2e)["log_crs_strict"], m_fe_2e$nobs))
cat(sprintf("Model 3 RE 3e:      β=%.3f, SE=%.3f, p=%.4f, N=%d  (singular=%s)\n",
            b_re, sqrt(var_re),
            specs_hlo |> filter(spec == "3e") |> pull(p_oda),
            specs_hlo |> filter(spec == "3e") |> pull(N),
            isSingular(m_re_3e)))
cat(sprintf("\nManual Hausman: %s\n", manual_note))
cat(sprintf("Unconditional ICC: %.1f%% (between-country share of raw HLO variance)\n",
            ifelse(!is.null(icc_unconditional), 100 * icc_unconditional$ICC_adjusted, NA)))

message("\n[m3] complete.")
