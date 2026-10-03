# Candidate bias-correction rules, replicating calibrate_psi_predictions()'s per-country
# map logic at main@9f3ea4f1b (R0) and the collapse-case alternatives.
#   R0  status quo: OLS -> clamp slope/offset -> blend toward identity to keep
#       logit-sd in [0.5, 2] x input (the floor blend is the "collapsed" map)
#   R1  as R0, but identity when the amplitude FLOOR binds
#   R2a as R0, but slope fixed at 1 and offset = mean(y - x) when the floor binds
#   R2b as R2a with offset = median(y - x) (robust to the +13.8 logit of capped targets)
#   R3  as R0, but the intercept is re-fitted after the slope clamp (b = ybar - a_c*xbar)
#       before the blend (fixes the level, keeps the 0.5 floor)
# Each returns list(A, B, status) such that logit(psi) = A * logit(pred) + B.
EPS <- 1e-6
lgt <- function(p, eps = EPS) qlogis(pmax(eps, pmin(1 - eps, p)))
clamp_to <- function(x, r) pmax(r[1], pmin(r[2], x))

fit_rule <- function(x_fit, y_fit, rule = "R0", min_train = 8L, min_pred_sd = 0.05,
                     slope_range = c(0.25, 4), offset_range = c(-4, 4),
                     amp_range = c(0.5, 2), eps = EPS) {
     ident <- list(A = 1, B = 0, status = "identity")
     if (length(x_fit) < min_train) return(ident)
     xl <- lgt(x_fit, eps); yl <- lgt(y_fit, eps)
     sd_xl <- sd(xl)
     if (!is.finite(sd_xl) || sd_xl < min_pred_sd || length(unique(round(xl, 8))) < 2L) return(ident)
     cf <- coef(lm(yl ~ xl))
     a <- cf[["xl"]]; b <- cf[["(Intercept)"]]
     if (!is.finite(a) || !is.finite(b)) return(ident)
     a_c <- clamp_to(a, slope_range)
     b_c <- if (rule == "R3" && a_c != a) clamp_to(mean(yl) - a_c * mean(xl), offset_range) else clamp_to(b, offset_range)
     status <- if (a_c != a || b_c != b) "guarded" else "fit"
     # The blend toward identity is affine, so sd(w*yhat + (1-w)*x) = |1 - w(1-a_c)| * sd(x):
     # the grid choice of w depends on a_c only (identical to the package's grid search).
     ratio <- abs(a_c)
     if (ratio < amp_range[1] || ratio > amp_range[2]) {
          floor_hit <- ratio < amp_range[1]
          if (floor_hit && rule == "R1") return(list(A = 1, B = 0, status = "collapsed_identity"))
          if (floor_hit && rule %in% c("R2a", "R2b")) {
               off <- if (rule == "R2a") mean(yl - xl) else median(yl - xl)
               return(list(A = 1, B = clamp_to(off, offset_range), status = "collapsed_slope1"))
          }
          target <- min(amp_range[2], max(amp_range[1], ratio))
          ws  <- seq(0, 1, by = 0.02)
          sds <- abs(1 - ws * (1 - a_c))
          w   <- ws[which.min(abs(sds - target))]
          return(list(A = w * a_c + (1 - w), B = w * b_c,
                      status = if (floor_hit) "guarded_floor" else "guarded_ceiling"))
     }
     list(A = a_c, B = b_c, status = status)
}

apply_map <- function(p, mp, eps = EPS) plogis(mp$A * lgt(p, eps) + mp$B)

# Scores of a psi series against the [0,1] target on observed weeks.
auc <- function(s, y) {
     y <- as.integer(y); n1 <- sum(y == 1); n0 <- sum(y == 0)
     if (n1 < 3 || n0 < 3) return(NA_real_)
     r <- rank(s); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
score_psi <- function(psi, y, eps = 1e-6) {
     ok <- is.finite(psi) & is.finite(y); psi <- psi[ok]; y <- y[ok]
     pc <- pmax(eps, pmin(1 - eps, psi))
     pos <- y > 0
     cal <- if (length(y) < 3 || !isTRUE(sd(pc) > 0)) c(NA_real_, NA_real_) else tryCatch(suppressWarnings(coef(glm(y ~ qlogis(pc), family = quasibinomial()))),
                     error = function(e) c(NA_real_, NA_real_))
     list(n = length(y), n_pos = sum(pos),
          pearson = if (length(y) > 2 && isTRUE(sd(psi) > 0) && isTRUE(sd(y) > 0)) cor(psi, y) else NA_real_,
          auc = auc(psi, pos),
          brier = mean((psi - y)^2),
          bce = -mean(y * log(pc) + (1 - y) * log(1 - pc)),
          cal_slope = unname(cal[2]),
          lvl_bias_outbreak = if (sum(pos) > 0) median(log(pc[pos] / y[pos])) else NA_real_,
          mean_psi = mean(psi), p95_p5 = if (length(psi)) unname(quantile(psi, 0.95) / quantile(psi, 0.05)) else NA_real_)
}
