# R/40_eda_audit.R
#
# Audit/diagnostics script. Default: reads data/interim/panel.parquet (production)
# and runs the Phase-2 diagnostics that feed PAP-0006 (MCAR on the production
# panel with and without UIS). Pass PANEL_PATH=data/interim/_panel_audit.parquet
# to re-run the Phase-1 audit-grade diagnostics (year-range viability + country
# universe enumeration, which only make sense on the audit panel).
#
# Output (committed):
#   Audit-mode (PANEL_PATH=*_panel_audit*):
#     output/tables/coverage_matrix.csv
#     output/tables/year_range_viability.csv
#     output/tables/country_universe_candidates.csv
#     output/tables/ssa_panel_missingness.csv
#     output/tables/mcar_test_result.txt
#     output/tables/audit_summary.md
#     output/figures/coverage/panel_audit.{pdf,png}
#
#   Production-mode (PANEL_PATH=*panel.parquet*):
#     output/tables/production_coverage_matrix.csv
#     output/tables/production_ssa_panel_missingness.csv
#     output/tables/production_mcar_test_result.txt
#     output/tables/production_mcar_with_uis.txt
#     output/tables/production_audit_summary.md
#     output/figures/coverage/panel_production.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
})

source("R/lib/coverage.R")

stopifnot(requireNamespace("naniar", quietly = TRUE))

PANEL_PATH <- Sys.getenv("PANEL_PATH", unset = "data/interim/panel.parquet")
is_audit_mode <- grepl("_panel_audit", PANEL_PATH)
out_prefix <- if (is_audit_mode) "" else "production_"
fig_tag    <- if (is_audit_mode) "panel_audit" else "panel_production"

message(sprintf("[audit] mode = %s; PANEL_PATH = %s",
                if (is_audit_mode) "AUDIT" else "PRODUCTION",
                PANEL_PATH))

# Three candidate windows (audit mode only)
WINDOWS <- list(
  win_2000_2022 = 2000:2022,
  win_2005_2020 = 2005:2020,
  win_2010_2020 = 2010:2020
)

# 6-col analytical subset for MCAR
# Production switches CRS column from `commit_usd_sum` (audit current-USD) to
# `disburse_usd_defl_sum` (production primary intent per methodology §3.5).
# After NA→0 coalesce within universe the CRS column has ~0% NA, so MCAR
# effectively measures missingness across {HLO, 3 WDI, WGI}.
MCAR_COLS_AUDIT <- c("hlo_hlo_score", "wdi_gdp_pc_usd", "wdi_edu_exp_pct_gdp",
                     "wdi_ptr_primary", "crs_commit_usd_sum", "wgi_ge_est")
MCAR_COLS_PROD  <- c("hlo_hlo_score", "wdi_gdp_pc_usd", "wdi_edu_exp_pct_gdp",
                     "wdi_ptr_primary", "crs_disburse_usd_defl_sum", "wgi_ge_est")
MCAR_COLS <- if (is_audit_mode) MCAR_COLS_AUDIT else MCAR_COLS_PROD

# Section 1: Load panel + summary -----------------------------------
panel <- arrow::read_parquet(PANEL_PATH)
message(sprintf("[audit] panel: %d rows × %d cols, %d countries, years %d-%d",
                nrow(panel), ncol(panel), dplyr::n_distinct(panel$iso3),
                min(panel$year), max(panel$year)))

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

# Section 2: Per-source coverage matrix -----------------------------
# Audit mode includes GARI (audit panel has it); production excludes (dropped).
marker_cols_audit <- c(
  wdi   = "wdi_gdp_pc_usd",
  hci   = "hci_hci_overall",
  wgi   = "wgi_va_est",
  uis   = "uis_priv_exp_pct_gdp",
  hlo   = "hlo_hlo_score",
  aap   = "aap_hlo_aap",
  ucdp  = "ucdp_in_conflict",
  covid = "covid_days_closed",
  gari  = "gari_ai_readiness_score_mean",
  crs   = "crs_commit_usd_sum",
  gcdf  = "gcdf_amount_const2021_sum"
)
marker_cols_prod <- marker_cols_audit[!names(marker_cols_audit) %in% "gari"]
marker_cols <- if (is_audit_mode) marker_cols_audit else marker_cols_prod

