# R/72_pass1_robustness_battery.R
#
# Phase 10 Session 01: Pass 1 Statistical Validity — gap-closing robustness battery.
#
# Three diagnostics/robustness specs, all on the locked Model 2 spec 2e encoding:
#
#  1. Granger causality test (panel) — Dumitrescu/Hurlin (2012) via plm::pgrangertest.
#     log_crs_strict → hlo_hlo_score, order = 1 HCI cycle.
#     Pre-tests for reverse causality on the within-country panel.
#     Caveat: T_eff ≤ 4 HCI cycles per country; interpret as exploratory.
#
#  2. HLO measure sensitivity (ADR-0004 principal robustness) —
#     refit Model 2 spec 2e using `aap_hlo_aap` (Altinok-Angrist-Patrinos 2018)
#     as outcome instead of `hlo_hlo_score`. Use AAP's full coverage
#     (1995-2015, 5 cycles) rather than restricting to the 2010-2020 primary
#     window (which has only 2 AAP cycles). Success criterion per
#     methodology §3.4: sign + within-CI agreement with primary β=11.14.
#
#  3. UIS-augmented listwise (ADR-0006 Robustness 1) —
#     refit Model 2 spec 2e with uis_priv_exp_pct_gdp added to the regressor
#     stack. Listwise-complete sample (expected N ≈ 69 per Phase-2 MCAR).
#     Comparison to primary β=11.14.
#
# Plus a combined sign-off table summarizing all three vs primary.
#
# Inputs:
#   data/interim/panel.parquet  — production panel
#   (Model 2 locked coefficients referenced inline; not re-read from
#    output/tables/model2_fe_baseline_v2.csv to keep the battery self-
#    contained for cross-spec comparison.)
#
# Outputs (4 tables × 2 formats = 8 files):
#   output/tables/pass1_granger_test.{csv,md}
#   output/tables/pass1_hlo_sensitivity.{csv,md}
#   output/tables/pass1_uis_listwise.{csv,md}
#   output/tables/pass1_robustness_signoff.{csv,md}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(fixest)
  library(plm)
})

PANEL_PATH        <- "data/interim/panel.parquet"

OUT_GRANGER_CSV   <- "output/tables/pass1_granger_test.csv"
OUT_GRANGER_MD    <- "output/tables/pass1_granger_test.md"
OUT_HLO_CSV       <- "output/tables/pass1_hlo_sensitivity.csv"
OUT_HLO_MD        <- "output/tables/pass1_hlo_sensitivity.md"
OUT_UIS_CSV       <- "output/tables/pass1_uis_listwise.csv"
OUT_UIS_MD        <- "output/tables/pass1_uis_listwise.md"
OUT_SIGNOFF_CSV   <- "output/tables/pass1_robustness_signoff.csv"
OUT_SIGNOFF_MD    <- "output/tables/pass1_robustness_signoff.md"

WGI_DIMS <- c("wgi_va_est", "wgi_pv_est", "wgi_ge_est",
              "wgi_rq_est", "wgi_rl_est", "wgi_cc_est")

# Locked Model 2 spec 2e reference (from output/tables/model2_fe_baseline_v2.csv;
# repeated inline here for cross-spec sign+within-CI comparison)
PRIMARY_BETA <- 11.1360
PRIMARY_SE   <- 5.5180
PRIMARY_N    <- 143
PRIMARY_LO   <- PRIMARY_BETA - 1.96 * PRIMARY_SE
PRIMARY_HI   <- PRIMARY_BETA + 1.96 * PRIMARY_SE

# === 1. Setup panel + PC1 (matches R/57 / R/51 encoding) ====================
message("[m10] loading production panel")
d_full <- arrow::read_parquet(PANEL_PATH)

