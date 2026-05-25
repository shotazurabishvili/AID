# R/43_eda_supplementary.R
#
# supplementary EDA on the production panel. Three sections:
#   §1 — Pearson correlation matrix on Model-2 candidate variables, with
#        skewed variables (GDP/cap, population, CRS, GCDF) log-transformed.
#        Output: heatmap + CSV. Informs the analysis VIF prep + PAP-0009.
#   §2 — Regional mean trajectories 2010-2020. 4-panel figure (HLO, gross
#        primary enrollment, GDP per capita, CRS disbursement). HLO panel
#        uses geom_point only (no line; HLO observed at 4 HCI cycles only,
#        connecting them would imply false interpolation). Other panels use
#        line + point + SE ribbon. Combined via cowplot::plot_grid.
#   §3 — Income-group stratification of Session-11 Table 1. Uses
#        WDI::WDI_data$country$income for classification (no new ingest).
#
# Inputs:  data/interim/panel.parquet
# Outputs: output/tables/correlation_matrix_primary.csv
#          output/tables/table1_by_income.{csv,md}
#          output/figures/eda/correlation_heatmap.{pdf,png}
#          output/figures/eda/regional_trajectories.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
  library(WDI)
  library(corrplot)
  library(cowplot)
  library(knitr)
})

PANEL_PATH        <- "data/interim/panel.parquet"
OUT_CORR_CSV      <- "output/tables/correlation_matrix_primary.csv"
OUT_CORR_PDF      <- "output/figures/eda/correlation_heatmap.pdf"
OUT_CORR_PNG      <- "output/figures/eda/correlation_heatmap.png"
OUT_TRAJ_PDF      <- "output/figures/eda/regional_trajectories.pdf"
OUT_TRAJ_PNG      <- "output/figures/eda/regional_trajectories.png"
OUT_INC_CSV       <- "output/tables/table1_by_income.csv"
OUT_INC_MD        <- "output/tables/table1_by_income.md"

# === Section 0: Setup ===========================================================
message("[supp-eda] loading production panel")
panel <- arrow::read_parquet(PANEL_PATH) |>
  filter(in_primary_window) |>
  mutate(iso3 = as.character(iso3))

# Region (consistent with the prior step Table 1)
region_map <- countrycode::codelist |>
  filter(!is.na(region), !is.na(iso3c)) |>
  select(iso3 = iso3c, region) |>
  distinct()
panel <- panel |> left_join(region_map, by = "iso3")
stopifnot(all(!is.na(panel$region)))

# Income (WDI metadata; no new ingest)
income_map <- WDI::WDI_data$country |>
  as_tibble() |>
  filter(!is.na(iso3c)) |>
  select(iso3 = iso3c, income) |>
  distinct()
panel <- panel |> left_join(income_map, by = "iso3")
n_no_income <- sum(is.na(panel$income))
message(sprintf("[supp-eda] panel: %d rows, %d countries, %d regions; %d income-classified, %d not classified",
                nrow(panel), n_distinct(panel$iso3), n_distinct(panel$region),
                sum(!is.na(panel$income)), n_no_income))

# === Section 1: Correlation matrix =============================================
message("\n[supp-eda] §1 Correlation matrix")

# 13 Model-2 candidate variables; log-transform skewed flow + scale variables.
# After country-level mean aggregation, then apply transforms before cor().
CORR_VARS_RAW <- c(
  "hlo_hlo_score", "hci_lays_overall",
  "wdi_gdp_pc_usd", "wdi_population",
  "wdi_edu_exp_pct_gdp", "wdi_ptr_primary", "wdi_primary_completion",
  "wdi_enroll_prim_gross",
  "wgi_ge_est",
  "ucdp_in_conflict", "covid_days_closed",
  "crs_disburse_usd_defl_ma3", "gcdf_amount_const2021_sum"
)
LOG_VARS <- c("wdi_gdp_pc_usd", "wdi_population",
              "crs_disburse_usd_defl_ma3", "gcdf_amount_const2021_sum")

