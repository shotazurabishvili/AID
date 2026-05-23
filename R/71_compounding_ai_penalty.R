# R/71_compounding_ai_penalty.R
#
# Phase 9 Session 01: Compounding AI penalty section (brief §1 line 159).
#
# Constructed variable per brief: HCI × AI Readiness Index.
# Joint distribution characterization on the 189-country GARI × HCI intersection:
#   - Composite: compound_index = HCI × (GARI_score / 100)  [both axes on 0-1]
#   - 2x2 sample-median split → "double-excluded" cell = low_hci ∩ low_gari
#   - SSA over-representation cross-tab
#   - Robustness: tercile split + HCI-2018-only sample
#
# This is a DESCRIPTIVE joint-distribution characterization, NOT a "compounding
# effect" estimate. With r=0.777 the dimensions are 60% redundant; the residual
# 22% is where the interaction claim has empirical bite but we have no clean
# outcome to test multiplicative-vs-additive (HLO/LAYS are inside HCI; GDP
# growth needs its own identification). The interaction test belongs in §6
# Discussion, not §5.
#
# HCI cycle choice: latest non-missing per country (mix of 2018 + 2020).
# Maximizes coverage; per-country cycle year reported in bottom-N table.
#
# Inputs:
#   data/interim/panel.parquet           — production panel (Phase 2)
#   data/interim/ai_readiness.parquet    — Oxford Insights GARI 2025
#
# Outputs (10 files total):
#   output/tables/compound_ai_penalty_quadrant.{csv,md}
#   output/tables/compound_ai_penalty_bottom20.{csv,md}
#   output/tables/compound_ai_penalty_ssa_crosstab.{csv,md}
#   output/tables/compound_ai_penalty_robustness.{csv,md}
#   output/figures/compound_ai_penalty_scatter.{pdf,png}

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(ggplot2)
})

PANEL_PATH     <- "data/interim/panel.parquet"
GARI_PATH      <- "data/interim/ai_readiness.parquet"

OUT_QUAD_CSV   <- "output/tables/compound_ai_penalty_quadrant.csv"
OUT_QUAD_MD    <- "output/tables/compound_ai_penalty_quadrant.md"
OUT_BOT_CSV    <- "output/tables/compound_ai_penalty_bottom20.csv"
OUT_BOT_MD     <- "output/tables/compound_ai_penalty_bottom20.md"
OUT_SSA_CSV    <- "output/tables/compound_ai_penalty_ssa_crosstab.csv"
OUT_SSA_MD     <- "output/tables/compound_ai_penalty_ssa_crosstab.md"
OUT_ROB_CSV    <- "output/tables/compound_ai_penalty_robustness.csv"
OUT_ROB_MD     <- "output/tables/compound_ai_penalty_robustness.md"
OUT_PLOT_PDF   <- "output/figures/compound_ai_penalty_scatter.pdf"
OUT_PLOT_PNG   <- "output/figures/compound_ai_penalty_scatter.png"

# === 1. Load HCI: latest non-missing cycle per country ========================
message("[m9] loading panel, taking latest HCI cycle per country")
panel <- arrow::read_parquet(PANEL_PATH)

