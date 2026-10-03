# Before (C3, shipped in config_default v6.1) / after (v0.102.0 re-application) for every
# country whose psi changes, plus the v0.100.1 psi as a reference.
suppressMessages({library(data.table)})
st  <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi"
c3d <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi/C3"
v0d <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/rebuild_stage2/psi_10seed"
rd <- function(f) fread(f)[, date := as.IDate(date)]
old <- rd(file.path(c3d, "pred_psi_suitability_day.csv")); new <- rd(file.path(st, "pred_psi_suitability_day.csv"))
v0  <- rd(file.path(v0d, "pred_psi_suitability_day.csv"))
obs <- rd(file.path(c3d, "data_psi_suitability.csv"))
changed <- new[old, on = c("iso_code", "date")][, .(changed = any(psi != i.psi)), by = iso_code][changed == TRUE, iso_code]
cat("countries whose psi changes:", changed, "\n")
stopifnot(identical(sort(changed), c("CIV", "GMB", "TGO", "UGA")))

CUT <- as.IDate("2026-09-17"); W0 <- as.IDate("2023-01-01"); HZN <- as.IDate("2027-04-29")
auc <- function(s, y) { y <- as.integer(y); n1 <- sum(y == 1); n0 <- sum(y == 0); r <- rank(s); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
summ <- function(d, lab) {
     d <- d[iso_code %in% changed]
     a <- d[, .(mean_all = mean(psi), maxmin_all = max(psi) / min(psi),
                mean_cfg = mean(psi[date >= W0 & date <= HZN]), min_cfg = min(psi[date >= W0 & date <= HZN]),
                max_cfg = max(psi[date >= W0 & date <= HZN]),
                maxmin_cfg = max(psi[date >= W0 & date <= HZN]) / min(psi[date >= W0 & date <= HZN])), by = iso_code]
     t <- merge(d[, .(iso_code, date, psi)], obs[, .(iso_code, date, intensity)], by = c("iso_code", "date"))[date <= CUT & !is.na(intensity)]
     b <- t[, .(n_wk = .N, n_pos = sum(intensity > 0), r_target = cor(psi, intensity),
                rho_target = cor(psi, intensity, method = "spearman"), auc = auc(psi, intensity > 0)), by = iso_code]
     out <- merge(a, b, by = "iso_code"); setnames(out, -1, paste0(names(out)[-1], "_", lab)); out
}
tab <- Reduce(function(x, y) merge(x, y, by = "iso_code"), list(summ(old, "C3"), summ(new, "new"), summ(v0, "v0100")))

# engine-facing psi* with the psi_star prior means (as in the v0.101 validation, section 7)
suppressMessages(pkgload::load_all("/Users/johngiles/MOSAIC/MOSAIC-pkg/.claude/worktrees/v0102", quiet = TRUE, export_all = FALSE))
e <- new.env(); load("/Users/johngiles/MOSAIC/MOSAIC-pkg/.claude/worktrees/v0102/data/config_default.rda", envir = e); cfg <- e$config_default
pz <- list(a = 1, b = 1, z = 2/3, k = 0)
eng <- function(d, lab) d[iso_code %in% changed & date >= W0 & date <= HZN, {
     ps <- calc_psi_star(psi[order(date)], a = pz$a, b = pz$b, z = pz$z, k = pz$k)
     f  <- pbeta(ps, cfg$decay_shape_1, cfg$decay_shape_2)
     .(psistar_mean = mean(ps), betaenv_p95_p5 = unname(quantile(ps, .95) / quantile(ps, .05)),
       surv_days = mean(cfg$decay_days_short + f * (cfg$decay_days_long - cfg$decay_days_short)))
}, by = iso_code][, setnames(.SD, -1, paste0(names(.SD)[-1], "_", lab))]
tab <- Reduce(function(x, y) merge(x, y, by = "iso_code"), list(tab, eng(old, "C3"), eng(new, "new"), eng(v0, "v0100")))
fwrite(tab, file.path(st, "work", "before_after_changed_countries.csv"))
options(width = 250)
p <- function(x, d = 3) formatC(x, digits = d, format = "fg", flag = "#")
cat("\n2018-01-01..2027-04-29 (file window) and 2023-01-01..2027-04-29 (config window); target correlation over observed weeks 2018-01-01..2026-09-17\n")
for (i in seq_len(nrow(tab))) with(tab[i], cat(sprintf(
     "%s | mean(2018+) %s -> %s | max/min(2018+) %s -> %s | cfg-window mean %s -> %s, range [%s, %s] -> [%s, %s], max/min %s -> %s (v0.100.1 %s) | r(psi,target) %s -> %s | spearman %s = %s | AUC %s | psi* mean %s -> %s (v0.100.1 %s) | psi* p95/p5 %s -> %s | survival d %.1f -> %.1f\n",
     iso_code, p(mean_all_C3), p(mean_all_new), p(maxmin_all_C3), p(maxmin_all_new), p(mean_cfg_C3), p(mean_cfg_new),
     p(min_cfg_C3), p(max_cfg_C3), p(min_cfg_new), p(max_cfg_new), p(maxmin_cfg_C3), p(maxmin_cfg_new), p(maxmin_cfg_v0100),
     p(r_target_C3), p(r_target_new), p(rho_target_C3), p(rho_target_new), p(auc_new), p(psistar_mean_C3), p(psistar_mean_new),
     p(psistar_mean_v0100), p(betaenv_p95_p5_C3), p(betaenv_p95_p5_new), surv_days_C3, surv_days_new)))
