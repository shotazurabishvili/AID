# R/70_model5_counterfactual.R
#
# Phase 8 Session 01: Model 5 counterfactual simulation (redesigned).
#
# Per ADR-0011: brief's original "$1B redirect from input-based to outcome-based
# programs using Model-4 effect sizes" cannot be honored after Model 4 was
# dropped (ADR-0007 Rejected). Two further constraints:
#
#   (a) Applying a literal +$1B annual shock to a single aid-receiving country
#       (median baseline ~$10-50M) is a 20-100x increase — wildly outside the
#       support of the within-country variation Model 2's β was identified on
#       (typical year-over-year Δlog(CRS) ≈ 0.1-0.5). The β is a marginal
#       within-sample effect, not a 100x extrapolation coefficient.
#
#   (b) Without Model 4 there is no "input-based vs outcome-based" axis to
#       redirect *between*. The brief's redirect framing has no quantitative
#       referent in this paper's identified models.
#
# Redesign: report Model 5 as a within-support marginal counterfactual on the
# already-identified Model 2 aggregate β. Three within-data shocks (+10%, +50%,
# +100% of the median country's MA disbursement) × three CI scenarios
# (lower 95% / point / upper 95% of Model 2 β) = 9 ΔHLO cells; each translated
# to ΔLAYS at three implied-EYS percentiles via the WB LAYS identity.
#
# The brief's $1B is reported separately as a *bridging context note* — what
# fraction of the sample's total annual CRS it represents, and which within-
# support scenario it most closely corresponds to. Bridge is in the output md,
# not in the headline scenario table. This is the honest face of the Model-4
# drop: §5.5 owned that the composition question is unanswerable; §5.6 now
# owns that the brief's $1B-redirect dollar-amount framing is not faithfully
# operationalizable without Model 4 either, and substitutes a within-support
# % shock that the data actually identifies.
#
# Inputs:
#   data/interim/panel.parquet                — production panel (Phase 2)
#   output/tables/model2_fe_baseline_v2.csv   — locked Model 2 spec 2e β + SE
#
# Outputs:
#   output/tables/model5_counterfactual.{csv,md}
#   output/tables/model5_baseline_quartile_sensitivity.{csv,md}
#   output/figures/model5_scenario_plot.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
})

PANEL_PATH      <- "data/interim/panel.parquet"
M2_BASELINE     <- "output/tables/model2_fe_baseline_v2.csv"

OUT_MAIN_CSV    <- "output/tables/model5_counterfactual.csv"
OUT_MAIN_MD     <- "output/tables/model5_counterfactual.md"
OUT_QSENS_CSV   <- "output/tables/model5_baseline_quartile_sensitivity.csv"
OUT_QSENS_MD    <- "output/tables/model5_baseline_quartile_sensitivity.md"
OUT_PLOT_PDF    <- "output/figures/model5_scenario_plot.pdf"
OUT_PLOT_PNG    <- "output/figures/model5_scenario_plot.png"

HLO_SCALE_MAX   <- 625    # Upper anchor of HCI HLOS scale (per WB LAYS identity)

# === 1. Load Model 2 spec 2e locked coefficients =============================
message("[m5] loading Model 2 spec 2e locked coefficients from ", M2_BASELINE)
m2 <- readr::read_csv(M2_BASELINE, show_col_types = FALSE)

# Extract β and SE for `log(1 + CRS disburse strict-past MA3)` from the 2e column.
beta_row <- m2 |>
  filter(term == "log(1 + CRS disburse strict-past MA3)", statistic == "estimate") |>
  pull(`2e (+WGI PC1; full)`)
se_row <- m2 |>
  filter(term == "log(1 + CRS disburse strict-past MA3)", statistic == "std.error") |>
  pull(`2e (+WGI PC1; full)`)
n_row <- m2 |>
  filter(part == "gof", term == "N") |>
  pull(`2e (+WGI PC1; full)`) |>
  as.integer()

# Strip the "**" significance marker and parenthesised SE formatting
beta_2e <- as.numeric(stringr::str_remove_all(beta_row, "[*]"))
se_2e   <- as.numeric(stringr::str_remove_all(se_row, "[()]"))
n_2e    <- n_row

stopifnot(!is.na(beta_2e), !is.na(se_2e), !is.na(n_2e))
cat(sprintf("[m5] Locked Model 2 spec 2e: β=%.4f, SE=%.4f, N=%d\n", beta_2e, se_2e, n_2e))

beta_lo <- beta_2e - 1.96 * se_2e
beta_hi <- beta_2e + 1.96 * se_2e

