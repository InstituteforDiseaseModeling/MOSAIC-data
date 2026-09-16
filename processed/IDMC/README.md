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

Two acquisition routes:

1. **IDU API** (preferred — full history). Easiest via the CRAN
   [`idmc`](https://cran.r-project.org/package=idmc) package (UN OCHA):
   `idmc::idmc_get_data()` reads an endpoint URL from the `IDMC_API` environment
   variable. The URL embeds a client id issued by IDMC on request. Live host is
   `helix-tools-api.idmcdb.org`.
2. **HDX per-country mirrors** — `<iso>-idmc-idu-events` datasets, open, no
   credentials. Available for **26 of the 27** MOSAIC national countries (TGO has
   no dataset).

⚠️ The URL advertised on the HDX resource page (`backend.idmcdb.org`) **no longer
resolves**. That host is retired.

## ⚠️ Coverage caveat — read before modelling

IDU is a rolling near-real-time product and accessible history depends on the route.
**The HDX mirrors begin ~2025.** The panels are zero-filled back to the
`panel_start` (default 2000-01-03, matching EM-DAT), so **zeros before a country's
first observed event mean "not in this extract", not "no displacement occurred".**

Check the per-country first-event dates printed by `process_IDMC_data()` (also
returned in the `coverage` attribute) before using these as a covariate or as a
denominator for any trigger/PPV analysis. This is a materially weaker coverage
guarantee than EM-DAT, which runs from 2000.

## ⚠️ Collinearity

`idmc_disaster_*` is largely flood/storm-driven and will correlate with
`emdat_flood_*` / `emdat_cyclone_*`. Do not enter both into a feature set without
checking. `idmc_conflict_*` is the genuinely additional signal — it has no EM-DAT
analogue and captures WASH collapse, camp formation and care-seeking disruption.

## Current extract

Built 2026-08-12 from the HDX per-country mirrors: **8,537 events, 26 countries,
2025-01-01 → 2026-08-03** (5,557 conflict / 2,980 disaster). Re-run against the API
once a client id is available to extend the history backwards.
