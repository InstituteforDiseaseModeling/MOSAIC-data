# Re-apply the v0.102.0 bias-correction rule to the stored C3 psi (no LSTM retraining).
#
# The v0.102.0 rule changes only countries whose v0.101.0 map sat on the amplitude
# FLOOR (the fit was blended toward identity until its logit-sd reached 0.5x the
# input's). For those the new output is the identity: psi = pred_bias_corrected =
# pred_smooth. Every other country's map is unchanged by construction, so its rows
# are copied byte-for-byte.
#
# Which C3 maps are floor-clamped is decided from the stored files plus the run's
# own guard counter (run_psi.log), because the per-country diagnostics were not
# saved and three of the four countries' fit sets start before the stored window
# (2015-03..2017 outbreak weeks; the day file starts 2018-01-01):
#   * each map logit(psi) = A logit(pred_smooth) + B is recovered exactly (R^2 = 1);
#   * a fit is "guarded" only if its slope was clamped (A in {0.25, 4}), its offset was
#     clamped (B = +-4), or the amplitude blend fired (A on the 0.02-grid neighbourhood
#     of 0.5 or 2); every other map is interior and cannot be guarded;
#   * the candidates near the floor and the ceiling together must equal the log's
#     guarded count, so every candidate was guarded, and a floor candidate with A not
#     0.25 and |B| not 4 can only have been guarded by the floor blend.
suppressMessages({library(data.table); library(jsonlite)})
src <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi/C3"
out <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi"
eps <- 1e-6; lgt <- function(p) qlogis(pmax(eps, pmin(1 - eps, p)))
md5 <- function(f) unname(tools::md5sum(f))

stopifnot(md5(file.path(src, "pred_psi_suitability_day.csv"))  == "d0eb1e2da04c24a8b2cbf43d548c0413",
          md5(file.path(src, "pred_psi_suitability_week.csv")) == "6a0f85cd17b2d4cecf3bf026b1807b82",
          md5(file.path(src, "data_psi_suitability.csv"))      == "1f1388641bfa8fea0fbf5f10305f1681",
          md5(file.path(src, "psi_suitability_config.json"))   == "e098f115724b4c0cd183cd051e0c6083")

day <- fread(file.path(src, "pred_psi_suitability_day.csv"))
maps <- day[, { x <- lgt(pred_smooth); y <- lgt(pred_bias_corrected); f <- lm(y ~ x)
                list(A = coef(f)[[2]], B = coef(f)[[1]], max_resid = max(abs(resid(f)))) }, by = iso_code]
stopifnot(all(maps$max_resid < 1e-9))

floor_tol   <- 0.02 * (1 - 0.25) / 2     # half the widest blend-grid step in A below 1
ceiling_tol <- 0.02 * (4 - 1) / 2        # ... and above 1
maps[, floor_cand   := abs(A - 0.5) <= floor_tol]
maps[, ceiling_cand := abs(A - 2.0) <= ceiling_tol]
maps[, clamp_value  := abs(A - 0.25) < 1e-9 | abs(A - 4) < 1e-9 | abs(abs(B) - 4) < 1e-9]
log_txt   <- readLines(file.path(src, "run_psi.log"))
n_guarded <- as.integer(sub(".*: (\\d+) country/countries had their affine correction guarded.*", "\\1",
                            grep("had their affine correction guarded", log_txt, value = TRUE)[1]))
n_cand <- sum(maps$floor_cand | maps$ceiling_cand | maps$clamp_value)
cat(sprintf("guarded count in run_psi.log: %d; floor candidates %d, ceiling candidates %d, clamp-value maps %d\n",
            n_guarded, sum(maps$floor_cand), sum(maps$ceiling_cand), sum(maps$clamp_value & !maps$floor_cand & !maps$ceiling_cand)))
stopifnot(n_cand == n_guarded)
stopifnot(!any(maps$floor_cand & maps$clamp_value))
collapsed <- sort(maps[floor_cand == TRUE, iso_code])
cat("floor-clamped in C3 (v0.102.0 -> identity):", collapsed, "\n")
print(maps[floor_cand | ceiling_cand, .(iso_code, A = round(A, 4), B = round(B, 4), floor_cand, ceiling_cand)])

# ---- text-level rewrite: psi (col 4) and pred_bias_corrected (col 7) := pred_smooth (col 6)
rewrite <- function(fname) {
     L <- readLines(file.path(src, fname))
     hdr <- strsplit(L[1], ",", fixed = TRUE)[[1]]
     stopifnot(identical(hdr[c(1, 4, 6, 7)], c("\"iso_code\"", "\"psi\"", "\"pred_smooth\"", "\"pred_bias_corrected\"")))
     body <- L[-1]
     iso  <- substr(body, 2, 4)
     hit  <- iso %in% collapsed
     f <- strsplit(body[hit], ",", fixed = TRUE)
     stopifnot(all(lengths(f) == length(hdr)))
     body[hit] <- vapply(f, function(z) { z[4] <- z[6]; z[7] <- z[6]; paste(z, collapse = ",") }, character(1))
     L2 <- c(L[1], body)
     writeLines(L2, file.path(out, fname))
     list(old = L, new = L2, hit = c(FALSE, hit))
}
rd <- rewrite("pred_psi_suitability_day.csv")
rw <- rewrite("pred_psi_suitability_week.csv")
file.copy(file.path(src, "data_psi_suitability.csv"), file.path(out, "data_psi_suitability.csv"), overwrite = TRUE)

