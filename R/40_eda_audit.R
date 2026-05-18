# R/40_eda_audit.R
#
# Phase 1 close-out audit. Reads data/interim/_panel_audit.parquet (the audit-
# grade merge from R/30_merge_panel.R) and produces the inputs needed to lock
# ADR-0002 (country universe) and ADR-0003 (year range), plus the MCAR test
# that sets up ADR-0006 (Phase 2 lock).
#
# Output (committed):
#   output/tables/coverage_matrix.csv
#   output/tables/year_range_viability.csv
#   output/tables/country_universe_candidates.csv
#   output/tables/ssa_panel_missingness.csv
#   output/tables/mcar_test_result.txt
#   output/tables/audit_summary.md
#   output/figures/coverage/panel_audit.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
})

source("R/lib/coverage.R")

stopifnot(requireNamespace("naniar", quietly = TRUE))

PANEL_PATH <- "data/interim/_panel_audit.parquet"

# Three candidate windows for ADR-0003
WINDOWS <- list(
  win_2000_2022 = 2000:2022,
  win_2005_2020 = 2005:2020,
  win_2010_2020 = 2010:2020
)

# Pinned 6-column analytical subset (the Model-2 candidate variables)
MCAR_COLS <- c("hlo_hlo_score",
               "wdi_gdp_pc_usd",
               "wdi_edu_exp_pct_gdp",
               "wdi_ptr_primary",
               "crs_commit_usd_sum",
               "wgi_ge_est")

# Section 1: Load panel + summary -----------------------------------
panel <- arrow::read_parquet(PANEL_PATH)
message(sprintf("[audit] panel: %d rows × %d cols, %d countries, years %d-%d",
                nrow(panel), ncol(panel), dplyr::n_distinct(panel$iso3),
                min(panel$year), max(panel$year)))

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

# Section 2: Per-source coverage matrix -----------------------------
# For each source-prefix, count countries with any non-NA value in each year
source_prefixes <- c("wdi","hci","wgi","uis","hlo","aap","ucdp","covid","gari","crs","gcdf")

# Marker column per source (a representative non-NA-when-present column)
marker_cols <- c(
  wdi   = "wdi_gdp_pc_usd",
  hci   = "hci_hci_overall",
  wgi   = "wgi_va_est",
  uis   = "uis_priv_exp_pct_gdp",
  hlo   = "hlo_hlo_score",
  aap   = "aap_hlo_aap",
  ucdp  = "ucdp_in_conflict",   # 0/1, never NA in our build — special handling below
  covid = "covid_days_closed",
  gari  = "gari_ai_readiness_score_mean",
  crs   = "crs_commit_usd_sum",
  gcdf  = "gcdf_amount_const2021_sum"
)

coverage_matrix <- map_dfr(names(marker_cols), function(src) {
  mc <- marker_cols[[src]]
  panel |>
    group_by(year) |>
    summarise(
      source = src,
      n_countries_with_data = if (src == "ucdp") {
        sum(!is.na(.data[[mc]]) & .data[[mc]] == 1)   # countries with active conflict
      } else {
        sum(!is.na(.data[[mc]]))
      },
      .groups = "drop"
    )
}) |>
  select(source, year, n_countries_with_data) |>
  pivot_wider(names_from = year, values_from = n_countries_with_data, values_fill = 0L)

readr::write_csv(coverage_matrix, "output/tables/coverage_matrix.csv")
message("[audit] coverage_matrix.csv written")

