# R/42_eda_divergence.R
#
# Phase 3 Session 01: paper §4.1 headline visualization — "Enrollment without
# learning." 2020 cross-sectional scatter of gross primary enrollment vs HLO
# score across the 133-country ADR-0002 universe.
#
# Why 2020: all 133 universe countries have a 2020 HLO observation (the most
# recent HCI cycle). Allows a clean single-year cross-section without the
# "latest cycle per country" definitional fragility.
#
# Outputs:
#   output/figures/eda/enrollment_vs_learning.pdf
#   output/figures/eda/enrollment_vs_learning.png
#   output/tables/divergence_2020_summary.txt
#
# COVID disclosure: 2020 HLO uses HCI-2020-release test administrations
# (pre-COVID; mostly 2018-2019 testing). 2020 WDI enrollment may be mildly
# COVID-affected by school-closure reporting in some countries. Documented
# in the figure caption.

suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(countrycode)
  library(ggrepel)
  library(scales)
})

PANEL_PATH    <- "data/interim/panel.parquet"
OUT_PDF       <- "output/figures/eda/enrollment_vs_learning.pdf"
OUT_PNG       <- "output/figures/eda/enrollment_vs_learning.png"
OUT_SUMMARY   <- "output/tables/divergence_2020_summary.txt"

LABEL_ISO3    <- c("NGA", "BGD", "IND", "IDN", "VNM", "KEN", "BRA", "EGY")

message("[divergence] loading production panel")
panel <- arrow::read_parquet(PANEL_PATH)

region_map <- countrycode::codelist |>
  filter(!is.na(region), !is.na(iso3c)) |>
  select(iso3 = iso3c, region) |>
  distinct()

d <- panel |>
  filter(year == 2020, in_primary_window) |>
  left_join(region_map, by = "iso3") |>
  filter(!is.na(hlo_hlo_score), !is.na(wdi_enroll_prim_gross)) |>
  mutate(label = ifelse(iso3 %in% LABEL_ISO3, iso3, NA_character_))

message(sprintf("[divergence] 2020 cross-section: %d countries with both HLO and enrollment", nrow(d)))

# OLS regression
fit <- lm(hlo_hlo_score ~ wdi_enroll_prim_gross, data = d)
fit_summary <- summary(fit)
r2 <- fit_summary$r.squared
slope <- coef(fit)[2]
intercept <- coef(fit)[1]
slope_p <- fit_summary$coefficients[2, 4]

annot_text <- sprintf("OLS: HLO = %.0f + %.2f x Enrollment\nR^2 = %.3f   n = %d",
                      intercept, slope, r2, nrow(d))

# Plot
p <- ggplot(d, aes(x = wdi_enroll_prim_gross, y = hlo_hlo_score)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              color = "grey45", fill = "grey85", alpha = 0.6, linewidth = 0.5) +
  geom_point(aes(color = region, size = log10(wdi_population)), alpha = 0.75) +
  ggrepel::geom_text_repel(aes(label = label),
                            size = 3, color = "black",
                            box.padding = 0.35, max.overlaps = Inf,
                            min.segment.length = 0.2,
                            seed = 42, na.rm = TRUE) +
  annotate("text", x = min(d$wdi_enroll_prim_gross, na.rm = TRUE) + 2,
           y = max(d$hlo_hlo_score, na.rm = TRUE),
           label = annot_text, hjust = 0, vjust = 1, size = 3.2,
           color = "grey30") +
  scale_color_brewer(palette = "Set2") +
  scale_size_continuous(range = c(1.6, 6), guide = "none") +
  labs(title = "Enrollment without learning: 2020 cross-section",
       subtitle = sprintf("Gross primary enrollment vs harmonized learning outcomes; 133-country analytical universe (ADR-0002); n = %d with both indicators observed", nrow(d)),
       x = "Gross primary enrollment (%)",
       y = "Harmonized Learning Outcome score (HCI HLOS)",
       color = "World Bank region",
       caption = paste0("Sources: HD.HCI.HLOS (HLO, HCI 2020 release using pre-COVID test administrations);\n",
                       "WDI SE.PRM.ENRR (gross primary enrollment, 2020). Descriptive association only - not a causal claim.")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 10),
        plot.subtitle = element_text(color = "grey30", size = 10),
        plot.caption = element_text(color = "grey40", size = 8, hjust = 0))

# Save
dir.create(dirname(OUT_PDF), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PDF, p, width = 8, height = 5.5)
ggsave(OUT_PNG, p, width = 8, height = 5.5, dpi = 150)
message(sprintf("[divergence] wrote %s and %s", OUT_PDF, OUT_PNG))

# Summary file
summary_lines <- c(
  "Divergence figure summary — paper §4.1 (Phase 3 Session 01)",
  sprintf("Date: %s", Sys.Date()),
  sprintf("Input panel: %s (production)", PANEL_PATH),
  "",
  "2020 cross-section, 133-country universe, both HLO + enrollment non-NA:",
  sprintf("  n countries     = %d", nrow(d)),
  sprintf("  HLO range       = %.0f - %.0f", min(d$hlo_hlo_score), max(d$hlo_hlo_score)),
  sprintf("  HLO mean (SD)   = %.1f (%.1f)", mean(d$hlo_hlo_score), sd(d$hlo_hlo_score)),
  sprintf("  Enrollment range = %.1f - %.1f", min(d$wdi_enroll_prim_gross), max(d$wdi_enroll_prim_gross)),
  sprintf("  Enrollment mean (SD) = %.1f (%.1f)", mean(d$wdi_enroll_prim_gross), sd(d$wdi_enroll_prim_gross)),
  "",
  "OLS regression: HLO ~ Enrollment",
  sprintf("  intercept    = %.2f", intercept),
  sprintf("  slope        = %.3f  (HLO points per 1pp enrollment increase)", slope),
  sprintf("  slope p      = %.2e", slope_p),
  sprintf("  R^2          = %.4f", r2),
  sprintf("  Adj R^2      = %.4f", fit_summary$adj.r.squared),
  "",
  "Substantive interpretation:",
  sprintf("  R^2 = %.2f: enrollment explains ~%.0f%% of cross-country HLO variance. Most learning",
          r2, r2 * 100),
  "  variation is NOT captured by enrollment, supporting the brief's divergence thesis.",
  sprintf("  Slope: %.2f HLO points per 1pp enrollment gain implies a country moving from 80%% to",
          slope),
  sprintf("  100%% gross enrollment would, ON AVERAGE, gain only %.1f HLO points (~%.1f%% of the 305-581",
          slope * 20, slope * 20 / (581 - 305) * 100),
  "  observed range). Enrollment expansion is not a learning-gains lever at panel scale.",
  "",
  "Labeled countries:"
)
labels_df <- d |>
  filter(!is.na(label)) |>
  select(iso3, region, hlo_hlo_score, wdi_enroll_prim_gross) |>
  arrange(iso3)
labels_text <- apply(labels_df, 1, function(r) sprintf("  %s (%s):  enroll=%.1f%%,  HLO=%.0f",
                                                       r["iso3"], r["region"],
                                                       as.numeric(r["wdi_enroll_prim_gross"]),
                                                       as.numeric(r["hlo_hlo_score"])))
summary_lines <- c(summary_lines, labels_text)

writeLines(summary_lines, OUT_SUMMARY)
message(sprintf("[divergence] wrote %s", OUT_SUMMARY))

message("[divergence] complete.")
