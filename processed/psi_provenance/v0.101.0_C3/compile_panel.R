# Compile the v0.101.0 suitability panel exactly as the ml-scientist's
# claude/v0101_rebuild/psi/scripts/compile_panel.R, but from the fix/v0101-trust
# worktree (shaped ZAF 2023 window, backfill trust) with PATHS$MODEL_INPUT on this
# worktree's model/input (rebuilt peaks: 161, incl. ZAF 2023-05-29).
# No args: canonical panel -> MOSAIC-data/processed/cholera/weekly (ENSO as merged).
# Args 1, 2: alternative DATA_ENSO dir and output dir (panel C: Nino4 fix).
args <- commandArgs(trailingOnly = TRUE)
WT <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/.claude/worktrees/v0101-trust"
ST <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_trust"
suppressMessages(devtools::load_all(WT, quiet = TRUE))
cat("MOSAIC (load_all)", as.character(packageVersion("MOSAIC")), "from", WT,
    " sha", system(sprintf("git -C %s rev-parse --short HEAD", WT), intern = TRUE), "\n")
set_root_directory("/Users/johngiles/MOSAIC")
PATHS <- get_paths()
PATHS$MODEL_INPUT  <- file.path(WT, "model/input")
alt <- length(args) >= 2
PATHS$DOCS_FIGURES <- file.path(ST, if (alt) "panel_C/figs" else "panel/figs")
if (alt) {
  PATHS$DATA_ENSO           <- normalizePath(args[1])
  PATHS$DATA_CHOLERA_WEEKLY <- normalizePath(args[2])
  # compile reads the combined surveillance from DATA_CHOLERA_WEEKLY: link the canonical one
  src_surv <- file.path(get_paths()$DATA_CHOLERA_WEEKLY, "cholera_surveillance_weekly_combined.csv")
  dst_surv <- file.path(PATHS$DATA_CHOLERA_WEEKLY, "cholera_surveillance_weekly_combined.csv")
  if (!file.exists(dst_surv)) file.symlink(src_surv, dst_surv)
}
dir.create(PATHS$DOCS_FIGURES, recursive = TRUE, showWarnings = FALSE)
pk <- file.path(PATHS$MODEL_INPUT, "param_epidemic_peaks.csv")
cat("peaks:", pk, " md5:", unname(tools::md5sum(pk)), " n_peaks:", nrow(read.csv(pk)), "\n")
for (f in c(file.path(PATHS$DATA_CHOLERA_WEEKLY, "cholera_surveillance_weekly_combined.csv"),
            file.path(PATHS$DATA_ENSO, "enso_weekly.csv")))
  cat("input:", f, " md5:", unname(tools::md5sum(f)), "\n")
cat("climate weekly parquets:", length(list.files(PATHS$DATA_CLIMATE, "\\.parquet$")), "in", PATHS$DATA_CLIMATE, "\n")
cat("DOCS_FIGURES ->", PATHS$DOCS_FIGURES, "\n")
t0 <- Sys.time()
compile_suitability_data(PATHS, cutoff = NULL, use_epidemic_peaks = TRUE,
                         date_start = "2000-01-01", date_stop = NULL,
                         forecast_mode = TRUE, forecast_horizon = 9,
                         include_lags = TRUE)
out <- file.path(PATHS$DATA_CHOLERA_WEEKLY, "cholera_country_weekly_suitability_data.csv")
cat("ELAPSED_MIN", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
cat("PANEL", out, " md5:", unname(tools::md5sum(out)), " bytes:", file.size(out), "\n")
print(warnings())
cat("DONE\n")