# ---- verification ---------------------------------------------------------------
for (nm in c("day", "week")) {
     r <- if (nm == "day") rd else rw
     stopifnot(length(r$old) == length(r$new))
     same <- r$old == r$new
     cat(sprintf("%s: %d rows; unaffected rows byte-identical: %d/%d; affected rows changed: %d/%d\n", nm, length(r$old) - 1L,
                 sum(same[!r$hit]), sum(!r$hit), sum(!same[r$hit]), sum(r$hit)))
     stopifnot(all(same[!r$hit]))
     fo <- strsplit(r$old[r$hit], ",", fixed = TRUE); fn <- strsplit(r$new[r$hit], ",", fixed = TRUE)
     stopifnot(all(mapply(function(a, b) identical(a[-c(4, 7)], b[-c(4, 7)]) && b[4] == a[6] && b[7] == a[6], fo, fn)))
}
nd <- fread(file.path(out, "pred_psi_suitability_day.csv")); od <- day
stopifnot(identical(nd[!iso_code %in% collapsed], od[!iso_code %in% collapsed]),
          identical(nd[iso_code %in% collapsed, psi], nd[iso_code %in% collapsed, pred_smooth]),
          identical(nd[iso_code %in% collapsed, pred_bias_corrected], nd[iso_code %in% collapsed, pred_smooth]),
          identical(nd[, !c("psi", "pred_bias_corrected")], od[, !c("psi", "pred_bias_corrected")]))
nw <- fread(file.path(out, "pred_psi_suitability_week.csv"))
chk <- merge(nw, nd, by = c("iso_code", "date"), suffixes = c("_w", "_d"))
stopifnot(nrow(chk) == nrow(nw), identical(chk$psi_w, chk$psi_d), identical(chk$pred_bias_corrected_w, chk$pred_bias_corrected_d))
cat("numeric checks passed: unaffected countries identical; affected psi == pred_bias_corrected == pred_smooth; week file == day file on its dates\n")

# ---- slim manifest: C3's slim manifest + a re-application record -------------------
man <- fromJSON(file.path(src, "psi_suitability_config.json"), simplifyVector = FALSE)
man$bias_correction_reapplied <- list(
     mosaic_version = "0.102.0",
     rule = "calibrate_psi_predictions() v0.102.0: a per-country fit whose corrected logit-sd would fall below amp_range[1] (0.5) times the input's is not applied; the country falls back to identity (psi = pred_bias_corrected = pred_smooth), status 'collapsed'. v0.101.0 blended such fits toward identity until they sat on the 0.5x floor.",
     method = "Re-applied to the stored C3 artefact without retraining: the LSTM ensemble (pred_raw, pred_smooth, q*) is C3's. Rows of every other country are byte-identical to C3.",
     collapsed_isos = as.list(collapsed),
     c3_floor_maps = lapply(collapsed, function(i) list(iso_code = i, slope = round(maps[iso_code == i, A], 6), offset = round(maps[iso_code == i, B], 6))),
     floor_status_evidence = sprintf("maps recovered exactly from the C3 day file (max |resid| %.1e); %d floor and %d ceiling candidates on the blend grid equal the %d guarded fits in run_psi.log, and no floor candidate carries a slope or offset clamp value, so each was guarded by the floor blend", max(maps$max_resid), sum(maps$floor_cand), sum(maps$ceiling_cand), n_guarded),
     source = list(dir = src,
                   pred_psi_suitability_day_md5 = md5(file.path(src, "pred_psi_suitability_day.csv")),
                   pred_psi_suitability_week_md5 = md5(file.path(src, "pred_psi_suitability_week.csv")),
                   psi_suitability_config_md5 = md5(file.path(src, "psi_suitability_config.json"))),
     script = "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi/work/13_reapply_C3.R",
     written_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
write_json(man, file.path(out, "psi_suitability_config.json"), pretty = TRUE, auto_unbox = TRUE, digits = NA, null = "null")
m2 <- fromJSON(file.path(out, "psi_suitability_config.json"), simplifyVector = FALSE)
m0 <- fromJSON(file.path(src, "psi_suitability_config.json"), simplifyVector = FALSE)
stopifnot(identical(m2[names(m0)], m0))
cat("slim manifest: every C3 field round-trips unchanged; added bias_correction_reapplied\n")

files <- c("pred_psi_suitability_day.csv", "pred_psi_suitability_week.csv", "data_psi_suitability.csv", "psi_suitability_config.json")
writeLines(sprintf("%s  %s", vapply(file.path(out, files), md5, character(1)), files), file.path(out, "MD5SUMS.txt"))
cat(readLines(file.path(out, "MD5SUMS.txt")), sep = "\n")
saveRDS(list(collapsed = collapsed, maps = maps), file.path(out, "work", "reapply_C3_maps.rds"))
