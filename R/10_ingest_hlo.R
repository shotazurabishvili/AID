# R/10_ingest_hlo.R
#
# Source: HLO — Harmonized Learning Outcomes (the headline outcome variable).
#   Primary:     World Bank `HD.HCI.HLOS` via the WDI R package (current HCI release)
#   Robustness:  Altinok, Angrist & Patrinos (2018) — WB Policy Research WP 8314,
#                fetched via the OWID `owid-datasets` GitHub mirror (subject/level pooled).
#                Original paper: documents1.worldbank.org/.../WPS8314.pdf
#
# Brief reference: Data Stack, line 69 (HLO). Decision: ADR-0004.
#
# === Pinned indicator list (PHASE 1 LOCK — modify only via ADR) =====================
# Primary (WDI):
#   HD.HCI.HLOS    Harmonized Test Scores (HCI component, ~300–625 scale)
#
# Robustness (AAP-2018 via OWID mirror):
#   One score column already pooled across subjects (math/reading/science)
#   and levels (primary/secondary). 163 countries × 1965-2015 at 5-year
#   intervals. Threshold shares (min/intermediate/advanced) dropped — not used
#   in the planned Phase-5 sensitivity (single-number score is sufficient).
# =====================================================================================

INDICATORS_PRIMARY <- c("HD.HCI.HLOS" = "hlo_score")

YEAR_RANGE  <- 1995:2024            # matches WDI script
SRC_PRIMARY <- "hlo"
SRC_AAP     <- "hlo_aap2018"

# OWID raw GitHub URL — frozen by OWID at the date of their retrieval (2018-07-19);
# pinned here for reproducibility. Fall through to a manual instruction if the URL 404s.
AAP_URL_CANDIDATES <- c(
  paste0(
    "https://raw.githubusercontent.com/owid/owid-datasets/master/datasets/",
    "Global%20Data%20Set%20on%20Education%20Quality%20(1965-2015)%20-%20",
    "Altinok,%20Angrist,%20and%20Patrinos%20(2018)/",
    "Global%20Data%20Set%20on%20Education%20Quality%20(1965-2015)%20-%20",
    "Altinok,%20Angrist,%20and%20Patrinos%20(2018).csv"
  )
)
AAP_LOCAL_NAME <- "aap2018.csv"

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(WDI)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

# Generous timeout for the WDI API (it occasionally takes >60s)
options(timeout = max(300, getOption("timeout")))

# 1. Fetch primary (WDI HD.HCI.HLOS) ----------------------------------
raw_file <- file.path(raw_dir(SRC_PRIMARY), "hlo_raw.rds")

if (raw_is_stale(raw_file, max_days = 30)) {
  message("[hlo] fetching HD.HCI.HLOS from WDI API (no cache or >30d stale)...")
  raw_primary <- WDI(
    country   = "all",
    indicator = names(INDICATORS_PRIMARY),
    start     = min(YEAR_RANGE),
    end       = max(YEAR_RANGE),
    extra     = TRUE
  )
  saveRDS(raw_primary, raw_file)
  fetched_on(SRC_PRIMARY, set = TRUE)
} else {
  message("[hlo] using cached raw at ", raw_file)
  raw_primary <- readRDS(raw_file)
}
raw_sha_primary <- hash_raw(raw_file)
message(sprintf("[hlo] primary raw: %d rows, %d cols, sha256=%s",
                nrow(raw_primary), ncol(raw_primary), substr(raw_sha_primary, 1, 12)))

# 2. Fetch AAP-2018 (OWID mirror) -------------------------------------
raw_aap <- file.path(raw_dir(SRC_AAP), AAP_LOCAL_NAME)

