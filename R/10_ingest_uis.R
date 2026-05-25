# R/10_ingest_uis.R
#
# Source: UNESCO Institute for Statistics (UIS) — SDG-4 bulk download
# Reference: Data Stack, line 67 (private expenditure + out-of-school rates)
# Methodology: UNESCO Institute for Statistics (annual SDG-4 release)
#
# Bulk download structure (Feb 2026 release):
#   SDG.zip contains SDG_DATA_NATIONAL.csv (long format: INDICATOR_ID, COUNTRY_ID,
#   YEAR, VALUE, MAGNITUDE, QUALIFIER) + SDG_LABEL.csv (code → label map).
#
# === Pinned indicator list (PHASE 1 LOCK — modify only via ADR) =====================
# Substitution notes from plan → actual UIS codes:
#   Planned XGDP.FSHH.FFNTP  →  Actual XGDP.FSHH.FFNTR  (only FFNTR available)
#   Planned XGDP.FSGOV.FFNTP →  Actual XGDP.FSGOV       (UIS simple total — cleanest WDI compare)
#   Planned ROFST.1          →  Actual ROFST.1.CP       (UIS uses .CP for cumulative %)
#   Planned ROFST.1.F        →  Actual ROFST.1.F.CP     (same)
#   Planned ROFST.1.M        →  Actual ROFST.1.M.CP
#   Planned ROFST.2          →  Actual ROFST.2.CP
#   Planned ROFST.3          →  Actual ROFST.3.CP
# =====================================================================================

INDICATORS <- c(
  "XGDP.FSHH.FFNTR" = "priv_exp_pct_gdp",       # Initial private (household) expenditure on education as % of GDP
  "XGDP.FSGOV"      = "gov_exp_pct_gdp_uis",    # Government expenditure on education as % of GDP (UIS; cross-check vs WDI)
  "ROFST.1.CP"      = "oos_rate_primary",       # Out-of-school rate, primary, both sexes (%)
  "ROFST.1.F.CP"    = "oos_rate_primary_f",
  "ROFST.1.M.CP"    = "oos_rate_primary_m",
  "ROFST.2.CP"      = "oos_rate_lower_sec",     # OOS, lower secondary
  "ROFST.3.CP"      = "oos_rate_upper_sec"      # OOS, upper secondary
)

SRC <- "uis"
UIS_BULK_URL_PRIMARY  <- "https://download.uis.unesco.org/bdds/202602/SDG.zip"
UIS_BULK_URL_FALLBACK <- NULL  # discovered at runtime if primary fails

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

# 1. Fetch ------------------------------------------------------------
raw_zip <- file.path(raw_dir(SRC), "SDG.zip")

if (raw_is_stale(raw_zip, max_days = 90)) {
  message("[uis] downloading SDG.zip (no cache or >90d stale)...")
  ok <- tryCatch({
    download.file(UIS_BULK_URL_PRIMARY, raw_zip, mode = "wb",
                  quiet = TRUE, timeout = 300)
    file.info(raw_zip)$size > 1e6
  }, error = function(e) { message("[uis] download error: ", conditionMessage(e)); FALSE })
  if (!isTRUE(ok)) {
    stop(
      "[uis] could not fetch SDG.zip from canonical URL.\n",
      "Manual fallback: visit https://databrowser.uis.unesco.org/resources/bulk, ",
      "download SDG.zip, place at ", raw_zip, ", and re-run."
    )
  }
  fetched_on(SRC, set = TRUE)
} else {
  message("[uis] using cached zip at ", raw_zip)
}
raw_sha <- hash_raw(raw_zip)
message(sprintf("[uis] raw sha256=%s", substr(raw_sha, 1, 12)))

# Unzip if data CSV not already extracted
data_csv  <- file.path(raw_dir(SRC), "SDG_DATA_NATIONAL.csv")
label_csv <- file.path(raw_dir(SRC), "SDG_LABEL.csv")
if (!file.exists(data_csv) || !file.exists(label_csv)) {
  message("[uis] unzipping...")
  unzip(raw_zip, exdir = raw_dir(SRC), overwrite = TRUE)
}