# Build PC1 from WGI dims, sign-flipped to align with wgi_ge_est (R/57 convention)
build_pc1 <- function(d) {
  wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
  complete_rows <- complete.cases(wgi_mat)
  pca <- prcomp(wgi_mat[complete_rows, ], scale. = TRUE, center = TRUE)
  if (pca$rotation["wgi_ge_est", "PC1"] < 0) {
    pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
    pca$x[, "PC1"]        <- -pca$x[, "PC1"]
  }
  out <- rep(NA_real_, nrow(d))
  out[complete_rows] <- pca$x[, "PC1"]
  out
}

d_full$wgi_pc1 <- build_pc1(d_full)
d_full <- d_full |> mutate(
  log_crs_strict = log1p(crs_disburse_usd_defl_ma3_lag1),
  log_gdp_pc     = log(wdi_gdp_pc_usd)
)

# Primary-window panel (matches Model 2 spec 2e estimation sample)
d_primary <- d_full |> filter(in_primary_window)

# === 2. Granger causality test ==============================================
message("\n[m10] running Granger causality test (log_crs_strict → hlo_hlo_score)")

# Build a balanced-as-possible (iso3, year) panel restricted to rows with
# both treatment and outcome non-missing.
plm_d <- d_primary |>
  filter(!is.na(hlo_hlo_score), !is.na(log_crs_strict)) |>
  select(iso3, year, hlo_hlo_score, log_crs_strict) |>
  as.data.frame()

# pgrangertest needs >=2 obs per country and a panel structure
plm_d <- pdata.frame(plm_d, index = c("iso3", "year"))