if (raw_is_stale(raw_aap, max_days = 365)) {
  message("[hlo_aap2018] downloading from OWID mirror (no cache or >365d stale)...")
  ok <- FALSE
  for (url in AAP_URL_CANDIDATES) {
    ok <- tryCatch({
      download.file(url, raw_aap, mode = "wb", quiet = TRUE, timeout = 120)
      file.info(raw_aap)$size > 5e3
    }, error = function(e) {
      message("[hlo_aap2018] download error: ", conditionMessage(e)); FALSE
    })
    if (isTRUE(ok)) break
  }
  if (!isTRUE(ok)) {
    stop(
      "[hlo_aap2018] could not fetch AAP-2018 from candidate URL(s).\n",
      "Manual fallback: visit https://openknowledge.worldbank.org/handle/10986/29281 ",
      "(WP 8314), or the OWID mirror at github.com/owid/owid-datasets, ",
      "download the CSV, place at ", raw_aap, ", and re-run."
    )
  }
  fetched_on(SRC_AAP, set = TRUE)
} else {
  message("[hlo_aap2018] using cached csv at ", raw_aap)
}
raw_sha_aap <- hash_raw(raw_aap)
message(sprintf("[hlo_aap2018] raw sha256=%s", substr(raw_sha_aap, 1, 12)))

# 3. Read + clean primary ---------------------------------------------
# Drop WDI aggregates (region/income groups). `extra=TRUE` adds a `region` column
# marking aggregates as "Aggregates".
raw_countries <- if ("region" %in% names(raw_primary)) {
  filter(raw_primary, region != "Aggregates")
} else raw_primary

cleaned_primary <- raw_countries |>
  mutate(iso3 = normalize_iso3(iso3c, src = SRC_PRIMARY, origin = "iso3c")) |>
  filter(!is.na(iso3)) |>
  select(iso3, year, all_of(setNames(names(INDICATORS_PRIMARY), unname(INDICATORS_PRIMARY)))) |>
  arrange(iso3, year)

message(sprintf("[hlo] cleaned primary: %d rows, %d countries, years %d-%d",
                nrow(cleaned_primary),
                n_distinct(cleaned_primary$iso3),
                min(cleaned_primary$year), max(cleaned_primary$year)))

# 4. Read + clean AAP-2018 --------------------------------------------
# OWID schema: Entity (country name) | Year | <score column> | <3 threshold columns>.
# The score column header is "Average harmonised learning outcome score (Altinok, ...) "
# — already pooled across subjects (math/reading/science) and levels (primary/secondary)
# per the OWID datapackage description.
aap_raw <- read_csv(raw_aap, col_types = cols(.default = col_character()),
                    progress = FALSE)

score_col <- names(aap_raw)[grepl("^Average harmonised", names(aap_raw))]
if (length(score_col) != 1) {
  stop("[hlo_aap2018] expected exactly one 'Average harmonised...' column; got ",
       length(score_col), ". Columns: ", paste(names(aap_raw), collapse = " | "))
}

cleaned_aap <- aap_raw |>
  rename(entity_raw = Entity, year_raw = Year, score_raw = all_of(score_col)) |>
  select(entity_raw, year_raw, score_raw) |>
  mutate(
    year     = suppressWarnings(as.integer(year_raw)),
    hlo_aap  = suppressWarnings(as.numeric(score_raw)),
    iso3     = normalize_iso3(entity_raw, src = SRC_AAP, origin = "country.name")
  ) |>
  filter(!is.na(iso3), !is.na(year), !is.na(hlo_aap),
         year %in% YEAR_RANGE) |>
  select(iso3, year, hlo_aap) |>
  arrange(iso3, year)

message(sprintf("[hlo_aap2018] cleaned: %d rows, %d countries, years %d-%d",
                nrow(cleaned_aap),
                n_distinct(cleaned_aap$iso3),
                min(cleaned_aap$year), max(cleaned_aap$year)))

# 5. Coverage audit + SSA contrast (both sources) ---------------------
cov_primary <- coverage_summary(cleaned_primary, SRC_PRIMARY)
print(cov_primary)
coverage_heatmap(cleaned_primary, SRC_PRIMARY)

cov_aap <- coverage_summary(cleaned_aap, SRC_AAP)
print(cov_aap)
coverage_heatmap(cleaned_aap, SRC_AAP)

# SSA universe — identical to UIS Session 03
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |>
  na.omit() |>
  unique()
message("[hlo] SSA universe: ", length(ssa_iso3), " ISO3 codes")

# Combine the two frames on (iso3, year) so both score columns sit side-by-side
# for the SSA missingness contrast. full_join: a row exists wherever either
# source observes; an NA in `hlo_score` or `hlo_aap` means "this source did
# not measure that country-year".
hlo_compare <- full_join(cleaned_primary, cleaned_aap, by = c("iso3", "year"))

