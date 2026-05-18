# R/41_eda_descriptives.R
#
# Phase 3 Session 01: paper §4.1 descriptive Table 1.
# Stratifies the 17 key analytical variables by WB region across the 133-country
# ADR-0002 universe within the 2010-2020 ADR-0003 primary window.
#
# Aggregation strategy: country-level mean over primary window first, then
# region-level summary (mean + SD across countries). This avoids over-weighting
# countries with denser observation coverage in any specific year.
#
# Outputs:
#   output/tables/table1_descriptives.csv  — machine-readable
#   output/tables/table1_descriptives.md   — manuscript-ready markdown
#
# Notes per plan:
# - Unit scaling: population → thousands; GDP/cap → USD; CRS/GCDF → USD millions
# - Binary `ucdp_in_conflict` reported as proportion (% of country-years)
# - `covid_days_closed` only populates 2020 within primary window — country mean
#   here = country's 2020 closure days (documented in table caption)

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
  library(knitr)
})

PANEL_PATH   <- "data/interim/panel.parquet"
OUT_CSV      <- "output/tables/table1_descriptives.csv"
OUT_MD       <- "output/tables/table1_descriptives.md"

# Variable spec: (column, display label, scale factor, format)
# scale factor 1 = display as-is; 1e-3 = thousands; 1e-6 = millions
VAR_SPEC <- tribble(
  ~col,                          ~label,                                          ~scale,  ~fmt,
  "hlo_hlo_score",               "HLO score (HCI HLOS)",                          1,       "continuous",
  "hci_lays_overall",            "LAYS (years)",                                  1,       "continuous",
  "aap_hlo_aap",                 "HLO score (AAP-2018 robustness)",               1,       "continuous",
  "wdi_gdp_pc_usd",              "GDP per capita (USD)",                          1,       "continuous",
  "wdi_population",              "Population (thousands)",                        1e-3,    "continuous",
  "wdi_edu_exp_pct_gdp",         "Govt education expenditure (% GDP)",            1,       "continuous",
  "wdi_ptr_primary",             "Pupil-teacher ratio, primary",                  1,       "continuous",
  "wdi_primary_completion",      "Primary completion rate (%)",                   1,       "continuous",
  "wdi_enroll_prim_gross",       "Gross primary enrollment (%)",                  1,       "continuous",
  "wdi_enroll_sec_gross",        "Gross secondary enrollment (%)",                1,       "continuous",
  "uis_oos_rate_primary",        "Out-of-school rate, primary (%)",               1,       "continuous",
  "wgi_ge_est",                  "Govt effectiveness (WGI, -2.5 to +2.5)",        1,       "continuous",
  "ucdp_in_conflict",            "In active conflict (% of country-years)",       100,     "proportion",
  "covid_days_closed",           "COVID-19 school closure days (2020 only)",      1,       "continuous",
  "crs_disburse_usd_defl_sum",   "OECD CRS education disbursement, USD millions", 1,       "continuous",  # OECD reports in USD millions natively
  "gcdf_amount_const2021_sum",   "AidData GCDF education aid, USD millions",      1e-6,    "continuous",  # AidData reports in raw USD; convert to millions
  "crs_n_donors",                "OECD CRS donor count per (country-year)",       1,       "continuous"
)

message("[table1] loading production panel")
panel <- arrow::read_parquet(PANEL_PATH) |>
  filter(in_primary_window) |>
  mutate(iso3 = as.character(iso3))

# Attach WB region
region_map <- countrycode::codelist |>
  filter(!is.na(region), !is.na(iso3c)) |>
  select(iso3 = iso3c, region) |>
  distinct()

panel <- panel |> left_join(region_map, by = "iso3")
stopifnot(all(!is.na(panel$region)))
message(sprintf("[table1] %d primary-window rows, %d countries, %d regions",
                nrow(panel), n_distinct(panel$iso3), n_distinct(panel$region)))

# Step 1: country-level mean across primary window
country_means <- panel |>
  group_by(iso3, region) |>
  summarise(across(all_of(VAR_SPEC$col), \(x) mean(x, na.rm = TRUE)),
            .groups = "drop") |>
  mutate(across(all_of(VAR_SPEC$col), \(x) ifelse(is.nan(x), NA_real_, x)))

# Apply scaling per variable spec
for (i in seq_len(nrow(VAR_SPEC))) {
  cc <- VAR_SPEC$col[i]
  s  <- VAR_SPEC$scale[i]
  if (s != 1) country_means[[cc]] <- country_means[[cc]] * s
}

# Step 2: region-level mean + SD across countries
fmt_cell <- function(values, fmt_kind) {
  v <- values[!is.na(values)]
  if (length(v) == 0) return("—")
  if (fmt_kind == "proportion") {
    sprintf("%.1f%%", mean(v))
  } else {
    m  <- mean(v)
    sd <- sd(v)
    if (abs(m) >= 1000) sprintf("%.0f (%.0f)", m, sd)
    else if (abs(m) >= 10) sprintf("%.1f (%.1f)", m, sd)
    else sprintf("%.2f (%.2f)", m, sd)
  }
}

region_summary <- function(df, region_name) {
  out <- VAR_SPEC |>
    rowwise() |>
    mutate(cell = fmt_cell(df[[col]], fmt)) |>
    ungroup() |>
    select(label, cell) |>
    rename(!!region_name := cell)
  out
}

regions <- sort(unique(country_means$region))

# Build a per-region table
region_tables <- map(regions, function(r) {
  sub <- country_means |> filter(region == r)
  region_summary(sub, r)
})

# Total column
total_table <- region_summary(country_means, "Total")

# Reduce-join all
table1 <- reduce(c(region_tables, list(total_table)), full_join, by = "label")

# Footer rows: n countries + n country-years per region
n_countries_row <- c(label = "n countries",
                     setNames(c(
                       map_chr(regions, \(r) as.character(sum(country_means$region == r))),
                       as.character(nrow(country_means))
                     ), c(regions, "Total")))

n_country_years_row <- c(label = "n country-years (primary window 2010-2020)",
                          setNames(c(
                            map_chr(regions, \(r) as.character(sum(panel$region == r))),
                            as.character(nrow(panel))
                          ), c(regions, "Total")))

table1 <- table1 |>
  bind_rows(as_tibble_row(n_countries_row),
            as_tibble_row(n_country_years_row))

# Write CSV
dir.create(dirname(OUT_CSV), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(table1, OUT_CSV)
message(sprintf("[table1] wrote %s", OUT_CSV))

# Write Markdown
caption <- paste0(
  "**Table 1.** Descriptive statistics of the 133-country analytical universe (ADR-0002), ",
  "primary window 2010–2020 (ADR-0003), stratified by World Bank region. ",
  "Cells show mean (SD) across countries within region (country-level means computed first across primary window). ",
  "`In active conflict` row reports the share of country-years with any active armed conflict (UCDP). ",
  "`COVID-19 school closure days` reflects 2020 only (within primary window). ",
  "Aid flows are arithmetic means of country-level annual sums in constant USD; medians are substantially lower (right-skewed distributions). ",
  "USD millions = 10⁶ USD. Population in thousands.\n"
)

md_lines <- c(caption,
              knitr::kable(table1, format = "pipe", align = c("l", rep("r", ncol(table1) - 1))))
writeLines(md_lines, OUT_MD)
message(sprintf("[table1] wrote %s", OUT_MD))

# Echo to stdout
cat("\n--- Table 1 preview ---\n")
print(table1, n = Inf, width = Inf)

message("[table1] complete.")
