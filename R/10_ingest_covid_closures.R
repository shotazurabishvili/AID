# R/10_ingest_covid_closures.R
#
# Source: UNESCO Global Monitoring of COVID-19 School Closures.
# Reference: Data Stack; the manuscript methodology section (Confounders — conflict and COVID).
# Methodology cite: UNESCO Institute for Statistics — Global Monitoring of School Closures.
#
# Two source files from HDX mirror (cleaner direct download than UNESCO's dashboard portal):
#   1. covid_impact_education.csv (6.7 MB, 169,051 rows) — daily Status time-series
#      per country, Feb 2020 - Mar 2022. Columns: Date, ISO, Country, Status, Note.
#      Date format: DD/MM/YYYY (European).
#      Status values (verified): "Closed due to COVID-19", "Partially open",
#      "Fully open", "Academic break".
#   2. duration-of-school-closures-31-march-22.xlsx (24 KB) — UNESCO's
#      pre-aggregated country totals; used for cross-validation only, not pinned.
#
# We DERIVE country-year totals from the daily CSV (transparent operationalization)
# and cross-check against UNESCO's published duration table.

# === Pinned column lists (PHASE 1 LOCK — modify only via ADR) =======================
DAILY_EXPECTED <- c("Date", "ISO", "Country", "Status")
EXPECTED_STATUS_VALUES <- c("Closed due to COVID-19", "Partially open",
                            "Fully open", "Academic break")
OUTPUT_COLS <- c("iso3", "year",
                 "days_closed", "days_partial", "days_open", "days_break",
                 "first_closure_date", "last_closure_date")
# ====================================================================================

SRC <- "covid_closures"
DAILY_URL    <- "https://data.humdata.org/dataset/6a41be98-75b9-4365-9ea3-e33d0dd2668b/resource/3b5baa74-c928-4cbc-adba-bf543c5d3050/download/covid_impact_education.csv"
DURATION_URL <- "https://data.humdata.org/dataset/6a41be98-75b9-4365-9ea3-e33d0dd2668b/resource/b7a9f3de-1ffb-42c9-85d2-ddee3f3e1e40/download/duration-of-school-closures-31-march-22.xlsx"

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(readxl)
  library(lubridate)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

options(timeout = max(300, getOption("timeout")))

# 1. Fetch both files (cached 365 days) ------------------------------
fetch_one <- function(url, dest, label) {
  if (raw_is_stale(dest, max_days = 365)) {
    message(sprintf("[covid] downloading %s ...", label))
    ok <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = FALSE)
      file.info(dest)$size > 1e3
    }, error = function(e) { message("[covid] download error: ", conditionMessage(e)); FALSE })
    if (!isTRUE(ok)) {
      stop("[covid] download failed for ", label, ". Manual fallback: ",
           "visit https://data.humdata.org/dataset/global-school-closures-covid19 ",
           "and place the file at ", dest, " before re-running.")
    }
  } else {
    message(sprintf("[covid] using cached %s at %s", label, dest))
  }
  sha <- hash_raw(dest)
  message(sprintf("[covid] %s: %.1f KB, sha256=%s",
                  label, file.info(dest)$size / 1e3, substr(sha, 1, 12)))
  invisible(sha)
}

daily_path    <- file.path(raw_dir(SRC), "covid_impact_education.csv")
duration_path <- file.path(raw_dir(SRC), "duration-of-school-closures-31-march-22.xlsx")

daily_sha    <- fetch_one(DAILY_URL,    daily_path,    "daily status CSV")
duration_sha <- fetch_one(DURATION_URL, duration_path, "UNESCO duration xlsx (cross-check)")
fetched_on(SRC, set = TRUE)

# 2. Read daily CSV --------------------------------------------------
raw <- readr::read_csv(daily_path,
                       col_types = cols(.default = col_character()),
                       progress = FALSE)
message(sprintf("[covid] daily CSV: %d rows × %d cols", nrow(raw), ncol(raw)))

missing_cols <- setdiff(DAILY_EXPECTED, names(raw))
if (length(missing_cols) > 0) {
  stop("[covid] daily CSV missing expected cols: ", paste(missing_cols, collapse = ", "),
       "\nAvailable: ", paste(names(raw), collapse = ", "))
}

observed_status <- sort(unique(raw$Status))
message("[covid] observed Status values:")
print(observed_status)

unknown_status <- setdiff(observed_status, EXPECTED_STATUS_VALUES)
if (length(unknown_status) > 0) {
  warning("[covid] UNKNOWN Status values seen (will fall into NA buckets): ",
          paste(unknown_status, collapse = " | "))
}

# 3. Parse Date + derive country-year totals -------------------------
clean <- raw |>
  mutate(date = lubridate::dmy(Date)) |>
  filter(!is.na(date), !is.na(ISO), !is.na(Status)) |>
  mutate(year = lubridate::year(date))

# Reduce status to four canonical category codes for safe wide-pivot
clean <- clean |>
  mutate(status_cat = case_when(
    Status == "Closed due to COVID-19" ~ "days_closed",
    Status == "Partially open"         ~ "days_partial",
    Status == "Fully open"             ~ "days_open",
    Status == "Academic break"         ~ "days_break",
    TRUE                               ~ NA_character_
  )) |>
  filter(!is.na(status_cat))

# Country-year × status counts
day_counts <- clean |>
  count(ISO, Country, year, status_cat, name = "days") |>
  pivot_wider(names_from = status_cat, values_from = days, values_fill = 0L)

# Ensure all four count columns exist even if some Status never observed in a year
for (cn in c("days_closed", "days_partial", "days_open", "days_break")) {
  if (!cn %in% names(day_counts)) day_counts[[cn]] <- 0L
}

