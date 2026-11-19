# Exploring childhood blood lead test trajectories

Authored by Cameron Hempton, Stephanie Iorga, [MI-Support](https://micom-hub.org/mi_support.html), [MICOM](https://www.micom-insight.net/)

This repository contains code that allows users to run a local R Shiny app for exploring childhood blood lead test trajectories. Users can generate a random population, adjust how separate tests are defined, and filter results by Michigan county, sex, and age. The app includes an interactive trajectory plot, summary counts, and a downloadable detailed summary. It was developed primarily in August 2026.

This app is a public demonstration that uses entirely synthetic data. A random population is generated on session start, with randomized test results. This can be regenerated using the "Generate Random Population" button. No actual patient records are included, and the simulated results do not reflect any real results or population trends.

## How to run the Shiny app

### Environment setup

First, install R and RStudio. [Instructions are provided by Posit here.](https://posit.co/download/rstudio-desktop/)

Second, install the necessary R libraries by running the following code in [RStudio's R console](https://docs.posit.co/ide/user/ide/guide/code/console.html):

```r
install.packages(c(
  "shiny", "bslib", "dplyr", "tidyr", "htmltools",
  "plotly", "lubridate"
))
```

### Run the app

Open [app.R](app.R) in the [RStudio source pane](https://docs.posit.co/ide/user/ide/guide/ui/ui-panes.html), then click the "Run App" button in the top right of this pane.

Alternatively, run the following command from the repository root:

```r
shiny::runApp(".")
```

Keep the `R/`, `scripts/`, and `www/` directories alongside `app.R`. The app does not require a data directory or configuration file.