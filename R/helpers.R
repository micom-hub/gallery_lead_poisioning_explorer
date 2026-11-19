# R/helpers.R
#
# Shared functions for the trajectory explorer.


prepare_synthetic_tests <- function(data) {
  data |>
    dplyr::mutate(
      Name = trimws(Name),
      COUNTY = trimws(COUNTY),
      SEX = toupper(trimws(SEX)),
      SAM_TYP = toupper(trimws(SAM_TYP)),

      DOB_R = as.Date(DOB, format = "%Y-%m-%d"),
      SPEC_DT_R = as.Date(SPEC_DT, format = "%Y-%m-%d"),

      PB_RESULT_new = as.numeric(sub("^<", "", PB_RESULT)) -
        ifelse(grepl("^<", PB_RESULT), 0.1, 0),

      Age = lubridate::time_length(
        lubridate::interval(DOB_R, SPEC_DT_R),
        unit = "years"
      )
    ) |>
    dplyr::arrange(Name, SPEC_DT_R)
}

first_nonmissing <- function(x) {
  if (is.factor(x)) {
    x <- as.character(x)
  }

  keep <- !is.na(x)

  if (is.character(x)) {
    keep <- keep & trimws(x) != ""
  }

  x <- x[keep]

  if (length(x) == 0L) {
    return(x[NA_integer_])
  }

  x[1]
}


format_age_ymd <- function(date_of_birth, test_date) {
  date_of_birth <- as.Date(date_of_birth)
  test_date <- as.Date(test_date)

  if (
    length(date_of_birth) != 1L ||
      length(test_date) != 1L ||
      is.na(date_of_birth) ||
      is.na(test_date) ||
      test_date < date_of_birth
  ) {
    return(NA_character_)
  }

  age <- lubridate::as.period(
    lubridate::interval(date_of_birth, test_date),
    unit = "year"
  )

  paste0(
    age@year,
    " Years, ",
    age@month,
    " Months, ",
    age@day,
    " Days"
  )
}


find_multiple_tests <- function(df, minimum_gap = 30) {
  required_columns <- c(
    "Name",
    "PB_RESULT_new",
    "SPEC_DT_R",
    "SAM_TYP",
    "Age"
  )

  missing_columns <- setdiff(required_columns, names(df))

  if (length(missing_columns) > 0L) {
    stop(
      "Missing longitudinal columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  if (
    length(minimum_gap) != 1L ||
      !is.numeric(minimum_gap) ||
      !is.finite(minimum_gap) ||
      minimum_gap < 0
  ) {
    stop("minimum_gap must be one finite, nonnegative number.")
  }

  trajectory_levels <- c(
    "low-low",
    "low-high",
    "high-low",
    "high-high"
  )

  df |>
    dplyr::mutate(
      .child_name = trimws(as.character(Name)),
      SPEC_DT_R = as.Date(SPEC_DT_R),
      PB_RESULT_new = suppressWarnings(as.numeric(PB_RESULT_new)),
      .original_row = dplyr::row_number(),

      sam_type_priority = dplyr::case_when(
        SAM_TYP == "V" ~ 2L,
        SAM_TYP == "C" ~ 1L,
        TRUE ~ 0L
      )
    ) |>
    dplyr::filter(
      !is.na(.child_name),
      .child_name != "",
      !is.na(SPEC_DT_R),
      is.finite(PB_RESULT_new),
      PB_RESULT_new >= 0
    ) |>
    dplyr::arrange(.child_name, SPEC_DT_R, .original_row) |>
    dplyr::group_by(.child_name) |>
    dplyr::mutate(
      gap_from_previous_test = as.numeric(
        SPEC_DT_R - dplyr::lag(SPEC_DT_R)
      ),

      new_testing_window = is.na(gap_from_previous_test) |
        gap_from_previous_test >= minimum_gap,

      testing_window = cumsum(new_testing_window)
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(.child_name, testing_window) |>
    dplyr::arrange(
      dplyr::desc(sam_type_priority),
      dplyr::desc(PB_RESULT_new),
      .original_row,
      .by_group = TRUE
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup() |>
    dplyr::group_by(.child_name) |>
    dplyr::mutate(
      retained_test_count = dplyr::n()
    ) |>
    dplyr::filter(retained_test_count >= 2L) |>
    dplyr::arrange(
      SPEC_DT_R,
      .original_row,
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      retained_test_number = dplyr::row_number(),
      elevated = PB_RESULT_new >= 3.5,

      first_test_elevated = dplyr::first(elevated),
      final_test_elevated = dplyr::last(elevated),

      trajectory = factor(
        paste0(
          ifelse(first_test_elevated, "high", "low"),
          "-",
          ifelse(final_test_elevated, "high", "low")
        ),
        levels = trajectory_levels
      ),

      first_test_date = dplyr::first(SPEC_DT_R),
      final_test_date = dplyr::last(SPEC_DT_R),

      time_since_first_test = as.numeric(
        SPEC_DT_R - first_test_date
      ),

      follow_up_days = as.numeric(
        final_test_date - first_test_date
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(.child_name, SPEC_DT_R, .original_row)
}
