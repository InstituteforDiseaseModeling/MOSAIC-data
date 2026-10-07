# Suitability panel D for psi retrain (MOSAIC 1.1.0): C3's compile call and covariates
# (enso_C Nino4 variant, climate/EMDAT trees as C3) on the refreshed surveillance
# (MOSAIC-data beb95f5). Writes claude/psi_v110/panel_D/weekly/cholera_country_weekly_suitability_data.csv
suppressMessages(devtools::load_all("/Users/johngiles/MOSAIC/MOSAIC-pkg", quiet = TRUE))
cat("MOSAIC (load_all)", as.character(packageVersion("MOSAIC")), "sha",
    system("git -C /Users/johngiles/MOSAIC/MOSAIC-pkg rev-parse --short HEAD", intern = TRUE), "\n")
set_root_directory("/Users/johngiles/MOSAIC")
PATHS <- get_paths()
ST <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/psi_v110/panel_D"
PATHS$DATA_ENSO <- "/Users/johngiles/MOSAIC/MOSAIC-data/processed/psi_provenance/v0.101.0_C3/enso_C"
PATHS$DATA_CHOLERA_WEEKLY <- file.path(ST, "weekly")
PATHS$DOCS_FIGURES <- file.path(ST, "figs")
src_surv <- file.path(get_paths()$DATA_CHOLERA_WEEKLY, "cholera_surveillance_weekly_combined.csv")
dst_surv <- file.path(PATHS$DATA_CHOLERA_WEEKLY, "cholera_surveillance_weekly_combined.csv")
if (!file.exists(dst_surv)) file.symlink(src_surv, dst_surv)
for (f in c(dst_surv, file.path(PATHS$DATA_ENSO, "enso_weekly.csv"), file.path(PATHS$MODEL_INPUT, "param_epidemic_peaks.csv")))
  cat("input:", f, " md5:", unname(tools::md5sum(f)), "\n")
t0 <- Sys.time()
compile_suitability_data(PATHS, cutoff = NULL, use_epidemic_peaks = TRUE, date_start = "2000-01-01", date_stop = NULL,
                         forecast_mode = TRUE, forecast_horizon = 9, include_lags = TRUE)
out <- file.path(PATHS$DATA_CHOLERA_WEEKLY, "cholera_country_weekly_suitability_data.csv")
cat("ELAPSED_MIN", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
cat("PANEL", out, " md5:", unname(tools::md5sum(out)), " bytes:", file.size(out), "\n")
x <- read.csv(out); cat("rows", nrow(x), "cols", ncol(x), "| last observed cases week:", max(x$date[!is.na(x$cases)]), "\n")
print(warnings()); cat("DONE\n")