country_means <- panel |>
  group_by(iso3) |>
  summarise(across(all_of(CORR_VARS_RAW), \(x) mean(x, na.rm = TRUE)),
            .groups = "drop") |>
  mutate(across(all_of(CORR_VARS_RAW), \(x) ifelse(is.nan(x), NA_real_, x)))

# Apply log transforms; log(1+x) for flow vars (handle zeros), log(x) for GDP/pop
trans <- country_means
trans$wdi_gdp_pc_usd            <- log(trans$wdi_gdp_pc_usd)
trans$wdi_population            <- log(trans$wdi_population)
trans$crs_disburse_usd_defl_ma3 <- log1p(trans$crs_disburse_usd_defl_ma3)
trans$gcdf_amount_const2021_sum <- log1p(trans$gcdf_amount_const2021_sum)

# Rename log columns for clarity in output
DISPLAY_NAMES <- c(
  hlo_hlo_score             = "HLO",
  hci_lays_overall          = "LAYS",
  wdi_gdp_pc_usd            = "log(GDP/cap)",
  wdi_population            = "log(Pop)",
  wdi_edu_exp_pct_gdp       = "EdExp %GDP",
  wdi_ptr_primary           = "PTR primary",
  wdi_primary_completion    = "Primary compl",
  wdi_enroll_prim_gross     = "Gross enroll prim",
  wgi_ge_est                = "Gov effect",
  ucdp_in_conflict          = "In conflict",
  covid_days_closed         = "COVID days",
  crs_disburse_usd_defl_ma3 = "log(1+CRS disb MA3)",
  gcdf_amount_const2021_sum = "log(1+GCDF)"
)

cor_input <- trans |>
  select(all_of(CORR_VARS_RAW)) |>
  rename_with(\(x) DISPLAY_NAMES[x])

M <- cor(cor_input, use = "pairwise.complete.obs", method = "pearson")
M_round <- round(M, 3)

# Write CSV
dir.create(dirname(OUT_CORR_CSV), recursive = TRUE, showWarnings = FALSE)
M_df <- as_tibble(M_round, rownames = "variable")
readr::write_csv(M_df, OUT_CORR_CSV)
message(sprintf("[supp-eda] wrote %s", OUT_CORR_CSV))

# Render heatmap with corrplot
dir.create(dirname(OUT_CORR_PDF), recursive = TRUE, showWarnings = FALSE)
pdf(OUT_CORR_PDF, width = 7.5, height = 6.5)
corrplot::corrplot(M, method = "color", type = "lower",
                   col = colorRampPalette(c("#2C7FB8", "white", "#D7301F"))(200),
                   tl.col = "black", tl.cex = 0.75, tl.srt = 45,
                   addCoef.col = "black", number.cex = 0.6,
                   diag = FALSE,
                   mar = c(0, 0, 2, 0),
                   title = "Pearson correlations among Model-2 candidate variables (133 universe, 2010-2020)")
dev.off()

png(OUT_CORR_PNG, width = 7.5, height = 6.5, units = "in", res = 150)
corrplot::corrplot(M, method = "color", type = "lower",
                   col = colorRampPalette(c("#2C7FB8", "white", "#D7301F"))(200),
                   tl.col = "black", tl.cex = 0.75, tl.srt = 45,
                   addCoef.col = "black", number.cex = 0.6,
                   diag = FALSE,
                   mar = c(0, 0, 2, 0),
                   title = "Pearson correlations among Model-2 candidate variables")
dev.off()
message(sprintf("[supp-eda] wrote %s and %s", OUT_CORR_PDF, OUT_CORR_PNG))

# Top 5 |r| pairs (excluding diagonal)
mat <- M
mat[upper.tri(mat, diag = TRUE)] <- NA
pairs_df <- as.data.frame.table(mat, responseName = "r", stringsAsFactors = FALSE) |>
  as_tibble() |>
  filter(!is.na(r)) |>
  mutate(abs_r = abs(r)) |>
  arrange(desc(abs_r)) |>
  slice_head(n = 5)
cat("\nTop 5 |r| pairs:\n")
print(pairs_df, n = 5)

# === Section 2: Regional trajectories =========================================
message("\n[supp-eda] §2 Regional trajectories")

