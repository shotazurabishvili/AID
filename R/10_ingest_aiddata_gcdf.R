# R/10_ingest_aiddata_gcdf.R
#
# Source: AidData GCDF v3.0 — Chinese development finance (TUFF methodology).
# Brief reference: Data Stack; methodology.md §3.11.
# Methodology cite: Custer, Strange, Dreher, Tierney et al. (AidData TUFF 3.0).
#
# Bulk file: 28 MB zip from AidData's CloudFront. Contains:
#   - AidDatasGlobalChineseDevelopmentFinanceDataset_v3.0.xlsx (main workbook; sheet GCDF_3.0)
#   - Field Definitions_GCDF 3.0.pdf (codebook)
#   - TUFF Methodology 3.0.pdf
#   - ADM Location Data/ (sub-national geo CSVs — not used here)
#
# Standard Deflate zip (no Deflate64). Base unzip() works.
#
# Pending ADRs this ingest preserves (no locks):
#   - ADR-0008 (China inclusion): Phase 5 lock. Working preference Option 2 —
#     OECD CRS only as primary; GCDF as headline robustness.
#
# === Pinned column list (PHASE 1 LOCK — modify only via ADR) ========================
# Column names verified against the actual GCDF_3.0 sheet (20,985 rows total).
# Sector Name values are UPPERCASE strings (e.g., "EDUCATION", "HEALTH").
# Recommended For Aggregates filter applies "Yes" rows only (avoids umbrella double-count).
KEEP_COLS <- c(
  # Identity
  "AidData Record ID",
  # Aggregation discipline (codebook-mandated filter)
  "Recommended For Aggregates",
  # Recipient
  "Recipient", "Recipient ISO-3", "Recipient Region",
  # Years (Commitment Year is the analytical match for OECD CRS commitments)
  "Commitment Year", "Implementation Start Year", "Completion Year",
  # Status / sector
  "Status", "Intent",
  "Sector Code", "Sector Name",
  "Infrastructure", "COVID",
  # Flow / financial classification
  "Flow Type", "Flow Type Simplified", "Flow Class",
  "OECD ODA Concessionality Threshold",
  # Funding / receiving agencies
  "Funding Agencies", "Funding Agencies Type",
  "Direct Receiving Agencies", "Direct Receiving Agencies Type",
  # Value (multiple measures — keep all; Constant USD 2021 is the primary)
  "Amount (Constant USD 2021)", "Amount (Original Currency)", "Amount (Nominal USD)",
  "Original Currency",
  # Project text (Phase-7 typology overlap with OECD CRS)
  "Title", "Description"
)
# ====================================================================================

SRC <- "aiddata_gcdf"
BULK_URL <- "https://docs.aiddata.org/ad4/datasets/AidDatas_Global_Chinese_Development_Finance_Dataset_Version_3_0.zip"
MAIN_SHEET <- "GCDF_3.0"
YEAR_RANGE <- 1995:2024
EDU_SECTOR_NAME <- "EDUCATION"   # exact uppercase match

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(readxl)
  library(countrycode)
})

source("R/lib/iso3.R")
source("R/lib/io.R")
source("R/lib/catalog.R")
source("R/lib/coverage.R")

options(timeout = max(600, getOption("timeout")))

# 1. Fetch bulk zip (cached 90 days) ---------------------------------
raw_zip <- file.path(raw_dir(SRC), "gcdf_bulk.zip")

if (raw_is_stale(raw_zip, max_days = 90)) {
  message("[aiddata_gcdf] downloading ~28 MB zip from AidData CloudFront...")
  ok <- tryCatch({
    download.file(BULK_URL, raw_zip, mode = "wb", quiet = FALSE)
    file.info(raw_zip)$size > 1e6
  }, error = function(e) { message("[aiddata_gcdf] download error: ", conditionMessage(e)); FALSE })
  if (!isTRUE(ok)) {
    stop("[aiddata_gcdf] download failed. Manual fallback: visit ",
         "https://www.aiddata.org/data/aiddatas-global-chinese-development-finance-dataset-version-3-0 ",
         "→ download zip → place at ", raw_zip, " and re-run.")
  }
  fetched_on(SRC, set = TRUE)
} else {
  message("[aiddata_gcdf] using cached zip at ", raw_zip)
}
raw_sha <- hash_raw(raw_zip)
message(sprintf("[aiddata_gcdf] raw zip: %.1f MB, sha256=%s",
                file.info(raw_zip)$size / 1e6, substr(raw_sha, 1, 12)))

# 2. Unzip + locate main xlsx ----------------------------------------
zip_entries <- tryCatch(unzip(raw_zip, list = TRUE),
                        error = function(e) stop("[aiddata_gcdf] zip listing failed: ", conditionMessage(e)))
if (nrow(zip_entries) == 0) stop("[aiddata_gcdf] zip is empty")

xlsx_in_zip <- zip_entries$Name[
  grepl("AidDatasGlobalChinese.*\\.xlsx$", zip_entries$Name, ignore.case = TRUE) &
  !grepl("__MACOSX|\\._", zip_entries$Name)
]
if (length(xlsx_in_zip) != 1) {
  stop("[aiddata_gcdf] expected exactly 1 main xlsx; got ", length(xlsx_in_zip),
       ". Entries: ", paste(xlsx_in_zip, collapse = " | "))
}

