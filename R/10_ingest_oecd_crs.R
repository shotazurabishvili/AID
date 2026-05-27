# R/10_ingest_oecd_crs.R
#
# Source: OECD DAC Creditor Reporting System (CRS) — the **treatment variable**
#   (ODA flows to education) anchoring the headline regression.
# Reference: Data Stack; manuscript §3
# Methodology cite: OECD DAC (annual CRS release)
#
# Bulk-download mechanism (discovered from ONEcampaign/oda_reader source):
#   1. Fetch SDMX dataflow XML at sdmx.oecd.org/.../DSD_CRS@DF_CRS/<version>
#   2. Regex the response for `CRS-Parquet-v` marker and extract the IDFile GUID
#   3. Download from stats.oecd.org/wbos/fileview2.aspx?IDFile=<GUID>
#      → ~1 GB zip containing the full CRS microdata as parquet
# At the prior step (2026-05-17) the current release is CRS-Parquet-v20260408,
# IDFile=50f0355e-8f61-4230-85f3-90b4db45bfc9. The script rediscovers on each
# stale-cache run so the next release is picked up automatically.
#
# Pending PAPs this ingest preserves (no locks this session):
#   - PAP-0005 (commitment vs disbursement)  → both measures retained
#   - PAP-0007 (intervention typology)       → project_title / short_description / long_description retained
#   - PAP-0008 (Chinese aid inclusion)       → OECD CRS is DAC-only; GCDF  covers China
#
# === Pinned column list (PHASE 1 LOCK — modify only via PAP) ========================
# Actual schema: legacy CRS dotStat format (NOT SDMX-dimensioned). Commitment and
# disbursement are SEPARATE wide columns, not long-format rows. Deflated (constant-USD)
# variants live alongside current-USD measures. PAP-0005 becomes a column-choice question;
# PAP-0007 typology coding reads project_title + short_description + long_description.
KEEP_COLS <- c(
  # Time
  "year",
  # Donor identity (numeric DAC member code + implementing agency)
  "donor_code", "donor_name", "agency_code", "agency_name",
  # Project identity (uniqueness within donor-year)
  "crs_id", "project_number",
  # Recipient identity (recipient_code is mostly iso3n; region/income for descriptives)
  "recipient_code", "recipient_name", "region_name", "incomegroup_name",
  # Sector taxonomy: 3-digit sector_code (used for the 110-114 filter)
  # + 5-digit purpose_code (Phase-7 typology granularity)
  "sector_code", "sector_name", "purpose_code", "purpose_name",
  # Flow / finance type / channel
  "flow_code", "flow_name", "bi_multi", "category", "finance_t", "aid_t",
  "channel_code", "channel_name", "parent_channel_code",
  # Value columns (PAP-0005: keep ALL measure variants + deflated counterparts)
  "usd_commitment",   "usd_commitment_defl",     # commitments (current + constant USD)
  "usd_disbursement", "usd_disbursement_defl",   # disbursements (current + constant USD)
  "usd_received",     "usd_received_defl",       # received (special cases)
  "usd_grant_equiv",  "usd_grant_equiv_defl",    # grant equivalent (post-2018 ODA methodology)
  "currency_code",
  # Description text (PAP-0007 typology source)
  "project_title", "short_description", "long_description", "keywords"
)
# ====================================================================================

SRC <- "oecd_crs"
SDMX_FLOW_URL <- "https://sdmx.oecd.org/public/rest/dataflow/OECD.DCD.FSD/DSD_CRS@DF_CRS/"
SDMX_VERSIONS <- c("1.6", "1.5", "1.4", "1.3", "1.2")    # decrement scan
SDMX_MARKER_REGEX <- "CRS-Parquet-v[^|<]*\\|https://stats\\.oecd\\.org/wbos/fileview2\\.aspx\\?IDFile=([0-9a-fA-F-]{36})"
BULK_BASE_URL <- "https://stats.oecd.org/wbos/fileview2.aspx?IDFile="
YEAR_RANGE <- 1995:2024
EDU_SECTOR_GROUP <- c(110L, 111L, 112L, 113L, 114L)

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

options(timeout = max(1800, getOption("timeout")))   # 30 min for the ~1 GB zip

