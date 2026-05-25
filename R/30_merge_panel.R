# R/30_merge_panel.R
#
# production merge. Replaces the Session-09 audit-grade
# minimal merge (which is preserved in git history for reference). This script
# produces the canonical analytical panel: data/interim/panel.parquet (committed).
#
# Differences vs audit-grade:
#   1. Filter to PAP-0002 universe (133 countries; read from
#      output/tables/country_universe_candidates.csv) instead of the full
#      union of 250 ISO3.
#   2. Year storage range 2000-2022 (widest robustness window per PAP-0003),
#      not 1995-2025. AI Readiness dropped (cross-sectional 2025; supplementary
#      re-joins it separately).
#   3. CRS column matrix expanded per PAP-0005: commit × disburse × current
#      × constant USD = 4 raw cols, plus 3-yr trailing MA (4 cols), 1-yr lag
#      (4 cols: defl + current USD), and 3-yr strictly-past MA (4 cols).
#      the corresponding analytical step picks primary from this 16-cell grid (PAP-0005 lock).
#   4. NA -> 0 coalesce on CRS + GCDF aid-flow columns within universe.
#      Rationale: ODA-eligible recipients with no CRS project in year t had
#      $0 aid that year, not "data missing". This enables clean MAs.
#      Outcome/control columns (HLO, WGI, UIS, WDI, ...) are NOT coalesced
#      because NA there means "not measured", which is structurally different.
#   5. Window + identification flags added: in_primary_window (2010-2020),
#      in_robust_2005_2020, has_2plus_hlo (FE-identifiable subset).
#
# Companion: R/40_eda_audit.R re-runs MCAR on this panel (PAP-0006 lock).

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(slider)
})

YEAR_RANGE      <- 2000:2022
UNIVERSE_CSV    <- "output/tables/country_universe_candidates.csv"
OUT_PATH        <- "data/interim/panel.parquet"
JOIN_STATS_PATH <- "output/tables/production_join_stats.csv"
EXPECTED_N      <- 133L

message("[merge-prod] starting production merge")

# 1. Load universe ---------------------------------------------------
universe <- readr::read_csv(UNIVERSE_CSV, show_col_types = FALSE) |>
  filter(meets_adr0002_option1) |>
  pull(iso3) |>
  unique() |>
  sort()

stopifnot(length(universe) == EXPECTED_N)
message(sprintf("[merge-prod] PAP-0002 universe: %d countries", length(universe)))

# 2. Load 10 source parquets (skip AI Readiness) ---------------------
load_interim <- function(name) {
  p <- file.path("data", "interim", paste0(name, ".parquet"))
  if (!file.exists(p)) stop("[merge-prod] missing interim parquet: ", p)
  arrow::read_parquet(p)
}

wdi  <- load_interim("wdi")
hci  <- load_interim("hci")
wgi  <- load_interim("wgi")
uis  <- load_interim("uis")
hlo  <- load_interim("hlo")
hlo_aap_raw <- load_interim("hlo_aap2018")
ucdp <- load_interim("ucdp")
covid <- load_interim("covid_closures")
crs  <- load_interim("oecd_crs")
gcdf <- load_interim("aiddata_gcdf")

message("[merge-prod] loaded 10 interim parquets (GARI excluded; Phase-9 separate)")

# 3. Collapse AAP-2018 sub-national rows (carry audit pattern) -------
hlo_aap <- hlo_aap_raw |>
  group_by(iso3, year) |>
  summarise(hlo_aap = mean(hlo_aap, na.rm = TRUE), .groups = "drop") |>
  mutate(year = as.integer(year))

message(sprintf("[merge-prod] AAP-2018 collapsed: %d rows -> %d (iso3, year) means",
                nrow(hlo_aap_raw), nrow(hlo_aap)))

# 4. Drop COVID date columns (not analytically used; create pivoting friction) ----
covid <- covid |>
  select(-any_of(c("first_closure_date", "last_closure_date")))

# 5. Aggregate CRS to (iso3, year) -----------------------------------
# Unprefixed names; prep() adds 'crs_' uniformly after the join (audit-bug pattern)
crs_panel <- crs |>
  group_by(iso3, year) |>
  summarise(
    commit_usd_sum        = sum(usd_commitment,        na.rm = TRUE),
    commit_usd_defl_sum   = sum(usd_commitment_defl,   na.rm = TRUE),
    disburse_usd_sum      = sum(usd_disbursement,      na.rm = TRUE),
    disburse_usd_defl_sum = sum(usd_disbursement_defl, na.rm = TRUE),
    n_projects            = dplyr::n(),
    n_donors              = dplyr::n_distinct(donor_code),
    .groups = "drop"
  ) |>
  mutate(year = as.integer(year))

