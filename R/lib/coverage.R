# R/lib/coverage.R
# Coverage summaries, heatmaps, and missingness diagnostics for ingestion audits.
#
# Assumes tidyverse + ggplot2 are loaded by the caller.

#' Per-variable coverage stats for a tidy long-or-wide ingestion frame.
#'
#' @param df        Data frame with key_cols + one or more value columns.
#' @param src       Source slug (added as a column on the result).
#' @param key_cols  Columns that identify the row (default c("iso3", "year")).
#'
#' @return tibble with one row per (source, indicator) and coverage stats.
coverage_summary <- function(df, src, key_cols = c("iso3", "year")) {
  value_cols <- setdiff(names(df), key_cols)
  if (length(value_cols) == 0) {
    return(tibble::tibble(source = src, indicator = character(),
                          n_obs = integer(), missing_pct = numeric(),
                          n_countries_with_data = integer(),
                          year_min = integer(), year_max = integer()))
  }

  purrr::map_dfr(value_cols, function(v) {
    x <- df[[v]]
    present_idx <- !is.na(x)
    yrs <- if ("year" %in% key_cols) df$year[present_idx] else integer()
    tibble::tibble(
      source = src,
      indicator = v,
      n_obs = sum(present_idx),
      n_missing = sum(!present_idx),
      missing_pct = round(100 * mean(!present_idx), 2),
      n_countries_with_data = if ("iso3" %in% key_cols) dplyr::n_distinct(df$iso3[present_idx]) else NA_integer_,
      year_min = if (length(yrs) > 0) suppressWarnings(min(yrs, na.rm = TRUE)) else NA_integer_,
      year_max = if (length(yrs) > 0) suppressWarnings(max(yrs, na.rm = TRUE)) else NA_integer_
    )
  })
}

#' Country-by-year heatmap of which indicators are present, faceted by indicator.
#' Saves PDF + PNG to output/figures/coverage/<src>.{pdf,png}.
coverage_heatmap <- function(df, src,
                             key_cols = c("iso3", "year"),
                             out_dir = "output/figures/coverage") {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  value_cols <- setdiff(names(df), key_cols)

  long <- df |>
    tidyr::pivot_longer(dplyr::all_of(value_cols),
                        names_to = "indicator", values_to = "value") |>
    dplyr::mutate(present = !is.na(value)) |>
    dplyr::select(-value)

  n_iso <- dplyr::n_distinct(long$iso3)

  p <- ggplot2::ggplot(long, ggplot2::aes(x = year, y = iso3, fill = present)) +
    ggplot2::geom_tile() +
    ggplot2::facet_wrap(~ indicator, ncol = 4) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#1f78b4", `FALSE` = "#f0f0f0"),
                               labels = c(`TRUE` = "present", `FALSE` = "missing")) +
    ggplot2::labs(title = paste0("Coverage: ", src),
                  x = "Year", y = NULL, fill = NULL) +
    ggplot2::theme_minimal(base_size = 8) +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = 4),
                   legend.position = "bottom",
                   panel.grid = ggplot2::element_blank())

  h <- max(8, n_iso * 0.06)
  ggplot2::ggsave(file.path(out_dir, paste0(src, ".pdf")), p,
                  width = 14, height = h, limitsize = FALSE)
  ggplot2::ggsave(file.path(out_dir, paste0(src, ".png")), p,
                  width = 14, height = h, dpi = 120, limitsize = FALSE)

  invisible(p)
}

#' Compare missingness rate in SSA vs non-SSA across variables.
#' Returns a tibble with per-indicator missing % for both groups + gap.
ssa_missingness_pattern <- function(df, ssa_iso3, key_cols = c("iso3", "year")) {
  value_cols <- setdiff(names(df), key_cols)
  ssa     <- dplyr::filter(df, iso3 %in% ssa_iso3)
  non_ssa <- dplyr::filter(df, !iso3 %in% ssa_iso3)

  purrr::map_dfr(value_cols, function(v) {
    tibble::tibble(
      indicator = v,
      ssa_missing_pct = round(100 * mean(is.na(ssa[[v]])), 2),
      non_ssa_missing_pct = round(100 * mean(is.na(non_ssa[[v]])), 2),
      gap_pct = round(100 * (mean(is.na(ssa[[v]])) - mean(is.na(non_ssa[[v]]))), 2),
      n_ssa = nrow(ssa),
      n_non_ssa = nrow(non_ssa)
    )
  })
}
