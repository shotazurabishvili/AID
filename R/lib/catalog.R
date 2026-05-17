# R/lib/catalog.R
# Manage data/catalog.yml as the machine source of truth; render data/catalog.md from it.

if (!requireNamespace("yaml", quietly = TRUE)) stop("R/lib/catalog.R requires 'yaml'")

CATALOG_YML <- "data/catalog.yml"
CATALOG_MD  <- "data/catalog.md"

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

read_catalog <- function() {
  if (!file.exists(CATALOG_YML)) return(list())
  yaml::read_yaml(CATALOG_YML)
}

write_catalog <- function(cat) {
  yaml::write_yaml(cat, CATALOG_YML)
  invisible(cat)
}

#' Merge updates into a source's entry. Existing fields are preserved unless overridden.
#'
#' @param src   Source slug (top-level key in catalog.yml).
#' @param ...   Named fields to set/update (access_date, n_rows, version, etc.).
update_catalog <- function(src, ...) {
  cat <- read_catalog()
  updates <- list(...)
  cat[[src]] <- utils::modifyList(cat[[src]] %||% list(), updates)
  cat[[src]]$last_updated <- format(Sys.Date(), "%Y-%m-%d")
  write_catalog(cat)
  invisible(cat[[src]])
}

#' Re-render data/catalog.md from catalog.yml. Idempotent.
render_catalog <- function() {
  cat <- read_catalog()
  if (length(cat) == 0) {
    warning("Catalog is empty; nothing to render")
    return(invisible(NULL))
  }

  trunc <- function(s, n) {
    s <- as.character(s)
    if (is.na(s) || nchar(s) <= n) return(s %||% "—")
    paste0(substr(s, 1, n - 1), "…")
  }

  rows <- vapply(names(cat), function(slug) {
    s <- cat[[slug]]
    vars_chr <- if (is.null(s$variables)) "—" else
      paste(vapply(s$variables, function(v) v$code %||% as.character(v), character(1)), collapse = ", ")
    yr <- s$year_range %||% c("—", "—")
    sprintf(
      "| **%s** | %s | %s | %s | %s | %s | %s | %s | %s |",
      s$name %||% slug,
      trunc(vars_chr, 80),
      s$url %||% "—",
      s$access_date %||% "—",
      s$version %||% "—",
      s$n_rows %||% "—",
      s$n_countries %||% "—",
      paste(yr, collapse = "–"),
      trunc(s$notes %||% "", 80)
    )
  }, character(1))

  header <- c(
    "# Data Catalog",
    "",
    "*Auto-rendered from `data/catalog.yml` by `R/lib/catalog.R::render_catalog()`. Do not edit by hand.*",
    "",
    "| Source | Variables | URL | Access date | Version | Rows | Countries | Years | Notes |",
    "|---|---|---|---|---|---|---|---|---|"
  )

  writeLines(c(header, unname(rows)), CATALOG_MD)
  message(sprintf("[catalog] rendered %d sources to %s", length(cat), CATALOG_MD))
  invisible(CATALOG_MD)
}
