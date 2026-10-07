# Compare psi D (refreshed surveillance) with C3 (shipped) and with replicate DB (keras noise floor).
rd <- function(f) { x <- read.csv(f)[, c("iso_code", "date", "psi")]; x$date <- as.Date(x$date); x }
C3 <- rd("claude/psi_v110/C3_recorrected_day.csv"); D <- rd("claude/psi_v110/D/pred_psi_suitability_day.csv"); DB <- rd("claude/psi_v110/DB/pred_psi_suitability_day.csv")
cat("date ranges: C3", format(range(C3$date)), "| D", format(range(D$date)), "\n")
m <- Reduce(function(a, b) merge(a, b, by = c("iso_code", "date")), list(setNames(C3, c("iso_code", "date", "c3")), setNames(D, c("iso_code", "date", "d")), setNames(DB, c("iso_code", "date", "db"))))
m <- m[m$date >= as.Date("2023-01-01"), ]
s <- do.call(rbind, lapply(split(m, m$iso_code), function(x) data.frame(iso = x$iso_code[1],
  r_D_C3 = cor(x$d, x$c3), mad_D_C3 = mean(abs(x$d - x$c3)), r_D_DB = cor(x$d, x$db), mad_D_DB = mean(abs(x$d - x$db)),
  mean_C3 = mean(x$c3), mean_D = mean(x$d),
  c3_2026 = mean(x$c3[format(x$date, "%Y") == "2026"]), d_2026 = mean(x$d[format(x$date, "%Y") == "2026"]), db_2026 = mean(x$db[format(x$date, "%Y") == "2026"]))))
cat(sprintf("2023+ median per-country: r(D,C3) %.3f mean|diff| %.3f  ||  noise floor r(D,DB) %.3f mean|diff| %.3f\n",
            median(s$r_D_C3), median(s$mad_D_C3), median(s$r_D_DB), median(s$mad_D_DB)))
s$beyond_noise <- s$mad_D_C3 > 2 * s$mad_D_DB
options(width = 200); print(s[order(-s$mad_D_C3), ], digits = 3, row.names = FALSE)
write.csv(s, "claude/psi_v110/compare_D_vs_C3.csv", row.names = FALSE)
x <- m[m$iso_code == "SOM", ]; mo <- format(x$date, "%Y-%m"); k <- mo >= "2025-10" & mo <= "2027-04"
cat("\nSOM monthly psi (C3 / D / DB):\n"); print(round(cbind(C3 = tapply(x$c3[k], mo[k], mean), D = tapply(x$d[k], mo[k], mean), DB = tapply(x$db[k], mo[k], mean)), 2))