coverage_matrix <- map_dfr(names(marker_cols), function(src) {
  mc <- marker_cols[[src]]
  if (!mc %in% names(panel)) return(NULL)
  panel |>
    group_by(year) |>
    summarise(
      source = src,
      n_countries_with_data = if (src == "ucdp") {
        sum(!is.na(.data[[mc]]) & .data[[mc]] == 1)
      } else if (src == "crs" && !is_audit_mode) {
        # Production CRS is coalesced NA→0; count POSITIVE-amount cells
        sum(.data[[mc]] > 0, na.rm = TRUE)
      } else if (src == "gcdf" && !is_audit_mode) {
        sum(.data[[mc]] > 0, na.rm = TRUE)
      } else {
        sum(!is.na(.data[[mc]]))
      },
      .groups = "drop"
    )
}) |>
  select(source, year, n_countries_with_data) |>
  pivot_wider(names_from = year, values_from = n_countries_with_data, values_fill = 0L)

readr::write_csv(coverage_matrix, paste0("output/tables/", out_prefix, "coverage_matrix.csv"))
message(sprintf("[audit] %scoverage_matrix.csv written", out_prefix))

# Section 3: Year-range viability (AUDIT MODE ONLY) -----------------
if (is_audit_mode) {
  viability <- map_dfr(names(WINDOWS), function(wname) {
    wyears <- WINDOWS[[wname]]
    win <- panel |> filter(year %in% wyears)
    n_iso <- dplyr::n_distinct(win$iso3)
    n_years <- length(wyears)
    n_cartesian <- n_iso * n_years
    hlo_cells <- sum(!is.na(win$hlo_hlo_score))
    n_countries_2plus_hlo <- win |>
      filter(!is.na(hlo_hlo_score)) |>
      count(iso3) |>
      filter(n >= 2) |>
      nrow()
    hlo_plus_wdi <- win |>
      filter(!is.na(hlo_hlo_score), !is.na(wdi_gdp_pc_usd),
             !is.na(wdi_edu_exp_pct_gdp), !is.na(wdi_ptr_primary)) |>
      nrow()
    full_row <- win |>
      filter(!is.na(hlo_hlo_score), !is.na(wdi_gdp_pc_usd),
             !is.na(wdi_edu_exp_pct_gdp), !is.na(wdi_ptr_primary),
             !is.na(crs_commit_usd_sum)) |>
      nrow()
    tibble(
      window = wname,
      years  = paste0(min(wyears), "-", max(wyears)),
      n_countries = n_iso,
      n_years = n_years,
      cartesian_cells = n_cartesian,
      hlo_cells = hlo_cells,
      countries_with_2plus_hlo = n_countries_2plus_hlo,
      hlo_plus_wdi_cells = hlo_plus_wdi,
      full_row_cells = full_row,
      useful_sample_pct = round(100 * full_row / n_cartesian, 2)
    )
  })
  print(viability)
  readr::write_csv(viability, "output/tables/year_range_viability.csv")
  message("[audit] year_range_viability.csv written")
}

# Section 4: Country universe enumeration (AUDIT MODE ONLY) ---------
if (is_audit_mode) {
  universe_window <- panel |> filter(year %in% 1995:2024)
  universe <- universe_window |>
    group_by(iso3) |>
    summarise(
      is_oda_eligible = any(!is.na(crs_commit_usd_sum) & crs_commit_usd_sum > 0),
      has_hlo         = any(!is.na(hlo_hlo_score)),
      n_hlo_cycles    = sum(!is.na(hlo_hlo_score)),
      .groups = "drop"
    ) |>
    mutate(meets_adr0002_option1 = is_oda_eligible & has_hlo) |>
    arrange(iso3)
  readr::write_csv(universe, "output/tables/country_universe_candidates.csv")
  universe_summary <- list(
    total_iso3 = nrow(universe),
    is_oda_eligible = sum(universe$is_oda_eligible),
    has_hlo = sum(universe$has_hlo),
    meets_option1 = sum(universe$meets_adr0002_option1),
    meets_option1_with_2_hlo = sum(universe$meets_adr0002_option1 & universe$n_hlo_cycles >= 2)
  )
  message(sprintf("[audit] universe: total=%d; ODA=%d; HLO=%d; Opt1=%d; (& ≥2 HLO)=%d",
                  universe_summary$total_iso3, universe_summary$is_oda_eligible,
                  universe_summary$has_hlo, universe_summary$meets_option1,
                  universe_summary$meets_option1_with_2_hlo))
}