xlsx_local <- file.path(raw_dir(SRC), xlsx_in_zip)
if (!file.exists(xlsx_local) ||
    file.info(xlsx_local)$mtime < file.info(raw_zip)$mtime) {
  message("[aiddata_gcdf] extracting main xlsx...")
  unzip(raw_zip, files = xlsx_in_zip, exdir = raw_dir(SRC), overwrite = TRUE)
}
xlsx_sha <- hash_raw(xlsx_local)
message(sprintf("[aiddata_gcdf] extracted xlsx: %.1f MB, sha256=%s",
                file.info(xlsx_local)$size / 1e6, substr(xlsx_sha, 1, 12)))

# 3. Schema introspection + filter -----------------------------------
sheets <- readxl::excel_sheets(xlsx_local)
message(sprintf("[aiddata_gcdf] sheets: %s", paste(sheets, collapse = " | ")))
if (!MAIN_SHEET %in% sheets) {
  stop("[aiddata_gcdf] expected sheet '", MAIN_SHEET, "' not found. Sheets: ",
       paste(sheets, collapse = " | "))
}

message(sprintf("[aiddata_gcdf] reading sheet '%s' (full read; ~21k rows × 126 cols)...", MAIN_SHEET))
raw <- readxl::read_excel(xlsx_local, sheet = MAIN_SHEET, guess_max = 50000)
message(sprintf("[aiddata_gcdf] raw sheet: %d rows × %d cols", nrow(raw), ncol(raw)))

missing_cols <- setdiff(KEEP_COLS, names(raw))
if (length(missing_cols) > 0) {
  stop("[aiddata_gcdf] pinned columns missing from GCDF schema: ",
       paste(missing_cols, collapse = ", "),
       "\nAvailable columns: ", paste(names(raw), collapse = " | "),
       "\nUpdate KEEP_COLS via an ADR if upstream schema changed.")
}

# Diagnostic: unique sector values
sector_vals <- sort(unique(raw[["Sector Name"]]))
message(sprintf("[aiddata_gcdf] unique sector values (%d): %s",
                length(sector_vals), paste(head(sector_vals, 30), collapse = " | ")))

# Apply filters: Recommended For Aggregates = Yes, Sector Name = EDUCATION, Commitment Year in range
filtered <- raw |>
  filter(
    toupper(`Recommended For Aggregates`) == "YES",
    toupper(`Sector Name`) == EDU_SECTOR_NAME,
    !is.na(`Commitment Year`),
    `Commitment Year` %in% YEAR_RANGE
  ) |>
  select(all_of(KEEP_COLS))

message(sprintf("[aiddata_gcdf] post-filter: %d rows (Education sector, Commitment Year %d-%d, Recommended)",
                nrow(filtered),
                suppressWarnings(min(filtered$`Commitment Year`)),
                suppressWarnings(max(filtered$`Commitment Year`))))

# 4. Recipient ISO3 --------------------------------------------------
# GCDF provides Recipient ISO-3 directly. Round-trip validate via countrycode;
# fall back to country-name normalization for any unresolved.
filtered <- filtered |>
  mutate(iso3 = countrycode::countrycode(`Recipient ISO-3`, origin = "iso3c",
                                          destination = "iso3c", warn = FALSE))

needs_fallback <- is.na(filtered$iso3) & !is.na(filtered$Recipient)
if (any(needs_fallback)) {
  message(sprintf("[aiddata_gcdf] %d rows need name-based ISO3 fallback", sum(needs_fallback)))
  filtered$iso3[needs_fallback] <- normalize_iso3(
    filtered$Recipient[needs_fallback], src = SRC, origin = "country.name")
}

n_pre <- nrow(filtered)
cleaned <- filtered |>
  filter(!is.na(iso3)) |>
  mutate(
    year = as.integer(`Commitment Year`),
    `Implementation Start Year` = suppressWarnings(as.integer(`Implementation Start Year`)),
    `Completion Year` = suppressWarnings(as.integer(`Completion Year`))
  ) |>
  arrange(iso3, year, `AidData Record ID`)

n_regional <- n_pre - nrow(cleaned)
message(sprintf("[aiddata_gcdf] %d rows on regional/unresolved aggregates dropped (%.1f%%)",
                n_regional, 100 * n_regional / max(n_pre, 1)))

message(sprintf("[aiddata_gcdf] cleaned: %d rows, %d countries, years %d-%d",
                nrow(cleaned),
                n_distinct(cleaned$iso3),
                min(cleaned$year), max(cleaned$year)))

# 5. Coverage audit + SSA *coverage* contrast (NOT missingness) ------
# Build per-(iso3, year) presence indicator: did China commit ANY education
# project in this country-year with a positive constant-USD amount?
avail_num <- cleaned |>
  group_by(iso3, year) |>
  summarise(
    has_china_edu_project = if (any(!is.na(`Amount (Constant USD 2021)`) &
                                    `Amount (Constant USD 2021)` > 0)) 1 else NA_real_,
    .groups = "drop"
  ) |>
  arrange(iso3, year)

