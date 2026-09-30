# IDMC internal-displacement country-week panels

Produced by `MOSAIC::process_IDMC_data()` (see `?process_IDMC_data`). Mirrors the
EM-DAT hazard panels in `../EMDAT/weekly/` so both join onto the same ISO-week grid
in `compile_suitability_data()`.

## Files

| file | contents |
|---|---|
| `weekly/displacement_conflict_country_weekly.csv` | conflict-driven displacement |
| `weekly/displacement_disaster_country_weekly.csv` | disaster-driven displacement |

Columns: `iso_code, year, week, date_start, date_stop, idmc_<kind>_active,
idmc_<kind>_new, idmc_<kind>_displaced` (the last is `log1p` of persons displaced).

## Source

IDMC **Internal Displacement Updates (IDU)** — event-level records with start/end
dates, a `displacement_type` (Conflict / Disaster) and a `figure` (persons
displaced). Licence **CC BY** (per-country HDX mirrors: CC BY-IGO).

### Acquisition — use `download_IDMC_data()`

`MOSAIC::download_IDMC_data(PATHS)` pulls the **HDX per-country mirrors**
(`<iso>-idmc-idu-events`): open, **no credentials**, refreshed daily. It resolves
each CSV's download URL at call time from the HDX CKAN API
(`package_show?id=<iso>-idmc-idu-events`) — the resource UUIDs change whenever
IDMC republishes, so they must not be hardcoded — and archives a dated snapshot
to `MOSAIC-data/raw/IDMC/hdx_<date>/`.

`process_IDMC_data()` then auto-selects the newest `hdx_<date>/` snapshot
(pass `source_dir` to reprocess an older one).

**Snapshots are never overwritten.** IDU is a *provisional* product: figures are
revised and records age out. The dated archive is the only way to reconstruct
what was known at a past date, matching the EM-DAT and WHO-dashboard conventions.

### The IDMC API route (not required)

The CRAN [`idmc`](https://cran.r-project.org/package=idmc) package wraps IDMC's
`external-api`, which is **credential gated** — an unauthenticated request to
`helix-tools-api.idmcdb.org/external-api/idus/all/` returns
`HTTP 403 {"detail":"Client is not registered."}`. A client id must be requested
from IDMC (`ch.datainfo@idmc.ch`). It buys **pre-2025 history** and nothing else;
it is not needed to run the pipeline.

It also cannot be used to *read* HDX downloads: `idmc_get_data()` unconditionally
parses a `standard_popup_text` column that the HDX CSVs do not carry.

⚠️ The URL advertised on the HDX resource page (`backend.idmcdb.org`) **no longer
resolves** — DNS failure confirmed 2026-09-17. That host is retired.

## ⚠️ Coverage caveat — read before modelling

IDU is a rolling near-real-time product. **38 of the 40 MOSAIC countries have an
HDX dataset; ERI and TGO have none** (measured 2026-09-17, when all 38 were
refreshed that same day).

Coverage is **not uniform**: most series begin 2025-01-01, but **KEN reaches back
to 2011** and several cover only a few weeks. The panels are zero-filled back to
`panel_start` (default 2000-01-03, matching EM-DAT), so **zeros before a
country's first observed event mean "not in this extract", not "no displacement
occurred".**

Check the per-country first-event dates printed by `process_IDMC_data()` (also
returned in the `coverage` attribute) before using these as a covariate or as a
denominator for any trigger/PPV analysis. This is a materially weaker coverage
guarantee than EM-DAT's, which runs from 2000.

## ⚠️ Collinearity

`idmc_disaster_*` is largely flood/storm-driven and will correlate with
`emdat_flood_*` / `emdat_cyclone_*`. Do not enter both into a feature set without
checking. `idmc_conflict_*` is the genuinely additional signal — it has no EM-DAT
analogue and captures WASH collapse, camp formation and care-seeking disruption.

## Current extract

Built 2026-08-12 from the HDX per-country mirrors: **8,537 events, 26 countries,
2025-01-01 → 2026-08-03** (5,557 conflict / 2,980 disaster).

⚠️ That build predates `download_IDMC_data()` and was produced out-of-band from a
scratch directory that no longer exists, so it is **not reproducible as-is** and
reached only 26 countries. Re-run `download_IDMC_data(PATHS)` +
`process_IDMC_data(PATHS)` to rebuild from an archived snapshot across all 38
available countries.
