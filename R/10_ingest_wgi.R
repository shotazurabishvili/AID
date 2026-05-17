# R/10_ingest_wgi.R
#
# Source: Worldwide Governance Indicators (WGI) — native bundle
# Brief reference: Data Stack, line 66; Self-Review § Data Integrity Checks (Langbein-Knack)
# Methodology: Kaufmann, Kraay & Mastruzzi (annual WGI release)
# Engaged critique: Langbein & Knack (2010) — see docs/lit/langbein-knack-2010.md
#
# This script fetches the native WGI multi-sheet Excel bundle (NOT via the WDI R
# package), which retains the n_sources count per country-year — the minimum
# information needed to acknowledge the Langbein-Knack aggregation critique in
# Phase 1. Full per-source values (one file per source organization like EIU,
# BTI, V-Dem) are NOT ingested here; that's deferred to Phase 5 if ADR-0009
# selects an option requiring source-level reconstruction.
#
# === Pinned indicator list (PHASE 1 LOCK — modify only via ADR) =====================
# For each of the six WGI dimensions, retain three metrics:
#   <dim>_est    Estimate of governance (range ~-2.5 to 2.5)
#   <dim>_se     Standard error (model-based, smaller = more sources / agreement)
#   <dim>_n_src  Number of underlying sources contributing (1-15+)
#
# Six dimensions:
#   va   Voice and Accountability
#   pv   Political Stability and Absence of Violence/Terrorism
#   ge   Government Effectiveness
#   rq   Regulatory Quality
#   rl   Rule of Law
#   cc   Control of Corruption
#
# Dropped: Rank, Lower, Upper percentile-rank columns (collinear with estimate).
# =====================================================================================

SRC <- "wgi"
YEAR_RANGE <- 1996:2024  # WGI is biennial 1996-2002, annual since 2002

# Map sheet names in the bundle → short dimension codes
SHEET_TO_DIM <- c(
  "VoiceandAccountability"          = "va",
  "Political StabilityNoViolence"   = "pv",
  "GovernmentEffectiveness"         = "ge",
  "RegulatoryQuality"               = "rq",
  "RuleofLaw"                       = "rl",
  "ControlofCorruption"             = "cc"
)

WGI_URLS <- c(
  primary  = "https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset.xlsx",
  fallback = "https://databank.worldbank.org/data/download/wgidataset.xlsx"
)

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

# 1. Fetch ------------------------------------------------------------
raw_file <- file.path(raw_dir(SRC), "wgidataset.xlsx")

if (raw_is_stale(raw_file, max_days = 90)) {
  fetched <- FALSE
  for (label in names(WGI_URLS)) {
    u <- WGI_URLS[[label]]
    message(sprintf("[wgi] trying %s URL: %s", label, u))
    ok <- tryCatch({
      download.file(u, raw_file, mode = "wb", quiet = TRUE, timeout = 60)
      sz <- file.info(raw_file)$size
      message(sprintf("[wgi] downloaded %d bytes", sz))
      sz > 1e5
    }, error = function(e) { message("[wgi] error: ", conditionMessage(e)); FALSE })
    if (isTRUE(ok)) { fetched <- TRUE; fetched_on(SRC, set = TRUE); break }
  }
  if (!fetched) {
    stop(
      "[wgi] could not fetch WGI bundle from either URL.\n",
      "Manual fallback: open https://info.worldbank.org/governance/wgi/, ",
      "download wgidataset.xlsx, place at ", raw_file, ", and re-run."
    )
  }
} else {
  message("[wgi] using cached raw at ", raw_file)
}
raw_sha <- hash_raw(raw_file)
message(sprintf("[wgi] raw sha256=%s", substr(raw_sha, 1, 12)))

# 2. Clean ------------------------------------------------------------
# Each dimension sheet has:
#   Row 7: year repeated 6 times per year (1996 1996 ... 2022 2022)
#   Row 8: column headers (Country/Territory, Code, Estimate, StdErr, NumSrc, Rank, Lower, Upper)
#   Row 9+: data
# Strategy: read year+header rows, build composite column names, read data,
# pivot long, filter to {Estimate, StdErr, NumSrc}, pivot wide.

