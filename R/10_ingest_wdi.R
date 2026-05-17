# R/10_ingest_wdi.R
#
# Source: World Development Indicators (WDI)
# Brief reference: Data Stack, line 65 (folds in former EdStats — see plan landmine 5)
# Methodology: World Bank annual WDI release; queried via the WDI R package
#
# === Pinned indicator list (PHASE 1 LOCK — modify only via ADR) =====================
#
# Controls (macro):
#   NY.GDP.PCAP.CD     GDP per capita (current US$)
#   NY.GDP.PCAP.PP.CD  GDP per capita, PPP (current intl $)
#   NY.GNP.PCAP.CD     GNI per capita (current US$)
#   SP.POP.TOTL        Population, total
#
# Education indicators (former EdStats, now WDI series):
#   SE.PRM.ENRR        Gross primary enrollment ratio
#   SE.SEC.ENRR        Gross secondary enrollment ratio
#   SE.PRM.NENR        Net primary enrollment ratio
#   SE.PRM.ENRL.TC.ZS  Pupil-teacher ratio, primary
#   SE.XPD.TOTL.GD.ZS  Government education expenditure (% of GDP)
#   SE.XPD.TOTL.GB.ZS  Government education expenditure (% of government expenditure)
#   SE.PRM.CMPT.ZS     Primary completion rate (% of relevant age group)
#   SE.SEC.CMPT.LO.ZS  Lower secondary completion rate
#   SE.PRM.UNER        Out-of-school primary (count)
# =====================================================================================

INDICATORS <- c(
  "NY.GDP.PCAP.CD"    = "gdp_pc_usd",
  "NY.GDP.PCAP.PP.CD" = "gdp_pc_ppp",
  "NY.GNP.PCAP.CD"    = "gni_pc_usd",
  "SP.POP.TOTL"       = "population",
  "SE.PRM.ENRR"       = "enroll_prim_gross",
  "SE.SEC.ENRR"       = "enroll_sec_gross",
  "SE.PRM.NENR"       = "enroll_prim_net",
  "SE.PRM.ENRL.TC.ZS" = "ptr_primary",
  "SE.XPD.TOTL.GD.ZS" = "edu_exp_pct_gdp",
  "SE.XPD.TOTL.GB.ZS" = "edu_exp_pct_gov",
  "SE.PRM.CMPT.ZS"    = "primary_completion",
  "SE.SEC.CMPT.LO.ZS" = "lower_sec_completion",
  "SE.PRM.UNER"       = "oos_primary_count"
)

YEAR_RANGE <- 1995:2024   # Buffer beyond brief's 2000-2022 for sensitivity
SRC <- "wdi"

suppressPackageStartupMessages({
  library(tidyverse)
  library(WDI)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

# 1. Fetch ------------------------------------------------------------
raw_file <- file.path(raw_dir(SRC), "wdi_raw.rds")

if (raw_is_stale(raw_file, max_days = 30)) {
  message("[wdi] fetching from WDI API (no cache or >30d stale)...")
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
  message("[wdi] using cached raw at ", raw_file)
  raw <- readRDS(raw_file)
}
raw_sha <- hash_raw(raw_file)
message(sprintf("[wdi] raw: %d rows, %d cols, sha256=%s", nrow(raw), ncol(raw), substr(raw_sha, 1, 12)))

# 2. Clean ------------------------------------------------------------
# Drop WDI aggregates (region/income groups). The 'region' column from extra=TRUE
# marks them as "Aggregates".
raw_countries <- if ("region" %in% names(raw)) {
  filter(raw, region != "Aggregates")
} else raw

cleaned <- raw_countries |>
  mutate(iso3 = normalize_iso3(iso3c, src = SRC, origin = "iso3c")) |>
  filter(!is.na(iso3)) |>
  select(iso3, year, all_of(setNames(names(INDICATORS), unname(INDICATORS)))) |>
  arrange(iso3, year)

message(sprintf("[wdi] cleaned: %d rows, %d countries, years %d-%d",
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
message("[wdi] ingestion complete.")
