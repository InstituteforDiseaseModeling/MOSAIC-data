# psi retrain D for MOSAIC 1.1.0 (dugong; C3 settings, refreshed surveillance). Args: run label, panel CSV, seed_base.
# Launch env: R_LIBS=~/R/lib_v110_psi (PSOCK seed workers resolve MOSAIC from it) and
# MOSAIC_PSI_CORE_BUDGET=<per-process slice> (TF intra-op = budget %/% parallel_seeds).
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
lab <- args[1]; panel <- normalizePath(args[2]); seed_base <- as.integer(args[3])
.libPaths(c("~/R/lib_v110_psi", "~/R/library", .libPaths()))
suppressMessages(library(MOSAIC))
d <- packageDescription("MOSAIC")
cat("MOSAIC", d$Version, "RemoteSha", d$RemoteSha, "from", find.package("MOSAIC"), "\n")
cat("R_LIBS =", Sys.getenv("R_LIBS"), " MOSAIC_PSI_CORE_BUDGET =", Sys.getenv("MOSAIC_PSI_CORE_BUDGET"), "\n")
set_root_directory("~/MOSAIC")
PATHS <- get_paths()
PATHS$MODEL_INPUT  <- normalizePath(file.path("~/psi_v110", lab, "out"))
PATHS$DOCS_FIGURES <- normalizePath(file.path("~/psi_v110", lab, "figs"))
cat("run", lab, " source panel:", panel, " md5:", unname(tools::md5sum(panel)),
    " seed_base:", seed_base, "\n")
t0 <- Sys.time()
res <- est_suitability(
  PATHS,
  fit_date_start  = NULL,          # -> B4 fixture 2015-01-01
  fit_date_stop   = NULL,          # auto: last week with cases + complete ENSO
  pred_date_start = "2018-01-01",  # config_default back-history floor
  pred_date_stop  = NULL,          # auto: last ENSO-complete week; fill tail dropped
  feature_set     = "v7.3",
  response_var    = "target_D_rate_per_country_floored",
  bias_correct    = TRUE,
  architecture    = "lstm_v2_hierarchical_film",
  arch_control    = list(n_seeds = 10L, region_map = "snf_k5", parallel_seeds = 10L,
                         seed_base = seed_base),
  source_csv      = panel)
cat("ELAPSED_MIN", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
print(warnings())
cat("DONE\n")
