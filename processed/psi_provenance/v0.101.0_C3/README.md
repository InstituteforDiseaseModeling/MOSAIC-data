# Provenance of the production psi "C3" (MOSAIC v0.101.0, config_default v6.1)

This directory records how the environmental-suitability series psi in MOSAIC's
`config_default` v6.1 (`psi_jt`, MOSAIC v0.101.0) was produced, so that it can be
audited and rebuilt.

The psi outputs themselves are committed in MOSAIC-pkg `model/input/`:

| file | md5 |
|---|---|
| `pred_psi_suitability_day.csv` (the source of `psi_jt`) | `d0eb1e2da04c24a8b2cbf43d548c0413` |
| `pred_psi_suitability_week.csv` | `6a0f85cd17b2d4cecf3bf026b1807b82` |
| `psi_suitability_config.json` (slim manifest) | `e098f115724b4c0cd183cd051e0c6083` |
| `data_psi_suitability.csv` (gitignored, local only) | `1f1388641bfa8fea0fbf5f10305f1681` |

The slim manifest differs from the run's full manifest only in that
`rw_diagnostics$*$fold_predictions` was removed. The full manifest is 24.2 MB, md5
`260c6cd137bd49079935d270884d19bf`, and is not committed.

## The fit

- **Function:** `est_suitability()`.
- **Model:** `architecture = "lstm_v2_hierarchical_film"`, `feature_set = "v7.3"`,
  `response_var = "target_D_rate_per_country_floored"`, `bias_correct = TRUE`, confidence
  weights on.
- **Seeds:** 10 seeds, 11, 22, ..., 110 (`arch_control = list(n_seeds = 10, region_map =
  "snf_k5", parallel_seeds = 10, seed_base = 11)`), aggregated by cross-seed median on the
  logit scale.
- **Windows:** fit 2015-01-01 to 2026-09-17; predictions 2018-01-01 to 2027-04-29.
- **Rolling CV:** 12 steps (4-week gap, 1-month step, 5-month test).
- **Where it ran:** on dugong with MOSAIC 0.100.1 @ `14433d85144ae2f924c28bf093161c708b247265`
  (R 4.5.2, TensorFlow 2.20.0, keras3 1.5.1). The `est_suitability()` code path is
  byte-identical to that of MOSAIC-pkg `fix/v0101-trust`, which was checked mechanically
  (PROVENANCE.md section 4).
- **Replicate:** C3B used the disjoint seeds 121..220 and agrees with C3 over 2023+ at a
  median per-country r of 0.972 and a median mean |diff| of 0.024. This is the tightest of the
  three production replicate pairs (the earlier pairs gave 0.968 / 0.029 and 0.967 / 0.028).
- **Reproducibility:** the fit reproduces statistically, not bitwise, because keras recurrent
  dropout is non-deterministic. The panel rebuilds bitwise.

## The panel the fit was trained on (not committed)

The panel is "panel C-trust round 2": `cholera_country_weekly_suitability_data.csv`, md5
`2c575f8c3ea05273d33b0280b5c9c7d5`, 227,756,944 bytes, 56,840 rows x 300 columns. It is
gitignored here (`*suitability_data.csv`) and regenerable.

- **Compiled by:** `compile_panel.R` in this directory, which calls
  `compile_suitability_data(PATHS, cutoff = NULL, use_epidemic_peaks = TRUE,
  date_start = "2000-01-01", date_stop = NULL, forecast_mode = TRUE, forecast_horizon = 9,
  include_lags = TRUE)`.
- **Code:** MOSAIC-pkg `fix/v0101-trust` @ `b65cee1626c59f86e5b63ce5320227c0687a6767`.
- **Inputs:** MOSAIC-data @ `04a6d0f64863f8c59279f8f78faf9ab48725cd21`, with `DATA_ENSO` pointed
  at `enso_C/` (below). A bitwise rebuild is logged in `compile_panel_C_rebuild_check.log`.
- **The release panel differs in two cells.** The release panel, built on MOSAIC-data
  `922ef89db984a0bf73fb043915c8526eaf296cca` from MOSAIC-pkg `595951bfc`, is md5
  `5e1e2498135cfc1083e69722336ce095`. It differs from the training panel only in two ZAF 2023
  `deaths` cells, a column psi never reads (PROVENANCE.md section 6). So C3 stands for the
  release panel.

## Why a variant ENSO input: the Nino4 NMME gap-fill

`enso_C/enso_weekly.csv` (md5 `7805ecfe8513c0d328e5726d49d14d58`) is the canonical
`processed/ENSO/enso_weekly.csv` (enso-data `3729c87`, md5 `51dbed25...`) with 10 weekly ENSO4
values replaced, 2026-W31 to W40. Every other line is byte-identical.

**The problem in the canonical compile.** enso-data's compile anchors each month on its first
day, taking the value from NOAA PSL, then BOM observed, then the NMME forecast, and interpolates
by day between anchors.
- NOAA PSL Nino4 ends in August 2026, so the 1 September 2026 anchor fell to BOM.
- BOM's `rnino_4` is a *relative* index: the tropical-mean anomaly is removed. In 2026 it ran
  0.86-1.01 below NOAA, while the compile's constant bias shift was only +0.37.