# Section 3: Year-range viability ------------------------------------
# Per candidate window: cartesian, HLO cells, countries with ≥2 HLO obs,
# full-row (HLO + WDI controls + CRS) cells, useful-sample share.
viability <- map_dfr(names(WINDOWS), function(wname) {
  wyears <- WINDOWS[[wname]]
  win <- panel |> filter(year %in% wyears)
  n_iso <- dplyr::n_distinct(win$iso3)
  n_years <- length(wyears)
  n_cartesian <- n_iso * n_years

  hlo_cells <- sum(!is.na(win$hlo_hlo_score))

  # Countries with ≥2 non-NA HLO observations within the window
  n_countries_2plus_hlo <- win |>
    filter(!is.na(hlo_hlo_score)) |>
    count(iso3) |>
    filter(n >= 2) |>
    nrow()

  # WDI-controls-and-HLO complete
  hlo_plus_wdi <- win |>
    filter(!is.na(hlo_hlo_score), !is.na(wdi_gdp_pc_usd),
           !is.na(wdi_edu_exp_pct_gdp), !is.na(wdi_ptr_primary)) |>
    nrow()

  # Full Model-2 row: HLO + WDI controls + CRS commit
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

# Section 4: Country universe enumeration ----------------------------
# Restrict to 1995-2024 window for the eligibility derivation (we don't want
# 2025-only AI Readiness to drive things; AI Readiness isn't ODA).
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
  total_iso3       = nrow(universe),
  is_oda_eligible  = sum(universe$is_oda_eligible),
  has_hlo          = sum(universe$has_hlo),
  meets_option1    = sum(universe$meets_adr0002_option1),
  meets_option1_with_2_hlo = sum(universe$meets_adr0002_option1 & universe$n_hlo_cycles >= 2)
)
message(sprintf("[audit] country universe: total=%d; ODA-eligible=%d; has_HLO=%d; ADR-0002 Option-1=%d; (& ≥2 HLO)=%d",
                universe_summary$total_iso3, universe_summary$is_oda_eligible,
                universe_summary$has_hlo, universe_summary$meets_option1,
                universe_summary$meets_option1_with_2_hlo))

# Section 5: Little MCAR test on pinned 6-col subset -----------------
# Default: 2010-2020 window + ADR-0002 Option 1 countries
option1_iso3 <- universe$iso3[universe$meets_adr0002_option1]
mcar_panel <- panel |>
  filter(year %in% 2010:2020, iso3 %in% option1_iso3) |>
  select(all_of(MCAR_COLS))

mcar_result <- tryCatch({
  res <- naniar::mcar_test(mcar_panel)
  sprintf("naniar::mcar_test() on 2010-2020 ∩ ADR-0002 Option-1 (n=%d rows, %d cols)\n\nstatistic = %.3f\ndf = %d\np_value = %.6f\nmissing_patterns = %d\n",
          nrow(mcar_panel), ncol(mcar_panel),
          res$statistic, res$df, res$p.value, res$missing.patterns)
}, error = function(e) {
  sprintf("naniar::mcar_test() FAILED: %s\n\nFalling back to naniar::miss_var_summary():\n%s\n\nnaniar::miss_case_table():\n%s\n",
          conditionMessage(e),
          paste(capture.output(print(naniar::miss_var_summary(mcar_panel))), collapse = "\n"),
          paste(capture.output(print(naniar::miss_case_table(mcar_panel))), collapse = "\n"))
})

writeLines(mcar_result, "output/tables/mcar_test_result.txt")
message("[audit] MCAR test result:")
cat(mcar_result)

# Section 6: SSA missingness on the merged panel --------------------
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |> na.omit() |> unique()

ssa_panel <- panel |>
  filter(year %in% 2010:2020, iso3 %in% option1_iso3) |>
  select(iso3, year, all_of(MCAR_COLS))

ssa_pat <- ssa_missingness_pattern(ssa_panel, ssa_iso3)
print(ssa_pat)
readr::write_csv(ssa_pat, "output/tables/ssa_panel_missingness.csv")
message("[audit] ssa_panel_missingness.csv written")

# Section 7: Coverage figure ----------------------------------------
cov_long <- coverage_matrix |>
  pivot_longer(-source, names_to = "year", values_to = "n_countries") |>
  mutate(year = as.integer(year),
         source = factor(source, levels = source_prefixes))

p_cov <- ggplot(cov_long, aes(x = year, y = source, fill = n_countries)) +
  geom_tile() +
  scale_fill_viridis_c(option = "magma", direction = -1,
                       name = "Countries\nobserved") +
  scale_x_continuous(breaks = seq(1995, 2025, 5)) +
  labs(title = "Phase-1 audit: per-source coverage by year",
       subtitle = "Cells colored by number of countries with any non-NA observation",
       x = "Year", y = "Source") +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank())

dir.create("output/figures/coverage", recursive = TRUE, showWarnings = FALSE)
ggsave("output/figures/coverage/panel_audit.pdf", p_cov, width = 11, height = 5)
ggsave("output/figures/coverage/panel_audit.png", p_cov, width = 11, height = 5, dpi = 150)
message("[audit] panel_audit.{pdf,png} written")

# Section 8: Audit summary scorecard --------------------------------
summary_md <- c(
  "# Phase 1 Close-Out Audit Summary",
  "",
  paste0("*Generated by `R/40_eda_audit.R` on ", Sys.Date(), "*"),
  "",
  "## Country universe (ADR-0002 input)",
  sprintf("- Total ISO3 in union of sources: **%d**", universe_summary$total_iso3),
  sprintf("- ODA-eligible (received aid in OECD CRS 1995-2024): **%d**", universe_summary$is_oda_eligible),
  sprintf("- Has ≥1 HLO observation: **%d**", universe_summary$has_hlo),
  sprintf("- **ADR-0002 Option 1 (intersection): %d**", universe_summary$meets_option1),
  sprintf("- ... of which with ≥2 HLO cycles (Model-2 identifiable): **%d**",
          universe_summary$meets_option1_with_2_hlo),
  "",
  "## Year-range viability (ADR-0003 input)",
  "",
  "| Window | Years | Countries | HLO cells | Countries ≥2 HLO | Full-row cells | Useful % |",
  "|---|---|---|---|---|---|---|",
  paste(paste0("| ", viability$years, " | ", viability$n_years, " | ", viability$n_countries,
               " | ", viability$hlo_cells, " | ", viability$countries_with_2plus_hlo,
               " | ", viability$full_row_cells, " | ", viability$useful_sample_pct, " |"),
        collapse = "\n"),
  "",
  "## MCAR test (ADR-0006 set-up; Phase 2 lock)",
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
message("[audit] all diagnostics complete. Read output/tables/audit_summary.md for the close-out scorecard.")
