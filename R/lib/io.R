# R/lib/io.R
# Path conventions, parquet I/O, and raw-file hashing for ingestion scripts.

if (!requireNamespace("arrow", quietly = TRUE))  stop("R/lib/io.R requires 'arrow'")
if (!requireNamespace("digest", quietly = TRUE)) stop("R/lib/io.R requires 'digest'")

#' Path to a source's raw directory; creates it on demand.
raw_dir <- function(src) {
  d <- file.path("data", "raw", src)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

#' Path to a source's interim parquet.
interim_path <- function(src) {
  d <- file.path("data", "interim")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  file.path(d, paste0(src, ".parquet"))
}

#' Write an interim parquet for a source.
write_interim <- function(df, src) {
  p <- interim_path(src)
  arrow::write_parquet(df, p)
  message(sprintf("[io] wrote %s (%d rows, %d cols)", p, nrow(df), ncol(df)))
  invisible(p)
}

#' SHA-256 of a file on disk.
hash_raw <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

#' Is the raw file missing or older than max_days?
raw_is_stale <- function(path, max_days = 30) {
  if (!file.exists(path)) return(TRUE)
  age_days <- as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "days"))
  age_days > max_days
}

#' Read or write the fetched-on date marker for a raw source directory.
fetched_on <- function(src, set = FALSE) {
  meta <- file.path(raw_dir(src), ".fetched_on")
  if (set) {
    writeLines(format(Sys.Date(), "%Y-%m-%d"), meta)
    invisible(meta)
  } else {
    if (file.exists(meta)) readLines(meta)[1] else NA_character_
  }
}