# Section 5: Little MCAR — pinned 6-col subset ----------------------
# In production mode, panel is already filtered to PAP-0002 universe; use
# in_primary_window flag. In audit mode, re-derive option1_iso3 to match
# the audit behavior.
run_mcar <- function(panel_data, cols, label) {
  sub <- panel_data |> select(all_of(cols))
  res <- tryCatch({
    r <- naniar::mcar_test(sub)
    sprintf("[%s] naniar::mcar_test() (n=%d rows, %d cols)\n\nstatistic = %.3f\ndf = %d\np_value = %.6f\nmissing_patterns = %d\n\nComplete-row count: %d\n",
            label, nrow(sub), ncol(sub),
            r$statistic, r$df, r$p.value, r$missing.patterns,
            sum(complete.cases(sub)))
  }, error = function(e) {
    sprintf("[%s] naniar::mcar_test() FAILED: %s\n\nFalling back to naniar::miss_var_summary():\n%s\n\nComplete-row count: %d\n",
            label, conditionMessage(e),
            paste(capture.output(print(naniar::miss_var_summary(sub))), collapse = "\n"),
            sum(complete.cases(sub)))
  })
  res
}

if (is_audit_mode) {
  option1_iso3 <- universe$iso3[universe$meets_adr0002_option1]
  mcar_panel <- panel |> filter(year %in% 2010:2020, iso3 %in% option1_iso3)
  mcar_result <- run_mcar(mcar_panel, MCAR_COLS, "audit 6-col 2010-2020 ∩ PAP-0002")
  writeLines(mcar_result, "output/tables/mcar_test_result.txt")
} else {
  # Production: filter via in_primary_window flag
  mcar_panel <- panel |> filter(in_primary_window)
  mcar_result_6col <- run_mcar(mcar_panel, MCAR_COLS_PROD, "production 6-col primary-window")
  mcar_result_7col <- run_mcar(mcar_panel, c(MCAR_COLS_PROD, "uis_priv_exp_pct_gdp"),
                                "production 7-col primary-window (+UIS)")
  writeLines(mcar_result_6col, "output/tables/production_mcar_test_result.txt")
  writeLines(mcar_result_7col, "output/tables/production_mcar_with_uis.txt")
  message("[audit] production MCAR (6-col):")
  cat(mcar_result_6col)
  message("[audit] production MCAR (7-col, +UIS):")
  cat(mcar_result_7col)
}

# Section 6: SSA missingness on the merged panel --------------------
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |> na.omit() |> unique()

if (is_audit_mode) {
  ssa_panel_in <- panel |>
    filter(year %in% 2010:2020, iso3 %in% option1_iso3) |>
    select(iso3, year, all_of(MCAR_COLS))
} else {
  ssa_panel_in <- panel |>
    filter(in_primary_window) |>
    select(iso3, year, all_of(MCAR_COLS_PROD), uis_priv_exp_pct_gdp)
}

ssa_pat <- ssa_missingness_pattern(ssa_panel_in, ssa_iso3)
print(ssa_pat)
readr::write_csv(ssa_pat, paste0("output/tables/", out_prefix, "ssa_panel_missingness.csv"))
message(sprintf("[audit] %sssa_panel_missingness.csv written", out_prefix))

# Section 7: Coverage figure ----------------------------------------
source_levels <- if (is_audit_mode) names(marker_cols_audit) else names(marker_cols_prod)
cov_long <- coverage_matrix |>
  pivot_longer(-source, names_to = "year", values_to = "n_countries") |>
  mutate(year = as.integer(year), source = factor(source, levels = source_levels))

year_breaks <- if (is_audit_mode) seq(1995, 2025, 5) else seq(2000, 2022, 5)