cov <- coverage_summary(avail_num, SRC)
print(cov)
coverage_heatmap(avail_num, SRC)

# SSA universe — same construction as Sessions 03 / 05
ssa_iso3 <- countrycode::codelist |>
  filter(region == "Sub-Saharan Africa") |>
  pull(iso3c) |>
  na.omit() |>
  unique()
message("[aiddata_gcdf] SSA universe: ", length(ssa_iso3), " ISO3 codes")

# Reuse the missingness helper but transform to coverage_pct = 100 - missing_pct.
# Methodological note: in GCDF "absence" doesn't mean "data missing", it means
# "China didn't fund anything there". So the right framing is COVERAGE (presence),
# not missingness (data absence).
ssa_pat <- ssa_missingness_pattern(avail_num, ssa_iso3) |>
  transmute(
    indicator,
    ssa_coverage_pct     = round(100 - ssa_missing_pct, 2),
    non_ssa_coverage_pct = round(100 - non_ssa_missing_pct, 2),
    gap_pp               = round(ssa_coverage_pct - non_ssa_coverage_pct, 2),
    n_ssa, n_non_ssa
  )
print(ssa_pat)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(ssa_pat, "output/tables/ssa_aiddata_gcdf_coverage.csv")

ssa_long <- ssa_pat |>
  pivot_longer(c(ssa_coverage_pct, non_ssa_coverage_pct),
               names_to = "region", values_to = "coverage_pct") |>
  mutate(region = recode(region,
                         ssa_coverage_pct     = "Sub-Saharan Africa",
                         non_ssa_coverage_pct = "Rest of world"))

p_ssa <- ggplot(ssa_long, aes(x = reorder(indicator, coverage_pct),
                              y = coverage_pct, fill = region)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("Sub-Saharan Africa" = "#d95f02",
                               "Rest of world"      = "#7570b3")) +
  labs(title = "China's geographic reach in education aid (GCDF v3.0)",
       subtitle = "Phase 1 Session 06 - feeds ADR-0008",
       x = NULL, y = "Coverage %  (share of country-year cells with >=1 Chinese education project)",
       fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("output/figures/coverage/ssa_aiddata_gcdf_coverage.pdf", p_ssa, width = 9, height = 4)
ggsave("output/figures/coverage/ssa_aiddata_gcdf_coverage.png", p_ssa, width = 9, height = 4, dpi = 150)

# Headline metric for session log + possible ADR-0008 Data Observed
ssa_d <- cleaned |> filter(iso3 %in% ssa_iso3)
total_usd_ssa <- sum(ssa_d$`Amount (Constant USD 2021)`, na.rm = TRUE)
message(sprintf("[aiddata_gcdf] HEADLINE: SSA Chinese education projects: %d across %d countries; total constant-USD: $%.2f B",
                nrow(ssa_d), n_distinct(ssa_d$iso3), total_usd_ssa / 1e9))

# 6. Write interim ---------------------------------------------------
write_interim(cleaned, SRC)

# 7. Update catalog --------------------------------------------------
n_year_cells <- length(unique(cleaned$iso3)) * length(unique(cleaned$year))
n_observed_cells <- nrow(distinct(cleaned, iso3, year))
overall_missing_pct <- round(100 * (1 - n_observed_cells / n_year_cells), 2)

update_catalog(
  SRC,
  url = "https://www.aiddata.org/data/aiddatas-global-chinese-development-finance-dataset-version-3-0",
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("GCDF v3.0 (xlsx release 2024-06-17; fetched ", fetched_on(SRC), ")"),
  n_rows      = nrow(cleaned),
  n_countries = n_distinct(cleaned$iso3),
  year_range  = c(min(cleaned$year), max(cleaned$year)),
  missing_pct = overall_missing_pct,
  raw_files   = list(
    list(name = basename(raw_zip),   sha256 = raw_sha),
    list(name = basename(xlsx_local), sha256 = xlsx_sha)
  ),
  variables = lapply(c(KEEP_COLS, "iso3"), function(c) list(code = c, name = c)),
  notes = paste0(
    "Chinese development finance only (TUFF methodology). Filtered to ",
    "Sector Name = EDUCATION + Recommended For Aggregates = Yes ",
    "(per AidData codebook; avoids umbrella double-counting). ",
    "Year filter on Commitment Year in ", min(YEAR_RANGE), "-", max(YEAR_RANGE), ". ",
    "Project-level resolution preserved; country-year aggregation at Phase 2. ",
    sprintf("SSA headline: %d projects across %d countries; $%.2f B constant-USD. ",
            nrow(ssa_d), n_distinct(ssa_d$iso3), total_usd_ssa / 1e9),
    "SSA-coverage contrast at output/tables/ssa_aiddata_gcdf_coverage.csv (coverage, NOT missingness). ",
    "Feeds ADR-0008 (Phase 5 lock). AidData Core v3.1 deferred per Session-06 author decision."
  )
)

render_catalog()
message("[aiddata_gcdf] ingestion complete.")
