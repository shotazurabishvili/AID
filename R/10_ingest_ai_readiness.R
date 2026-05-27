# R/10_ingest_ai_readiness.R
#
# Source: Oxford Insights Government AI Readiness Index 2025 (GARI).
# Reference: Data Stack; manuscript §3 (supplementary measures);
#                   feeds the HCI–GARI composite supplementary analysis.
# Methodology cite: Oxford Insights (2026). Government AI Readiness Index 2025.
#                   Report version dated 2026-01-29.
#
# The PDF report is publicly accessible despite a registration form on the
# landing page. Country-level data lives in a 195-country table split across
# pages 59-68 (verified at runtime via pdfplumber probe). The table has 8
# columns: Country, Rank, Policy Capacity, AI Infrastructure, Governance,
# Public Sector Adoption, Development & Diffusion, Resilience. NO overall
# composite score is published in the table; we derive an equally-weighted
# pillar mean and clearly label it as derived.
#
# Toolchain note: R-native PDF extraction is blocked (no libpoppler-cpp-dev,
# no pdftotext). We shell out to .venv-tools/bin/python running
# scripts/extract_pdf_table.py (pdfplumber). One-time setup:
#   bash scripts/setup_tools_venv.sh

# === Pinned column list (PHASE 1 LOCK — modify only via PAP) ========================
# Source table columns (8): Country, Rank, Policy Capacity, AI Infrastructure,
# Governance, Public Sector Adoption, Development & Diffusion, Resilience
EXPECTED_HEADER_PATTERN <- c("country", "rank", "policy", "infrastructure",
                             "governance", "public sector", "development", "resilience")
OUTPUT_COLS <- c(
  "iso3", "year",
  "ai_readiness_rank",              # 1 = most ready (lower is better)
  "ai_pillar_policy_capacity",
  "ai_pillar_ai_infrastructure",
  "ai_pillar_governance",
  "ai_pillar_public_sector_adoption",
  "ai_pillar_development_and_diffusion",
  "ai_pillar_resilience",
  "ai_readiness_score_mean"         # DERIVED: equally-weighted mean of 6 pillars
)
# ====================================================================================

SRC <- "ai_readiness"
PDF_URL <- "https://oxfordinsights.com/wp-content/uploads/2026/01/2025-Government-AI-Readiness-Index-Report_01_26.pdf"
EDITION_YEAR <- 2025L

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

# 1. Fetch PDF (cached 365 days) -------------------------------------
raw_pdf <- file.path(raw_dir(SRC), "gari_2025.pdf")

if (raw_is_stale(raw_pdf, max_days = 365)) {
  message(sprintf("[ai_readiness] downloading GARI 2025 PDF (~8 MB) ..."))
  ok <- tryCatch({
    download.file(PDF_URL, raw_pdf, mode = "wb", quiet = FALSE)
    file.info(raw_pdf)$size > 1e6
  }, error = function(e) { message("[ai_readiness] download error: ", conditionMessage(e)); FALSE })
  if (!isTRUE(ok)) {
    stop("[ai_readiness] download failed. Manual fallback: visit ",
         "https://oxfordinsights.com/ai-readiness/government-ai-readiness-index-2025/, ",
         "submit the registration form, save the PDF at ", raw_pdf, ", and re-run.")
  }
  fetched_on(SRC, set = TRUE)
} else {
  message("[ai_readiness] using cached PDF at ", raw_pdf)
}
raw_sha <- hash_raw(raw_pdf)
message(sprintf("[ai_readiness] PDF: %.1f MB, sha256=%s",
                file.info(raw_pdf)$size / 1e6, substr(raw_sha, 1, 12)))