# 1. Discover bulk file ID -------------------------------------------
discover_file_id <- function() {
  for (v in SDMX_VERSIONS) {
    url <- paste0(SDMX_FLOW_URL, v)
    message(sprintf("[oecd_crs] probing SDMX dataflow %s ...", v))
    resp <- tryCatch(
      paste(readLines(url, warn = FALSE), collapse = "\n"),
      error = function(e) { message("[oecd_crs] probe error: ", conditionMessage(e)); NA_character_ }
    )
    if (is.na(resp) || !nzchar(resp)) next
    m <- regmatches(resp, regexpr(SDMX_MARKER_REGEX, resp))
    if (length(m) == 0 || !nzchar(m[1])) next
    gid <- sub(".*IDFile=", "", m[1])
    label_match <- regmatches(resp, regexpr("CRS-Parquet-v[0-9]+", resp))
    label <- if (length(label_match) > 0) label_match[1] else "CRS-Parquet-vUNKNOWN"
    message(sprintf("[oecd_crs] discovered %s (SDMX %s) IDFile=%s", label, v, gid))
    return(list(version = v, label = label, file_id = gid))
  }
  stop(
    "[oecd_crs] could not discover CRS-Parquet file ID from any SDMX version.\n",
    "Manual fallback: visit ",
    "https://data-explorer.oecd.org/vis?df%5Bds%5D=DisseminateFinalBoost&df%5Bid%5D=DSD_CRS%40DF_CRS&df%5Bag%5D=OECD.DCD.FSD ",
    "→ Developer API → Bulk Download → copy the IDFile GUID, then either:\n",
    "  (a) hardcode it in this script's discover_file_id() fallback, or\n",
    "  (b) place the downloaded zip directly at data/raw/oecd_crs/crs_bulk.zip and re-run."
  )
}

# 2. Fetch bulk zip (cached 90 days) ---------------------------------
raw_zip <- file.path(raw_dir(SRC), "crs_bulk.zip")

if (raw_is_stale(raw_zip, max_days = 90)) {
  meta <- discover_file_id()
  url <- paste0(BULK_BASE_URL, meta$file_id)
  message(sprintf("[oecd_crs] downloading %s (~1 GB, may take 10-20 min)...", meta$label))
  ok <- tryCatch({
    download.file(url, raw_zip, mode = "wb", quiet = FALSE)
    file.info(raw_zip)$size > 100e6   # sanity check: at least 100 MB
  }, error = function(e) { message("[oecd_crs] download error: ", conditionMessage(e)); FALSE })
  if (!isTRUE(ok)) {
    stop("[oecd_crs] download failed or yielded an implausibly small file. ",
         "Manual fallback: place the bulk zip at ", raw_zip, " and re-run.")
  }
  fetched_on(SRC, set = TRUE)
  # Stash the discovered metadata for the catalog `notes` field
  writeLines(c(meta$version, meta$label, meta$file_id),
             file.path(raw_dir(SRC), ".sdmx_meta"))
} else {
  message("[oecd_crs] using cached zip at ", raw_zip)
}
raw_sha <- hash_raw(raw_zip)
message(sprintf("[oecd_crs] raw zip: %.1f MB, sha256=%s",
                file.info(raw_zip)$size / 1e6, substr(raw_sha, 1, 12)))

# List zip contents (base unzip can list Def64 entries even if it can't extract them).
zip_entries <- tryCatch(unzip(raw_zip, list = TRUE),
                        error = function(e) stop("[oecd_crs] zip listing failed: ", conditionMessage(e)))
if (nrow(zip_entries) == 0) stop("[oecd_crs] zip is empty")

parquet_in_zip <- zip_entries$Name[grepl("\\.parquet$", zip_entries$Name, ignore.case = TRUE)]
if (length(parquet_in_zip) == 0) {
  stop("[oecd_crs] no .parquet file found inside ", raw_zip,
       ". Contents: ", paste(zip_entries$Name, collapse = ", "))
}
message(sprintf("[oecd_crs] zip contains %d .parquet entry(ies): %s",
                length(parquet_in_zip), paste(parquet_in_zip, collapse = ", ")))