traj_vars <- c("hlo_hlo_score", "wdi_enroll_prim_gross",
               "wdi_gdp_pc_usd", "crs_disburse_usd_defl_sum")

traj_long <- panel |>
  select(iso3, year, region, all_of(traj_vars)) |>
  pivot_longer(all_of(traj_vars), names_to = "metric", values_to = "value")

# Per-(region, year, metric): mean + SE across countries
traj_summary <- traj_long |>
  filter(!is.na(value)) |>
  group_by(region, year, metric) |>
  summarise(mean = mean(value),
            se   = sd(value) / sqrt(dplyr::n()),
            n    = dplyr::n(),
            .groups = "drop")

metric_labels <- c(
  hlo_hlo_score             = "HLO score (HCI HLOS) - HCI cycles only",
  wdi_enroll_prim_gross     = "Gross primary enrollment (%)",
  wdi_gdp_pc_usd            = "GDP per capita (USD)",
  crs_disburse_usd_defl_sum = "OECD CRS education disbursement (USD millions)"
)

make_panel <- function(metric_key, with_line = TRUE) {
  d <- traj_summary |> filter(metric == metric_key)
  p <- ggplot(d, aes(x = year, y = mean, color = region, fill = region))
  if (with_line) {
    p <- p +
      geom_ribbon(aes(ymin = mean - se, ymax = mean + se),
                  alpha = 0.12, color = NA) +
      geom_line(linewidth = 0.7) +
      geom_point(size = 1.5)
  } else {
    p <- p + geom_point(size = 2)
  }
  p +
    scale_color_brewer(palette = "Set2") +
    scale_fill_brewer(palette = "Set2") +
    scale_x_continuous(breaks = c(2010, 2013, 2016, 2018, 2020)) +
    labs(x = NULL, y = NULL, title = metric_labels[[metric_key]]) +
    theme_minimal(base_size = 10) +
    theme(legend.position = "none",
          plot.title = element_text(size = 10, color = "grey20"))
}

p_hlo    <- make_panel("hlo_hlo_score", with_line = FALSE)
p_enroll <- make_panel("wdi_enroll_prim_gross")
p_gdp    <- make_panel("wdi_gdp_pc_usd")
p_crs    <- make_panel("crs_disburse_usd_defl_sum")

# Extract shared legend from a temp plot
p_for_legend <- p_enroll + theme(legend.position = "bottom",
                                  legend.title = element_text(size = 10),
                                  legend.text = element_text(size = 9)) +
                 labs(color = "World Bank region", fill = "World Bank region")
legend_grob <- cowplot::get_legend(p_for_legend)

grid <- cowplot::plot_grid(p_hlo, p_enroll, p_gdp, p_crs,
                            ncol = 2, labels = "AUTO", label_size = 11)
final <- cowplot::plot_grid(grid, legend_grob,
                             ncol = 1, rel_heights = c(1, 0.08))

ggsave(OUT_TRAJ_PDF, final, width = 10, height = 8)
ggsave(OUT_TRAJ_PNG, final, width = 10, height = 8, dpi = 150)
message(sprintf("[supp-eda] wrote %s and %s", OUT_TRAJ_PDF, OUT_TRAJ_PNG))

# Print HLO regional 2010 vs 2020 deltas
hlo_deltas <- traj_summary |>
  filter(metric == "hlo_hlo_score", year %in% c(2010, 2020)) |>
  select(region, year, mean) |>
  pivot_wider(names_from = year, values_from = mean, names_prefix = "y") |>
  mutate(delta_2010_2020 = round(y2020 - y2010, 1))
cat("\nHLO regional 2010 vs 2020 deltas:\n")
print(hlo_deltas)

# === Section 3: Income-group Table 1 ==========================================
message("\n[supp-eda] §3 Income-group Table 1")

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
  "crs_disburse_usd_defl_sum",   "OECD CRS education disbursement, USD millions", 1,       "continuous",
  "gcdf_amount_const2021_sum",   "AidData GCDF education aid, USD millions",      1e-6,    "continuous",
  "crs_n_donors",                "OECD CRS donor count per (country-year)",       1,       "continuous"
)

