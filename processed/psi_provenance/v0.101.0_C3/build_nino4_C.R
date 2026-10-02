# Panel C ENSO input: replace the Aug-Sep 2026 Nino4 (ENSO4) gap-fill dip with
# NOAA-consistent values and write an alternative enso_weekly.csv (only ENSO4 rows
# in the affected ISO weeks change; every other variable/row is byte-identical).
#
# Mechanism being undone (enso-data 3729c87, compile_noaa_nmme.py): monthly values
# are anchored on the 1st of the month with priority NOAA historical > BOM observed
# > NMME forecast, then linearly interpolated by day (value_adj = NOAA-baselined).
# NOAA PSL Nino4 ends 2026-08 (1.29, snapshot 2026-09-07; no NOAA Sep in the
# checkout), so the 2026-09-01 anchor fell to BOM's RELATIVE Nino4 (rnino_4, Sep
# 0.21 -> value_adj 0.49 after a single +0.37 mean-bias shift), while 2026-10-01 is
# NMME (2.13). In 2026 NOAA-minus-BOM-relative is +0.86/+1.01/+0.94 (Jun/Jul/Aug),
# so the constant shift leaves the Sep anchor ~1 degC low -> a V-shaped dip.
# NOAA-consistent replacement: the anchor the same compile produces from its
# next-priority source (NMME ENSMEAN, current + 36 past issues, NOAA-baselined with
# enso-data's own apply_baseline_correction_to_dataframe; reproduction validated
# exactly on all 8 published forecast anchors 2026-10..2027-05):
#   2026-08-01 = 1.29 (NOAA), 2026-09-01 = 1.8762091049382714 (NMME counterfactual),
#   2026-10-01 = 2.129681327160494 (NMME, as published).
ST  <- "/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0101_rebuild/psi"
SRC <- "/Users/johngiles/MOSAIC/MOSAIC-data/processed/ENSO"
OUT <- file.path(ST, "nino4", "enso_C"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
suppressMessages(library(data.table))

dly <- fread(file.path(SRC, "enso_daily.csv"))
wk  <- fread(file.path(SRC, "enso_weekly.csv"))
wk_raw <- readLines(file.path(SRC, "enso_weekly.csv"))
dly[, date := as.IDate(date)]

e4 <- dly[variable == "ENSO4", .(date, value)]
iso_key <- function(d) list(iso_year = as.integer(format(d, "%G")), iso_week = as.integer(format(d, "%V")))
agg <- function(x) x[, c(iso_key(date), list(v = value))][, .(value = round(mean(v), 2)), by = .(iso_year, iso_week)]

# 1. Validate the aggregation against the published weekly (unmodified data).
w0 <- merge(agg(e4), wk[variable == "ENSO4", .(iso_year = year, iso_week = week, pub = value)],
            by = c("iso_year", "iso_week"))
cat("aggregation check: ENSO4 weeks", nrow(w0), " max|reproduced - published|",
    max(abs(w0$value - w0$pub)), " n mismatched", sum(abs(w0$value - w0$pub) > 1e-9), "\n")
print(w0[abs(value - pub) > 1e-9])   # the single R-vs-numpy rounding tie (2027-W17, mean exactly 1.395), outside the edited weeks
stopifnot(max(abs(w0$value - w0$pub)) < 0.0100001)

# 2. Re-interpolate the two affected monthly segments through the new Sep-01 anchor.
anch <- data.table(date  = as.IDate(c("2026-08-01", "2026-09-01", "2026-10-01")),
                   value = c(1.29, 1.8762091049382714, 2.129681327160494))
seg  <- e4$date >= anch$date[1] & e4$date <= anch$date[3]
e4C  <- copy(e4)
e4C[seg, value := round(approx(as.numeric(anch$date), anch$value, xout = as.numeric(date))$y, 2)]
cat("daily rows re-interpolated:", sum(seg), " (", format(min(e4C$date[seg])), "..", format(max(e4C$date[seg])), ")\n")
stopifnot(all(e4C$value[!seg] == e4$value[!seg]))

# 3. Weekly: replace only weeks whose daily values changed.
wA <- agg(e4); wC <- agg(e4C)
chg <- merge(wA, wC, by = c("iso_year", "iso_week"), suffixes = c("_A", "_C"))[value_A != value_C]
cat("ENSO4 weeks changed:", nrow(chg), "\n"); print(chg)
# Edit a base read.csv copy so utils::write.csv reproduces the canonical file's
# quoting byte-for-byte on every untouched line.
wkC <- utils::read.csv(file.path(SRC, "enso_weekly.csv"), stringsAsFactors = FALSE)
for (i in seq_len(nrow(chg))) {
  r <- wkC$variable == "ENSO4" & wkC$year == chg$iso_year[i] & wkC$week == chg$iso_week[i]
  stopifnot(sum(r) == 1L)
  wkC$value[r] <- chg$value_C[i]
}
stopifnot(sum(wkC$value != wk$value) == nrow(chg))

# Monthly means (documentation): Aug/Sep 2026 under A and C.
mm <- function(x) x[format(date, "%Y-%m") %in% c("2026-07", "2026-08", "2026-09", "2026-10"),
                    .(mean = round(mean(value), 2)), by = .(month = format(date, "%Y-%m"))]
cat("ENSO4 monthly means A (published):\n"); print(mm(e4))
cat("ENSO4 monthly means C (NOAA-consistent):\n"); print(mm(e4C))

# Write the C weekly with the same quoting/format as process_enso_data (utils::write.csv).
utils::write.csv(wkC, file.path(OUT, "enso_weekly.csv"), row.names = FALSE)
new_raw <- readLines(file.path(OUT, "enso_weekly.csv"))
cat("lines differing from canonical enso_weekly.csv:", sum(new_raw != wk_raw), "of", length(wk_raw), "\n")
print(cbind(A = wk_raw[new_raw != wk_raw], C = new_raw[new_raw != wk_raw]))
stopifnot(sum(new_raw != wk_raw) == nrow(chg))
fwrite(chg, file.path(ST, "nino4", "enso4_weeks_changed.csv"))
fwrite(rbind(e4[seg][, variant := "A_published"], e4C[seg][, variant := "C_noaa_consistent"]),
       file.path(ST, "nino4", "enso4_daily_aug_sep_2026_A_vs_C.csv"))
cat("canonical md5", unname(tools::md5sum(file.path(SRC, "enso_weekly.csv"))),
    " C md5", unname(tools::md5sum(file.path(OUT, "enso_weekly.csv"))), "\n")
