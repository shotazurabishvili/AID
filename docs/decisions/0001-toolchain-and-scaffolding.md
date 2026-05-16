# ADR-0001: Toolchain and project scaffolding

**Status:** Accepted
**Date:** 2026-05-16
**Phase:** 0 — Infrastructure

## Context

This is the project's session-zero ADR. The user (practitioner-researcher) wants a durable multi-session scaffold for a quantitative paper targeting *World Development*. Several foundational forks needed to be locked before any analysis begins: statistical environment, version control, workspace location, engagement model, and the session-continuity mechanism.

## Options considered

1. **R + renv on WSL, hybrid workspace, ADR + per-session-log continuity model** (chosen)
2. **Python with pyfixest / statsmodels** — no system install needed, faster start, but slightly weaker HLM ecosystem and less idiomatic for World Development reviewers
3. **R on Windows + RStudio, called from WSL via Rscript.exe** — heavier, gives the author a GUI, but adds cross-filesystem complexity

## Decision

**R + renv installed on WSL.** Primary workspace at `~/AID` (fast Linux I/O); selected artifacts mirrored to `C:\Users\szura\Desktop\AID\mirror\` via rsync so the author sees current outputs on Windows. Git initialized locally; private GitHub remote (`shotazurabishvili/AID`) from day one because *World Development* expects a reproducibility deposit at submission. Continuity model: a `CLAUDE.md` bootstrap file + per-session log files under `docs/session_log/` + one ADR per consequential analytical choice under `docs/decisions/`.

**Why this combination:**

- *R over Python*: the brief explicitly prefers R; `fixest` and `lme4` are the gold standard for the panel-FE and HLM models that anchor the paper; World Development referees are R-fluent.
- *WSL over Windows*: R package install times and data wrangling are markedly faster on the Linux filesystem; the hybrid mirror gives up almost nothing.
- *Git + GitHub from day one*: the cost is one `gh repo create`; the payoff is the journal's reproducibility deposit being trivial when submission time comes.
- *ADR + per-session log over a single rolling log*: this is a 30–45 session project. A single log becomes unscannable. ADRs surface decision points that the brief warns will be challenged by referees (variable operationalization, missingness strategy, group coding).

## Consequences

- Every analytical decision a referee could plausibly attack gets its own ADR with an "imagined critique + response" section. This pre-funds the adversarial Pass 3 review.
- Each session ends with a session-log file + a `CLAUDE.md` "Current state" update. Next-session bootstrap takes < 60s.
- The author runs `sudo apt install r-base ...` once (Claude Code can't enter the sudo password); after that, no further sudo is needed.
- Raw data is gitignored; reproducibility relies on `data/catalog.md` source URLs + access dates, not bundled data.
- The Windows-side `mirror/` is a one-way push from WSL; never edit files in `mirror/` directly.

## How a referee might attack this

*"Why R specifically? Your reproducibility deposit forces reviewers to install an R environment."* — Standard practice in development economics and education research; we lock with renv so a single `renv::restore()` rebuilds the environment exactly. `Quarto` outputs render to PDF/HTML for readers who don't run the code themselves.
