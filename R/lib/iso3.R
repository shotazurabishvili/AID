# R/lib/iso3.R
# ISO3 country-code normalization with project-specific overrides.
#
# Pure helper — sourced by ingestion scripts. Assumes tidyverse is already loaded
# by the caller (we only need countrycode + base R here).

if (!requireNamespace("countrycode", quietly = TRUE)) {
  stop("R/lib/iso3.R requires the 'countrycode' package")
}

# Overrides for sources where countrycode() returns NA, wrong code, or where the
# upstream label format varies. Lookup is by exact string match (case-sensitive).
ISO3_OVERRIDES <- c(
  # Kosovo
  "Kosovo" = "XKX", "KOSOVO" = "XKX", "XKX" = "XKX", "XK" = "XKX",
  # Taiwan
  "Taiwan" = "TWN", "Taiwan, China" = "TWN", "Taiwan, Province of China" = "TWN",
  "Chinese Taipei" = "TWN", "TWN" = "TWN",
  # Palestine / West Bank & Gaza
  "West Bank and Gaza" = "PSE", "Palestinian Territories" = "PSE",
  "Palestine, State of" = "PSE", "WBG" = "PSE", "PS" = "PSE", "PSE" = "PSE",
  # South Sudan (created 2011)
  "South Sudan" = "SSD", "SSD" = "SSD",
  # North Macedonia (renamed 2019)
  "North Macedonia" = "MKD", "Macedonia, FYR" = "MKD",
  "Macedonia, the former Yugoslav Republic of" = "MKD",
  # Eswatini (renamed 2018)
  "Eswatini" = "SWZ", "Swaziland" = "SWZ",
  # Czechia
  "Czechia" = "CZE", "Czech Republic" = "CZE",
  # Côte d'Ivoire (encoding variants)
  "Côte d'Ivoire" = "CIV", "Cote d'Ivoire" = "CIV", "Ivory Coast" = "CIV",
  # Common non-country aggregates → NA so they get filtered downstream
  "World" = NA_character_, "WLD" = NA_character_,
  "European Union" = NA_character_, "EUU" = NA_character_, "EU" = NA_character_,
  "OECD members" = NA_character_, "OED" = NA_character_,
  "Arab World" = NA_character_, "ARB" = NA_character_
)

#' Normalize a vector of country names/codes to ISO3.
#'
#' @param x         Character vector of country labels (names, ISO2, ISO3, WB codes, etc.)
#' @param src       Source slug used to name the unresolved-log CSV.
#' @param origin    Optional countrycode origin ("iso3c", "country.name", "iso2c", "wb").
#'                  If NULL, tries iso3c → country.name → wb in turn.
#'
#' @return Character vector of ISO3 codes (NA where unresolvable).
normalize_iso3 <- function(x, src = "unknown", origin = NULL) {
  x_chr <- as.character(x)
  result <- rep(NA_character_, length(x_chr))

  # Step 1: apply explicit overrides
  in_overrides <- x_chr %in% names(ISO3_OVERRIDES)
  result[in_overrides] <- ISO3_OVERRIDES[x_chr[in_overrides]]

  # Step 2: countrycode for the rest
  to_resolve <- !in_overrides & !is.na(x_chr) & nzchar(x_chr)
  if (any(to_resolve)) {
    vals <- x_chr[to_resolve]
    if (!is.null(origin)) {
      attempt <- suppressWarnings(
        countrycode::countrycode(vals, origin, "iso3c", warn = FALSE)
      )
    } else {
      # Cascade: try iso3c, country.name, then wb. First non-NA wins per element.
      a1 <- suppressWarnings(countrycode::countrycode(vals, "iso3c",        "iso3c", warn = FALSE))
      a2 <- suppressWarnings(countrycode::countrycode(vals, "country.name", "iso3c", warn = FALSE))
      a3 <- suppressWarnings(countrycode::countrycode(vals, "wb",           "iso3c", warn = FALSE))
      attempt <- ifelse(!is.na(a1), a1, ifelse(!is.na(a2), a2, a3))
    }
    result[to_resolve] <- attempt
  }

  # Step 3: log unresolved (only true country-like labels, not blanks)
  unresolved_mask <- is.na(result) & !is.na(x_chr) & nzchar(x_chr) & !in_overrides
  if (any(unresolved_mask)) {
    log_path <- file.path("output", "logs", paste0("iso3_unresolved_", src, ".csv"))
    dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(
      data.frame(source = src, original = unique(x_chr[unresolved_mask])),
      log_path, row.names = FALSE
    )
    message(sprintf("[iso3:%s] %d unresolved labels logged to %s",
                    src, length(unique(x_chr[unresolved_mask])), log_path))
  }

  result
}
