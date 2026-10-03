suppressMessages({library(data.table)})
mk_env <- function(f) { e <- new.env(); sys.source("/Users/johngiles/MOSAIC/MOSAIC-pkg/.claude/worktrees/v0102/R/check_psi_amplitude.R", envir = e)
  sys.source(f, envir = e); e }
old <- mk_env("calibrate_psi_predictions_main.R"); new <- mk_env("calibrate_psi_predictions_new.R")
d0 <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi/C3"
day <- fread(file.path(d0, "pred_psi_suitability_day.csv")); day[, date := as.Date(date)]
obs <- fread(file.path(d0, "data_psi_suitability.csv")); obs[, date := as.Date(date)]
el <- as.data.frame(merge(day[, .(iso_code, date, pred_smooth)], obs[, .(iso_code, date, intensity)], by = c("iso_code","date"), all.x = TRUE))
cut <- as.Date("2026-09-17")
run <- function(e) withCallingHandlers(e$calibrate_psi_predictions(el, el[, c("iso_code","date","intensity")], cut,
          pred_col = "pred_smooth", obs_col = "intensity", out_col = "psi"),
          warning = function(w) { cat("  [warn]", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
cat("OLD:\n"); o <- run(old); cat("NEW:\n"); n <- run(new)
do <- attr(o, "calibration_diagnostics"); dn <- attr(n, "calibration_diagnostics")
cmp <- merge(data.table(do)[, .(iso_code, old_status = status, old_amp = round(amp_ratio, 3))],
             data.table(dn)[, .(iso_code, new_status = status, new_amp = round(amp_ratio, 3), slope = round(slope, 3), offset = round(offset, 3))], by = "iso_code")
o <- as.data.table(o); n <- as.data.table(n)
chk <- o[, .(iso_code, date, po = psi)][n[, .(iso_code, date, pn = psi, ps = pred_smooth)], on = c("iso_code","date")][,
        .(bit_identical_to_old = identical(po, pn), identical_to_input = identical(pn, ps)), by = iso_code]
res <- merge(cmp, chk, by = "iso_code")
print(res[old_status != new_status | !bit_identical_to_old])
cat(sprintf("\nunchanged countries: %d / %d bit-identical to the old function (all with unchanged status)\n",
            res[old_status == new_status & bit_identical_to_old, .N], res[old_status == new_status, .N]))
cat("changed countries:", res[bit_identical_to_old == FALSE, iso_code], " -> all identical to input:", all(res[bit_identical_to_old == FALSE, identical_to_input]), "\n")
