#' Get all Data for a Tournament
#'
#' For a given URL, or tournament ID (which can be found in the URL),
#' this function scraps a list of tibbles and related data which are
#' found on that page.
#'
#' @param id The URL of the chess-results.com tournament page or
#'           the id that is present in the URL, supplied as a string.
#' @returns A list of tibbles about the different aspects of the tournament.
#'
#' @examples
#' chess_results("1443765")
#'
#' chess_results("https://chess-results.com/tnr134.aspx")
#' @export

chess_results <- function(id) {
  url <- chess_results_standard_url(id)
  page_html <- chess_results_read_html(url)
  main_tournament_tables <- chess_results_read_main_tables(page_html, url)
  main_tournament_tables[[1]] <-
    chess_results_fix_table_1(main_tournament_tables)
  if (length(main_tournament_tables) == 1) {
    list(NA, main_tournament_tables[[1]])
  }
  main_tournament_tables[[2]] <-
    chess_results_fix_table_2(main_tournament_tables)
  main_tournament_tables <-
    chess_results_fix_main_table_names(main_tournament_tables)
  if (!is.data.frame(main_tournament_tables[[1]])) {
    warning(paste0("The tournament is more than 5 days old. ",
                   "tournament_information is NA. ",
                   "Please help the developer in scraping tables ",
                   "for such tournaments at the Codeberg repo."))
  }
  return(main_tournament_tables)
}

chess_results_standard_url <- function(id) {
  if (startsWith(id, "https")) {
    id <- sub(".*tnr *(.*?) *\\.aspx.*",
              "\\1", id)
  }
  url <- paste0("https://chess-results.com/tnr",
                id, ".aspx?lan=1&art=0&turdet=ALL&flag=NO")
  return(url)
}

chess_results_read_html <- function(url) {
  page_html <- url |>
    rvest::read_html()
  return(page_html)
}

chess_results_read_main_tables <- function(page_html, url) {
  if (!grepl("defaultDialogMsg", page_html, fixed = TRUE)) {
    main_tournament_tables <- page_html |>
      rvest::html_elements("table") |>
      rvest::html_table(convert = TRUE, na.strings = c("", 0, ".", "-"))
    main_tournament_tables <- main_tournament_tables[c(4, 6)]
  } else {
    # This section needs read_html_live to click the button to
    # show tournament details. I have not figured out how to do that,
    # so this is just currently returning a NA for table 1 for now.
    main_tournament_tables <- page_html |>
      rvest::html_elements("table") |>
      rvest::html_table(convert = TRUE, na.strings = c("", 0, ".", "-"))
    main_tournament_tables <- main_tournament_tables[c(4, 6)]
    main_tournament_tables <- rev(main_tournament_tables)
  }
  return(main_tournament_tables)
}

chess_results_table_header_names <- function() {
  table_header_names <-
    list(list(organizer = "organizer_s",
              average_rating = "rating_o"),
         list(title = "x1",
              federation = "fed",
              rating = "rtg",
              club_or_city = "club_city",
              international_rating = "rtg_i",
              national_rating = "rtg_n",
              group = "gr",
              type = "typ"))
  return(table_header_names)
}

chess_results_transpose_table_1 <- function(main_tournament_table) {
  main_tournament_table <- main_tournament_table |>
    t() |>
    janitor::row_to_names(1) |>
    tibble::as_tibble()
  return(main_tournament_table)
}

chess_results_split_table_1 <- function(main_tournament_table) {
  if ("date" %in% colnames(main_tournament_table)) {
    main_tournament_table <- main_tournament_table |>
      tidyr::separate_wider_delim("date",
                                  delim = " to ",
                                  names = c("start_date",
                                            "end_date"),
                                  too_few = "align_start")
  }
  if (is.na(main_tournament_table["end_date"])) {
    main_tournament_table["end_date"] <- main_tournament_table["start_date"]
  }
  if ("rating_o_average_age" %in% colnames(main_tournament_table)) {
    main_tournament_table <- main_tournament_table |>
      tidyr::separate_wider_delim("rating_o_average_age",
                                  delim = " / ",
                                  names = c("average_rating",
                                            "average_age"))
  }
  return(main_tournament_table)
}