# 2. Read + clean ------------------------------------------------------
# Filter at read time to avoid loading 1.46M rows when we want ~7 indicators
message("[uis] reading SDG_DATA_NATIONAL.csv with on-the-fly filter...")
raw <- read_csv(
  data_csv,
  col_types = cols(
    INDICATOR_ID = col_character(),
    COUNTRY_ID   = col_character(),
    YEAR         = col_integer(),
    VALUE        = col_double(),
    MAGNITUDE    = col_character(),
    QUALIFIER    = col_character()
  ),
  progress = FALSE
) |>
  filter(INDICATOR_ID %in% names(INDICATORS))

message(sprintf("[uis] filtered to %d obs across %d indicators",
                nrow(raw), n_distinct(raw$INDICATOR_ID)))

# Pivot wide, normalize ISO3
cleaned <- raw |>
  select(iso3_raw = COUNTRY_ID, year = YEAR, INDICATOR_ID, VALUE) |>
  mutate(col = INDICATORS[INDICATOR_ID]) |>
  select(-INDICATOR_ID) |>
  pivot_wider(names_from = col, values_from = VALUE,
              values_fn = mean) |>          # mean handles any rare duplicates
  mutate(iso3 = normalize_iso3(iso3_raw, src = SRC, origin = "iso3c")) |>
  filter(!is.na(iso3)) |>
  select(iso3, year, all_of(unname(INDICATORS))) |>
  arrange(iso3, year)

message(sprintf("[uis] cleaned: %d rows, %d countries, years %d-%d",
                nrow(cleaned),
                n_distinct(cleaned$iso3),
                min(cleaned$year), max(cleaned$year)))

# 3. Audit -------------------------------------------------------------
cov <- coverage_summary(cleaned, SRC)
print(cov)
coverage_heatmap(cleaned, SRC)

# 4. SSA missingness pattern (the headline output of this session) -----
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |>
  na.omit() |>
  unique()
message("[uis] SSA universe: ", length(ssa_iso3), " ISO3 codes")

ssa_pat <- ssa_missingness_pattern(cleaned, ssa_iso3)
print(ssa_pat)

# Persist SSA missingness table + figure
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(ssa_pat, "output/tables/ssa_uis_missingness.csv")

ssa_long <- ssa_pat |>
  pivot_longer(c(ssa_missing_pct, non_ssa_missing_pct),
               names_to = "region", values_to = "missing_pct") |>
  mutate(region = recode(region,
                         ssa_missing_pct     = "Sub-Saharan Africa",
                         non_ssa_missing_pct = "Rest of world"))

p <- ggplot(ssa_long, aes(x = reorder(indicator, missing_pct), y = missing_pct, fill = region)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("Sub-Saharan Africa" = "#d95f02", "Rest of world" = "#7570b3")) +
  labs(title = "UIS missingness: SSA vs rest of world",
       subtitle = "the corresponding analytical step — informs PAP-0006",
       x = NULL, y = "Missing %", fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("output/figures/coverage/ssa_uis_missingness.pdf", p, width = 8, height = 5)
ggsave("output/figures/coverage/ssa_uis_missingness.png", p, width = 8, height = 5, dpi = 150)

# 5. Write interim -----------------------------------------------------
write_interim(cleaned, SRC)

# 6. Update catalog ----------------------------------------------------
overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(cleaned[, unname(INDICATORS)]))), 2
)
release <- "SDG bulk 2026-02"

update_catalog(
  SRC,
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = release,
  n_rows      = nrow(cleaned),
  n_countries = n_distinct(cleaned$iso3),
  year_range  = c(min(cleaned$year), max(cleaned$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(list(name = basename(raw_zip), sha256 = raw_sha)),
  variables   = lapply(seq_along(INDICATORS), function(i) {
    list(code = names(INDICATORS)[i], name = unname(INDICATORS)[i])
  }),
  notes = paste(
    "Native SDG bulk (Feb 2026); substitutions from planned codes:",
    "FFNTP→FFNTR (private exp), ROFST.N→ROFST.N.CP (cumulative %),",
    "XGDP.FSGOV.FFNTP→XGDP.FSGOV (simple total). SSA missingness pattern at",
    "output/tables/ssa_uis_missingness.csv feeds PAP-0006 (the analysis lock)."
  )
)

render_catalog()
message("[uis] ingestion complete.")