# 2. Extract all tables via the Python helper -----------------------
tables_dir <- file.path(raw_dir(SRC), "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

# Re-extract if output is empty or older than the PDF
existing <- list.files(tables_dir, pattern = "\\.csv$", full.names = TRUE)
pdf_mtime <- file.info(raw_pdf)$mtime
needs_extract <- length(existing) == 0 ||
  min(file.info(existing)$mtime, na.rm = TRUE) < pdf_mtime

if (needs_extract) {
  venv_py <- ".venv-tools/bin/python"
  if (!file.exists(venv_py)) {
    stop("[ai_readiness] tools venv missing. Run: bash scripts/setup_tools_venv.sh")
  }
  message("[ai_readiness] extracting PDF tables via pdfplumber ...")
  rc <- system2(venv_py,
                args = c("scripts/extract_pdf_table.py",
                         shQuote(raw_pdf), shQuote(tables_dir)),
                stdout = "", stderr = "")
  if (rc != 0) {
    stop("[ai_readiness] PDF extraction failed (rc=", rc, ").")
  }
}

table_files <- list.files(tables_dir, pattern = "\\.csv$", full.names = TRUE)
message(sprintf("[ai_readiness] %d table CSVs available", length(table_files)))

# 3. Identify + concatenate the country-ranking tables --------------
# The 195-country score table is split across multiple pages (verified: pages
# 59-68 in the 2026-01-29 release). Each fragment has 8 columns; the header
# row only appears on the first page. We select all 8-column tables, promote
# the header from whichever fragment has it, and concatenate.
inspect <- map_dfr(table_files, function(f) {
  raw <- tryCatch(
    suppressMessages(readr::read_csv(f, col_types = cols(.default = col_character()),
                                      col_names = FALSE, progress = FALSE)),
    error = function(e) NULL
  )
  if (is.null(raw)) return(tibble::tibble(file = basename(f), rows = NA, cols = NA))
  tibble::tibble(file = basename(f), rows = nrow(raw), cols = ncol(raw))
})
print(inspect)

candidate_files <- inspect |>
  filter(cols == 8, rows >= 5) |>
  pull(file)

if (length(candidate_files) == 0) {
  stop("[ai_readiness] no 8-column tables found. Inspect ", tables_dir,
       " manually and pin the right table(s).")
}

message(sprintf("[ai_readiness] %d candidate 8-column tables: %s",
                length(candidate_files), paste(candidate_files, collapse = ", ")))

# Read each and concatenate
fragments <- map_dfr(candidate_files, function(name) {
  suppressMessages(readr::read_csv(file.path(tables_dir, name),
                                   col_types = cols(.default = col_character()),
                                   col_names = FALSE, progress = FALSE)) |>
    mutate(source_file = name)
})

# Identify header row (the one that contains "Country" + "Rank" etc.)
header_idx <- which(
  fragments$X1 == "Country" &
  fragments$X2 == "Rank"
)
if (length(header_idx) < 1) {
  stop("[ai_readiness] could not find header row 'Country|Rank|...'. ",
       "First rows of fragments:\n",
       paste(capture.output(print(head(fragments, 5))), collapse = "\n"))
}
message(sprintf("[ai_readiness] header rows found at indices: %s",
                paste(header_idx, collapse = ", ")))

# Keep only data rows: drop the header row(s); the surviving rows are 195 countries
data_rows <- fragments[-header_idx, ]

# Rename to pinned slugs
gari <- data_rows |>
  transmute(
    country_raw = X1,
    rank_raw    = X2,
    pillar_policy_capacity_raw         = X3,
    pillar_ai_infrastructure_raw       = X4,
    pillar_governance_raw              = X5,
    pillar_public_sector_adoption_raw  = X6,
    pillar_development_and_diffusion_raw = X7,
    pillar_resilience_raw              = X8
  )

message(sprintf("[ai_readiness] raw country rows: %d", nrow(gari)))

# 4. Clean pillar text — pdfplumber sometimes embeds newlines + thousands separators
clean_num <- function(x) {
  x |>
    str_replace_all("[\n\r]", "") |>
    str_replace_all(",", "") |>
    str_trim() |>
    as.numeric()
}

gari <- gari |>
  mutate(
    country = str_replace_all(country_raw, "[\n\r]", " ") |> str_squish(),
    ai_readiness_rank = clean_num(rank_raw) |> as.integer(),
    ai_pillar_policy_capacity         = clean_num(pillar_policy_capacity_raw),
    ai_pillar_ai_infrastructure       = clean_num(pillar_ai_infrastructure_raw),
    ai_pillar_governance              = clean_num(pillar_governance_raw),
    ai_pillar_public_sector_adoption  = clean_num(pillar_public_sector_adoption_raw),
    ai_pillar_development_and_diffusion = clean_num(pillar_development_and_diffusion_raw),
    ai_pillar_resilience              = clean_num(pillar_resilience_raw)
  )

# 5. ISO3 normalization ---------------------------------------------
gari <- gari |>
  mutate(iso3 = normalize_iso3(country, src = SRC, origin = "country.name"))

n_pre <- nrow(gari)
n_unresolved <- sum(is.na(gari$iso3))
message(sprintf("[ai_readiness] ISO3 normalization: %d unresolved out of %d rows",
                n_unresolved, n_pre))

# 6. Derive composite + finalize ------------------------------------
cleaned <- gari |>
  filter(!is.na(iso3)) |>
  mutate(
    year = EDITION_YEAR,
    ai_readiness_score_mean = rowMeans(
      cbind(ai_pillar_policy_capacity, ai_pillar_ai_infrastructure,
            ai_pillar_governance, ai_pillar_public_sector_adoption,
            ai_pillar_development_and_diffusion, ai_pillar_resilience),
      na.rm = TRUE
    )
  ) |>
  select(all_of(OUTPUT_COLS)) |>
  arrange(ai_readiness_rank)

message(sprintf("[ai_readiness] cleaned: %d countries × %d cols (year=%d, cross-sectional)",
                nrow(cleaned), ncol(cleaned), EDITION_YEAR))
message(sprintf("[ai_readiness] derived composite (mean of 6 pillars) range: %.2f - %.2f",
                min(cleaned$ai_readiness_score_mean, na.rm = TRUE),
                max(cleaned$ai_readiness_score_mean, na.rm = TRUE)))

# 7. Audit + write interim ------------------------------------------
cov <- coverage_summary(cleaned, SRC)
print(cov)
coverage_heatmap(cleaned, SRC)

write_interim(cleaned, SRC)

# Phase-9 preview: HCI × GARI correlation
hci_path <- "data/interim/hci.parquet"
if (file.exists(hci_path)) {
  hci <- arrow::read_parquet(hci_path)
  hci_latest <- hci |>
    group_by(iso3) |>
    slice_max(year, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(iso3, hci_overall)
  joined <- inner_join(cleaned, hci_latest, by = "iso3")
  cor_val <- cor(joined$ai_readiness_score_mean, joined$hci_overall,
                 use = "complete.obs")
  message(sprintf("[ai_readiness] PHASE-9 PREVIEW: %d countries joined with HCI; cor(GARI mean, HCI overall) = %.3f",
                  nrow(joined), cor_val))
}

# 8. Update catalog -------------------------------------------------
overall_missing_pct <- round(
  100 * mean(is.na(as.matrix(cleaned[, setdiff(OUTPUT_COLS, c("iso3", "year"))]))), 2
)

update_catalog(
  SRC,
  url         = "https://oxfordinsights.com/ai-readiness/government-ai-readiness-index-2025/",
  access_date = format(Sys.Date(), "%Y-%m-%d"),
  version     = paste0("GARI 2025 (Oxford Insights, report v01_26 dated 2026-01-29); fetched ", fetched_on(SRC)),
  n_rows      = nrow(cleaned),
  n_countries = dplyr::n_distinct(cleaned$iso3),
  year_range  = c(EDITION_YEAR, EDITION_YEAR),
  missing_pct = overall_missing_pct,
  raw_files   = list(list(name = basename(raw_pdf), sha256 = raw_sha)),
  variables   = lapply(OUTPUT_COLS, function(c) list(code = c, name = c)),
  notes = paste0(
    "Cross-sectional source (single edition); year=2025 reflects edition stamp, ",
    "not a measurement year per se. Extracted from PDF (pages 59-68) via ",
    ".venv-tools/bin/python scripts/extract_pdf_table.py (pdfplumber). ",
    "Source table has 8 columns: Country, Rank, and 6 pillar scores (Policy Capacity, ",
    "AI Infrastructure, Governance, Public Sector Adoption, Development & Diffusion, ",
    "Resilience). No overall composite published in source; ",
    "ai_readiness_score_mean is OUR DERIVED equally-weighted mean of the 6 pillars ",
    "(Oxford's official weighting may differ; transparent and reproducible). ",
    "Feeds the HCI × GARI composite analysis."
  )
)

render_catalog()
message("[ai_readiness] ingestion complete.")
