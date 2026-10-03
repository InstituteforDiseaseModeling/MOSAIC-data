# v0.102.0 production psi: C3 re-corrected under the v0.102.0 collapse rule

Laptop: `/Users/johngiles/MOSAIC/MOSAIC-pkg/claude/v0102_psi/` (gitignored scratch). Written 2026-10-03.

**This is C3, the psi baked into config_default v6.1 (MOSAIC 0.101.0), with the bias correction re-applied under the v0.102.0 rule.**
- No LSTM was retrained, and no dugong run was made.
- `pred_raw`, `pred_smooth` and the q* columns are C3's, byte for byte.
- Only `psi` and `pred_bias_corrected` change, and only for CIV, GMB, TGO and UGA.

## Rule (MOSAIC-pkg `fix/v0102-sparse`, commit `1e4a1f14964d55db45b2d1a60cd39dba015e6c75`)

`calibrate_psi_predictions()` does not apply a per-country fit whose corrected logit-sd would fall below `amp_range[1]` (0.5) times the input's. The country falls back to identity: `psi = pred_bias_corrected = pred_smooth`, with status `"collapsed"`.

Up to v0.101.0 such a fit was blended toward identity until it reached the 0.5x floor. That map came from the guard constants:
- The slope was clamped to 0.25 while the OLS intercept was kept, then clamped to ±4.
- The 0.02-grid blend then landed at w = 0.66, giving logit-slope 0.505.

The ceiling (2x) blend and the slope/offset clamps are unchanged.

## Inputs

C3 is documented in `claude/v0101_rebuild/psi/README.md` §9, with its provenance bundle in `C3/provenance/`.

| file | md5 |
|---|---|
| `C3/pred_psi_suitability_day.csv` | `d0eb1e2da04c24a8b2cbf43d548c0413` |
| `C3/pred_psi_suitability_week.csv` | `6a0f85cd17b2d4cecf3bf026b1807b82` |
| `C3/data_psi_suitability.csv` | `1f1388641bfa8fea0fbf5f10305f1681` |
| `C3/psi_suitability_config.json` (slim) | `e098f115724b4c0cd183cd051e0c6083` |

## Outputs (`MD5SUMS.txt`)

| file | md5 | note |
|---|---|---|
| `pred_psi_suitability_day.csv` | `eac62fb99bf04c1dd8ff547388a0c1b1` | 136,240 rows; the 122,617 rows of the 36 unchanged countries are byte-identical to C3 |
| `pred_psi_suitability_week.csv` | `617c34f67f2b6e8b1e2ade6be445b276` | 19,400 rows; 17,461 byte-identical |
| `data_psi_suitability.csv` | `1f1388641bfa8fea0fbf5f10305f1681` | unchanged copy of C3's |
| `psi_suitability_config.json` | `a8ef948cd3fb69d16d6762ddb6050597` | C3's slim manifest; every field round-trips unchanged, plus a `bias_correction_reapplied` record (rule, collapsed countries, their C3 maps, source md5s, code commit) |

## Method (`work/13_reapply_C3.R`)

1. **Recover each country's map.** The C3 map logit(psi) = A·logit(pred_smooth) + B is recovered exactly from the day file (max |resid| 2.7e-11).
2. **Decide which maps sat on the floor.** C3 did not save its per-country diagnostics, and the fit used outbreak weeks from 2015-03 onward while the day file starts on 2018-01-01. The decision therefore uses the run's own guard counter.
   - A map can be "guarded" only by a clamp value (slope 0.25 or 4, offset ±4) or by an amplitude blend (A in the 0.02-grid neighbourhood of 0.5 or 2).
   - There are 4 floor candidates (CIV, GMB, TGO, UGA) and 5 ceiling candidates (BFA, CAF, LBR, SWZ, ZAF). Together they equal the 9 guarded fits in `C3/run_psi.log`.
   - No floor candidate carries a clamp value, so each of the four was guarded by the floor blend.
   - TGO (A = 0.501) is the case that needs this argument; CIV, GMB and UGA sit exactly on the w = 0.66 grid point (A = 0.505).
3. **Rewrite at the text level.** For the four countries, the `psi` and `pred_bias_corrected` fields are replaced by the row's own `pred_smooth` field, which is exactly what the package writes for an identity country. Every other line is copied unchanged.

## Verification

