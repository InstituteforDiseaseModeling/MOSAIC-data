"""Counterfactual Sep-2026 Nino4 anchor for the enso-data NMME compile (read-only).

Reproduces enso-data 3729c87 compile_noaa_nmme.combine_enso_data()'s baseline
correction for ENSO4 'forecast' rows (current NMME issue + the 36 most recent
past issues, grouped by target date, minus the mean NMME-minus-NOAA bias over
their overlap), using enso-data's own apply_baseline_correction_to_dataframe.
The compile kept BOM's *relative* Nino4 (rnino_4) as the 2026-09-01 anchor
(priority observed > forecast); this prints what the anchor would have been
from the next-priority source (NMME), and validates the reproduction against
the published forecast anchors (2026-10-01 .. 2027-05-01) in the compiled daily.
Run from the enso-data repo root with PYTHONDONTWRITEBYTECODE=1 (writes nothing there).
"""
import sys
from pathlib import Path
import pandas as pd

sys.path.insert(0, "src")
from enso.utils.adjust_enso_baseline import apply_baseline_correction_to_dataframe  # noqa: E402

NOAA = Path("downloads/noaa/2026/2026-09-07/processed/noaa_enso_historical.csv")
CUR = Path("downloads/nmme/2026/2026-09-08/processed/nmme_indices.csv")
DAILY = Path("downloads/nmme/2026/2026-09-08/compiled/compiled_ENSO_NMME_daily.csv")
BIAS_REFERENCE_ISSUES = 36

noaa = pd.read_csv(NOAA)
noaa["value"] = pd.to_numeric(noaa["value"], errors="coerce")
noaa = noaa.dropna(subset=["value"])
noaa = noaa[noaa["variable"] == "ENSO4"].assign(data_source="historical")

past = sorted(Path("downloads/nmme").glob("*/*/processed/nmme_indices.csv"))
past = [f for f in past if f != CUR][-BIAS_REFERENCE_ISSUES:]
fc = pd.concat([pd.read_csv(f) for f in [CUR] + past], ignore_index=True)
fc = fc[fc["variable"] == "ENSO4"].assign(data_source="forecast")

df = pd.concat([d[["year", "month", "variable", "value", "data_source"]] for d in (noaa, fc)],
               ignore_index=True)
df["date"] = pd.to_datetime(df[["year", "month"]].assign(day=1))
df = df[df["year"] >= 1970]
out = apply_baseline_correction_to_dataframe(df, historical_source="historical",
                                             forecast_sources=["forecast"])
fadj = out[out["data_source"] == "forecast"].groupby("date")["value_adj"].first()

daily = pd.read_csv(DAILY, parse_dates=["date"])
daily = daily[daily["variable"] == "ENSO4"].set_index("date")
print(f"issues used: current {CUR.parent.parent.name} + {len(past)} past "
      f"({past[0].parent.parent.name} .. {past[-1].parent.parent.name})")
print("validation (reproduced forecast value_adj vs published compiled daily, rounded 2dp):")
ok = True
for d in pd.date_range("2026-10-01", "2027-05-01", freq="MS"):
    pub = daily.loc[d, "value_adj"]
    rep = round(float(fadj.loc[d]), 2)
    ok &= abs(rep - pub) < 1e-9
    print(f"  {d:%Y-%m-%d}  reproduced {rep:+.2f}  published {pub:+.2f}  {'OK' if abs(rep - pub) < 1e-9 else 'MISMATCH'}")
print("ALL_MATCH", ok)
sep = pd.Timestamp("2026-09-01")
print(f"NOAA 2026-08-01 anchor (historical): {noaa.set_index('date' if 'date' in noaa else noaa.index).shape and float(df[(df.data_source=='historical') & (df.date==pd.Timestamp('2026-08-01'))]['value'].iloc[0]):+.4f}")
print(f"NMME counterfactual 2026-09-01 anchor value_adj: {float(fadj.loc[sep]):+.4f} "
      f"(issue-mean raw {fc[(fc.year==2026)&(fc.month==9)]['value'].mean():+.4f}, "
      f"n_issues {int(((fc.year==2026)&(fc.month==9)).sum())})")
print(f"published 2026-09-01 anchor (BOM relative, value_adj): {daily.loc[sep, 'value_adj']:+.2f} "
      f"(value_org {daily.loc[sep, 'value_org']:+.2f})")