# === 2. Load panel, restrict to Model 2 estimation sample ====================
message("\n[m5] loading panel and restricting to Model 2 spec 2e complete cases")
d <- arrow::read_parquet(PANEL_PATH) |> filter(in_primary_window)

# Build PC1 the same way R/57 does so we can identify the complete-case sample
WGI_DIMS <- c("wgi_va_est", "wgi_pv_est", "wgi_ge_est",
              "wgi_rq_est", "wgi_rl_est", "wgi_cc_est")
wgi_mat <- d |> select(all_of(WGI_DIMS)) |> as.matrix()
complete_wgi <- complete.cases(wgi_mat)
pca <- prcomp(wgi_mat[complete_wgi, ], scale. = TRUE, center = TRUE)
if (pca$rotation["wgi_ge_est", "PC1"] < 0) {
  pca$rotation[, "PC1"] <- -pca$rotation[, "PC1"]
  pca$x[, "PC1"]        <- -pca$x[, "PC1"]
}
d$wgi_pc1 <- NA_real_
d$wgi_pc1[complete_wgi] <- pca$x[, "PC1"]

# Spec 2e regressor stack: hlo + log_crs + log_gdp + ptr + ed_exp + wgi_pc1
est_sample <- d |>
  mutate(log_crs_strict = log1p(crs_disburse_usd_defl_ma3_lag1),
         log_gdp_pc     = log(wdi_gdp_pc_usd)) |>
  filter(!is.na(hlo_hlo_score),
         !is.na(log_crs_strict),
         !is.na(log_gdp_pc),
         !is.na(wdi_ptr_primary),
         !is.na(wdi_edu_exp_pct_gdp),
         !is.na(wgi_pc1))

cat(sprintf("[m5] Estimation-sample reconstruction: N=%d rows (target: %d from locked table)\n",
            nrow(est_sample), n_2e))
# Note: small drift possible if singletons differ between feols and our filter;
# treatment baselines come from this sample, which closely mirrors Model 2.

# === 3. Baseline disbursement summaries (units: constant USD MILLIONS) ======
# crs_disburse_usd_defl_ma3_lag1 is in constant USD millions per
# data_dictionary.md (the CRS panel preserves OECD's source-native millions).
baseline_ma <- est_sample$crs_disburse_usd_defl_ma3_lag1
baseline_summary <- tibble(
  statistic = c("Q1 (25th pctile)", "Median (50th pctile)", "Q3 (75th pctile)",
                "Mean", "Min", "Max", "N rows"),
  value_usd_M = c(quantile(baseline_ma, 0.25, na.rm = TRUE),
                  median(baseline_ma, na.rm = TRUE),
                  quantile(baseline_ma, 0.75, na.rm = TRUE),
                  mean(baseline_ma, na.rm = TRUE),
                  min(baseline_ma, na.rm = TRUE),
                  max(baseline_ma, na.rm = TRUE),
                  length(baseline_ma))
) |> mutate(value_usd_M = round(value_usd_M, 2))

cat("\n=== Baseline annual CRS disburse (MA3-lag1, constant USD millions) ===\n")
print(baseline_summary)

baseline_med <- median(baseline_ma, na.rm = TRUE)
baseline_q1  <- quantile(baseline_ma, 0.25, na.rm = TRUE) |> unname()
baseline_q3  <- quantile(baseline_ma, 0.75, na.rm = TRUE) |> unname()
sample_total_M <- sum(baseline_ma, na.rm = TRUE)  # total annual aid in the sample, USD M

# === 4. Implied EYS distribution from the LAYS identity ======================
# LAYS = EYS * (HLO/625)  ⇒  EYS = LAYS * 625 / HLO   (per methodology.md §3.4)
eys_impl <- est_sample |>
  filter(!is.na(hci_lays_overall), hlo_hlo_score > 0) |>
  mutate(eys_impl = hci_lays_overall * HLO_SCALE_MAX / hlo_hlo_score) |>
  pull(eys_impl)

eys_p10 <- unname(quantile(eys_impl, 0.10, na.rm = TRUE))
eys_p50 <- unname(quantile(eys_impl, 0.50, na.rm = TRUE))
eys_p90 <- unname(quantile(eys_impl, 0.90, na.rm = TRUE))

cat(sprintf("\nImplied EYS (LAYS×625/HLO) percentiles on est sample (N=%d): p10=%.2f yr, p50=%.2f yr, p90=%.2f yr\n",
            length(eys_impl), eys_p10, eys_p50, eys_p90))