p_cov <- ggplot(cov_long, aes(x = year, y = source, fill = n_countries)) +
  geom_tile() +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Countries\nobserved") +
  scale_x_continuous(breaks = year_breaks) +
  labs(title = sprintf("%s: per-source coverage by year",
                        if (is_audit_mode) "Phase-1 audit" else "Phase-2 production panel"),
       subtitle = "Cells colored by number of countries with any non-NA observation",
       x = "Year", y = "Source") +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank())

dir.create("output/figures/coverage", recursive = TRUE, showWarnings = FALSE)
ggsave(paste0("output/figures/coverage/", fig_tag, ".pdf"), p_cov, width = 11, height = 5)
ggsave(paste0("output/figures/coverage/", fig_tag, ".png"), p_cov, width = 11, height = 5, dpi = 150)
message(sprintf("[audit] %s.{pdf,png} written", fig_tag))

# Section 8: Summary scorecard --------------------------------------
if (is_audit_mode) {
  summary_md <- c(
    "# the analysis Close-Out Audit Summary",
    "",
    paste0("*Generated by `R/40_eda_audit.R` (AUDIT mode) on ", Sys.Date(), "*"),
    "",
    "## Country universe (PAP-0002 input)",
    sprintf("- Total ISO3 in union of sources: **%d**", universe_summary$total_iso3),
    sprintf("- ODA-eligible (received aid in OECD CRS 1995-2024): **%d**", universe_summary$is_oda_eligible),
    sprintf("- Has ≥1 HLO observation: **%d**", universe_summary$has_hlo),
    sprintf("- **PAP-0002 Option 1 (intersection): %d**", universe_summary$meets_option1),
    sprintf("- ... of which with ≥2 HLO cycles (Model-2 identifiable): **%d**",
            universe_summary$meets_option1_with_2_hlo),
    "",
    "## Year-range viability (PAP-0003 input)",
    "",
    "| Window | Years | Countries | HLO cells | Countries ≥2 HLO | Full-row cells | Useful % |",
    "|---|---|---|---|---|---|---|",
    paste(paste0("| ", viability$years, " | ", viability$n_years, " | ", viability$n_countries,
                 " | ", viability$hlo_cells, " | ", viability$countries_with_2plus_hlo,
                 " | ", viability$full_row_cells, " | ", viability$useful_sample_pct, " |"),
          collapse = "\n"),
    "",
    "## MCAR test (PAP-0006 set-up; the analysis lock)",
    "",
    "```",
    mcar_result,
    "```",
    "",
    "## SSA missingness on the merged panel (analytical subset)",
    "",
    paste(capture.output(print(ssa_pat)), collapse = "\n")
  )
  writeLines(summary_md, "output/tables/audit_summary.md")
  message("[audit] audit_summary.md written")
} else {
  summary_md <- c(
    "# the analysis Open: Production Panel Audit Summary",
    "",
    paste0("*Generated by `R/40_eda_audit.R` (PRODUCTION mode) on ", Sys.Date(), "*"),
    "",
    sprintf("Panel: `%s` — %d rows × %d cols, %d countries, years %d-%d",
            PANEL_PATH, nrow(panel), ncol(panel),
            dplyr::n_distinct(panel$iso3), min(panel$year), max(panel$year)),
    sprintf("Primary-window (2010-2020) rows: %d", sum(panel$in_primary_window)),
    sprintf("Countries with ≥2 HLO obs (FE-identifiable): %d", sum(unique(panel$iso3) %in% unique(panel$iso3[panel$has_2plus_hlo]))),
    "",
    "## MCAR test — 6-col (PAP-0006 lock primary input)",
    "",
    "```",
    mcar_result_6col,
    "```",
    "",
    "## MCAR test — 7-col with UIS (quantifies cost of including UIS)",
    "",
    "```",
    mcar_result_7col,
    "```",
    "",
    "## SSA missingness on the production panel (primary window)",
    "",
    paste(capture.output(print(ssa_pat)), collapse = "\n")
  )
  writeLines(summary_md, "output/tables/production_audit_summary.md")
  message("[audit] production_audit_summary.md written")
}

message("[audit] all diagnostics complete.")