# Extract via the Python Deflate64 helper. OECD ships the CRS bulk zip with
# ZIP method 9 (Deflate64), which R's unzip() and Python stdlib zipfile cannot
# decompress. scripts/extract_deflate64_zip.py uses the zipfile-deflate64 PyPI
# shim. One-time setup: bash scripts/setup_tools_venv.sh
parquet_local <- file.path(raw_dir(SRC), parquet_in_zip[1])
if (!file.exists(parquet_local) ||
    file.info(parquet_local)$mtime < file.info(raw_zip)$mtime) {
  message("[oecd_crs] extracting via scripts/extract_deflate64_zip.py (Deflate64)...")
  venv_py <- ".venv-tools/bin/python"
  if (!file.exists(venv_py)) {
    stop("[oecd_crs] tools venv missing. Run: bash scripts/setup_tools_venv.sh")
  }
  rc <- system2(venv_py,
                args = c("scripts/extract_deflate64_zip.py",
                         shQuote(raw_zip),
                         shQuote(raw_dir(SRC)),
                         shQuote(parquet_in_zip[1])),
                stdout = "", stderr = "")
  if (rc != 0 || !file.exists(parquet_local)) {
    stop("[oecd_crs] Deflate64 extraction failed (rc=", rc, "). ",
         "Expected output at ", parquet_local)
  }
}
parquet_sha <- hash_raw(parquet_local)
message(sprintf("[oecd_crs] extracted parquet: %.1f MB, sha256=%s",
                file.info(parquet_local)$size / 1e6, substr(parquet_sha, 1, 12)))

# 3. Inspect schema + detect sector-code form ------------------------
ds <- arrow::open_dataset(parquet_local)
all_cols <- names(ds$schema)
missing_cols <- setdiff(KEEP_COLS, all_cols)
if (length(missing_cols) > 0) {
  stop("[oecd_crs] pinned columns missing from CRS schema: ",
       paste(missing_cols, collapse = ", "),
       "\nAvailable columns: ", paste(all_cols, collapse = ", "),
       "\nUpdate KEEP_COLS via an PAP if the upstream schema changed.")
}

# Probe sector_code to decide 3-digit vs 5-digit filter
sample_sec <- ds |>
  select(sector_code) |>
  filter(!is.na(sector_code)) |>
  head(2000) |>
  collect()
sector_is_5digit <- max(sample_sec$sector_code, na.rm = TRUE) > 999
message(sprintf("[oecd_crs] sector_code form detected: %s",
                ifelse(sector_is_5digit, "5-digit purpose codes", "3-digit sector group")))

# 4. Read + filter with arrow pushdown -------------------------------
message("[oecd_crs] reading + filtering (year + education sector group + column projection)...")
if (sector_is_5digit) {
  filtered <- ds |>
    filter(year %in% YEAR_RANGE,
           !is.na(sector_code),
           (sector_code %/% 100L) %in% EDU_SECTOR_GROUP) |>
    select(all_of(KEEP_COLS)) |>
    collect()
} else {
  filtered <- ds |>
    filter(year %in% YEAR_RANGE,
           !is.na(sector_code),
           sector_code %in% EDU_SECTOR_GROUP) |>
    select(all_of(KEEP_COLS)) |>
    collect()
}

message(sprintf("[oecd_crs] filtered: %d rows (education sector, %d-%d)",
                nrow(filtered), min(filtered$year), max(filtered$year)))

# 5. Normalize recipient ISO3 + clean --------------------------------
# Important: OECD uses its OWN area-code system (e.g., Nigeria = 261, not the
# ISO 3166-1 numeric 566). We resolve via recipient_name with the project's
# normalize_iso3() helper, which handles known country-name aliases (Kosovo,
# Taiwan, Côte d'Ivoire, etc.) and logs unresolved labels (OECD regionals
# like "Africa, regional" / "Developing countries, unspecified") to
# output/logs/iso3_unresolved_oecd_crs.csv for audit.
n_pre <- nrow(filtered)
cleaned <- filtered |>
  mutate(iso3 = normalize_iso3(recipient_name, src = SRC, origin = "country.name"))

n_regional <- sum(is.na(cleaned$iso3))
message(sprintf("[oecd_crs] %d rows (%.1f%%) on regional/unspecified aggregates — dropped from country panel",
                n_regional, 100 * n_regional / n_pre))

n_regional <- sum(is.na(cleaned$iso3))
message(sprintf("[oecd_crs] %d rows (%.1f%%) on regional/unspecified aggregates — dropped from country panel",
                n_regional, 100 * n_regional / n_pre))

cleaned <- cleaned |>
  filter(!is.na(iso3)) |>
  mutate(year = as.integer(year),
         usd_commitment   = as.numeric(usd_commitment),
         usd_disbursement = as.numeric(usd_disbursement),
         usd_grant_equiv  = as.numeric(usd_grant_equiv)) |>
  arrange(iso3, year, donor_code, purpose_code)

message(sprintf("[oecd_crs] cleaned: %d rows, %d countries, years %d-%d, %d donors",
                nrow(cleaned),
                n_distinct(cleaned$iso3),
                min(cleaned$year), max(cleaned$year),
                n_distinct(cleaned$donor_code)))