chess_results_table_1_suffix <- function(main_tournament_table) {
  for (i in c("organizer", "tournament_director", "arbiter",
              "chief_arbiter", "deputy_chief_arbiter",
              "rating_calculation", "pairing_program")) {
    if (i %in% colnames(main_tournament_table)) {
      main_tournament_table <- main_tournament_table |>
        tidyr::separate_wider_delim(dplyr::all_of(i),
                                    delim = stringr::regex("[,;]\\s*"),
                                    names_sep = "_")
    }
  }
  return(main_tournament_table)
}

chess_results_table_1_time_and_federation <-
  function(main_tournament_table) {
    for (i in c("Standard", "Rapid", "Blitz")) {
      if (any(grepl(i, colnames(main_tournament_table)))) {
        main_tournament_table <- main_tournament_table |>
          cbind(i = TRUE)
        names(main_tournament_table)[ncol(main_tournament_table)] <-
          tolower(i)
      }
    }
    main_tournament_table <- main_tournament_table |>
      dplyr::rename_with(~ paste0("time_control"),
                         dplyr::contains("time_control"))
    main_tournament_table <- main_tournament_table |>
      dplyr::relocate(
        names(main_tournament_table)[ncol(main_tournament_table)],
        .after = "time_control")
    main_tournament_table["federation"][1,1] <-
      gsub(".*\\( (.+) \\).*", "\\1",
           main_tournament_table["federation"][1,1])
    return(main_tournament_table)
  }

chess_results_table_1_class <- function(main_tournament_table) {
  for (i in c("number_of_rounds",
              "average_rating",
              "average_age",
              "fide_event_id")) {
    if (i %in% colnames(main_tournament_table)) {
      main_tournament_table[c(i)] <-
        lapply(main_tournament_table[c(i)], as.integer)
    }
  }
  if (tryCatch(readr::parse_date(main_tournament_table$start_date),
               error=function(x) NA)) {
    main_tournament_table[c("start_date",
                            "end_date")] <-
      lapply(main_tournament_table[c("start_date",
                                     "end_date")], readr::parse_date)
  }
  main_tournament_table <- main_tournament_table |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character), stringr::str_trim))
  return(main_tournament_table)
}

chess_results_fix_table_1 <- function(main_tournament_tables) {
  main_tournament_table <- main_tournament_tables[[1]]
  if (is.null(main_tournament_table)) {
    return(NA)
  }
  main_tournament_table <- main_tournament_table |>
    chess_results_transpose_table_1() |>
    janitor::clean_names() |>
    dplyr::rename(
      dplyr::any_of(
        unlist(chess_results_table_header_names()[[1]]))) |>
    chess_results_split_table_1() |>
    chess_results_table_1_time_and_federation() |>
    chess_results_table_1_suffix() |>
    chess_results_table_1_class()
  return(main_tournament_table)
}

chess_results_fix_table_2 <- function(main_tournament_tables) {
  main_tournament_table <- main_tournament_tables[[2]]
  main_tournament_table <- main_tournament_table |>
    subset(select = -c(1))
  main_tournament_table <- main_tournament_table |>
    tibble::as_tibble(.name_repair = "universal_quiet") |>
    janitor::clean_names() |>
    dplyr::rename(
      dplyr::any_of(
        unlist(chess_results_table_header_names()[[2]])))
  return(main_tournament_table)
}

chess_results_fix_main_table_names <- function(main_tournament_tables) {
  names(main_tournament_tables) <- c("tournament_information",
                                     "tournament_starting_rank")
  return(main_tournament_tables)
}