cm_inc <- panel |>
  group_by(iso3, income) |>
  summarise(across(all_of(VAR_SPEC$col), \(x) mean(x, na.rm = TRUE)),
            .groups = "drop") |>
  mutate(across(all_of(VAR_SPEC$col), \(x) ifelse(is.nan(x), NA_real_, x)))

for (i in seq_len(nrow(VAR_SPEC))) {
  cc <- VAR_SPEC$col[i]
  s  <- VAR_SPEC$scale[i]
  if (s != 1) cm_inc[[cc]] <- cm_inc[[cc]] * s
}

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

income_summary <- function(df, group_name) {
  VAR_SPEC |>
    rowwise() |>
    mutate(cell = fmt_cell(df[[col]], fmt)) |>
    ungroup() |>
    select(label, cell) |>
    rename(!!group_name := cell)
}

income_order <- c("Low income", "Lower middle income", "Upper middle income", "High income")
present <- intersect(income_order, unique(cm_inc$income))
extras  <- setdiff(unique(cm_inc$income), c(present, NA))   # e.g., "Not classified" string
has_na_income <- any(is.na(cm_inc$income))

# Build column tabs only for cohorts that have countries
group_tabs <- map(present, function(grp) {
  income_summary(cm_inc |> filter(income == grp), grp)
})
extra_tabs <- map(extras, function(grp) {
  income_summary(cm_inc |> filter(income == grp), grp)
})
tabs <- c(group_tabs, extra_tabs)
if (has_na_income) {
  tabs <- c(tabs, list(income_summary(cm_inc |> filter(is.na(income)), "Not classified (NA)")))
}
tabs <- c(tabs, list(income_summary(cm_inc, "Total")))

table1_inc <- reduce(tabs, full_join, by = "label")

# Footer rows — match column order in tabs
cohort_names <- c(present, extras)
if (has_na_income) cohort_names <- c(cohort_names, "Not classified (NA)")

n_countries_row <- c(label = "n countries")
n_country_years_row <- c(label = "n country-years (primary window)")
for (grp in cohort_names) {
  if (grp == "Not classified (NA)") {
    n_countries_row[[grp]] <- as.character(sum(is.na(cm_inc$income)))
    n_country_years_row[[grp]] <- as.character(sum(is.na(panel$income)))
  } else {
    n_countries_row[[grp]] <- as.character(sum(cm_inc$income == grp, na.rm = TRUE))
    n_country_years_row[[grp]] <- as.character(sum(panel$income == grp, na.rm = TRUE))
  }
}
n_countries_row[["Total"]] <- as.character(nrow(cm_inc))
n_country_years_row[["Total"]] <- as.character(nrow(panel))

table1_inc <- table1_inc |>
  bind_rows(as_tibble_row(n_countries_row),
            as_tibble_row(n_country_years_row))

readr::write_csv(table1_inc, OUT_INC_CSV)

caption <- paste0(
  "**Table 1B.** Descriptive statistics of the 133-country analytical universe (PAP-0002), ",
  "primary window 2010-2020 (PAP-0003), stratified by **World Bank income classification** ",
  "(`WDI::WDI_data$country$income`, current-year as of session date). Cells show mean (SD) ",
  "across countries within group (country-level means computed first across primary window). ",
  "`In active conflict` row reports share of country-years with any active armed conflict. ",
  "`COVID-19 school closure days` reflects 2020 only. Aid flows are arithmetic means of ",
  "country-level annual sums in constant USD; medians are substantially lower (right-skewed). ",
  "**Caveat:** High income bucket comprises graduated ODA recipients (e.g., Chile, Korea) - ",
  "countries that received aid in 1995-2024 but are currently classified high-income. ",
  "Not classified bucket: typically XKX (Kosovo).\n"
)

md_lines <- c(caption,
              knitr::kable(table1_inc, format = "pipe",
                           align = c("l", rep("r", ncol(table1_inc) - 1))))
writeLines(md_lines, OUT_INC_MD)
message(sprintf("[supp-eda] wrote %s and %s", OUT_INC_CSV, OUT_INC_MD))

cat("\n--- Income Table 1 preview ---\n")
print(table1_inc, n = Inf, width = Inf)

message("\n[supp-eda] complete.")
