# R/10_ingest_ucdp.R
#
# Source: UCDP/PRIO Armed Conflict Dataset v25.1 + UCDP Battle-Related Deaths v25.1
#   (Uppsala Conflict Data Program / Peace Research Institute Oslo).
# Reference: Data Stack; the manuscript methodology section (Confounders — conflict and COVID).
# Methodology cite: Pettersson, Davies et al. (annual UCDP release).
#
# Two source files, both tiny CSVs in zip form (44 KB + 38 KB):
#   ACD: 2,752 conflict-year rows × 28 cols, 1946-2024
#   BRD: 1,586 conflict-year rows × 25 cols (battle-related deaths), 1989-2024
#
# Aggregation: both datasets are conflict-year (one row per (conflict_id, year)).
# gwno_loc is a comma-space-separated list of Gleditsch-Ward numeric country codes
# (verified: e.g., "651, 666" for Egypt+Yemen; "2, 200, 700" for USA+UK+Afghanistan).
# We expand to (country, year, conflict_id) before aggregating to (iso3, year).
#
# Important methodology note: BRD's 25-deaths-per-conflict-year threshold means
# low-intensity violence is excluded. This is documented UCDP behavior; documented
# in catalog notes.

# === Pinned column lists (PHASE 1 LOCK — modify only via ADR) =======================
ACD_EXPECTED <- c("conflict_id", "year", "location", "gwno_loc",
                  "intensity_level", "type_of_conflict", "incompatibility")
BRD_EXPECTED <- c("conflict_id", "year", "bd_best", "bd_low", "bd_high", "gwno_loc")
OUTPUT_COLS <- c("iso3", "year",
                 "in_conflict",        # binary 0/1 (filled with 0 for country-years with no ACD row)
                 "intensity_max",      # max intensity_level in (iso3, year); NA if no conflict
                 "n_conflicts",        # count of distinct conflict_id active in (iso3, year)
                 "internal_armed",     # any type_of_conflict == 3 (intrastate)
                 "internationalized",  # any type_of_conflict == 4 (internationalized intrastate)
                 "bd_best", "bd_low", "bd_high")   # summed across conflicts; 0 when no BRD row
# ====================================================================================

SRC <- "ucdp"
ACD_URL <- "https://ucdp.uu.se/downloads/ucdpprio/ucdp-prio-acd-251-csv.zip"
BRD_URL <- "https://ucdp.uu.se/downloads/brd/ucdp-brd-conf-251-csv.zip"
YEAR_RANGE <- 1995:2024

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

options(timeout = max(300, getOption("timeout")))

# 1. Fetch both zips (cached 365 days) -------------------------------
fetch_one <- function(url, dest, label) {
  if (raw_is_stale(dest, max_days = 365)) {
    message(sprintf("[ucdp] downloading %s ...", label))
    ok <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = FALSE)
      file.info(dest)$size > 1e3
    }, error = function(e) { message("[ucdp] download error: ", conditionMessage(e)); FALSE })
    if (!isTRUE(ok)) {
      stop("[ucdp] download failed for ", label, ". Manual fallback: ",
           "visit https://ucdp.uu.se/downloads/, download the CSV zip, place at ",
           dest, ", and re-run.")
    }
  } else {
    message(sprintf("[ucdp] using cached %s at %s", label, dest))
  }
  sha <- hash_raw(dest)
  message(sprintf("[ucdp] %s: %.1f KB, sha256=%s",
                  label, file.info(dest)$size / 1e3, substr(sha, 1, 12)))
  invisible(sha)
}

acd_zip <- file.path(raw_dir(SRC), "ucdp-prio-acd-251-csv.zip")
brd_zip <- file.path(raw_dir(SRC), "ucdp-brd-conf-251-csv.zip")

acd_sha <- fetch_one(ACD_URL, acd_zip, "ACD v25.1")
brd_sha <- fetch_one(BRD_URL, brd_zip, "BRD v25.1")
fetched_on(SRC, set = TRUE)

# 2. Read both CSVs --------------------------------------------------
read_zipped_csv <- function(zip_path, label) {
  entries <- unzip(zip_path, list = TRUE)
  csv_name <- entries$Name[grepl("\\.csv$", entries$Name, ignore.case = TRUE)]
  if (length(csv_name) != 1) {
    stop("[ucdp] expected exactly 1 CSV in ", label, " zip; got ",
         length(csv_name), ". Entries: ", paste(entries$Name, collapse = " | "))
  }
  raw <- readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE,
                         progress = FALSE)
  message(sprintf("[ucdp] %s CSV: %d rows × %d cols", label, nrow(raw), ncol(raw)))
  raw
}

acd <- read_zipped_csv(acd_zip, "ACD")
brd <- read_zipped_csv(brd_zip, "BRD")

