# Provenance: psi run C3 (MOSAIC v0.101.0, config_default v6.1 candidate)

C3 supersedes C2. Its panel is panel C-trust round 2: Monday-Sunday WHO weeks, a report-dated ZAF 2023 curve with its own deaths, spread counts rounded half up, and `backfill_case_gaps = FALSE` by default.

The panel rebuilds bitwise. The psi fit reproduces statistically, not bitwise, because keras recurrent dropout is non-deterministic. Staged on the laptop at `MOSAIC-pkg/claude/v0101_rebuild/psi/C3/provenance/` (2026-10-01).

## 1. Outputs this bundle reproduces

The run outputs are staged on the laptop in `claude/v0101_rebuild/psi/C3/`. The laptop md5s match dugong's `~/psi_v0101/C3/out/`.

| file | md5 |
|---|---|
| `pred_psi_suitability_day.csv` (the psi_jt source) | `d0eb1e2da04c24a8b2cbf43d548c0413` |
| `pred_psi_suitability_week.csv` | `6a0f85cd17b2d4cecf3bf026b1807b82` |
| `data_psi_suitability.csv` | `1f1388641bfa8fea0fbf5f10305f1681` |
| `psi_suitability_config.json` (slim; only `rw_diagnostics$*$fold_predictions` removed) | `e098f115724b4c0cd183cd051e0c6083` |
| `full_manifest/psi_suitability_config_full.json` (same file as dugong's `psi_suitability_config.json`) | `260c6cd137bd49079935d270884d19bf` |

The disjoint-seed replicate C3B (seeds 121..220) is staged in `claude/v0101_rebuild/psi/C3B/`: day file `396ef9c348560a850b7d306ef3658c02`, week file `fe29dfb69c0cf9fc1565fea8c533926b`.

## 2. Suitability panel (panel C-trust round 2; NOT copied, 227 MB)

- **md5** `2c575f8c3ea05273d33b0280b5c9c7d5`; 227,756,944 bytes; 56,840 rows x 300 columns; 40 countries.
  - Covariates run 2000-01-06..2027-04-29 and observed cases to 2026-09-17.
  - Its canonical twin (canonical ENSO) is `594ffd1c2c7443e7fae5f0e691fc8008`.
  - The round-1 panel (`0e7ec3f0…`, run C2) is archived on the laptop at `claude/v0101_trust/panel_C/panel_C_r1_0e7ec3f0.csv.gz`.
- **Rebuild command** (laptop):
  `Rscript claude/v0101_trust/compile_panel.R claude/v0101_rebuild/psi/nino4/enso_C <output dir>`
  - `compile_panel.R` in this bundle is that script, verbatim (md5 `184b4d92cf3e6f1b31155149751c368c`, unchanged since round 1).
  - Arg 1 is `DATA_ENSO`. Arg 2 becomes `DATA_CHOLERA_WEEKLY`, and the script symlinks MOSAIC-data's combined surveillance file into it.
  - `DOCS_FIGURES` receives only the GAM diagnostics.
- **Code:** MOSAIC-pkg `fix/v0101-trust` @ `b65cee1626c59f86e5b63ce5320227c0687a6767` (DESCRIPTION 0.101.0), via `devtools::load_all()` on a clean worktree. Check out b65cee162 to rebuild.
  - The branch later advanced to 74a328565 (seasonal dynamics, priors v17.1). That move changes no R/ code and not `param_epidemic_peaks.csv`, so it should give the same panel. Only b65cee162 was verified.
  - `compile_suitability_data()` now defaults to `backfill_case_gaps = FALSE`.
  - `PATHS$MODEL_INPUT` is that worktree's `model/input`.
  - `param_epidemic_peaks.csv` md5 `945fec6b811f8d65fe4a5946bc22c3bc` (161 peaks), committed in f71eef0e4. The peaks are inert for psi but part of the panel md5.
- **Call:** `compile_suitability_data(PATHS, cutoff = NULL, use_epidemic_peaks = TRUE, date_start = "2000-01-01", date_stop = NULL, forecast_mode = TRUE, forecast_horizon = 9, include_lags = TRUE)`. These are `update_mosaic_data()`'s arguments; every other argument is left at its default.
- **Inputs:** MOSAIC-data @ `04a6d0f64863f8c59279f8f78faf9ab48725cd21`.
  - Tracked `processed/` matches the commit. The only untracked file is `processed/mobility/D_traveltime_hours.csv`, which the compile does not read.
  - `processed/cholera/weekly/cholera_surveillance_weekly_combined.csv`: md5 `eff063352770c9be54c7e1ea7dc68139` (blob `36adad66…`). This is the Monday-Sunday, report-dated, half-up surveillance.
  - Unchanged since round 1 (c8ff09f):
    - `processed/climate/weekly/*.parquet`: 40 files, tree `8f1246f1e312e8b9c4b064188efb2055c2dcd31c`, from open-meteo-pipeline `fddf00f991d7f14ef95ad2c2ed9991c7ab8fc2d1`.
    - `processed/EMDAT/weekly/`: tree `1a6398de55c5a113758cb060f4f53b9ed674a6a3`.
    - `processed/ENSO/`: tree `e9bb9cc63b0146a623ce0e5b27c15c511e87edd8`, from enso-data `3729c875861ab6e2cefe2622857eebed195b7a2b`. The canonical `enso_weekly.csv` (`51dbed25…`) is replaced by `enso_C/` here; `enso_daily.csv` is `c541f0f6…`.
  - **Not pinned by git:** `processed/demographics/UN_world_population_prospects_daily.csv`, md5 `011bc07262a491ffbb47741bbeecdbf4`, 189,832,592 bytes.
    - It is gitignored. Regenerate it with `process_UN_demographics_data()` from the tracked annual / 1967-2100 files, and check the md5.
- **Verified rebuild:** on 2026-10-01 the same script, with only its scratch root changed, rebuilt md5 `2c575f8c…` byte for byte (`compile_panel_C_rebuild_check.log`). The original compile log is `compile_panel_C.log`.

## 3. ENSO input `enso_C/enso_weekly.csv` (copied, identical to C2's)

- md5 `7805ecfe8513c0d328e5726d49d14d58`, 717,573 bytes. ENSO4 2026-W31..W40 are NOAA-consistent; all other lines are byte-identical to canonical.
- **Built by `build_nino4_C.R`** (md5 `74554f4e50a699d9371eca67e52d064b`; log `build_nino4_C.log`). Its Sep-01 anchor is 1.8762091049382714.
- **The anchor comes from `nmme_gapfill_anchor.py`** (md5 `7fa75ee0f325bfa0feb533c5072accd9`).
  - Run it from the enso-data root at `3729c87`: `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python <bundle>/nmme_gapfill_anchor.py`. It is read-only and every input is tracked.
  - The re-run log (`nmme_gapfill_anchor.log`, 2026-10-01, Python 3.12.1, pandas 3.0.0) reproduces +1.8762 and all 8 published anchors.

## 4. Psi fit (dugong)

- **Package:** MOSAIC 0.100.1 @ `14433d85144ae2f924c28bf093161c708b247265`, in `~/R/lib_v0101_rc`. R 4.5.2, TensorFlow 2.20.0, keras3 1.5.1. The fit runs through `~/bin/r-mosaic-Rscript` (`--max-connections=512`, venv libexpat preload).
- **Why the manifest says 0.100.1:** the `est_suitability()` code path is byte-identical between 14433d851 and b65cee162. This was checked mechanically.
  - None of the 15 suitability files differs. Those are `est_suitability`, `build_suitability_sequences`, `calc_psi_star`, `calibrate_psi_predictions`, `ensemble_suitability`, `feature_sets`, `get_lstm_sequence_splits`, `loss_suitability`, `lstm_film_suitability`, `make_lagged_data`, `region_maps_suitability`, `rolling_cv_suitability`, `run_rolling_cv_suitability` and the two `plot_suitability_*` files.
  - Round 2 changed only `compile_suitability_data.R`, `est_epidemic_peaks.R`, `process_WHO_weekly_data.R` and `surveillance_curation.R`. None of them is called from the suitability path; `compile_suitability_data` appears there only in comments.
  - Of the 275 functions defined in the 32 R files that changed since 14433d851, the path calls only `.mosaic_set_blas_threads()`, and its body is byte-identical.
- **Command:**
  `R_LIBS=$HOME/R/lib_v0101_rc MOSAIC_PSI_CORE_BUDGET=85 ~/bin/r-mosaic-Rscript ~/psi_v0101/run_psi.R C3 ~/psi_v0101/panel/C_trust_r2/cholera_country_weekly_suitability_data.csv 11`
  - `run_psi.R` is in this bundle (md5 `f59e9728b62242668cace9f9e7832e93`).
  - C3B is identical except for the label `C3B` and seed base `121`.
  - The budget of 85 gives 10 PSOCK workers × 8 TF intra-op threads. It affects only speed.
- **`est_suitability()` settings:**
  - Fit window: 2015-01-01 to 2026-09-17 (auto; equals target_anchor_end).
  - Prediction window: 2018-01-01 to 2027-04-29.
  - Model: `feature_set = "v7.3"`, `response_var = "target_D_rate_per_country_floored"`, `bias_correct = TRUE`, `architecture = "lstm_v2_hierarchical_film"`.
  - `arch_control = list(n_seeds = 10, region_map = "snf_k5", parallel_seeds = 10, seed_base = 11)`, which gives seeds 11, 22, …, 110.
  - Confidence weights are applied. There are 12 rolling-CV steps (4-week gap, 1-month step, 5-month test). Seeds are aggregated by cross-seed median on the logit scale.
- **Replicate check:** C3B against C3 gives a 2023+ median per-country r of 0.972 and mean|diff| of 0.024. The C2-vs-C2B floor was 0.968 / 0.029 and A vs B was 0.967 / 0.028.

## 5. Bundle contents

`MD5SUMS.txt` lists every file:
- `PROVENANCE.md`: this file.
- `compile_panel.R`: panel compile script.
- `compile_panel_C.log`: round-2 compile log.
- `compile_panel_C_rebuild_check.log`: log of the bitwise rebuild.
- `enso_C/enso_weekly.csv`: ENSO input.
- `build_nino4_C.R` and `build_nino4_C.log`: ENSO input build.
- `nmme_gapfill_anchor.py` and `nmme_gapfill_anchor.log`: Sep-01 anchor derivation and its re-run.
- `run_psi.R`: psi fit driver.

## 6. Addendum, 2026-10-01: the release panel C

Appended after sections 1-5; they are unchanged.

- **Psi C3 was trained on panel C `2c575f8c3ea05273d33b0280b5c9c7d5`** (section 2). **The release panel C is `5e1e2498135cfc1083e69722336ce095`**: 227,756,944 bytes, 56,840 rows x 300 columns, on the laptop at `claude/v0101_trust/panel_C/cholera_country_weekly_suitability_data.csv`.
  - Its canonical twin is `d8a2896974eb8f7df106632fa32987d7` (was `594ffd1c…`).
  - The superseded panels are archived on the laptop: `claude/v0101_trust/panel_C/panel_C_r2_2c575f8c.csv.gz` and `claude/v0101_trust/panel/panel_v0101_trust_canonical_r2_594ffd1c.csv.gz`.
- **The two panels differ in two cells, both in the `deaths` column:**
  - ZAF 2023-05-25 (WHO 2023-W21, the week of Monday 22 May): 13 -> 14.
  - ZAF 2023-06-08 (W23, the week of Monday 5 June): 6 -> 5.
  - Every other cell is identical, compared exactly as text. That includes `cases`, all target columns, `confidence_weight` and `cases_binary`.
  - `deaths_per_1000` is also identical. It is the UN WPP crude death rate, which does not depend on cholera deaths.
- **Psi never reads `deaths`:**
  - It is not among the 38 columns of the v7.3 feature set (climate, ENSO and seasonal).
  - It is not the response (`target_D_rate_per_country_floored`) and not a weight.
  - None of the 15 suitability files listed in section 4 mentions "death".
  - So C3's psi stands for the release panel.
- **Why the deaths changed:** the 28 May anchor of the ZAF 2023 death curve is 25, not 24. The old value left out the Free State death of 25 May at Parys hospital.
  - Fixed in MOSAIC-pkg `fix/v0101-trust` @ `9ec46e414b1570292bc96f557af3313f196031ab`.
  - Surveillance rebuilt in MOSAIC-data @ `922ef89db984a0bf73fb043915c8526eaf296cca`. `cholera_surveillance_weekly_combined.csv` is now md5 `d8e8ce84d1fcc4f113d5fa221836a4a6` (was `eff06335…`).
  - Cases are unchanged, and so are the ZAF totals (1,390 cases, 47 deaths).
- **Rebuild:** the same `compile_panel.R` (md5 `184b4d92cf3e6f1b31155149751c368c`), call and inputs as section 2, with two exceptions:
  - MOSAIC-pkg is `fix/v0101-trust` @ `595951bfc6d2717f6ae0756cee6bf5cd1c0c6c15`;
  - MOSAIC-data is @ `922ef89`, whose only change from `04a6d0f` is four surveillance files.
  - `param_epidemic_peaks.csv` is unchanged (`945fec6b811f8d65fe4a5946bc22c3bc`, 161 peaks). Re-detecting the peaks on the new surveillance gives the same file.
  - The compile log matches the round-2 log except for the sha, md5 and timing lines.
- **`MD5SUMS.txt`:** the release panel's md5 is a separate last line. The panel itself is not copied. The `PROVENANCE.md` line (`f145432959229fbad64ec92d67c89721`) is the md5 of this file before this section was appended.
