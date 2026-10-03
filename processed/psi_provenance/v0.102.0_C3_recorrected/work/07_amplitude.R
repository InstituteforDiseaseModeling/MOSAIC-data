# Amplitude evidence.
# (1) The all-weeks calibration slope beta of the uncorrected LSTM output (quasi-binomial GLM of
#     the [0,1] target on logit(pred), zeros included) is the logit-amplitude multiplier that best
#     calibrates psi against the target: a map with slope A leaves calibration slope beta/A, so the
#     ideal A* = beta. Compare A* with 0.5 (the floor map) and 1 (identity).
# (2) Identifiability of the outbreak-week slope the correction estimates (2018+ window).
# (3) The production C3 floor maps vs identity applied to the OOS fold predictions.
suppressMessages({library(data.table)})
source("/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi/work/rules.R")
d0 <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi/C3"
day <- fread(file.path(d0, "pred_psi_suitability_day.csv")); day[, date := as.Date(date)]
obs <- fread(file.path(d0, "data_psi_suitability.csv")); obs[, date := as.Date(date)]
fpe <- readRDS("/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi/work/fold_pred_ensemble.rds")
cut <- as.Date("2026-09-17")
is_tab <- merge(day[, .(iso_code, date, pred_smooth, psi)], obs[, .(iso_code, date, intensity)],
                by = c("iso_code", "date"))[date <= cut & !is.na(intensity)]
oos_tab <- merge(fpe, obs[, .(iso_code, date, intensity)], by = c("iso_code", "date"))[!is.na(intensity)]
calb <- function(p, y) { if (sum(y > 0) < 5 || sum(y == 0) < 5) return(NA_real_)
     unname(coef(suppressWarnings(glm(y ~ lgt(p), family = quasibinomial())))[2]) }
slope_id <- function(p, y) { s <- y > 0; if (sum(s) < 8) return(list(r = NA_real_, a = NA_real_, t = NA_real_))
     x <- lgt(p[s]); z <- lgt(y[s]); if (sd(x) < 1e-8) return(list(r = NA_real_, a = NA_real_, t = NA_real_))
     f <- summary(lm(z ~ x)); list(r = cor(x, z), a = f$coefficients[2, 1], t = f$coefficients[2, 3]) }
rec <- day[, { f <- lm(lgt(pred_bias_corrected) ~ lgt(pred_smooth)); list(A_prod = coef(f)[[2]], B_prod = coef(f)[[1]]) }, by = iso_code]
tab <- is_tab[, c(list(beta_is = calb(pred_smooth, intensity)), slope_id(pred_smooth, intensity)), by = iso_code]
tab <- merge(tab, oos_tab[, .(beta_oos = calb(pred, intensity)), by = iso_code], by = "iso_code", all = TRUE)
tab <- merge(tab, rec, by = "iso_code")
setorder(tab, A_prod)
options(width = 200)
print(tab[, .(iso_code, A_prod = round(A_prod, 3), outbreak_r = round(r, 2), outbreak_slope = round(a, 2), t_slope = round(t, 1),
              Astar_is = round(beta_is, 2), Astar_oos = round(beta_oos, 2))])
ok <- tab[is.finite(beta_is) & !iso_code %in% c("CIV", "GMB", "TGO", "UGA")]
cat(sprintf("\nA* (all-weeks calibration slope of the raw LSTM), countries with >=5 outbreak and >=5 zero weeks:\n  in-sample: median %.2f, IQR %.2f-%.2f, share > 0.75: %d/%d, share closer to 1 than to 0.5: %d/%d\n",
            median(tab$beta_is, na.rm = TRUE), quantile(tab$beta_is, .25, na.rm = TRUE), quantile(tab$beta_is, .75, na.rm = TRUE),
            sum(tab$beta_is > 0.75, na.rm = TRUE), sum(is.finite(tab$beta_is)),
            sum(tab$beta_is > 0.75, na.rm = TRUE), sum(is.finite(tab$beta_is))))
cat(sprintf("  OOS:       median %.2f, IQR %.2f-%.2f, share > 0.75: %d/%d\n",
            median(tab$beta_oos, na.rm = TRUE), quantile(tab$beta_oos, .25, na.rm = TRUE), quantile(tab$beta_oos, .75, na.rm = TRUE),
            sum(tab$beta_oos > 0.75, na.rm = TRUE), sum(is.finite(tab$beta_oos))))
fwrite(tab, "amplitude_by_country.csv")

cat("\n-- (3) production C3 floor maps vs identity on the OOS fold predictions (all folds pooled) --\n")
for (iso in c("CIV", "GMB", "TGO", "UGA")) {
     tt <- oos_tab[iso_code == iso]
     mp <- list(A = rec[iso_code == iso, A_prod], B = rec[iso_code == iso, B_prod])
     s0 <- score_psi(apply_map(tt$pred, mp), tt$intensity); s1 <- score_psi(tt$pred, tt$intensity)
     cat(sprintf("%s n=%d pos=%d AUC=%.3f | floor map: Brier %.4f BCE %.4f pearson %.3f calslope %.2f lvl %.2f mean %.3f | identity: Brier %.4f BCE %.4f pearson %.3f calslope %.2f lvl %.2f mean %.3f\n",
                 iso, s0$n, s0$n_pos, s0$auc, s0$brier, s0$bce, s0$pearson, s0$cal_slope, s0$lvl_bias_outbreak, s0$mean_psi,
                 s1$brier, s1$bce, s1$pearson, s1$cal_slope, s1$lvl_bias_outbreak, s1$mean_psi))
}
cat("\n-- UGA in-sample (2018+): production floor map vs identity --\n")
s <- is_tab[iso_code == "UGA"]
for (nm in c("floor", "identity")) {
     p <- if (nm == "floor") s$psi else s$pred_smooth
     sc <- score_psi(p, s$intensity)
     cat(sprintf("UGA %-8s Brier %.4f BCE %.4f pearson %.3f calslope %.2f lvl %.2f mean %.3f p95/p5 %.1f\n", nm, sc$brier, sc$bce, sc$pearson, sc$cal_slope, sc$lvl_bias_outbreak, sc$mean_psi, sc$p95_p5))
}
