# R/10_ingest_hci.R
#
# Source: Human Capital Index (HCI)
# Brief reference: Data Stack, line 68
# Methodology: World Bank Human Capital Project (Patrinos et al.)
#
# === Pinned indicator list (PHASE 1 LOCK — modify only via ADR) =====================
# NOTE: HD.HCI.HLOS (Harmonized Test Scores) is *not* included here — it is the
# headline learning outcome variable, ingested separately in Session 04 (HLO source).
#
#   HD.HCI.OVRL      Human Capital Index, overall
#   HD.HCI.OVRL.FE   HCI, female
#   HD.HCI.OVRL.MA   HCI, male
#   HD.HCI.LAYS      Learning-adjusted years of school
#   HD.HCI.LAYS.FE   Learning-adjusted years of school, female
#   HD.HCI.LAYS.MA   Learning-adjusted years of school, male
# =====================================================================================

INDICATORS <- c(
  "HD.HCI.OVRL"    = "hci_overall",
  "HD.HCI.OVRL.FE" = "hci_female",
  "HD.HCI.OVRL.MA" = "hci_male",
  "HD.HCI.LAYS"    = "lays_overall",
  "HD.HCI.LAYS.FE" = "lays_female",
  "HD.HCI.LAYS.MA" = "lays_male"
)

# HCI is published intermittently (2010, 2017, 2018, 2020, 2022). Pull a wide window;
# expect sparse year coverage — most country-years will be NA, which is correct.
YEAR_RANGE <- 2000:2024
SRC <- "hci"

suppressPackageStartupMessages({
  library(tidyverse)
  library(WDI)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

# 1. Fetch ------------------------------------------------------------
raw_file <- file.path(raw_dir(SRC), "hci_raw.rds")

if (raw_is_stale(raw_file, max_days = 30)) {
  message("[hci] fetching from WDI API...")
  raw <- WDI(
    country   = "all",
    indicator = names(INDICATORS),
    start     = min(YEAR_RANGE),
    end       = max(YEAR_RANGE),
    extra     = TRUE
  )
  saveRDS(raw, raw_file)
  fetched_on(SRC, set = TRUE)
} else {
  message("[hci] using cached raw at ", raw_file)
  raw <- readRDS(raw_file)
}
raw_sha <- hash_raw(raw_file)
message(sprintf("[hci] raw: %d rows, %d cols, sha256=%s", nrow(raw), ncol(raw), substr(raw_sha, 1, 12)))

# 2. Clean ------------------------------------------------------------
raw_countries <- if ("region" %in% names(raw)) {
  filter(raw, region != "Aggregates")
} else raw

cleaned <- raw_countries |>
  mutate(iso3 = normalize_iso3(iso3c, src = SRC, origin = "iso3c")) |>
  filter(!is.na(iso3)) |>
  select(iso3, year, all_of(setNames(names(INDICATORS), unname(INDICATORS)))) |>
  arrange(iso3, year)

message(sprintf("[hci] cleaned: %d rows, %d countries, years %d-%d",
                nrow(cleaned),
                n_distinct(cleaned$iso3),
                min(cleaned$year), max(cleaned$year)))

# 3. Audit ------------------------------------------------------------
cov <- coverage_summary(cleaned, SRC)
print(cov)
coverage_heatmap(cleaned, SRC)

# 4. Write interim ----------------------------------------------------
write_interim(cleaned, SRC)

# 5. Update catalog ---------------------------------------------------
overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(cleaned[, unname(INDICATORS)]))), 2
)

update_catalog(
  SRC,
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("WDI API live, fetched ", fetched_on(SRC)),
  n_rows      = nrow(cleaned),
  n_countries = n_distinct(cleaned$iso3),
  year_range  = c(min(cleaned$year), max(cleaned$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(list(name = basename(raw_file), sha256 = raw_sha)),
  variables   = lapply(seq_along(INDICATORS), function(i) {
    list(code = names(INDICATORS)[i], name = unname(INDICATORS)[i])
  })
)

render_catalog()
message("[hci] ingestion complete.")
