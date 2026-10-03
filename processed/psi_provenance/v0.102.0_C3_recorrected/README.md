# Provenance of the psi behind config_default v6.2 (MOSAIC v0.102.0)

This directory records how the environmental-suitability series psi in MOSAIC's `config_default` v6.2 (`psi_jt`, MOSAIC v0.102.0) was produced.

The psi is the production C3 fit, documented in `../v0.101.0_C3/`. Its per-country bias correction was re-applied under the v0.102.0 rule of `calibrate_psi_predictions()`. **No model was retrained.**

- `pred_raw`, `pred_smooth` and the quantile columns are C3's, byte for byte.
- Only `psi` and `pred_bias_corrected` change, and only for **CIV, GMB, TGO and UGA**.
- The 36 other countries are byte-identical to C3.

The psi outputs are committed in MOSAIC-pkg `model/input/`:

| file | md5 |
|---|---|
| `pred_psi_suitability_day.csv` (the source of `psi_jt`) | `eac62fb99bf04c1dd8ff547388a0c1b1` |
| `pred_psi_suitability_week.csv` | `617c34f67f2b6e8b1e2ade6be445b276` |
| `psi_suitability_config.json` (slim manifest, with a `bias_correction_reapplied` record) | `a8ef948cd3fb69d16d6762ddb6050597` |
| `data_psi_suitability.csv` (gitignored, unchanged from C3) | `1f1388641bfa8fea0fbf5f10305f1681` |

`config_default` v6.2 was built from that day file by `data-raw/make_config_default.R`:
- **rda** `2fa0f56ba201d27ce26169b24385ead2`;
- **json** `b9d7fecaaa61c5def993c8f4ef827efc`;
- **two builds** were byte-identical;
- **independent check:** reproduced exactly from a clean `git archive` of MOSAIC-pkg `d50d46f59` by the release red team.

## The rule (MOSAIC-pkg `1e4a1f149`)

A per-country logit-affine correction whose output logit-sd would fall below `amp_range[1]` (0.5) times its input's is not applied. That country takes the identity map, `psi = pred_bias_corrected = pred_smooth`, with status `"collapsed"`.

The corrected series is affine in the input, so the output/input sd ratio is the clamped slope itself. The rule is therefore exactly "clamped slope < 0.5".

## Files

| file | content |
|---|---|
| `PROVENANCE.md` | the re-application record: method, verification, before/after table, caveats (written 2026-10-03) |
| `MD5SUMS.txt` | md5 of the four staged outputs |
| `work/13_reapply_C3.R` | the re-application: map recovery, floor classification, text-level rewrite |
| `work/11_old_vs_new.R` | v0.101.0 vs v0.102.0 function on identical inputs, all 40 countries |
| `work/16_package_check.R` | MOSAIC 0.102.0 end-to-end on the countries whose whole fit set is in the stored window |
| `work/07_amplitude.R`, `work/amplitude_by_country.csv` | amplitude calibration and slope identifiability |
| `work/14_before_after.R`, `work/before_after_changed_countries.csv` | before/after metrics for the four changed countries |
| `work/rules.R` | the candidate rules compared |

The scripts are kept exactly as run. Their absolute paths point at the laptop scratch tree of the time:
- `MOSAIC-pkg/claude/v0101_rebuild/psi/C3`, the C3 run, whose provenance is in `../v0.101.0_C3/`;
- `MOSAIC-pkg/claude/v0102_psi`;
- the `.claude/worktrees/v0102` worktree of branch `fix/v0102-sparse`.

## Known caveats (release red team, 2026-10-03)

- **The floor is a slope cutoff, not an identification test.** The four floor countries have outbreak-week slope t-values of −2.14, −0.21, 0.80 and 1.65; every fitted country has t ≥ 3.42 (TCD). So on C3 the rule picks exactly the countries whose slope is unidentified.
  - The rule itself does not test identification.
  - Its output jumps at the cutoff: a probe with true slope 0.49 vs 0.51 gives a 2.9x difference in mean psi.
- **TGO is threshold-borderline.**
  - TGO's C3 map (0.501085, 0.624475) is a blended unclamped OLS fit, not a guard-constant map.
  - Across the seven 2026 refits its slope was 0.50–0.77, and its outbreak-week slope is unidentified in all of them (t ≈ 0.8). Only C3 falls below 0.5.
  - Its v6.2 level (mean psi 0.256 → 0.068) is therefore decided by replicate noise.
- **The v0.101.0 maps of CIV, GMB and UGA came from the guard constants.**
  - CIV and GMB: (0.505, −2.64) = 0.66 × (0.25, −4).
  - UGA: slope clamped at 0.25, offset from the data.
  - The PROVENANCE.md sentence that the old floor map "came from the guard constants" is correct for those three, not for TGO.
- **CIV's own LSTM output sits at the 0.01 ensemble clamp** on 25–86% of days in each year from 2018 to 2023, and on 67% of 2023 days. The re-correction restores its 2024–2026 excursions only.
- **Follow-ups for the next release:**
  - an identification-based criterion (identity when the outbreak-week t is below about 2, or precision-weighted shrinkage of slope toward 1 and offset toward 0);
  - persisting `calibration_diagnostics` in the manifest (they are dropped at `R/run_rolling_cv_suitability.R:485`).