granger_result <- tryCatch(
  plm::pgrangertest(hlo_hlo_score ~ log_crs_strict,
                    data = plm_d, order = 1L, test = "Ztilde"),
  error = function(e) {
    message("[m10] pgrangertest failed: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(granger_result)) {
  cat("\n=== Granger test result ===\n")
  print(granger_result)
  granger_tbl <- tibble(
    test       = "Dumitrescu-Hurlin (Z-tilde) panel Granger",
    direction  = "log_crs_strict → hlo_hlo_score",
    order_lag  = 1,
    statistic  = round(unname(granger_result$statistic), 4),
    p_value    = round(granger_result$p.value, 4),
    n_countries = length(unique(plm_d$iso3)),
    note       = sprintf("T_eff per country = %d (HCI cycles only). Exploratory; interpret with caution given small T.",
                         length(unique(plm_d$year)))
  )
} else {
  granger_tbl <- tibble(
    test = "Dumitrescu-Hurlin panel Granger",
    direction = "log_crs_strict → hlo_hlo_score",
    order_lag = 1, statistic = NA_real_, p_value = NA_real_,
    n_countries = length(unique(plm_d$iso3)),
    note = "pgrangertest failed; see stdout / consider lag-order reduction"
  )
}

readr::write_csv(granger_tbl, OUT_GRANGER_CSV)
writeLines(c(
  "# Pass 1 — Granger causality test (panel)",
  "",
  "**Direction:** `log_crs_strict → hlo_hlo_score` (one-cycle lag).",
  "**Test:** Dumitrescu-Hurlin (2012) Z-tilde panel Granger (`plm::pgrangertest`).",
  "**Caveat:** T_eff ≤ 4 HCI cycles per country in primary window — interpret as exploratory pre-test, not a definitive reverse-causality verdict.",
  "",
  knitr::kable(granger_tbl, format = "pipe"),
  "",
  "**Reading:** rejection of the null \"log(CRS) does not Granger-cause HLO\" provides exploratory support for the treatment-side direction of the within-country association. Non-rejection at small T is uninformative rather than evidence of no causality."
), OUT_GRANGER_MD)
message(sprintf("[m10] wrote %s and %s", OUT_GRANGER_CSV, OUT_GRANGER_MD))

# === 3. HLO measure sensitivity (AAP-2018) ===================================
message("\n[m10] refitting Model 2 spec 2e on AAP-2018 HLO measure")

# AAP-2018 covers 1995-2015 (5 cycles in our panel). Two specs:
#   3a: Full AAP coverage (1995-2015, 5 cycles) — uses AAP's natural data shape
#   3b: AAP restricted to overlap window (year >= 2010, only 2 AAP cycles)
#       — isolates "measure choice" effect from "sample-window composition" effect
# If 3a and 3b agree → sample window is not driving the result (measure effect).
# If 3a disagrees with 3b → sign-flip is window-composition (different aid epoch).

# 3a: Full AAP coverage
d_aap_full <- d_full |>
  filter(!is.na(aap_hlo_aap),
         !is.na(log_crs_strict), !is.na(log_gdp_pc),
         !is.na(wdi_ptr_primary), !is.na(wdi_edu_exp_pct_gdp),
         !is.na(wgi_pc1))

cat(sprintf("[m10] AAP-2018 full estimation sample N = %d rows, %d countries, year range %d-%d\n",
            nrow(d_aap_full), length(unique(d_aap_full$iso3)),
            min(d_aap_full$year), max(d_aap_full$year)))

m_aap_full <- feols(
  aap_hlo_aap ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
  data = d_aap_full, vcov = ~iso3
)

# 3b: AAP restricted to overlap with primary window (year >= 2010)
d_aap_overlap <- d_aap_full |> filter(year >= 2010)
cat(sprintf("[m10] AAP-2018 overlap-window (year>=2010) sample N = %d rows, %d countries\n",
            nrow(d_aap_overlap), length(unique(d_aap_overlap$iso3))))

m_aap_overlap <- if (length(unique(d_aap_overlap$year)) >= 2 &&
                     length(unique(d_aap_overlap$iso3)) >= 5) {
  tryCatch(
    feols(
      aap_hlo_aap ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                    wdi_edu_exp_pct_gdp + wgi_pc1 | iso3 + year,
      data = d_aap_overlap, vcov = ~iso3
    ),
    error = function(e) { message("[m10] AAP-overlap feols failed: ", conditionMessage(e)); NULL }
  )
} else NULL

# Use the FULL AAP spec as the primary AAP sensitivity (per ADR-0004 framing);
# overlap is the supporting evidence on window-vs-measure decomposition.
m_aap <- m_aap_full
d_aap <- d_aap_full

aap_beta <- unname(coef(m_aap)["log_crs_strict"])
aap_se   <- unname(sqrt(diag(vcov(m_aap)))["log_crs_strict"])
aap_n    <- m_aap$nobs
aap_p    <- unname(fixest::pvalue(m_aap)["log_crs_strict"])
aap_lo   <- aap_beta - 1.96 * aap_se
aap_hi   <- aap_beta + 1.96 * aap_se

# Overlap-window beta (NA if not estimated)
if (!is.null(m_aap_overlap)) {
  aap_ov_beta <- unname(coef(m_aap_overlap)["log_crs_strict"])
  aap_ov_se   <- unname(sqrt(diag(vcov(m_aap_overlap)))["log_crs_strict"])
  aap_ov_n    <- m_aap_overlap$nobs
  aap_ov_p    <- unname(fixest::pvalue(m_aap_overlap)["log_crs_strict"])
} else {
  aap_ov_beta <- NA_real_; aap_ov_se <- NA_real_; aap_ov_n <- NA_integer_; aap_ov_p <- NA_real_
}

# Sign + within-CI agreement (primary vs full AAP)
sign_agree    <- sign(aap_beta) == sign(PRIMARY_BETA)
within_ci     <- (aap_beta >= PRIMARY_LO & aap_beta <= PRIMARY_HI) ||
                 (PRIMARY_BETA >= aap_lo & PRIMARY_BETA <= aap_hi)

# Overlap-window decomposition reading
ov_sign_agree <- if (!is.na(aap_ov_beta)) sign(aap_ov_beta) == sign(PRIMARY_BETA) else NA

hlo_tbl <- tibble(
  spec        = c("Primary (WB HD.HCI.HLOS, 2010-2020)",
                  "AAP-2018 full coverage (1995-2015)",
                  "AAP-2018 overlap window (year >= 2010)"),
  outcome     = c("hlo_hlo_score", "aap_hlo_aap", "aap_hlo_aap"),
  N           = c(PRIMARY_N, aap_n, aap_ov_n),
  beta        = round(c(PRIMARY_BETA, aap_beta, aap_ov_beta), 4),
  se          = round(c(PRIMARY_SE,   aap_se,   aap_ov_se),   4),
  p_value     = round(c(NA_real_,     aap_p,    aap_ov_p),    4)
)

readr::write_csv(hlo_tbl, OUT_HLO_CSV)
writeLines(c(
  "# Pass 1 — HLO measure sensitivity (ADR-0004 principal robustness)",
  "",
  "Refit of Model 2 spec 2e (locked encoding: log_crs_strict + log_gdp_pc + wdi_ptr_primary + wdi_edu_exp_pct_gdp + wgi_pc1; two-way FE country + year; country-clustered SE) with the AAP-2018 harmonized learning outcome (`aap_hlo_aap`) substituted for the WB primary measure.",
  "",
  "**Two AAP-2018 specifications** to disentangle measure-choice vs sample-window effects:",
  "",
  sprintf("- **AAP full coverage** — N = %d rows, %d countries, year range %d-%d (5 AAP cycles).",
          aap_n, length(unique(d_aap$iso3)), min(d_aap$year), max(d_aap$year)),
  sprintf("- **AAP overlap window (year ≥ 2010)** — N = %s rows, %s countries (2 AAP cycles in primary window).",
          if(is.na(aap_ov_n)) "n/a" else as.character(aap_ov_n),
          if(is.na(aap_ov_n)) "n/a" else as.character(length(unique(d_aap_overlap$iso3)))),
  "",
  knitr::kable(hlo_tbl, format = "pipe"),
  "",
  sprintf("**Sign agreement (primary vs AAP full):** %s", ifelse(sign_agree, "✓ same sign", "✗ DIFFERENT SIGN")),
  sprintf("**Within-CI agreement (full):** %s", ifelse(within_ci, "✓ within-CI", "✗ outside-CI")),
  sprintf("**Sign agreement (primary vs AAP overlap-window):** %s",
          if(is.na(ov_sign_agree)) "not estimable (insufficient overlap)"
          else if(ov_sign_agree) "✓ same sign" else "✗ DIFFERENT SIGN"),
  "",
  "**Reading per methodology §3.4:** \"the within-country coefficient must be the same sign and within-CI magnitude across the primary and AAP-2018 specifications for the headline claim to stand.\"  The two AAP variants test whether any sign disagreement is driven by *measure choice* (AAP harmonization vs WB HCI) or by *sample-window composition* (AAP's pre-2010 epoch vs primary's 2010-2020). If full-AAP and overlap-AAP agree → measure-effect. If they disagree → window-effect."
), OUT_HLO_MD)
message(sprintf("[m10] wrote %s and %s", OUT_HLO_CSV, OUT_HLO_MD))

# === 4. UIS-augmented listwise (ADR-0006 Robustness 1) =======================
message("\n[m10] refitting Model 2 spec 2e + UIS private expenditure (listwise)")

d_uis <- d_primary |>
  filter(!is.na(hlo_hlo_score),
         !is.na(log_crs_strict), !is.na(log_gdp_pc),
         !is.na(wdi_ptr_primary), !is.na(wdi_edu_exp_pct_gdp),
         !is.na(wgi_pc1),
         !is.na(uis_priv_exp_pct_gdp))

cat(sprintf("[m10] UIS-augmented listwise N = %d rows (expected ~69 per Phase-2 MCAR)\n",
            nrow(d_uis)))

m_uis <- feols(
  hlo_hlo_score ~ log_crs_strict + log_gdp_pc + wdi_ptr_primary +
                  wdi_edu_exp_pct_gdp + wgi_pc1 + uis_priv_exp_pct_gdp |
                  iso3 + year,
  data = d_uis, vcov = ~iso3
)

uis_beta <- unname(coef(m_uis)["log_crs_strict"])
uis_se   <- unname(sqrt(diag(vcov(m_uis)))["log_crs_strict"])
uis_n    <- m_uis$nobs
uis_p    <- unname(fixest::pvalue(m_uis)["log_crs_strict"])
uis_lo   <- uis_beta - 1.96 * uis_se
uis_hi   <- uis_beta + 1.96 * uis_se

uis_sign_agree <- sign(uis_beta) == sign(PRIMARY_BETA)
uis_within_ci  <- (uis_beta >= PRIMARY_LO & uis_beta <= PRIMARY_HI) ||
                  (PRIMARY_BETA >= uis_lo & PRIMARY_BETA <= uis_hi)

# Also report the UIS covariate itself
uis_cov_beta <- unname(coef(m_uis)["uis_priv_exp_pct_gdp"])
uis_cov_se   <- unname(sqrt(diag(vcov(m_uis)))["uis_priv_exp_pct_gdp"])
uis_cov_p    <- unname(fixest::pvalue(m_uis)["uis_priv_exp_pct_gdp"])

uis_tbl <- tibble(
  spec        = c("Primary (UIS dropped, ADR-0006 Option 3)", "Robustness 1 (UIS-augmented listwise)"),
  N           = c(PRIMARY_N, uis_n),
  beta_ODA    = round(c(PRIMARY_BETA, uis_beta), 4),
  se_ODA      = round(c(PRIMARY_SE,   uis_se), 4),
  ci_lo_ODA   = round(c(PRIMARY_LO,   uis_lo), 4),
  ci_hi_ODA   = round(c(PRIMARY_HI,   uis_hi), 4),
  p_ODA       = round(c(NA_real_,     uis_p), 4),
  beta_UIS    = c(NA_real_, round(uis_cov_beta, 4)),
  se_UIS      = c(NA_real_, round(uis_cov_se, 4)),
  p_UIS       = c(NA_real_, round(uis_cov_p, 4))
)

readr::write_csv(uis_tbl, OUT_UIS_CSV)
writeLines(c(
  "# Pass 1 — UIS-augmented listwise (ADR-0006 Robustness 1)",
  "",
  "Refit of Model 2 spec 2e with `uis_priv_exp_pct_gdp` added to the regressor stack. Listwise-complete subset on the 2010-2020 primary window. Per ADR-0006, this is *Robustness 1* of three originally committed (Robustness 2 = MI, now retired per ADR-0012; Robustness 3 = the primary UIS-dropped spec).",
  "",
  sprintf("**UIS-augmented listwise N = %d** vs primary N = %d (~%.0f%% sample loss adding UIS).",
          uis_n, PRIMARY_N, 100 * (1 - uis_n / PRIMARY_N)),
  "",
  knitr::kable(uis_tbl, format = "pipe"),
  "",
  sprintf("**ODA-coefficient sign agreement:** %s", ifelse(uis_sign_agree, "✓ same sign", "✗ DIFFERENT SIGN — investigate")),
  sprintf("**ODA-coefficient within-CI agreement:** %s", ifelse(uis_within_ci, "✓ within-CI", "✗ outside-CI — investigate")),
  "",
  "**Reading per ADR-0006:** if primary, listwise-UIS, and (former) MI-UIS all give the same sign and within-CI magnitude, the result is robust to the UIS-inclusion choice. With MI retired by ADR-0012, the listwise vs primary comparison carries the full robustness burden in that direction."
), OUT_UIS_MD)
message(sprintf("[m10] wrote %s and %s", OUT_UIS_CSV, OUT_UIS_MD))

# === 5. Combined sign-off table ==============================================
message("\n[m10] building combined sign-off table")

signoff_tbl <- tibble(
  spec         = c("Primary (locked Model 2 spec 2e)",
                   "Granger pre-test (DH Z-tilde, order=1)",
                   "HLO sensitivity (AAP-2018)",
                   "UIS-augmented listwise (ADR-0006 Rob 1)"),
  source       = c("output/tables/model2_fe_baseline_v2.csv",
                   "pass1_granger_test.csv",
                   "pass1_hlo_sensitivity.csv",
                   "pass1_uis_listwise.csv"),
  N            = c(PRIMARY_N,
                   length(unique(plm_d$iso3)),
                   aap_n, uis_n),
  beta_ODA     = c(PRIMARY_BETA,
                   NA_real_,
                   round(aap_beta, 4),
                   round(uis_beta, 4)),
  se_ODA       = c(PRIMARY_SE,
                   NA_real_,
                   round(aap_se, 4),
                   round(uis_se, 4)),
  p_ODA        = c(NA_real_,
                   if(!is.null(granger_result)) round(granger_result$p.value, 4) else NA_real_,
                   round(aap_p, 4),
                   round(uis_p, 4)),
  passes       = c("(reference)",
                   if(!is.null(granger_result) && granger_result$p.value < 0.10) "Granger rejects null at p<0.10 — directional support" else "Granger non-rejection at small T (uninformative)",
                   ifelse(sign_agree && within_ci, "PASS (sign + within-CI)", "INVESTIGATE"),
                   ifelse(uis_sign_agree && uis_within_ci, "PASS (sign + within-CI)", "INVESTIGATE"))
)

readr::write_csv(signoff_tbl, OUT_SIGNOFF_CSV)
writeLines(c(
  "# Pass 1 — Combined robustness sign-off",
  "",
  "Three sensitivity specs run as Phase 10 Session 01 gap-closing battery, each compared to the locked Model 2 spec 2e primary (β = 11.14, SE = 5.52, N = 143). Sign + within-CI agreement is the success criterion.",
  "",
  knitr::kable(signoff_tbl, format = "pipe"),
  "",
  "**Overall sign-off:** the Pass 1 robustness battery is reported in `findings.md §5.8` and consolidates into the `output/pass1_statistical_validity_audit.md` gate document. Remaining obligations not requiring code (UNESCO bias note; 3-level HLM scope decision) are documented in methodology §3.6 and §3.8 respectively."
), OUT_SIGNOFF_MD)
message(sprintf("[m10] wrote %s and %s", OUT_SIGNOFF_CSV, OUT_SIGNOFF_MD))

# === 6. stdout summary =======================================================
cat("\n=== Phase 10 Session 01 summary ===\n")
cat(sprintf("Primary (locked): β=%.4f, SE=%.4f, N=%d, 95%% CI [%.4f, %.4f]\n",
            PRIMARY_BETA, PRIMARY_SE, PRIMARY_N, PRIMARY_LO, PRIMARY_HI))

if (!is.null(granger_result)) {
  cat(sprintf("\nGranger DH Z-tilde, order=1: statistic = %.4f, p = %.4f, N countries = %d\n",
              unname(granger_result$statistic), granger_result$p.value,
              length(unique(plm_d$iso3))))
}

cat(sprintf("\nHLO sensitivity (AAP-2018): β = %.4f, SE = %.4f, N = %d (sign agree=%s, within-CI=%s)\n",
            aap_beta, aap_se, aap_n, sign_agree, within_ci))

cat(sprintf("\nUIS-augmented listwise: β_ODA = %.4f, SE = %.4f, N = %d (sign agree=%s, within-CI=%s)\n",
            uis_beta, uis_se, uis_n, uis_sign_agree, uis_within_ci))
cat(sprintf("                       β_UIS = %.4f, SE = %.4f, p = %.4f\n",
            uis_cov_beta, uis_cov_se, uis_cov_p))

message("\n[m10] complete.")