hci_by_country <- panel |>
  filter(!is.na(hci_hci_overall)) |>
  group_by(iso3) |>
  slice_max(year, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(iso3, hci_year = year, hci_overall = hci_hci_overall)

cat(sprintf("[m9] HCI latest-cycle sample: %d countries\n", nrow(hci_by_country)))
cat("[m9] HCI cycle-year breakdown:\n")
print(table(hci_by_country$hci_year))

# === 2. Load GARI ============================================================
message("\n[m9] loading GARI 2025")
gari <- arrow::read_parquet(GARI_PATH) |>
  select(iso3,
         gari_mean = ai_readiness_score_mean,
         starts_with("ai_pillar_"),
         ai_readiness_rank)
cat(sprintf("[m9] GARI sample: %d countries\n", nrow(gari)))

# === 3. Join + composite ======================================================
message("\n[m9] joining + computing composite")
d <- inner_join(hci_by_country, gari, by = "iso3") |>
  mutate(gari_norm      = gari_mean / 100,
         compound_index = hci_overall * gari_norm)

n_joined <- nrow(d)
cat(sprintf("[m9] Joined sample: %d countries\n", n_joined))

# === 4. Region + SSA flag =====================================================
if (requireNamespace("countrycode", quietly = TRUE)) {
  d$region <- countrycode::countrycode(d$iso3, "iso3c", "region", warn = FALSE)
  d$is_ssa <- d$region == "Sub-Saharan Africa" & !is.na(d$region)
  cat(sprintf("[m9] region derived via countrycode; %d SSA, %d non-SSA, %d unresolved-region\n",
              sum(d$is_ssa, na.rm = TRUE),
              sum(!d$is_ssa & !is.na(d$region)),
              sum(is.na(d$region))))
} else {
  # Hand-maintained SSA iso3 fallback (UN M.49 SSA group, 48 countries)
  ssa_iso3 <- c("AGO","BEN","BWA","BFA","BDI","CMR","CPV","CAF","TCD","COM","COG",
                "COD","CIV","DJI","GNQ","ERI","SWZ","ETH","GAB","GMB","GHA","GIN",
                "GNB","KEN","LSO","LBR","MDG","MWI","MLI","MRT","MUS","MOZ","NAM",
                "NER","NGA","RWA","STP","SEN","SYC","SLE","SOM","ZAF","SSD","SDN",
                "TZA","TGO","UGA","ZMB","ZWE")
  d$region <- ifelse(d$iso3 %in% ssa_iso3, "Sub-Saharan Africa", "Other")
  d$is_ssa <- d$iso3 %in% ssa_iso3
  message("[m9] countrycode unavailable; using hand-maintained SSA iso3 fallback")
}

# === 5. Quadrant assignment (median split, default) ===========================
hci_med  <- median(d$hci_overall, na.rm = TRUE)
gari_med <- median(d$gari_norm, na.rm = TRUE)

d <- d |>
  mutate(
    hci_band  = if_else(hci_overall >= hci_med,  "high_hci",  "low_hci"),
    gari_band = if_else(gari_norm   >= gari_med, "high_gari", "low_gari"),
    quadrant  = paste(hci_band, gari_band, sep = "_"),
    is_double_excluded = (hci_band == "low_hci" & gari_band == "low_gari")
  )

cat(sprintf("\n[m9] sample medians: HCI=%.4f, GARI_norm=%.4f\n", hci_med, gari_med))
cat("[m9] quadrant counts:\n")
print(table(d$quadrant))

# === 6. Table 1: quadrant counts + country lists =============================
quadrant_tbl <- d |>
  group_by(quadrant) |>
  summarise(
    n_countries = dplyr::n(),
    mean_hci    = round(mean(hci_overall),  4),
    mean_gari   = round(mean(gari_norm),    4),
    mean_compound = round(mean(compound_index), 4),
    n_ssa       = sum(is_ssa),
    iso3_list   = paste(sort(iso3), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(desc(mean_compound))

readr::write_csv(quadrant_tbl, OUT_QUAD_CSV)
writeLines(c(
  "# Compounding AI penalty — quadrant counts (sample-median split)",
  "",
  sprintf("**Joined sample N = %d** (intersection of GARI 2025 195 countries × panel HCI-non-missing iso3 set).", n_joined),
  sprintf("**Sample medians:** HCI = %.4f; GARI_norm (GARI/100) = %.4f.", hci_med, gari_med),
  sprintf("**HCI cycle distribution:** %s (latest non-missing per country).",
          paste(sprintf("%d: %d", as.integer(names(table(hci_by_country$hci_year))),
                        as.integer(table(hci_by_country$hci_year))), collapse = "; ")),
  "",
  knitr::kable(quadrant_tbl |> select(-iso3_list), format = "pipe"),
  "",
  "## Country lists per quadrant",
  ""
), OUT_QUAD_MD)
# Append country lists
con <- file(OUT_QUAD_MD, "a")
for (i in seq_len(nrow(quadrant_tbl))) {
  writeLines(c(
    sprintf("### %s (N = %d, %d SSA)",
            quadrant_tbl$quadrant[i], quadrant_tbl$n_countries[i], quadrant_tbl$n_ssa[i]),
    "",
    sprintf("`%s`", quadrant_tbl$iso3_list[i]),
    ""
  ), con)
}
close(con)
message(sprintf("[m9] wrote %s and %s", OUT_QUAD_CSV, OUT_QUAD_MD))

# === 7. Table 2: bottom-20 by compound_index ==================================
bottom20 <- d |>
  arrange(compound_index) |>
  slice_head(n = 20) |>
  transmute(rank_bottom = row_number(),
            iso3,
            region,
            is_ssa,
            hci_year,
            hci_overall    = round(hci_overall, 4),
            gari_norm      = round(gari_norm, 4),
            compound_index = round(compound_index, 4),
            quadrant)

readr::write_csv(bottom20, OUT_BOT_CSV)
writeLines(c(
  "# Compounding AI penalty — bottom-20 countries by compound_index",
  "",
  sprintf("Most exposed to the joint low-HCI ∩ low-GARI position (low compound_index = both axes weak). N joined = %d. Compound index = HCI × (GARI_score / 100).", n_joined),
  "",
  knitr::kable(bottom20, format = "pipe")
), OUT_BOT_MD)
message(sprintf("[m9] wrote %s and %s", OUT_BOT_CSV, OUT_BOT_MD))

# === 8. Table 3: SSA × quadrant cross-tab ====================================
ssa_quad <- d |>
  mutate(ssa_label = if_else(is_ssa, "SSA", "RoW")) |>
  count(ssa_label, quadrant) |>
  pivot_wider(names_from = quadrant, values_from = n, values_fill = 0)

# Add row totals + column shares
ssa_quad <- ssa_quad |>
  rowwise() |>
  mutate(row_total = sum(c_across(where(is.numeric))))
ssa_quad <- ungroup(ssa_quad)

col_totals <- d |> count(quadrant) |>
  pivot_wider(names_from = quadrant, values_from = n) |>
  mutate(ssa_label = "TOTAL", row_total = n_joined) |>
  select(ssa_label, everything())

# Share-of-quadrant-that-is-SSA (column share)
quad_names <- setdiff(names(ssa_quad), c("ssa_label", "row_total"))
col_shares <- d |> count(quadrant) |>
  left_join(d |> filter(is_ssa) |> count(quadrant, name = "n_ssa"), by = "quadrant") |>
  mutate(n_ssa = coalesce(n_ssa, 0L),
         pct_ssa = round(100 * n_ssa / n, 1)) |>
  select(quadrant, n_total = n, n_ssa, pct_ssa) |>
  arrange(quadrant)

ssa_crosstab_combined <- bind_rows(
  ssa_quad |> mutate(ssa_label = as.character(ssa_label)),
  col_totals
)

readr::write_csv(ssa_crosstab_combined, OUT_SSA_CSV)
writeLines(c(
  "# Compounding AI penalty — SSA vs RoW × quadrant cross-tab",
  "",
  sprintf("Joined sample N = %d.  SSA in sample: %d (%.1f%%).",
          n_joined, sum(d$is_ssa), 100 * mean(d$is_ssa)),
  "",
  "## Counts: SSA vs RoW × quadrant",
  "",
  knitr::kable(ssa_crosstab_combined, format = "pipe"),
  "",
  "## Column shares: SSA representation within each quadrant",
  "",
  knitr::kable(col_shares, format = "pipe"),
  "",
  "**Headline read:** the row above for `low_hci_low_gari` quadrant gives the count of double-excluded countries and the SSA share within that cell."
), OUT_SSA_MD)
message(sprintf("[m9] wrote %s and %s", OUT_SSA_CSV, OUT_SSA_MD))

# === 9. Table 4: Robustness (tercile + HCI-2018-only) =========================
# Tercile split
hci_terc  <- quantile(d$hci_overall, c(1/3, 2/3), na.rm = TRUE)
gari_terc <- quantile(d$gari_norm,   c(1/3, 2/3), na.rm = TRUE)

d_terc <- d |>
  mutate(hci_terc  = case_when(hci_overall < hci_terc[1] ~ "low",
                                hci_overall < hci_terc[2] ~ "mid",
                                TRUE ~ "high"),
         gari_terc = case_when(gari_norm < gari_terc[1] ~ "low",
                                gari_norm < gari_terc[2] ~ "mid",
                                TRUE ~ "high"),
         double_excluded_terc = (hci_terc == "low" & gari_terc == "low"))

# 2018-only sample
hci_2018 <- panel |> filter(year == 2018, !is.na(hci_hci_overall)) |>
  select(iso3, hci_overall = hci_hci_overall)
d_2018 <- inner_join(hci_2018, gari, by = "iso3") |>
  mutate(gari_norm = gari_mean / 100)
hci_med_2018  <- median(d_2018$hci_overall)
gari_med_2018 <- median(d_2018$gari_norm)
d_2018 <- d_2018 |>
  mutate(double_excluded_2018 = (hci_overall < hci_med_2018) & (gari_norm < gari_med_2018))

# Country sets for agreement
set_default <- d |> filter(is_double_excluded) |> pull(iso3) |> sort()
set_terc    <- d_terc |> filter(double_excluded_terc) |> pull(iso3) |> sort()
set_2018    <- d_2018 |> filter(double_excluded_2018) |> pull(iso3) |> sort()

agree_terc <- length(intersect(set_default, set_terc)) /
              max(length(union(set_default, set_terc)), 1)
agree_2018 <- length(intersect(set_default, set_2018)) /
              max(length(union(set_default, set_2018)), 1)

rob_tbl <- tibble(
  specification = c(
    sprintf("Median-split (HEADLINE, N=%d)", n_joined),
    sprintf("Tercile-split (N=%d; double-excluded = low/low tercile)", nrow(d_terc)),
    sprintf("HCI-2018-only median-split (N=%d)", nrow(d_2018))
  ),
  n_double_excluded = c(length(set_default), length(set_terc), length(set_2018)),
  jaccard_vs_headline = c(1.000, round(agree_terc, 3), round(agree_2018, 3)),
  countries = c(
    paste(set_default, collapse = "; "),
    paste(set_terc, collapse = "; "),
    paste(set_2018, collapse = "; ")
  )
)

readr::write_csv(rob_tbl, OUT_ROB_CSV)
writeLines(c(
  "# Compounding AI penalty — robustness panel",
  "",
  "Three alternative specifications for the 'double-excluded' country set.  `jaccard_vs_headline` is the intersection-over-union of each set with the headline median-split set — closer to 1 means more stable.",
  "",
  knitr::kable(rob_tbl |> select(-countries), format = "pipe"),
  "",
  "## Country sets per specification",
  "",
  paste0("**Median-split (headline):** `", paste(set_default, collapse = "; "), "`"),
  "",
  paste0("**Tercile-split (low/low):** `", paste(set_terc, collapse = "; "), "`"),
  "",
  paste0("**HCI-2018-only median-split:** `", paste(set_2018, collapse = "; "), "`")
), OUT_ROB_MD)
message(sprintf("[m9] wrote %s and %s", OUT_ROB_CSV, OUT_ROB_MD))

# === 10. Figure: scatter with quadrant overlay + bottom-N labels =============
message("\n[m9] building scatter plot")

label_pts <- d |> arrange(compound_index) |> slice_head(n = 15)

p <- ggplot(d, aes(x = hci_overall, y = gari_norm)) +
  geom_vline(xintercept = hci_med,  linetype = "dashed", color = "grey60") +
  geom_hline(yintercept = gari_med, linetype = "dashed", color = "grey60") +
  annotate("rect",
           xmin = -Inf, xmax = hci_med, ymin = -Inf, ymax = gari_med,
           alpha = 0.08, fill = "#B2182B") +
  geom_point(aes(color = is_ssa, shape = is_ssa), size = 2.5, alpha = 0.85) +
  scale_color_manual(values = c(`TRUE` = "#1F78B4", `FALSE` = "#888888"),
                     labels = c(`TRUE` = "SSA", `FALSE` = "RoW"),
                     name = "Region") +
  scale_shape_manual(values = c(`TRUE` = 17, `FALSE` = 16),
                     labels = c(`TRUE` = "SSA", `FALSE` = "RoW"),
                     name = "Region") +
  labs(
    title    = "The compounding AI penalty — joint distribution of human capital and AI readiness",
    subtitle = sprintf("HCI (latest cycle, mostly 2018-2020) vs Oxford GARI 2025 / 100. N joined = %d; r (preview) = 0.777. Red-shaded quadrant: low-HCI low-GARI on sample-median split (the 'double-excluded' cell).",
                       n_joined),
    x = "Human Capital Index (0-1, HCI latest cycle)",
    y = "AI Readiness Index / 100 (Oxford GARI 2025)",
    caption = sprintf("Source: WB HCI + Oxford Insights GARI 2025. Labeled points = bottom-15 by compound_index = HCI × (GARI/100).")
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        plot.title.position = "plot")

# Add quadrant labels in corners
p <- p +
  annotate("text", x = max(d$hci_overall) - 0.02, y = max(d$gari_norm) - 0.02,
           label = "high HCI / high GARI", hjust = 1, vjust = 1, size = 3, color = "grey40") +
  annotate("text", x = min(d$hci_overall) + 0.02, y = max(d$gari_norm) - 0.02,
           label = "low HCI / high GARI", hjust = 0, vjust = 1, size = 3, color = "grey40") +
  annotate("text", x = max(d$hci_overall) - 0.02, y = min(d$gari_norm) + 0.02,
           label = "high HCI / low GARI", hjust = 1, vjust = 0, size = 3, color = "grey40") +
  annotate("text", x = min(d$hci_overall) + 0.02, y = min(d$gari_norm) + 0.02,
           label = "DOUBLE-EXCLUDED\n(low HCI / low GARI)",
           hjust = 0, vjust = 0, size = 3.2, color = "#B2182B", fontface = "bold")

# Country labels (ggrepel preferred; fallback to geom_text)
if (requireNamespace("ggrepel", quietly = TRUE)) {
  p <- p + ggrepel::geom_text_repel(
    data = label_pts, aes(label = iso3),
    size = 3, max.overlaps = 30, segment.color = "grey50", segment.size = 0.3,
    box.padding = 0.3, point.padding = 0.2, min.segment.length = 0.1
  )
} else {
  message("[m9] ggrepel unavailable; falling back to geom_text")
  p <- p + geom_text(data = label_pts, aes(label = iso3),
                     size = 3, hjust = -0.2, vjust = -0.2, check_overlap = TRUE)
}

dir.create(dirname(OUT_PLOT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PLOT_PDF, p, width = 10, height = 7.5)
ggsave(OUT_PLOT_PNG, p, width = 10, height = 7.5, dpi = 150)
message(sprintf("[m9] wrote %s and %s", OUT_PLOT_PDF, OUT_PLOT_PNG))

# === 11. stdout summary =======================================================
cat("\n=== Phase 9 Session 01 summary ===\n")
cat(sprintf("Joined sample (HCI latest cycle × GARI 2025): N = %d countries.\n", n_joined))
cat(sprintf("HCI cycle-year breakdown: %s\n",
            paste(sprintf("%d=%d", as.integer(names(table(d$hci_year))),
                          as.integer(table(d$hci_year))), collapse = "; ")))
cat(sprintf("SSA in sample: %d (%.1f%%)\n", sum(d$is_ssa), 100 * mean(d$is_ssa)))
cat(sprintf("Sample medians: HCI=%.4f, GARI_norm=%.4f\n\n", hci_med, gari_med))
cat("Quadrant counts:\n")
print(quadrant_tbl |> select(quadrant, n_countries, n_ssa, mean_hci, mean_gari, mean_compound))
cat(sprintf("\nDouble-excluded (low_hci ∩ low_gari): %d countries; %d of them SSA (%.1f%% of cell)\n",
            sum(d$is_double_excluded),
            sum(d$is_double_excluded & d$is_ssa),
            100 * sum(d$is_double_excluded & d$is_ssa) / max(sum(d$is_double_excluded), 1)))
cat(sprintf("\nRobustness: Jaccard (tercile vs headline) = %.3f; (HCI-2018-only vs headline) = %.3f\n",
            agree_terc, agree_2018))
cat("\nTop-5 most-double-excluded countries (lowest compound_index):\n")
print(bottom20 |> slice_head(n = 5) |>
        select(rank_bottom, iso3, hci_year, hci_overall, gari_norm, compound_index))
message("\n[m9] complete.")