# Schema validation
missing_acd <- setdiff(ACD_EXPECTED, names(acd))
missing_brd <- setdiff(BRD_EXPECTED, names(brd))
if (length(missing_acd) > 0) stop("[ucdp] ACD missing expected cols: ", paste(missing_acd, collapse = ", "))
if (length(missing_brd) > 0) stop("[ucdp] BRD missing expected cols: ", paste(missing_brd, collapse = ", "))

# 3. Filter to YEAR_RANGE + expand gwno_loc to per-country rows ------
# This dramatically shrinks the dataset (1946 -> 1995 cuts >40%) and avoids
# Yugoslavia/Czechoslovakia/USSR normalization noise.
expand_loc <- function(df) {
  df |>
    filter(year %in% YEAR_RANGE,
           !is.na(gwno_loc), nchar(gwno_loc) > 0) |>
    mutate(gwno_loc_split = strsplit(gwno_loc, ", *")) |>
    tidyr::unnest(gwno_loc_split) |>
    mutate(gwno = suppressWarnings(as.integer(gwno_loc_split))) |>
    filter(!is.na(gwno))
}

acd_long <- expand_loc(acd)
brd_long <- expand_loc(brd)

message(sprintf("[ucdp] ACD expansion: %d rows -> %d (country, year, conflict) rows after gwno_loc unnest + year filter",
                sum(acd$year %in% YEAR_RANGE), nrow(acd_long)))
message(sprintf("[ucdp] BRD expansion: %d rows -> %d (country, year, conflict) rows",
                sum(brd$year %in% YEAR_RANGE), nrow(brd_long)))

# Convert GW codes to ISO3 (countrycode supports origin="gwn"). Manual overrides
# for GW codes that countrycode mis-resolves but where the analytical mapping is
# unambiguous in our 1995+ window:
#   678 = "Yemen (North Yemen)" — UCDP keeps the pre-unification code for modern
#         Yemen state; all 1995+ rows are post-unification Yemen (incl. the 2014+
#         civil war). Map to YEM.
#   345 = "Serbia (Yugoslavia)" — pre-2006 the GW universe used 345 for the
#         Serbian state across Yugoslavia / Serbia-Montenegro. Modern Serbia is
#         SRB. The 1998-1999 entries (Kosovo war) belong to Serbia.
GW_OVERRIDES <- c("678" = "YEM", "345" = "SRB")

resolve_gw <- function(gw_int) {
  base <- suppressWarnings(
    countrycode::countrycode(gw_int, origin = "gwn", destination = "iso3c", warn = FALSE)
  )
  needs_override <- is.na(base) & as.character(gw_int) %in% names(GW_OVERRIDES)
  base[needs_override] <- GW_OVERRIDES[as.character(gw_int[needs_override])]
  base
}

acd_long$iso3 <- resolve_gw(acd_long$gwno)
brd_long$iso3 <- resolve_gw(brd_long$gwno)

# Log unresolved GW codes (historical entities like USSR=365 pre-1992)
unresolved_acd <- unique(acd_long$gwno[is.na(acd_long$iso3)])
unresolved_brd <- unique(brd_long$gwno[is.na(brd_long$iso3)])
unresolved <- unique(c(unresolved_acd, unresolved_brd))
if (length(unresolved) > 0) {
  log_path <- file.path("output", "logs", paste0("iso3_unresolved_", SRC, ".csv"))
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
  # Compose a sample location label per unresolved gwno using whichever location
  # column the upstream CSV exposes (ACD has `location`; BRD has `location_inc`).
  acd_loc <- if ("location" %in% names(acd_long)) acd_long$location else rep(NA_character_, nrow(acd_long))
  brd_loc <- if ("location_inc" %in% names(brd_long)) brd_long$location_inc
             else if ("location" %in% names(brd_long)) brd_long$location
             else rep(NA_character_, nrow(brd_long))
  utils::write.csv(
    data.frame(source = SRC,
               gwno = unresolved,
               sample_location = sapply(unresolved, function(g) {
                 locs <- unique(c(
                   acd_loc[acd_long$gwno == g][1],
                   brd_loc[brd_long$gwno == g][1]
                 ))
                 paste(na.omit(locs), collapse = " / ")
               })),
    log_path, row.names = FALSE
  )
  message(sprintf("[iso3:%s] %d unresolved GW codes logged to %s", SRC, length(unresolved), log_path))
}

acd_long <- acd_long |> filter(!is.na(iso3))
brd_long <- brd_long |> filter(!is.na(iso3))

# 4. Aggregate ACD to (iso3, year) ----------------------------------
acd_agg <- acd_long |>
  group_by(iso3, year) |>
  summarise(
    in_conflict       = 1L,
    intensity_max     = max(intensity_level, na.rm = TRUE),
    n_conflicts       = dplyr::n_distinct(conflict_id),
    internal_armed    = as.integer(any(type_of_conflict == 3, na.rm = TRUE)),
    internationalized = as.integer(any(type_of_conflict == 4, na.rm = TRUE)),
    .groups = "drop"
  )