# === 5. Within-support headline scenarios (+10%, +50%, +100% on median country)
shock_pcts <- c(0.10, 0.50, 1.00)
shock_labels <- c("+10% (low-shock)", "+50% (mid-shock)", "+100% (high-shock)")
beta_scenarios <- c(lower95 = beta_lo, point = beta_2e, upper95 = beta_hi)
beta_labels    <- c(lower95 = "Worst case (β lower 95% CI)",
                    point   = "Expected case (β point estimate)",
                    upper95 = "Best case (β upper 95% CI)")

main_grid <- expand_grid(shock_pct = shock_pcts,
                         beta_label_key = names(beta_scenarios)) |>
  mutate(
    baseline_usd_M  = baseline_med,
    shock_usd_M     = baseline_med * shock_pct,
    new_ma_usd_M    = baseline_med + shock_usd_M,
    delta_log_crs   = log1p(new_ma_usd_M) - log1p(baseline_med),
    beta_value      = beta_scenarios[beta_label_key],
    delta_hlo_pts   = beta_value * delta_log_crs,
    shock_label     = factor(shock_pct, levels = shock_pcts, labels = shock_labels),
    scenario_label  = beta_labels[beta_label_key],
    delta_lays_p10  = eys_p10 * delta_hlo_pts / HLO_SCALE_MAX,
    delta_lays_p50  = eys_p50 * delta_hlo_pts / HLO_SCALE_MAX,
    delta_lays_p90  = eys_p90 * delta_hlo_pts / HLO_SCALE_MAX
  )

main_out <- main_grid |>
  transmute(
    shock          = as.character(shock_label),
    scenario       = scenario_label,
    baseline_usd_M = round(baseline_usd_M, 2),
    shock_usd_M    = round(shock_usd_M, 2),
    delta_log_crs  = round(delta_log_crs, 4),
    beta_value     = round(beta_value, 4),
    delta_hlo_pts  = round(delta_hlo_pts, 3),
    delta_lays_p10 = round(delta_lays_p10, 4),
    delta_lays_p50 = round(delta_lays_p50, 4),
    delta_lays_p90 = round(delta_lays_p90, 4)
  ) |>
  arrange(shock, factor(scenario, levels = beta_labels))

