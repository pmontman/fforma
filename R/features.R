#' @export
heterogeneity_tsfeat_workaround <- function(x) {
  output <- c(arch_acf =0, garch_acf=0, arch_r2=0, garch_r2=0)
  try( output <- tsfeatures::heterogeneity(x) )
  output
}

#' @export
hw_parameters_tsfeat_workaround <- function(x) {
  hw_fit <- NULL
  hw_fit$par <- c(NA, NA, NA)
  try(hw_fit <- forecast::ets(x, model=c("AAA")), silent=TRUE)
  names(hw_fit$par) <- c("hw_alpha", "hw_beta" , "hw_gamma")
  hw_fit$par[1:3]
}

#' @describeIn process_THA_features
#' Calculate features from Talagala, Hyndman, Athanaspoulos from a single time series
#' @export
#' @import tsfeatures
calc_features <- function(seriesentry) {
  series <- seriesentry$x
  featrow <- tsfeatures(
    series,
    features = c(
      "acf_features",
      "arch_stat",
      "crossing_points",
      "entropy",
      "flat_spots",
      heterogeneity_tsfeat_workaround,
      "holt_parameters",
      "hurst",
      "lumpiness",
      "nonlinearity",
      "pacf_features",
      "stl_features",
      "stability",
      hw_parameters_tsfeat_workaround,
      "unitroot_kpss",
      "unitroot_pp"
    )
  )


  #additional features
  series_length <- length(series)

  featrow <- tibble::add_column(
    featrow,
    "series_length" = series_length)

  featrow[is.na(featrow)] <-
    0 #SET NAs TO 0 ?


  #adding dummy variables for non seasonal series
  #that are not output by tsfeatures
  if (length(featrow) == 37) {
    featrow <- tibble::add_column(featrow, "seas_acf1" = 0, .before = 7)
    featrow <- tibble::add_column(featrow, "seas_pacf" =
                                    0, .before = 24)
    featrow = tibble::add_column(
      featrow,
      "seasonal_strength" = 0,
      "peak" = 0,
      "trough" = 0,
      .before=33)
  }
  seriesentry$features <- featrow
  seriesentry
}

