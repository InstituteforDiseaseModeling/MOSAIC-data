# Provenance: psi D (MOSAIC 1.1.0, config_default v7.1)

psi D is a retrain of the production psi C3 (`../v0.101.0_C3/`, re-corrected in `../v0.102.0_C3_recorrected/`). It changes one thing: the surveillance it learns from. That is the refreshed AI-enhanced combined surveillance of MOSAIC-data beb95f5, built from ai-cholera-data-mining dec875e5. The model, settings and covariates are C3's.

## Outputs
These are baked into MOSAIC-pkg `model/input/` at commit 4e310d743. The fit was run on dugong in `~/psi_v110/D/out/`.

| file | md5 |
|---|---|
| `pred_psi_suitability_day.csv` (the psi_jt source) | `60163deed20c46cdca0565862639de5d` |
| `pred_psi_suitability_week.csv` | `f3812e62383542fd3b36970749ef0cfb` |
| `data_psi_suitability.csv` (gitignored in MOSAIC-pkg) | `45b6c8206c9c3a0f2c9a11b22aae39f1` |
| `psi_suitability_config.json`, full manifest (not committed) | `58464bc2fa257b2477ddd2acbec37bbb` |

The tracked `psi_suitability_config.json` is the slim manifest: only `rw_diagnostics$*$fold_predictions` is removed, as for C3.

The `psi_jt` fingerprint of config_default v7.1 is `e0498acdc601b3c987fb5bc00815d224`, the md5 of its values as little-endian doubles (`psi_fingerprint.R`).

The disjoint-seed replicate DB (seeds 121..220) has day file md5 `a5247ab72cccc701cadf419a38c3cc92`. It sets the keras noise floor and is not shipped.

## Suitability panel D (not copied, 228 MB)
- **md5** `1917488487daf33187e98f4c9be46a83`; 227,907,201 bytes; 56,840 rows x 300 columns; observed cases to 2026-10-01.
- **Built by** `compile_panel_D.R` (log `compile_panel_D.log`) on the laptop. It uses `devtools::load_all()` of MOSAIC-pkg 6fc1b57f1 (1.1.0) and makes C3's call: `compile_suitability_data(PATHS, cutoff = NULL, use_epidemic_peaks = TRUE, date_start = "2000-01-01", date_stop = NULL, forecast_mode = TRUE, forecast_horizon = 9, include_lags = TRUE)`.
- **Inputs identical to C3's** (each checked):
  - ENSO: `../v0.101.0_C3/enso_C/enso_weekly.csv`, md5 `7805ecfe…`.
  - Climate: `processed/climate/weekly/` tree `8f1246f1…`.
  - EMDAT: `processed/EMDAT/weekly/` tree `1a6398de…`.
  - UN WPP daily: md5 `011bc072…`.
- **Changed inputs:**
  - `processed/cholera/weekly/cholera_surveillance_weekly_combined.csv`, md5 `e8fd8695b3c2d778b216d07966ab0b25` (MOSAIC-data beb95f5).
  - `model/input/param_epidemic_peaks.csv`, md5 `9849dce8…`. This is inert for psi.
- **Comparison with C3's release panel** (`5e1e2498…`): the keys and the 300 column names are identical. Only the 18 surveillance-derived columns differ: cases, cases_binary, deaths, source, source_deaths, confidence_weight, disaggregation_method, date_start, date_stop, country, note, rate, transmission_intensity and the five target columns. No feature column differs.

## Psi fit (dugong)
- **Package:** MOSAIC 1.1.0 at MOSAIC-pkg 6fc1b57f1, installed from a clone into `~/R/lib_v110_psi` (RemoteSha is therefore empty in the log). The `est_suitability()` code path equals C3's re-corrected path: since C3's build commit, only `calibrate_psi_predictions.R` (the 0.102.0 collapse rule) changed.
- **Command:** `R_LIBS=$HOME/R/lib_v110_psi MOSAIC_PSI_CORE_BUDGET=85 ~/bin/r-mosaic-Rscript ~/psi_v110/run_psi.R D ~/psi_v110/panel_D/cholera_country_weekly_suitability_data.csv 11` (log `run_psi_D.log`, 31.5 min). DB used label `DB` and seed base `121` (log `run_psi_DB.log`). The two ran concurrently.
- **Settings** are C3's: fit 2015-01-01 to 2026-10-01 (auto); predictions 2018-01-01 to 2027-04-29; feature set v7.3; target D; `bias_correct = TRUE`; lstm_v2 hierarchical FiLM; region map snf_k5; 10 seeds (all succeeded); cross-seed median on the logit scale.
- **Reproducibility:** statistical, not bitwise, because keras recurrent dropout is non-deterministic, as for C3.

## D against C3 (`compare_psi.R`, `compare_D_vs_C3.csv`)
- Over 2023+, the median per-country r is 0.738 and mean |diff| 0.058. The noise floor (D against DB) is 0.939 and 0.024. 28 of 40 locations move by more than twice their own noise floor.
- SOM monthly psi, C3 -> D:
  - April to September 2026: 0.72, 0.91, 0.90, 0.72, 0.65, 0.58 -> 0.19, 0.39, 0.22, 0.11, 0.08, 0.13.
  - November 2026 to March 2027: 0.81, 0.87, 0.84, 0.77, 0.59 -> 0.73, 0.89, 0.92, 0.93, 0.79.
