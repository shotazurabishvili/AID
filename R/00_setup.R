# 00_setup.R
# Initialize the project's R environment via renv and lock the core package stack.
# Run once after R is installed on the system. Idempotent: safe to re-run.

# Bootstrap renv if not yet installed
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

# Initialize renv if no lockfile exists yet
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE, restart = FALSE)
}

# Core stack for this project — econometrics, HLM, ANOVA, data, plotting, manuscript
core_packages <- c(
  # Data wrangling and I/O
  "tidyverse",      # dplyr, tidyr, readr, purrr, ggplot2, etc.
  "arrow",          # parquet read/write for interim datasets
  "haven",          # read Stata/SPSS files (some sources ship .dta)
  "readxl",         # OECD bulk extracts sometimes ship .xlsx
  "janitor",        # clean_names, tabyl

  # Country codes and metadata
  "countrycode",    # ISO3 normalization

  # Data access
  "WDI",            # World Bank WDI + WGI API

  # Econometrics
  "fixest",         # PRIMARY: fast FE panel estimation, clustered SE, etale
  "plm",            # diagnostic tests (Hausman, Wooldridge, BP) for panel models
  "lmtest",         # additional diagnostic tests
  "sandwich",       # robust SE
  "car",            # vif, Anova(), Levene's test

  # Multilevel models
  "lme4",
  "lmerTest",       # p-values for lme4
  "performance",    # ICC, model checks

  # ANOVA / effect sizes / post-hoc
  "rstatix",        # tidy ANOVA wrappers, effect sizes
  "emmeans",        # post-hoc and Tukey HSD
  "effectsize",     # Cohen's d, eta-squared

  # Tables and reporting
  "modelsummary",   # regression tables to multiple formats
  "broom",          # tidy() / glance() for model objects
  "broom.mixed",    # tidy() for lme4/lmerTest

  # Manuscript / reproducibility
  "knitr",
  "rmarkdown",
  "quarto",
  "targets"         # optional: pipeline orchestration
)

cat("Installing core packages via renv...\n")
renv::install(core_packages)

# Snapshot to lock the environment
renv::snapshot(prompt = FALSE)

cat("\nSetup complete. Verify with:\n")
cat("  library(fixest); library(lme4); library(tidyverse)\n")