read_dim_sheet <- function(file, sheet_name, dim_code) {
  # WGI bundle layout (per 2024 release):
  #   xlsx rows  1-13: title + legend (variable amount of blank space)
  #   xlsx row     14: year header (1996 1996 1996 1996 1996 1996 2000 2000 ...)
  #   xlsx row     15: metric header (Country/Territory, Code, Estimate, StdErr, NumSrc, Rank, Lower, Upper, ...)
  #   xlsx rows   16+: data (Aruba ABW <values>...)
  #
  # We detect the year row dynamically (search top 25 rows for a row where most
  # non-NA cells are 4-digit ints) — robust to small future layout shifts.

  probe <- read_excel(file, sheet = sheet_name, n_max = 25,
                      col_names = FALSE, .name_repair = "minimal")

  year_row_idx <- NA_integer_
  for (r in seq_len(nrow(probe))) {
    v <- suppressWarnings(as.integer(unlist(probe[r, ])))
    if (sum(!is.na(v) & v >= 1990 & v <= 2030) >= 10) {
      year_row_idx <- r; break
    }
  }
  if (is.na(year_row_idx)) stop("[wgi:", sheet_name, "] could not find year header row")

  raw <- read_excel(file, sheet = sheet_name, skip = year_row_idx - 1,
                    col_names = FALSE, .name_repair = "minimal")

  years_row   <- suppressWarnings(as.integer(unlist(raw[1, ])))
  metrics_row <- as.character(unlist(raw[2, ]))
  n_cols <- ncol(raw)

  # Build column names matching actual data width
  col_new <- character(n_cols)
  for (j in seq_len(n_cols)) {
    if (!is.na(years_row[j])) {
      col_new[j] <- paste0("y", years_row[j], "_", metrics_row[j])
    } else if (!is.na(metrics_row[j]) && nchar(metrics_row[j]) > 0) {
      col_new[j] <- metrics_row[j]                 # ID cols: "Country/Territory", "Code"
    } else {
      col_new[j] <- paste0("drop_", j)
    }
  }

  dat <- raw[-c(1, 2), ]                           # drop the 2 header rows
  names(dat) <- col_new

  dat <- dat |>
    filter(!is.na(.data$Code), nchar(.data$Code) > 0) |>
    select(.data$Code, starts_with("y"))

  long <- dat |>
    pivot_longer(cols = -Code,
                 names_to = c("year", "metric"),
                 names_pattern = "y(\\d+)_(.+)") |>
    mutate(year  = as.integer(year),
           value = suppressWarnings(as.numeric(value))) |>
    filter(metric %in% c("Estimate", "StdErr", "NumSrc")) |>
    mutate(metric = recode(metric,
                           "Estimate" = "est",
                           "StdErr"   = "se",
                           "NumSrc"   = "n_src"),
           dimension = dim_code)

  long
}

all_long <- map_dfr(names(SHEET_TO_DIM), function(sh) {
  message("[wgi] reading sheet: ", sh)
  read_dim_sheet(raw_file, sh, SHEET_TO_DIM[[sh]])
})

# Wide form: one row per (country, year); columns like va_est, va_se, va_n_src, pv_est, ...
cleaned <- all_long |>
  unite("col", dimension, metric, sep = "_") |>
  pivot_wider(names_from = col, values_from = value) |>
  mutate(iso3 = normalize_iso3(Code, src = SRC, origin = "iso3c")) |>
  filter(!is.na(iso3)) |>
  select(iso3, year, ends_with("_est"), ends_with("_se"), ends_with("_n_src")) |>
  arrange(iso3, year)

message(sprintf("[wgi] cleaned: %d rows, %d countries, years %d-%d",
                nrow(cleaned),
                n_distinct(cleaned$iso3),
                min(cleaned$year), max(cleaned$year)))

# 3. Audit ------------------------------------------------------------
cov <- coverage_summary(cleaned, SRC)
print(cov, n = 30)
coverage_heatmap(cleaned, SRC)

# 4. Write interim ----------------------------------------------------
write_interim(cleaned, SRC)

# 5. Update catalog ---------------------------------------------------
value_cols <- setdiff(names(cleaned), c("iso3", "year"))
overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(cleaned[, value_cols]))), 2
)

INDICATOR_DEFS <- list(
  va_est   = "Voice and Accountability — estimate",
  va_se    = "Voice and Accountability — standard error",
  va_n_src = "Voice and Accountability — number of underlying sources",
  pv_est   = "Political Stability and Absence of Violence — estimate",
  pv_se    = "Political Stability and Absence of Violence — standard error",
  pv_n_src = "Political Stability and Absence of Violence — n sources",
  ge_est   = "Government Effectiveness — estimate",
  ge_se    = "Government Effectiveness — standard error",
  ge_n_src = "Government Effectiveness — n sources",
  rq_est   = "Regulatory Quality — estimate",
  rq_se    = "Regulatory Quality — standard error",
  rq_n_src = "Regulatory Quality — n sources",
  rl_est   = "Rule of Law — estimate",
  rl_se    = "Rule of Law — standard error",
  rl_n_src = "Rule of Law — n sources",
  cc_est   = "Control of Corruption — estimate",
  cc_se    = "Control of Corruption — standard error",
  cc_n_src = "Control of Corruption — n sources"
)

update_catalog(
  SRC,
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("Native bundle, fetched ", fetched_on(SRC)),
  n_rows      = nrow(cleaned),
  n_countries = n_distinct(cleaned$iso3),
  year_range  = c(min(cleaned$year), max(cleaned$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(list(name = basename(raw_file), sha256 = raw_sha)),
  variables   = lapply(names(INDICATOR_DEFS), function(v) {
    list(code = v, name = INDICATOR_DEFS[[v]])
  })
)

render_catalog()
message("[wgi] ingestion complete.")
