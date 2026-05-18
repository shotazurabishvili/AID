# R/30_merge_panel.R
#
# Phase 1 close-out: audit-grade minimal merge of all 11 interim parquets into
# a single (iso3, year) panel for the Session 09 audit (ADR-0002/0003 locks
# + MCAR test). Output: data/interim/_panel_audit.parquet (gitignored).
#
# THIS IS NOT THE PRODUCTION MERGE. Phase 2 Session 01 will rewrite this script
# to add analytical transforms (3-year MA on ODA, lag structure, deflator choice,
# donor-level CRS aggregation per ADR-0005). Production output will be
# data/interim/panel.parquet (no underscore).
#
# Aggregation scope here:
# - Project-level sources (OECD CRS, AidData GCDF) → (iso3, year) sums of value
#   columns plus a project-count signal. No 3-yr MA, no deflator choice, no
#   donor-level splits.
# - Country-year sources (WDI, HCI, WGI, UIS, HLO, AAP-2018, UCDP, COVID) →
#   joined as-is.
# - Cross-sectional source (AI Readiness, year=2025) → joined as-is; produces
#   NA in all other panel years.
#
# Panel year range: 1995-2025 (extended one year beyond YEAR_RANGE so AI
# Readiness has a join target). Most sources are NA in 2025; AI Readiness is
# NA in all other years. Both patterns are structural, not pathology.

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
})

YEAR_RANGE <- 1995:2025
OUT_PATH   <- "data/interim/_panel_audit.parquet"

message("[merge] starting audit-grade merge")

# 1. Load all 11 interim parquets ------------------------------------
load_interim <- function(name) {
  p <- file.path("data", "interim", paste0(name, ".parquet"))
  if (!file.exists(p)) stop("[merge] missing interim parquet: ", p)
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
gari <- load_interim("ai_readiness")
crs  <- load_interim("oecd_crs")
gcdf <- load_interim("aiddata_gcdf")

message(sprintf("[merge] loaded 11 interim parquets"))

# AAP-2018 has sub-national rows (e.g., several Canadian provinces all
# resolving to CAN, Dubai+Abu Dhabi → ARE) that produce (iso3, year)
# duplicates after the join. Aggregate to (iso3, year) mean to enforce
# the panel key. Documented in script header.
hlo_aap <- hlo_aap_raw |>
  group_by(iso3, year) |>
  summarise(hlo_aap = mean(hlo_aap, na.rm = TRUE), .groups = "drop")
message(sprintf("[merge] AAP-2018 collapsed: %d rows -> %d (iso3, year) means",
                nrow(hlo_aap_raw), nrow(hlo_aap)))

# 2. Aggregate project-level sources to (iso3, year) ----------------
crs_panel <- crs |>
  group_by(iso3, year) |>
  summarise(
    commit_usd_sum   = sum(usd_commitment, na.rm = TRUE),
    disburse_usd_sum = sum(usd_disbursement, na.rm = TRUE),
    n_projects       = n(),
    .groups = "drop"
  ) |>
  mutate(year = as.integer(year))

message(sprintf("[merge] CRS aggregated: %d project rows -> %d (iso3, year) rows",
                nrow(crs), nrow(crs_panel)))

gcdf_panel <- gcdf |>
  group_by(iso3, year) |>
  summarise(
    amount_const2021_sum = sum(`Amount (Constant USD 2021)`, na.rm = TRUE),
    n_projects           = n(),
    .groups = "drop"
  ) |>
  mutate(year = as.integer(year))

message(sprintf("[merge] GCDF aggregated: %d project rows -> %d (iso3, year) rows",
                nrow(gcdf), nrow(gcdf_panel)))

# 3. Build country universe + (iso3, year) cartesian skeleton --------
all_iso3 <- unique(c(
  wdi$iso3, hci$iso3, wgi$iso3, uis$iso3, hlo$iso3, hlo_aap$iso3,
  ucdp$iso3, covid$iso3, gari$iso3, crs_panel$iso3, gcdf_panel$iso3
))
all_iso3 <- sort(unique(all_iso3[!is.na(all_iso3)]))

message(sprintf("[merge] country universe (union of all sources): %d ISO3 codes", length(all_iso3)))

skeleton <- tidyr::expand_grid(iso3 = all_iso3, year = YEAR_RANGE)

# 4. Prefix non-key columns by source slug + left-join in sequence ---
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

# Build the joined panel
panel <- skeleton |>
  left_join(prep(wdi,  "wdi"),  by = c("iso3", "year")) |>
  left_join(prep(hci,  "hci"),  by = c("iso3", "year")) |>
  left_join(prep(wgi,  "wgi"),  by = c("iso3", "year")) |>
  left_join(prep(uis,  "uis"),  by = c("iso3", "year")) |>
  left_join(prep(hlo,  "hlo"),  by = c("iso3", "year")) |>
  left_join(prep(hlo_aap, "aap"), by = c("iso3", "year")) |>
  left_join(prep(ucdp, "ucdp"), by = c("iso3", "year")) |>
  left_join(prep(covid, "covid"), by = c("iso3", "year")) |>
  left_join(prep(gari, "gari"), by = c("iso3", "year")) |>
  left_join(prep(crs_panel, "crs"), by = c("iso3", "year")) |>
  left_join(prep(gcdf_panel, "gcdf"), by = c("iso3", "year"))

message(sprintf("[merge] joined panel: %d rows × %d cols", nrow(panel), ncol(panel)))

# 5. Per-source join statistics --------------------------------------
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
  "gari",      nrow(gari),              sum(!is.na(panel$gari_ai_readiness_score_mean)),
  "crs",       nrow(crs),               sum(!is.na(panel$crs_commit_usd_sum)),
  "gcdf",      nrow(gcdf),              sum(!is.na(panel$gcdf_amount_const2021_sum))
)
print(join_stats)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(join_stats, "output/tables/merge_join_stats.csv")

# 6. Write audit panel (gitignored) ----------------------------------
arrow::write_parquet(panel, OUT_PATH)
message(sprintf("[merge] wrote %s (%d rows × %d cols)", OUT_PATH, nrow(panel), ncol(panel)))
message("[merge] complete.")