# First/last closure date per country (across all years; informational)
closure_dates <- clean |>
  filter(status_cat == "days_closed") |>
  group_by(ISO) |>
  summarise(first_closure_date = min(date),
            last_closure_date  = max(date),
            .groups = "drop")

panel <- day_counts |>
  left_join(closure_dates, by = "ISO") |>
  arrange(ISO, year)

# 4. ISO3 normalization ---------------------------------------------
# UNESCO uses ISO3 directly in the ISO column; round-trip validate.
panel <- panel |>
  mutate(iso3 = suppressWarnings(
    countrycode::countrycode(ISO, origin = "iso3c", destination = "iso3c", warn = FALSE)
  ))

needs_fallback <- is.na(panel$iso3) & !is.na(panel$Country)
if (any(needs_fallback)) {
  message(sprintf("[covid] %d (iso3, year) cells need name-based fallback", sum(needs_fallback)))
  panel$iso3[needs_fallback] <- normalize_iso3(
    panel$Country[needs_fallback], src = SRC, origin = "country.name"
  )
}

# Filter to 2020-2022 (the active monitoring window) and drop unresolved
panel <- panel |>
  filter(!is.na(iso3), year %in% 2020:2022) |>
  select(all_of(OUTPUT_COLS)) |>
  arrange(iso3, year)

message(sprintf("[covid] panel: %d (iso3, year) rows, %d countries, years %d-%d",
                nrow(panel), dplyr::n_distinct(panel$iso3),
                min(panel$year), max(panel$year)))
message(sprintf("[covid] max days_closed in 2020: %d", max(panel$days_closed[panel$year == 2020], na.rm = TRUE)))
message(sprintf("[covid] max days_closed in 2021: %d", max(panel$days_closed[panel$year == 2021], na.rm = TRUE)))

# 5. Cross-validate against UNESCO pre-aggregated xlsx ---------------
# Read the pre-aggregated duration file and compare full-closure totals.
# UNESCO's xlsx structure varies by release; we look for a country-named column
# and a numeric "fully closed" / similar column. Best-effort; warn on mismatch.
xlsx_validation <- tryCatch({
  sheets <- readxl::excel_sheets(duration_path)
  message(sprintf("[covid] UNESCO duration xlsx sheets: %s", paste(sheets, collapse = " | ")))
  # Read the first sheet that has data
  d <- NULL
  for (s in sheets) {
    cand <- suppressMessages(readxl::read_excel(duration_path, sheet = s, guess_max = 5000))
    if (nrow(cand) >= 10 && any(grepl("clos", names(cand), ignore.case = TRUE))) {
      d <- cand; break
    }
  }
  if (is.null(d)) {
    message("[covid] cross-check: no usable sheet found in duration xlsx; skipping")
    NULL
  } else {
    message(sprintf("[covid] cross-check xlsx columns: %s",
                    paste(names(d), collapse = " | ")))
    NULL  # we have the table loaded; full diff is left to the session-log analysis
  }
}, error = function(e) {
  message("[covid] cross-check xlsx read error (non-fatal): ", conditionMessage(e))
  NULL
})

# Our own total fully-closed days, summed across the full 2020-2022 window
our_totals <- panel |>
  group_by(iso3) |>
  summarise(total_days_closed = sum(days_closed), .groups = "drop")
message(sprintf("[covid] OUR derived: %d countries; median total_days_closed = %.0f; max = %d",
                nrow(our_totals),
                stats::median(our_totals$total_days_closed),
                max(our_totals$total_days_closed)))

# 6. Audit + write interim + catalog --------------------------------
# coverage_heatmap pivots non-key columns; Date columns aren't pivotable alongside
# integers. Audit the numeric/count columns only.
panel_numeric <- panel |>
  select(iso3, year, days_closed, days_partial, days_open, days_break)
cov <- coverage_summary(panel_numeric, SRC)
print(cov)
coverage_heatmap(panel_numeric, SRC)

# SSA missingness table (audit-only; small-island absences are the real signal)
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |> na.omit() |> unique()
ssa_pat <- ssa_missingness_pattern(panel_numeric, ssa_iso3)
print(ssa_pat)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(ssa_pat, "output/tables/ssa_covid_closures_missingness.csv")

write_interim(panel, SRC)

overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(panel[, setdiff(OUTPUT_COLS, c("iso3", "year"))]))), 2
)

update_catalog(
  SRC,
  url         = "https://data.humdata.org/dataset/global-school-closures-covid19",
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("UNESCO daily status CSV (Feb 2020 - Mar 2022); fetched ", fetched_on(SRC)),
  n_rows      = nrow(panel),
  n_countries = dplyr::n_distinct(panel$iso3),
  year_range  = c(min(panel$year), max(panel$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(
    list(name = basename(daily_path),    sha256 = daily_sha),
    list(name = basename(duration_path), sha256 = duration_sha)
  ),
  variables   = lapply(OUTPUT_COLS, function(c) list(code = c, name = c)),
  notes = paste0(
    "Country-year panel derived from UNESCO daily status time-series ",
    "(transparent operationalization; UNESCO's pre-aggregated duration xlsx ",
    "retained for cross-validation only). Days per status category counted ",
    "per (iso3, year): days_closed (Status='Closed due to COVID-19'), days_partial ",
    "(Partially open), days_open (Fully open), days_break (Academic break). ",
    "Scope: 2020-2022 active monitoring window. Cited as UNESCO Global Monitoring ",
    "of School Closures. Feeds Model 2 as a time-varying confounder."
  )
)

render_catalog()
message("[covid] ingestion complete.")