- **Byte-level:** unchanged countries are byte-identical in the day and week files. In changed rows only the two fields differ, and both equal `pred_smooth`.
- **Parsed:** unchanged countries are `identical()` to C3. For the four, `psi == pred_bias_corrected == pred_smooth` exactly. The week file equals the day file on its dates.
- **Package end-to-end:** MOSAIC 0.102.0 was run on the six countries whose whole fit set is in the stored window (`work/16_package_check.R`).
  - GMB is "collapsed" and bit-identical to the staged psi; SLE (identity) is bit-identical.
  - BFA, MLI, RWA and ZAF agree to 2.1e-15, which is `lm` row-order rounding; the staged file keeps C3's bytes for them.
- **Old vs new function on identical inputs** (all 40 countries, stored window; `work/11_old_vs_new.R`): the 37 countries with unchanged status are bit-identical, and the collapsing ones equal their input.

## Changed countries (`work/before_after_changed_countries.csv`)

Columns:
- **Mean, range and max/min:** config window 2023-01-01..2027-04-29.
- **r:** Pearson correlation of psi with the target (`target_D`) over observed weeks, 2018-01-01..2026-09-17.
- **psi\*:** engine-facing psi* at the prior means (a = 1, b = 1, z = 2/3, k = 0), as in the v0.101 validation.

| iso | mean C3 → new | range C3 → new | max/min C3 → new (v0.100.1) | r C3 → new | psi\* mean C3 → new (v0.100.1) |
|---|---|---|---|---|---|
| CIV | 0.0106 → 0.0291 | [0.0070, 0.042] → [0.010, 0.278] | 6.1 → 27.8 (25.3) | −0.035 → −0.029 | 0.028 → 0.070 (0.407) |
| GMB | 0.0070 → 0.0102 | [0.0070, 0.0093] → [0.010, 0.018] | 1.3 → 1.8 (1.0) | −0.195 → −0.192 | 0.019 → 0.027 (0.019) |
| TGO | 0.256 → 0.068 | [0.157, 0.665] → [0.010, 0.530] | 4.2 → 53.0 (138) | 0.537 → 0.517 | 0.458 → 0.131 (0.182) |
| UGA | 0.091 → 0.123 | [0.035, 0.280] → [0.015, 0.631] | 8.1 → 41.7 (21.1) | 0.343 → 0.332 | 0.206 → 0.237 (0.244) |

The rank information (Spearman, AUC) is unchanged up to floating-point ties, because both maps are monotone.

## Caveats

- **TGO is threshold-borderline.**
  - TGO was floor-clamped only in C3. In the other six 2026 refits it was a fit, at slope 0.55-0.77; its outbreak-week slope is unidentified in all of them (t of about 0.8).
  - Under the new rule its level depends on which side of the floor a run lands. C3/C3B mean ratio over 2023+ goes from 0.95 to 0.25.
  - CIV and UGA were on the floor in all seven refits. GMB becomes stable (0.68 → 0.99).
- **CIV's own LSTM output sits at the 0.01 ensemble clamp for all of 2018-2023.** The new psi restores only the 2024-2026 excursions (maximum 0.15 / 0.21 / 0.28); 2025 brackets the July outbreak.
  - CIV's in-sample signal is nil (AUC 0.37); out of sample it is 0.66 on 17 outbreak weeks.
- **psi remains a weak signal.**
  - Out of sample the LSTM is about 3x over-dispersed: the median all-weeks calibration slope is 0.34.
  - Where the per-country correction is a genuine fit, identity scores better than the correction out of sample (`work/09_flattening_check.R`).
  - The correction's OOS value is unproven; that is a separate follow-up.
- **Bake via `make_config_default()` pointed at this `pred_psi_suitability_day.csv`.** Do not inject psi_jt by hand. The config v6.2 rebuild is the coordinator's.

## Evidence scripts (`work/`)

| script | what it does |
|---|---|
| `rules.R` | candidate rules and scores |
| `04` | map recovery and exact package reproduction |
| `05` / `05a` | in-sample evidence; replica validated against the package to 2.2e-16 |
| `06`, `08`, `09` | forward-chaining OOS on the full-manifest fold predictions, country-clustered bootstrap, flattening check |
| `07` | amplitude calibration and slope identifiability |
| `10` | replicate stability |
| `13` | this re-application |
| `14` | before/after |
| `16` | package end-to-end check |
