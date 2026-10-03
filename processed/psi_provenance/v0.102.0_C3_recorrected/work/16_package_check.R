# The v0.102.0 package function, run end-to-end on the countries whose entire outbreak-week fit
# set lies in the stored 2018+ window, reproduces the staged v0.102.0 psi.
suppressMessages({library(data.table); pkgload::load_all("/Users/johngiles/MOSAIC/MOSAIC-pkg/.claude/worktrees/v0102", quiet = TRUE)})
cat("MOSAIC", as.character(packageVersion("MOSAIC")), "\n")
c3  <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi/C3"
stg <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi"
day <- fread(file.path(c3, "pred_psi_suitability_day.csv")); day[, date := as.Date(date)]
obs <- fread(file.path(c3, "data_psi_suitability.csv")); obs[, date := as.Date(date)]
new <- fread(file.path(stg, "pred_psi_suitability_day.csv")); new[, date := as.Date(date)]
cut <- as.Date("2026-09-17")
inwin <- c("BFA", "GMB", "MLI", "RWA", "SLE", "ZAF")
el <- as.data.frame(merge(day[iso_code %in% inwin, .(iso_code, date, pred_smooth)], obs[, .(iso_code, date, intensity)],
                          by = c("iso_code", "date"), all.x = TRUE))
out <- withCallingHandlers(calibrate_psi_predictions(el, el[, c("iso_code", "date", "intensity")], cut,
          pred_col = "pred_smooth", obs_col = "intensity", out_col = "psi_pkg"),
          warning = function(w) { cat("  [warn]", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
print(attr(out, "calibration_diagnostics")[, c("iso_code", "n_outbreak", "status", "slope", "offset", "amp_ratio")])
cmp <- merge(as.data.table(out)[, .(iso_code, date, psi_pkg)], new[, .(iso_code, date, psi_staged = psi)], by = c("iso_code", "date"))
print(cmp[, .(max_abs_diff = max(abs(psi_pkg - psi_staged)), bit_identical = identical(psi_pkg, psi_staged)), by = iso_code])
