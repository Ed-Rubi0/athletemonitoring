#' S3 method for summarizing \code{\link{prepare}} results
#'
#' This function returns long summary of the \code{athletemonitoring} object
#'
#' @param object Object of class \code{athletemonitoring}
#' @param ... Extra arguments. Not used
#' @return Tibble with athlete - variable summaries
#' @export
#' @examples
#' # Load monitoring data set
#' data("monitoring")
#'
#' # Filter out only 'Training Load'
#' monitoring <- monitoring[monitoring$Variable == "Training Load", ]
#'
#' # Convert column to date format (or use numeric)
#' monitoring$Date <- as.Date(monitoring$Date, "%Y-%m-%d")
#'
#' # Run the athlete monitoring data preparation
#' prepared_data <- prepare(
#'   data = monitoring,
#'   athlete = "Full Name",
#'   date = "Date",
#'   variable = "Variable",
#'   value = "Value",
#'   acute = 7,
#'   chronic = 42,
#'
#'   # How should be missing entry treated?
#'   # What do we assume? Zero load? Let's keep NA
#'   NA_session = NA,
#'
#'   # How should missing days (i.e. no entries) be treated?
#'   # Here we assume no training, hence zero
#'   NA_day = 0,
#'
#'   # How should be multiple day entries summarised?
#'   # With "load", it is a "sum", witho other metrics that
#'   # do not aggregate, it can me "mean"
#'   day_aggregate = function(x) {
#'     sum(x, na.rm = TRUE)
#'   },
#'
#'   # Rolling estimators for Acute and Chronic windows
#'   rolling_estimators = function(x) {
#'     c(
#'       "mean" = mean(x, na.rm = TRUE),
#'       "sd" = sd(x, na.rm = TRUE),
#'       "cv" = sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE)
#'     )
#'   },
#'
#'   # Additional estimator post-rolling
#'   posthoc_estimators = function(data) {
#'     data$ACD <- data$acute.mean - data$chronic.mean
#'     data$ACR <- data$acute.mean / data$chronic.mean
#'     data$ES <- data$ACD / data$chronic.sd
#'
#'     # Make sure to return the data
#'     return(data)
#'   },
#'
#'   # Group summary estimators
#'   group_summary_estimators = function(x) {
#'     c(
#'       "median" = median(x, na.rm = TRUE),
#'       "lower" = quantile(x, 0.25, na.rm = TRUE)[[1]],
#'       "upper" = quantile(x, 0.75, na.rm = TRUE)[[1]]
#'     )
#'   }
#' )
#'
#' # Get summary
#' prepared_data
#' summary(prepared_data)
summary.athletemonitoring <- function(object, ...) {

  # +++++++++++++++++++++++++++++++++++++++++++
  # Code chunk for dealing with R CMD check note
  athlete <- NULL
  variable <- NULL
  level <- NULL
  levels_sum <- NULL
  variable.value <- NULL
  missing_entry <- NULL
  missing_day <- NULL
  # +++++++++++++++++++++++++++++++++++++++++++

  if (object$type == "nominal") {
    summary_table <- object$data_wide %>%
      dplyr::group_by(athlete, variable) %>%
      dplyr::mutate(levels_sum = sum(variable.value, na.rm = TRUE)) %>%
      dplyr::group_by(athlete, variable, level) %>%
      dplyr::summarise(
        `Day entries` = sum(!is.na(variable.value)),
        `Missing entries` = sum(missing_entry),
        `Missing days` = sum(missing_day),
        `Start date` = min(date),
        `Stop date` = max(date),
        `Proportion` = sum(variable.value, na.rm = TRUE) / levels_sum[1]
      ) %>%
      dplyr::ungroup()
  } else {
    summary_table <- object$data_wide %>%
      dplyr::group_by(athlete, variable) %>%
      dplyr::summarise(
        `Day entries` = sum(!is.na(variable.value)),
        `Missing entries` = sum(missing_entry),
        `Missing days` = sum(missing_day),
        `Start date` = min(date),
        `Stop date` = max(date),
        `Mean` = mean(variable.value, na.rm = TRUE),
        `SD` = stats::sd(variable.value, na.rm = TRUE),
        `Min` = min(variable.value, na.rm = TRUE),
        `Max` = mean(variable.value, na.rm = TRUE),
        `Median` = stats::median(variable.value, na.rm = TRUE),
        `IQR` = stats::IQR(variable.value, na.rm = TRUE),
        `MAD` = stats::mad(variable.value, na.rm = TRUE)
      ) %>%
      dplyr::ungroup()
  }


  return(summary_table)
}