message(sprintf("[merge-prod] CRS aggregated: %d project rows -> %d (iso3, year) cells",
                nrow(crs), nrow(crs_panel)))

# 6. Aggregate GCDF to (iso3, year) ----------------------------------
gcdf_panel <- gcdf |>
  group_by(iso3, year) |>
  summarise(
    amount_const2021_sum = sum(`Amount (Constant USD 2021)`, na.rm = TRUE),
    n_projects           = dplyr::n(),
    .groups = "drop"
  ) |>
  mutate(year = as.integer(year))

message(sprintf("[merge-prod] GCDF aggregated: %d project rows -> %d (iso3, year) cells",
                nrow(gcdf), nrow(gcdf_panel)))

# 7. Build skeleton: universe x year_range ---------------------------
skeleton <- tidyr::expand_grid(iso3 = universe, year = YEAR_RANGE)
message(sprintf("[merge-prod] skeleton: %d rows (%d countries x %d years)",
                nrow(skeleton), length(universe), length(YEAR_RANGE)))

# 8. Prefix non-key columns by source slug ---------------------------
prefix_cols <- function(df, prefix, key_cols = c("iso3", "year")) {
  non_key <- setdiff(names(df), key_cols)
  if (length(non_key) == 0) return(df)
  df |> rename_with(\(x) paste0(prefix, "_", x), all_of(non_key))
}

prep <- function(df, prefix) {
  df |>
    mutate(iso3 = as.character(iso3), year = as.integer(year)) |>
    prefix_cols(prefix)
}

# 9. Left-join sources onto skeleton --------------------------------
panel <- skeleton |>
  left_join(prep(wdi,        "wdi"),   by = c("iso3", "year")) |>
  left_join(prep(hci,        "hci"),   by = c("iso3", "year")) |>
  left_join(prep(wgi,        "wgi"),   by = c("iso3", "year")) |>
  left_join(prep(uis,        "uis"),   by = c("iso3", "year")) |>
  left_join(prep(hlo,        "hlo"),   by = c("iso3", "year")) |>
  left_join(prep(hlo_aap,    "aap"),   by = c("iso3", "year")) |>
  left_join(prep(ucdp,       "ucdp"),  by = c("iso3", "year")) |>
  left_join(prep(covid,      "covid"), by = c("iso3", "year")) |>
  left_join(prep(crs_panel,  "crs"),   by = c("iso3", "year")) |>
  left_join(prep(gcdf_panel, "gcdf"),  by = c("iso3", "year"))

message(sprintf("[merge-prod] joined panel: %d rows x %d cols", nrow(panel), ncol(panel)))

# 10. NA -> 0 coalesce on CRS + GCDF aid-flow columns within universe ----
# Explicit column names (avoid `starts_with`+`where` since it would catch MA/lag
# columns that don't exist yet at this point in the script).
coalesce_cols <- c(
  "crs_commit_usd_sum", "crs_commit_usd_defl_sum",
  "crs_disburse_usd_sum", "crs_disburse_usd_defl_sum",
  "crs_n_projects", "crs_n_donors",
  "gcdf_amount_const2021_sum", "gcdf_n_projects"
)

panel <- panel |>
  mutate(across(all_of(coalesce_cols), \(x) coalesce(x, 0)))

message("[merge-prod] coalesced CRS + GCDF flow columns NA -> 0 within universe")