# 5. Aggregate BRD to (iso3, year) ----------------------------------
brd_agg <- brd_long |>
  group_by(iso3, year) |>
  summarise(
    bd_best = sum(bd_best, na.rm = TRUE),
    bd_low  = sum(bd_low,  na.rm = TRUE),
    bd_high = sum(bd_high, na.rm = TRUE),
    .groups = "drop"
  )

# 6. Build full (iso3, year) panel ----------------------------------
# Universe: all ISO3 codes that appear in either ACD or BRD across the year range,
# combined with WB-style country list for completeness (so we have rows for
# non-conflict-affected countries too).
all_iso3 <- countrycode::codelist |>
  filter(!is.na(iso3c)) |>
  pull(iso3c) |>
  unique()

panel <- tidyr::expand_grid(iso3 = sort(all_iso3), year = YEAR_RANGE) |>
  left_join(acd_agg, by = c("iso3", "year")) |>
  left_join(brd_agg, by = c("iso3", "year")) |>
  mutate(
    in_conflict       = tidyr::replace_na(in_conflict, 0L),
    intensity_max     = ifelse(is.na(intensity_max), NA_integer_, as.integer(intensity_max)),
    n_conflicts       = tidyr::replace_na(n_conflicts, 0L),
    internal_armed    = tidyr::replace_na(internal_armed, 0L),
    internationalized = tidyr::replace_na(internationalized, 0L),
    bd_best           = tidyr::replace_na(bd_best, 0),
    bd_low            = tidyr::replace_na(bd_low,  0),
    bd_high           = tidyr::replace_na(bd_high, 0)
  ) |>
  select(all_of(OUTPUT_COLS)) |>
  arrange(iso3, year)

message(sprintf("[ucdp] panel: %d rows, %d countries, years %d-%d",
                nrow(panel), dplyr::n_distinct(panel$iso3),
                min(panel$year), max(panel$year)))
message(sprintf("[ucdp] country-years with active conflict: %d (%.1f%% of cells)",
                sum(panel$in_conflict), 100 * mean(panel$in_conflict)))

# Prevalence diagnostic — SSA vs Rest (replaces the SSA-missingness audit; see plan)
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |> na.omit() |> unique()
ssa_prev   <- panel |> filter(iso3 %in% ssa_iso3)   |> summarise(p = mean(in_conflict)) |> pull(p)
rest_prev  <- panel |> filter(!iso3 %in% ssa_iso3)  |> summarise(p = mean(in_conflict)) |> pull(p)
message(sprintf("[ucdp] DIAGNOSTIC: conflict prevalence SSA %.1f%% vs Rest %.1f%% (gap %+.1f pp)",
                100 * ssa_prev, 100 * rest_prev, 100 * (ssa_prev - rest_prev)))

# 7. Audit + write interim + catalog --------------------------------
# coverage_summary expects NA = missing; in our 0/1-filled panel there's no
# missingness by construction, so the summary is mostly informational.
cov <- coverage_summary(panel, SRC)
print(cov)
coverage_heatmap(panel, SRC)

write_interim(panel, SRC)

overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(panel[, setdiff(OUTPUT_COLS, c("iso3", "year"))]))), 2
)

update_catalog(
  SRC,
  url         = "https://ucdp.uu.se/downloads/",
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("UCDP v25.1 (ACD + BRD-conf, last-modified 2025-06; fetched ", fetched_on(SRC), ")"),
  n_rows      = nrow(panel),
  n_countries = dplyr::n_distinct(panel$iso3),
  year_range  = c(min(panel$year), max(panel$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(
    list(name = basename(acd_zip), sha256 = acd_sha),
    list(name = basename(brd_zip), sha256 = brd_sha)
  ),
  variables   = lapply(OUTPUT_COLS, function(c) list(code = c, name = c)),
  notes = paste0(
    "Country-year panel aggregated from ACD (binary in_conflict, intensity_max, ",
    "n_conflicts, internal_armed, internationalized) + BRD (summed bd_best/low/high). ",
    "gwno_loc multi-country conflicts expanded via strsplit(', *') + countrycode(origin='gwn'). ",
    "Panel filled with 0s for country-years with no conflict observation (NA-as-zero ",
    "for in_conflict / n_conflicts / bd_*; intensity_max remains NA when no conflict). ",
    "BRD 25-deaths threshold: low-intensity violence below 25 battle deaths/conflict-year ",
    "is excluded by UCDP construction (documented behavior, not a bug). ",
    "Cited as Pettersson, Davies et al. Feeds Model 2 as a time-varying confounder."
  )
)

render_catalog()
message("[ucdp] ingestion complete.")