ssa_pat <- ssa_missingness_pattern(hlo_compare, ssa_iso3)
print(ssa_pat)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(ssa_pat, "output/tables/ssa_hlo_missingness.csv")

ssa_long <- ssa_pat |>
  pivot_longer(c(ssa_missing_pct, non_ssa_missing_pct),
               names_to = "region", values_to = "missing_pct") |>
  mutate(region = recode(region,
                         ssa_missing_pct     = "Sub-Saharan Africa",
                         non_ssa_missing_pct = "Rest of world"))

p_ssa <- ggplot(ssa_long, aes(x = reorder(indicator, missing_pct),
                              y = missing_pct, fill = region)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("Sub-Saharan Africa" = "#d95f02",
                               "Rest of world"      = "#7570b3")) +
  labs(title = "HLO missingness: SSA vs rest of world",
       subtitle = "Phase 1 Session 04 - feeds ADR-0004",
       x = NULL, y = "Missing %", fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("output/figures/coverage/ssa_hlo_missingness.pdf", p_ssa, width = 8, height = 4)
ggsave("output/figures/coverage/ssa_hlo_missingness.png", p_ssa, width = 8, height = 4, dpi = 150)

# 6. Write interim ----------------------------------------------------
write_interim(cleaned_primary, SRC_PRIMARY)
write_interim(cleaned_aap,     SRC_AAP)

# 7. Update catalog (two entries: primary + robustness) ---------------
overall_missing_pct_primary <- round(
  100 * mean(is.na(as.matrix(cleaned_primary[, unname(INDICATORS_PRIMARY)]))), 2
)
overall_missing_pct_aap <- round(
  100 * mean(is.na(cleaned_aap$hlo_aap)), 2
)

update_catalog(
  SRC_PRIMARY,
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("WDI API live, fetched ", fetched_on(SRC_PRIMARY)),
  n_rows      = nrow(cleaned_primary),
  n_countries = n_distinct(cleaned_primary$iso3),
  year_range  = c(min(cleaned_primary$year), max(cleaned_primary$year)),
  missing_pct = overall_missing_pct_primary,
  raw_files   = list(list(name = basename(raw_file), sha256 = raw_sha_primary)),
  variables   = lapply(seq_along(INDICATORS_PRIMARY), function(i) {
    list(code = names(INDICATORS_PRIMARY)[i], name = unname(INDICATORS_PRIMARY)[i])
  }),
  notes = paste(
    "Headline outcome variable. Primary specification per ADR-0004.",
    "Robustness slug `hlo_aap2018`.",
    "SSA missingness contrast at output/tables/ssa_hlo_missingness.csv."
  )
)

update_catalog(
  SRC_AAP,
  name             = "HLO — Altinok-Angrist-Patrinos 2018 robustness",
  url              = "https://openknowledge.worldbank.org/handle/10986/29281",
  auth_required    = "no",
  methodology_cite = "Altinok, Angrist & Patrinos (2018) WP 8314",
  access_date      = format(Sys.Date(), "%Y-%m-%d"),
  version          = paste0("OWID mirror of WP 8314, retrieved 2018-07-19; fetched locally ",
                            fetched_on(SRC_AAP)),
  n_rows           = nrow(cleaned_aap),
  n_countries      = n_distinct(cleaned_aap$iso3),
  year_range       = c(min(cleaned_aap$year), max(cleaned_aap$year)),
  missing_pct      = overall_missing_pct_aap,
  raw_files        = list(list(name = basename(raw_aap), sha256 = raw_sha_aap)),
  variables        = list(list(code = "AAP2018.HLO", name = "hlo_aap")),
  notes = paste(
    "Robustness measure per ADR-0004. WB Policy Research WP 8314.",
    "Fetched via OWID owid-datasets GitHub mirror (subjects/levels pre-pooled by OWID).",
    "Threshold-share columns dropped — single score is sufficient for Phase-5 sensitivity.",
    "5-year intervals (2000, 2005, 2010, 2015 within our YEAR_RANGE)."
  )
)

render_catalog()
message("[hlo] ingestion complete.")