# 11. Compute MA3 (trailing-inclusive: t-2, t-1, t) + lag1 + strictly-past MA ----
# Trailing-inclusive MA: .before=2, .after=0, .complete=TRUE returns NA when fewer
# than 3 obs in window (years 2000-2001 per country).
# Strictly-past MA (mean of t-3, t-2, t-1): dplyr::lag(ma3, n=1). NA for first
# 3 years per country. Used in the corresponding analytical step to foreclose contemporaneous
# leakage (PAP-0005 sensitivity grid).
# Group by iso3; arrange ensures within-country time order.
panel <- panel |>
  group_by(iso3) |>
  arrange(year, .by_group = TRUE) |>
  mutate(
    # 3-yr trailing-inclusive MA (mean of t-2, t-1, t)
    crs_commit_usd_ma3        = slide_dbl(crs_commit_usd_sum,        mean, .before = 2, .after = 0, .complete = TRUE),
    crs_commit_usd_defl_ma3   = slide_dbl(crs_commit_usd_defl_sum,   mean, .before = 2, .after = 0, .complete = TRUE),
    crs_disburse_usd_ma3      = slide_dbl(crs_disburse_usd_sum,      mean, .before = 2, .after = 0, .complete = TRUE),
    crs_disburse_usd_defl_ma3 = slide_dbl(crs_disburse_usd_defl_sum, mean, .before = 2, .after = 0, .complete = TRUE),
    # 1-yr lag (all four USD bases, for PAP-0005 grid symmetry)
    crs_commit_usd_lag1        = dplyr::lag(crs_commit_usd_sum,        n = 1),
    crs_commit_usd_defl_lag1   = dplyr::lag(crs_commit_usd_defl_sum,   n = 1),
    crs_disburse_usd_lag1      = dplyr::lag(crs_disburse_usd_sum,      n = 1),
    crs_disburse_usd_defl_lag1 = dplyr::lag(crs_disburse_usd_defl_sum, n = 1),
    # 3-yr strictly-past MA (mean of t-3, t-2, t-1) = lag(ma3, 1)
    crs_commit_usd_ma3_lag1        = dplyr::lag(crs_commit_usd_ma3,        n = 1),
    crs_commit_usd_defl_ma3_lag1   = dplyr::lag(crs_commit_usd_defl_ma3,   n = 1),
    crs_disburse_usd_ma3_lag1      = dplyr::lag(crs_disburse_usd_ma3,      n = 1),
    crs_disburse_usd_defl_ma3_lag1 = dplyr::lag(crs_disburse_usd_defl_ma3, n = 1),
    # GCDF — trailing-inclusive MA + 1-yr lag  + strictly-past MA (PAP-0008 grid)
    gcdf_amount_const2021_ma3      = slide_dbl(gcdf_amount_const2021_sum, mean, .before = 2, .after = 0, .complete = TRUE),
    gcdf_amount_const2021_lag1     = dplyr::lag(gcdf_amount_const2021_sum, n = 1),
    gcdf_amount_const2021_ma3_lag1 = dplyr::lag(gcdf_amount_const2021_ma3, n = 1)
  ) |>
  ungroup()

message("[merge-prod] computed MA3 + lag1 + strictly-past MA transforms within country")

# 12. Window flags + identification flag ----------------------------
has_2plus_hlo_iso3 <- panel |>
  filter(!is.na(hlo_hlo_score)) |>
  count(iso3) |>
  filter(n >= 2) |>
  pull(iso3)

panel <- panel |>
  mutate(
    in_primary_window   = year %in% 2010:2020,
    in_robust_2005_2020 = year %in% 2005:2020,
    has_2plus_hlo       = iso3 %in% has_2plus_hlo_iso3
  )

message(sprintf("[merge-prod] flags added: %d/%d countries have ≥2 HLO observations",
                length(has_2plus_hlo_iso3), length(universe)))

# 13. Verify (iso3, year) uniqueness --------------------------------
stopifnot(!any(duplicated(panel[, c("iso3", "year")])))
stopifnot(nrow(panel) == length(universe) * length(YEAR_RANGE))
message("[merge-prod] (iso3, year) is unique key; balanced panel OK")

# 14. Per-source join statistics ------------------------------------
join_stats <- tribble(
  ~source,            ~rows_in_source, ~cells_with_data_in_panel,
  "wdi",       nrow(wdi),               sum(!is.na(panel$wdi_gdp_pc_usd)),
  "hci",       nrow(hci),               sum(!is.na(panel$hci_hci_overall)),
  "wgi",       nrow(wgi),               sum(!is.na(panel$wgi_va_est)),
  "uis",       nrow(uis),               sum(!is.na(panel$uis_priv_exp_pct_gdp)),
  "hlo",       nrow(hlo),               sum(!is.na(panel$hlo_hlo_score)),
  "aap2018",   nrow(hlo_aap),           sum(!is.na(panel$aap_hlo_aap)),
  "ucdp",      nrow(ucdp),              sum(panel$ucdp_in_conflict == 1, na.rm = TRUE),
  "covid",     nrow(covid),             sum(!is.na(panel$covid_days_closed)),
  "crs",       nrow(crs),               sum(panel$crs_commit_usd_sum > 0,  na.rm = TRUE),
  "gcdf",      nrow(gcdf),              sum(panel$gcdf_amount_const2021_sum > 0, na.rm = TRUE)
)
print(join_stats)

dir.create(dirname(JOIN_STATS_PATH), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(join_stats, JOIN_STATS_PATH)

# 15. Write production panel (committed; no underscore) ------------
arrow::write_parquet(panel, OUT_PATH)
message(sprintf("[merge-prod] wrote %s (%d rows x %d cols)", OUT_PATH, nrow(panel), ncol(panel)))
message("[merge-prod] complete.")
