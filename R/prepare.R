#' Prepare Athlete Monitoring Data
#'
#'
#' @details Extra arguments \code{...} involve \code{use_counts} for nominal model
#'
#' @param data Data frame
#' @param athlete Name of the column in the \code{data} where the athlete id or name is located
#' @param date Name of the column in the \code{data} where the date is located. \code{date} has
#'     to be either \code{Date} or \code{numeric} class
#' @param variable Name of the column in the \code{data} where the variable name is located
#' @param value Name of the column in the \code{data} where the value of \code{variable} is located
#' @param day_aggregate Function for aggregating multiple day entries. Defaults is \code{sum}
#' @param NA_session What value should be imputed for missing values in \code{value}? Default is \code{NA}
#' @param NA_day What value should be imputed for missing days? Default is \code{NA}
#' @param acute Duration of the acute rolling window. Default is 7
#' @param chronic Duration of the chronic rolling window. Default is 28
#' @param rolling_fill Value used to fill start of the rolling windows. Default is \code{NA}
#' @param rolling_estimators Function providing rolling estimators. See Details
#' @param posthoc_estimators Function providing post-hoc estimators. See Details
#' @param group_summary_estimators Function providing group summary estimators. See Details
#' @param iter Should progress be shown? Default is \code{TRUE}
#' @param ... Extra arguments. See Details
#'
#' @return Object of class \code{athletemonitoring}
#' @export
#'
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
#'
#'
#' ## Plots
#'
#' # Table plot
#' # Produces formattable output with sparklines
#' plot(
#'   prepared_data,
#'   type = "table",
#'
#'   # Use to filter out estimators
#'   estimator_name = c("acute.mean", "chronic.mean", "ES", "chronic.sd", "chronic.cv"),
#'
#'   # Use to filter out athlete
#'   # athlete_name = NULL,
#'
#'   # Use to filter out variables
#'   # variable_name = NULL,
#'
#'   # Show last entries
#'   last_n = 42,
#'
#'   # Round numbers
#'   digits = 2
#' )
#'
#' # Bar plot
#' # To plot group average
#' plot(
#'   prepared_data,
#'   type = "bar"
#' )
#'
#' # To plot per athlete, use trellis argument
#' plot(
#'   prepared_data,
#'   type = "bar",
#'   trellis = TRUE
#' )
#'
#' # To filter out athlete variable and add Acute and Chronic lines to the group average:
#' plot(
#'   prepared_data,
#'   type = "bar",
#'
#'   # To filter out athletes
#'   # athlete_name = NULL,
#'
#'   # To filter out variable
#'   # variable_name = NULL,
#'
#'   # Add acute mean
#'   acute_name = "acute.mean",
#'
#'   # Add chronic mean
#'   chronic_name = "chronic.mean",
#'
#'   # Plot last n entries/days
#'   last_n = 42
#' )
#'
#' # If you want to plot for each athlete, use trellis=TRUE
#' plot(
#'   prepared_data,
#'   type = "bar",
#'   acute_name = "acute.mean",
#'   chronic_name = "chronic.mean",
#'   last_n = 42,
#'   trellis = TRUE
#' )
#'
#' # Line plots
#' # These plots represent summary of the rollins estimators
#' plot(
#'   prepared_data,
#'   type = "line",
#'
#'   # To filter out athletes
#'   # athlete_name = NULL,
#'
#'   # To filter out variables
#'   # variable_name = NULL,
#'
#'   # To filter out estimators
#'   # estimator_name = NULL,
#'
#'   # Tell graph where the lower group estimator is
#'   # which is in this case 25%th percentile of the group
#'   group_lower_name = "group.lower",
#'
#'   # The name of the centrality estimator of the group
#'   group_central_name = "group.median",
#'
#'   # Tell graph where the upper group estimator is
#'   # which is in this case 75%th percentile of the group
#'   group_upper_name = "group.upper",
#'
#'   # Use trellis if you do not plot for a single individual
#'   trellis = TRUE
#' )
#'
#' # Previous chart looks messy because it plot all athletes
#' # To avoid that, filter out only one athlete
#' plot(
#'   prepared_data,
#'   type = "line",
#'
#'   # To filter out athletes
#'   athlete_name = "Ann Whitaker",
#'
#'   group_lower_name = "group.lower",
#'   group_central_name = "group.median",
#'   group_upper_name = "group.upper",
#'   trellis = TRUE
#' )
prepare <- function(data,
                    athlete,
                    date,
                    variable,
                    value,
                    day_aggregate = function(x) {
                      sum(x)
                    },
                    NA_session = NA,
                    NA_day = NA,
                    acute = 7,
                    chronic = 28,
                    rolling_fill = NA,
                    rolling_estimators = function(x) {
                      c(
                        "mean" = mean(x, na.rm = TRUE),
                        "sd" = stats::sd(x, na.rm = TRUE),
                        "cv" = stats::sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE),
                        "conf" = sum(!is.na(x)) / length(x)
                      )
                    },
                    posthoc_estimators = function(data) {
                      return(data)
                    },
                    group_summary_estimators = function(x) {
                      c(
                        "median" = stats::median(x, na.rm = TRUE),
                        "lower" = stats::quantile(x, 0.25, na.rm = TRUE)[[1]],
                        "upper" = stats::quantile(x, 0.75, na.rm = TRUE)[[1]]
                      )
                    },
                    iter = TRUE,
                    ...) {
  if (is.numeric(data[[value]])) {
    # Numeric
    prepare_numeric(
      data = data,
      athlete = athlete,
      date = date,
      variable = variable,
      value = value,
      day_aggregate = day_aggregate,
      NA_session = NA_session,
      NA_day = NA_day,
      acute = acute,
      chronic = chronic,
      rolling_fill = rolling_fill,
      rolling_estimators = rolling_estimators,
      posthoc_estimators = posthoc_estimators,
      group_summary_estimators = group_summary_estimators,
      iter = iter
    )
  } else {
    # Nominal
    if(iter) {
      message(
        paste0(
          "Using nominal approach: ",
          "column 'value' in the 'data' provided is not numeric. ",
          "It will be treated as nominal and each level will be analyzed as separate ",
          "variable using rolling proportions or counts approach. ",
          "To use rolling counts, set 'use_counts=TRUE'.\n"
        )
      )
    }

    prepare_nominal(
      data = data,
      athlete = athlete,
      date = date,
      variable = variable,
      value = value,
      day_aggregate = day_aggregate,
      NA_session = NA_session,
      NA_day = NA_day,
      acute = acute,
      chronic = chronic,
      rolling_fill = rolling_fill,
      rolling_estimators = rolling_estimators,
      posthoc_estimators = posthoc_estimators,
      group_summary_estimators = group_summary_estimators,
      iter = iter,
      ...
    )
  }
}
