# md5 of config_default$psi_jt as raw little-endian doubles: identical on every machine iff psi is identical.
suppressPackageStartupMessages(library(MOSAIC))
f <- tempfile(); writeBin(as.vector(MOSAIC::config_default$psi_jt), f, endian = "little")
cat(Sys.info()[["nodename"]], "MOSAIC", as.character(packageVersion("MOSAIC")), "config", MOSAIC::config_default$metadata$version,
    "psi_jt md5", unname(tools::md5sum(f)), "\n")