dir.create(dirname(OUT_MAIN_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(main_out, OUT_MAIN_CSV)

# Brief-bridge context number: $1B distributed across the est sample = $X per
# country avg = Y% on the median baseline → which within-support cell it lands in
mean_per_country_if_1B <- 1000 / nrow(est_sample)   # $M per country
pct_of_median_if_1B    <- 100 * mean_per_country_if_1B / baseline_med
total_pct_of_sample    <- 100 * 1000 / sample_total_M

main_md <- c(
  "# Model 5 — Counterfactual (within-support headline scenarios)",
  "",
  "**Source:** locked Model 2 spec 2e (HLO outcome, two-way FE country + year, country-clustered SE). β = ",
  sprintf("%.4f (SE %.4f, N = %d). 95%% CI = [%.4f, %.4f].", beta_2e, se_2e, n_2e, beta_lo, beta_hi),
  "",
  sprintf("**Baseline:** median annual CRS disbursement (MA3-lag1, constant USD millions) across the Model 2 estimation sample = **$%.1fM**. Q1 = $%.1fM; Q3 = $%.1fM.",
          baseline_med, baseline_q1, baseline_q3),
  "",
  "**Shocks:** within-support percentage increases applied to the median country's annual disbursement. These stay near the support of the within-country log-CRS variation Model 2 was estimated on; a literal $1B injection to a single country (~20-50× baseline) would be a wild extrapolation beyond that support — see ADR-0011 and the brief-bridge note below.",
  "",
  "**LAYS translation** via the WB identity ΔLAYS = EYS × ΔHLO / 625, holding EYS constant. Implied-EYS percentiles on the estimation sample: ",
  sprintf("p10 = %.2f yr; p50 = %.2f yr; p90 = %.2f yr.", eys_p10, eys_p50, eys_p90),
  "",
  knitr::kable(main_out, format = "pipe"),
  "",
  "## Brief-bridge context: where does the brief's $1B redirect land?",
  "",
  sprintf("A $1B annual increase distributed across the %d-country Model 2 estimation sample = **$%.2fM per country on average**, which is **%.1f%%** of the median baseline ($%.1fM) and **%.2f%%** of the sample's total annual education aid ($%.1fB). This lands in the low-shock band of the headline table; the brief's $1B is *not* well-described by the highest-shock scenarios above. Applying the entire $1B to a single country would push that country %.0f× above its baseline — outside the data support Model 2 was identified on, and we do not project there.",
          nrow(est_sample), mean_per_country_if_1B, pct_of_median_if_1B,
          baseline_med, total_pct_of_sample, sample_total_M / 1000,
          (1000 + baseline_med) / baseline_med),
  "",
  "## Limits acknowledged (per ADR-0011)",
  "",
  "- **Identification:** Model 2 is static FE on small-T (T_eff ≤ 4 HCI cycles per country); GMM unavailable (ADR-0010). β is identified within-country over time but does not preclude unmeasured time-varying confounding.",
  "- **Composition:** counterfactual is on aggregate CRS disbursement only. The brief's input-vs-outcome typology question is unanswered (ADR-0007 Rejected; findings.md §5.5).",
  "- **Single-cycle marginal projection** (one HCI cycle ≈ 5 yr); no inter-temporal discounting; not a steady-state forecast.",
  "- **Plug-in CI propagation** on β only (does not propagate joint regressor covariance) — chosen as the honest match for the static-FE inference base; a full Monte Carlo would overreach.",
  "- **LAYS identity holds EYS constant**, isolating the learning-quality channel; sensitivity to EYS across p10/p50/p90 is reported in-table.",
  "- **Implementation quality / political economy / absorptive capacity** caveats per brief §2.",
  ""
)
writeLines(main_md, OUT_MAIN_MD)
message(sprintf("[m5] wrote %s and %s", OUT_MAIN_CSV, OUT_MAIN_MD))

# === 6. Baseline-quartile sensitivity ========================================
# Same three shock × three β scenarios, but baseline at Q1 / Q2 / Q3
quart_grid <- expand_grid(
  baseline_label = c("Q1 (25th pctile)", "Median (50th pctile)", "Q3 (75th pctile)"),
  shock_pct      = shock_pcts,
  beta_label_key = names(beta_scenarios)
) |>
  mutate(
    baseline_usd_M = case_when(
      baseline_label == "Q1 (25th pctile)"     ~ baseline_q1,
      baseline_label == "Median (50th pctile)" ~ baseline_med,
      baseline_label == "Q3 (75th pctile)"     ~ baseline_q3
    ),
    shock_usd_M    = baseline_usd_M * shock_pct,
    new_ma_usd_M   = baseline_usd_M + shock_usd_M,
    delta_log_crs  = log1p(new_ma_usd_M) - log1p(baseline_usd_M),
    beta_value     = beta_scenarios[beta_label_key],
    delta_hlo_pts  = beta_value * delta_log_crs,
    delta_lays_p50 = eys_p50 * delta_hlo_pts / HLO_SCALE_MAX,
    scenario_label = beta_labels[beta_label_key],
    shock_label    = factor(shock_pct, levels = shock_pcts, labels = shock_labels)
  )

quart_out <- quart_grid |>
  transmute(
    baseline       = baseline_label,
    shock          = as.character(shock_label),
    scenario       = scenario_label,
    baseline_usd_M = round(baseline_usd_M, 2),
    delta_log_crs  = round(delta_log_crs, 4),
    delta_hlo_pts  = round(delta_hlo_pts, 3),
    delta_lays_p50 = round(delta_lays_p50, 4)
  )

readr::write_csv(quart_out, OUT_QSENS_CSV)
quart_md <- c(
  "# Model 5 — Baseline-quartile sensitivity",
  "",
  "Same shock × β scenario grid as the headline table, but applied at the Q1 / median / Q3 of baseline CRS across the Model 2 estimation sample. ΔLAYS uses the median implied-EYS only (the headline table shows the full p10/p50/p90 fan).",
  "",
  knitr::kable(quart_out, format = "pipe"),
  "",
  "**Reading:** marginal ΔHLO from a given *percentage* shock is roughly invariant across baseline-CRS quartiles in log-space (this is a structural property of log1p, not a substantive finding) — at very low baselines the absolute $-shock for a fixed-% shock is small but the log-difference is large, and vice versa. The cross-quartile contrast becomes substantive only when expressed in absolute dollars rather than percentages.",
  ""
)
writeLines(quart_md, OUT_QSENS_MD)
message(sprintf("[m5] wrote %s and %s", OUT_QSENS_CSV, OUT_QSENS_MD))

# === 7. Scenario figure ======================================================
message("\n[m5] building scenario figure")

plot_main <- main_grid |>
  mutate(scenario_short = recode(scenario_label,
                                  !!!setNames(c("Worst", "Expected", "Best"),
                                              beta_labels)),
         scenario_short = factor(scenario_short, levels = c("Worst","Expected","Best")))

p_hlo <- ggplot(plot_main, aes(x = shock_label, y = delta_hlo_pts, fill = scenario_short)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.1f", delta_hlo_pts)),
            position = position_dodge(width = 0.8),
            vjust = -0.3, size = 3) +
  scale_fill_manual(values = c("Worst" = "#B2182B", "Expected" = "#4D4D4D", "Best" = "#1B7837")) +
  labs(title = "Model 5: ΔHLO points per shock × β-CI scenario",
       subtitle = sprintf("Median baseline = $%.1fM annual CRS; Model 2 spec 2e β = %.2f (95%% CI [%.2f, %.2f])",
                           baseline_med, beta_2e, beta_lo, beta_hi),
       x = "Shock magnitude (% of median country's annual CRS)",
       y = "ΔHLO (points; HCI scale 300-625)",
       fill = "β scenario") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

p_lays <- plot_main |>
  pivot_longer(c(delta_lays_p10, delta_lays_p50, delta_lays_p90),
               names_to = "eys_pct", values_to = "delta_lays") |>
  mutate(eys_pct = recode(eys_pct,
                           delta_lays_p10 = sprintf("EYS p10 (%.1f yr)", eys_p10),
                           delta_lays_p50 = sprintf("EYS p50 (%.1f yr)", eys_p50),
                           delta_lays_p90 = sprintf("EYS p90 (%.1f yr)", eys_p90))) |>
  filter(scenario_short == "Expected") |>
  ggplot(aes(x = shock_label, y = delta_lays, fill = eys_pct)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.3f", delta_lays)),
            position = position_dodge(width = 0.8),
            vjust = -0.3, size = 3) +
  scale_fill_brewer(palette = "Blues") +
  labs(title = "Model 5: ΔLAYS at expected β, fan over implied-EYS percentiles",
       subtitle = "LAYS = EYS × (HLO/625); EYS percentiles derived from the LAYS/HLO identity",
       x = "Shock magnitude (% of median country's annual CRS)",
       y = "ΔLAYS (years)",
       fill = "Implied EYS pctile") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

# Stack vertically — prefer patchwork, fall back to gridExtra, then HLO-only
if (requireNamespace("patchwork", quietly = TRUE)) {
  combined_plot <- patchwork::wrap_plots(p_hlo, p_lays, ncol = 1)
} else if (requireNamespace("gridExtra", quietly = TRUE)) {
  message("[m5] patchwork unavailable — using gridExtra")
  combined_plot <- gridExtra::arrangeGrob(p_hlo, p_lays, ncol = 1)
} else {
  message("[m5] patchwork + gridExtra unavailable — writing HLO panel only")
  combined_plot <- p_hlo
}

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, combined_plot, width = 10, height = 10)
ggsave(OUT_PLOT_PNG, combined_plot, width = 10, height = 10, dpi = 150)
message(sprintf("[m5] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 8. Stdout summary =======================================================
cat("\n=== Phase 8 Session 01 summary ===\n")
cat(sprintf("Model 2 spec 2e locked: β=%.4f, SE=%.4f, N=%d\n", beta_2e, se_2e, n_2e))
cat(sprintf("β 95%% CI: [%.4f, %.4f]\n", beta_lo, beta_hi))
cat(sprintf("Baseline annual CRS (median, MA3-lag1): $%.2fM\n", baseline_med))
cat(sprintf("Implied EYS percentiles: p10=%.2f / p50=%.2f / p90=%.2f years\n",
            eys_p10, eys_p50, eys_p90))
cat("\n--- Headline scenarios (ΔHLO at three β × three shocks; LAYS at median EYS) ---\n")
print(main_out |> select(shock, scenario, delta_hlo_pts, delta_lays_p50))
cat(sprintf("\nBrief-bridge: $1B distributed across N=%d countries = $%.2fM/country avg (%.1f%% of median baseline; %.2f%% of sample's total annual CRS of $%.2fB).\n",
            nrow(est_sample), mean_per_country_if_1B, pct_of_median_if_1B,
            total_pct_of_sample, sample_total_M / 1000))
cat("\n--- Baseline-quartile sensitivity (expected β only at median EYS) ---\n")
print(quart_out |> filter(scenario == "Expected case (β point estimate)") |>
        select(baseline, shock, delta_hlo_pts, delta_lays_p50))
message("\n[m5] complete.")