- The September anchor therefore came out at 0.49, between NOAA's 1.29 for August and NMME's
  2.13 for October. That produced a spurious V-shaped dip in ENSO4 over August-September 2026.
- The dip feeds the LSTM's ENSO4 features and their lags, and the flood GAM.

**The fix.** The variant uses, for that one anchor, the next source in the compile's own
priority: the NMME ensemble mean, baselined to NOAA by enso-data's own correction.
- That anchor is 1.8762. `nmme_gapfill_anchor.py` re-derives it read-only from the enso-data
  checkout, and also reproduces all 8 published NMME anchors.
- `build_nino4_C.R` writes the file.

**Check against observations.** The check was not an input to the variant. NOAA CPC weekly
OISST gives a flat Nino4 of about 0.8-1.1 through August-September 2026, with no dip and no
ramp. A truth proxy was built from those observations with the pipeline's own interpolation.
Against it, the variant's weekly ENSO4 mean absolute error is 0.28-0.34, and the canonical
compile's is 0.41-0.47. The variant is closer to observations, though it over-corrects.

The variant's weekly ENSO4 equals that of the v0.100.1 panel, which was compiled before BOM's
September value existed.

## Contents

| file | what |
|---|---|
| `PROVENANCE.md` | full provenance: outputs, panel, ENSO input, fit, release-panel addendum |
| `MD5SUMS.txt` | md5 of every file in the bundle (staging manifest; see the notes below) |
| `compile_panel.R` | panel compile script (arg 1 `DATA_ENSO`, arg 2 scratch dir) |
| `compile_panel_C.log`, `compile_panel_C_rebuild_check.log` | compile log and its bitwise rebuild |
| `enso_C/enso_weekly.csv` | the variant ENSO input |
| `build_nino4_C.R`, `build_nino4_C.log` | builds the variant ENSO input |
| `nmme_gapfill_anchor.py`, `nmme_gapfill_anchor.log` | derives the 1 September 2026 NMME anchor |
| `run_psi.R` | psi fit driver (dugong) |

## Notes on `MD5SUMS.txt`

`MD5SUMS.txt` is the staging manifest, copied verbatim apart from the `build_nino4_C.R` line.
- **The last line points outside this bundle.** It records the release panel's md5 at its
  staging path on the laptop. The panel is not committed.
- **The `PROVENANCE.md` line is current.** It is the md5 of the file as committed,
  `c30166dab1a38f0cf844bb5c366f72e9`. The last sentence of PROVENANCE.md section 6 quotes
  `f1454329...`, the md5 before that section was appended, and is out of date.
- **The `build_nino4_C.R` line is the corrected script,** `2be3d6c07373a8c86aa73026b48b750a`.
  As run, the script read `processed/enso` in lower case, which resolves only on a
  case-insensitive file system such as the laptop's; the directory is `processed/ENSO`, and the
  committed script now reads it there. That path is the only change. PROVENANCE.md section 3
  quotes the md5 of the script as run, `74554f4e50a699d9371eca67e52d064b`, and
  `build_nino4_C.log` is that run's output. The corrected script reproduces
  `enso_C/enso_weekly.csv` byte for byte, with the same log.

## Reproduce

The R scripts are laptop scripts with hard-coded paths (`ST`, `SRC`, `WT` at the top). Edit them
to rebuild elsewhere.

1. **ENSO anchor.** From the enso-data root at `3729c87`, run
   `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python <this dir>/nmme_gapfill_anchor.py`. Expect
   +1.8762.
2. **Variant ENSO input.** Run `build_nino4_C.R`. It reads the canonical
   `processed/ENSO/enso_daily.csv` and `enso_weekly.csv`. Check the result against `enso_C/` by
   md5.
3. **Panel.** With a MOSAIC-pkg worktree at `b65cee162` and MOSAIC-data at `04a6d0f`, run
   `Rscript compile_panel.R <dir holding enso_weekly.csv> <output dir>`. Check that the panel
   md5 is `2c575f8c3ea05273d33b0280b5c9c7d5`. The gitignored
   `processed/demographics/UN_world_population_prospects_daily.csv` (md5
   `011bc07262a491ffbb47741bbeecdbf4`) is regenerated by `process_UN_demographics_data()`.
4. **Fit (dugong).** Run
   `R_LIBS=$HOME/R/lib_v0101_rc MOSAIC_PSI_CORE_BUDGET=85 ~/bin/r-mosaic-Rscript run_psi.R C3 <panel> 11`.
   For the replicate, use `C3B` and seed base `121`. Expect statistical, not bitwise, agreement.
5. **Bake into the config.** In MOSAIC-pkg, copy the day file into `model/input/` and run
   `data-raw/make_config_default.R`. Do not inject psi_jt by hand.

Source revisions:
- MOSAIC-pkg: panel `b65cee162`, fit `14433d851`, config_default v6.1 built on `fix/v0101-trust`.
- MOSAIC-data: `04a6d0f` (training panel), `922ef89` (release panel and config_default v6.1).
- enso-data: `3729c875861ab6e2cefe2622857eebed195b7a2b`.
- open-meteo-pipeline: `fddf00f991d7f14ef95ad2c2ed9991c7ab8fc2d1`.