# 6. Coverage audit + SSA contrast -----------------------------------
# Build per-(iso3, year) availability table: did we observe ANY positive
# commitment / disbursement / grant-equivalent flow in this country-year?
# (Encoded as 1=present, NA=missing so coverage_summary treats them like
# regular indicators.)
avail_num <- cleaned |>
  group_by(iso3, year) |>
  summarise(
    has_commitment   = if (any(!is.na(usd_commitment)   & usd_commitment   > 0)) 1 else NA_real_,
    has_disbursement = if (any(!is.na(usd_disbursement) & usd_disbursement > 0)) 1 else NA_real_,
    has_grant_equiv  = if (any(!is.na(usd_grant_equiv)  & usd_grant_equiv  > 0)) 1 else NA_real_,
    .groups = "drop"
  ) |>
  arrange(iso3, year)

cov <- coverage_summary(avail_num, SRC)
print(cov)
coverage_heatmap(avail_num, SRC)

# SSA missingness contrast
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |>
  na.omit() |>
  unique()
message("[oecd_crs] SSA universe: ", length(ssa_iso3), " ISO3 codes")

ssa_pat <- ssa_missingness_pattern(avail_num, ssa_iso3)
print(ssa_pat)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(ssa_pat, "output/tables/ssa_oecd_crs_missingness.csv")

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
  labs(title = "OECD CRS missingness: SSA vs rest of world",
       subtitle = "the corresponding analytical step - feeds PAPs 0002 / 0005",
       x = NULL, y = "Missing %", fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("output/figures/coverage/ssa_oecd_crs_missingness.pdf", p_ssa, width = 8, height = 4)
ggsave("output/figures/coverage/ssa_oecd_crs_missingness.png", p_ssa, width = 8, height = 4, dpi = 150)

# 7. Write interim ---------------------------------------------------
write_interim(cleaned, SRC)

# 8. Update catalog --------------------------------------------------
# (iso3, year) cartesian missingness as a single headline number
n_year_cells <- length(unique(cleaned$iso3)) * length(unique(cleaned$year))
n_observed_cells <- nrow(distinct(cleaned, iso3, year))
overall_missing_pct <- round(100 * (1 - n_observed_cells / n_year_cells), 2)

# Read SDMX meta if cached
sdmx_meta <- if (file.exists(file.path(raw_dir(SRC), ".sdmx_meta"))) {
  readLines(file.path(raw_dir(SRC), ".sdmx_meta"))
} else c(NA, NA, NA)
sdmx_version <- sdmx_meta[1]
sdmx_label   <- sdmx_meta[2]
sdmx_file_id <- sdmx_meta[3]

update_catalog(
  SRC,
  url = "https://data-explorer.oecd.org/vis?df%5Bds%5D=DisseminateFinalBoost&df%5Bid%5D=DSD_CRS%40DF_CRS&df%5Bag%5D=OECD.DCD.FSD",
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0(sdmx_label, " (SDMX dataflow ", sdmx_version, ", fetched ", fetched_on(SRC), ")"),
  n_rows      = nrow(cleaned),
  n_countries = n_distinct(cleaned$iso3),
  year_range  = c(min(cleaned$year), max(cleaned$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(
    list(name = basename(raw_zip),       sha256 = raw_sha),
    list(name = basename(parquet_local), sha256 = parquet_sha)
  ),
  variables = lapply(c(KEEP_COLS, "iso3"), function(c) list(code = c, name = c)),
  notes = paste0(
    "Education sector group (sector_code in 110/111/112/113/114) filter at ingest; ",
    "5-digit purpose_code retained for Phase-7 typology granularity. ",
    "Schema: legacy CRS dotStat format (commitments + disbursements + grant-equivalent ",
    "are SEPARATE wide columns with paired _defl constant-USD variants). ",
    "Project-level resolution preserved; country-year aggregation in R/30_merge_panel.R. ",
    "Pending PAPs preserved: 0005 (commitment vs disbursement = column choice), ",
    "0007 (intervention typology - project_title + short/long_description + keywords retained), ",
    "0008 (China inclusion - DAC-only here; GCDF the prior step complements). ",
    "Discovered IDFile=", sdmx_file_id, ". ",
    n_regional, " rows (", round(100*n_regional/n_pre, 1), "%) on regional/unspecified aggregates dropped. ",
    "SSA missingness contrast at output/tables/ssa_oecd_crs_missingness.csv."
  )
)

render_catalog()
message("[oecd_crs] ingestion complete.")
