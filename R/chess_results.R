#' Get all data for a tournament
#'
#' Scrape a list of tibble from chess-results.com by giving a URL
#' or tournament ID. (The tournament ID can be found in the URL).
#' It currently returns tournament information, starting rank,
#' playing schedule, pairings/results for each round, and closing rank.
#'
#' @param id The URL or the tournament ID of the tournament page
#' @param user_agent The User Agent to be used when accessing
#'                   chess-results.com
#' @returns A list of tibble about the different aspects of
#'          the tournament. The sub-list contains the data for
#'          the pairings/results for each round.
#'
#' @examples
#' \donttest{
#' url <- "https://s3.chess-results.com/tnr1445162.aspx?lan=1"
#' data <- chess_results(url)
#' dplyr::glimpse(data)
#' }
#' @export

chess_results <- function(id, user_agent = "chessResults R package") {
  tournament_data <- harvest_tournament_data(id, user_agent)
  tournament_data[[1]] <-
    fix_tournament_information(tournament_data)
  tournament_data[[2]] <-
    fix_starting_rank(tournament_data)
  tournament_data[[3]] <-
    fix_playing_schedule(tournament_data)
  tournament_data[[4]] <-
    fix_rounds(tournament_data)
  tournament_data[[5]] <-
    fix_closing_rank(tournament_data)
  tournament_data <-
    fix_list_names(tournament_data)
  return(tournament_data)
}

extract_correct_id <- function(id) {
  if (startsWith(id, "https")) {
    id <- sub(".*tnr *(.*?) *\\.aspx.*",
              "\\1", id)
  }
  return(id)
}

generate_url <- function(id, page, round = NA) {
  if (is.na(round)) {
    url <- paste0("https://chess-results.com/tnr",
                  id, ".aspx?lan=1&art=", page, "&turdet=ALL&flag=NO",
                  "&zeilen=99999")
  } else {
    url <- paste0("https://chess-results.com/tnr",
                  id, ".aspx?lan=1&art=", page, "&turdet=ALL&flag=NO&rd=",
                  round, "&zeilen=99999")
  }
  return(url)
}


harvest_tournament_data <- function(id, user_agent) {
  id <- extract_correct_id(id)
  message("Harvesting tournament_information and starting_rank.")
  url <- generate_url(id, 0)
  page_html <- rvest::read_html(url)
  temporary_tournament_name <- page_html |>
    rvest::html_elements("title") |>
    rvest::html_text()
  tournament_name <- sub("\r\n\tChess-Results Server Chess-results.com - ",
                         "", temporary_tournament_name, fixed = TRUE)
  tournament_name <- sub("\r\n", "", tournament_name, fixed = TRUE)
  tournament_data <- page_html |>
    rvest::html_elements("table") |>
    rvest::html_table(convert = TRUE,
                      na.strings = c("", 0, ".", "-"))
  if (grepl("defaultDialogMsg", page_html, fixed = TRUE)) {
    # This section needs rvest::read_html_live() to click the button for
    # showing tournament details. I have not figured out how to do that yet,
    # so this is currently returning just a NA for tournament_information.
    table_position <- 4
    tournament_data <- list(NA, tournament_data[[table_position]])
    warning(paste0("The tournament is more than 5 days old. ",
                   "tournament_information is NA. ",
                   "Please help the developer in scrapping ",
                   "the tibble for such tournaments ",
                   "at the Codeberg repo. ",
                   "<https://codeberg.org/SirfHaru/chessresults>"))
  } else {
    table_position <- 6
    tournament_data <- tournament_data[c(table_position - 2,
                                         table_position)]
    # Move the following line outside of the conditional
    # when rvest::read_html_live is implemented in the if part.
    tournament_data[[1]] <-
      tibble::add_row(tournament_data[[1]], X1 = "tournament_name",
                      X2 = tournament_name, .before = 1)
  }
  message("Harvesting playing_schedule.")
  url <- generate_url(id, 14)
  page_html <- rvest::read_html(url)
  temporary_tournament_data <- page_html |>
    rvest::html_elements("table") |>
    rvest::html_table()
  tournament_data[[3]] <- temporary_tournament_data[[table_position]]
  message("Harvesting rounds.")
  url <- generate_url(id, 2, 0)
  page_html <- rvest::read_html(url)
  temporary_tournament_data <-
    page_html |>
    rvest::html_elements("table") |>
    rvest::html_table(header = TRUE,
                      convert = TRUE,
                      na.strings = c("", 0))
  table_position <- table_position - 1
  tournament_data[[4]] <-
    temporary_tournament_data[-c(1:table_position,
                                 length(temporary_tournament_data))]
  tournament_data[[4]] <- rev(tournament_data[[4]])
  message("Harvesting closing_rank.")
  url <- generate_url(id, 1)
  page_html <- rvest::read_html(url)
  temporary_tournament_data <- page_html |>
    rvest::html_elements("table") |>
    rvest::html_table(convert = TRUE,
                      na.strings = c(""))
  table_position <- table_position + 1
  if (length(temporary_tournament_data) < table_position) {
    tournament_data[[5]] <- NA
  } else {
    tournament_data[[5]] <- temporary_tournament_data[[table_position]]
  }
  return(tournament_data)
}

column_names <- function() {
  column_names <-
    list(list(organizer = "organizer_s",
              average_rating = "rating_o"),
         list(title = "x1",
              federation = "fed",
              rating = "rtg",
              club_or_city = "club_city",
              international_rating = "rtg_i",
              national_rating = "rtg_n",
              group = "gr",
              type = "typ"),
         list(white_title = "x",
              white_rating = "rtg",
              white_club_or_city = "club_city",
              white_points = "pts",
              black_title = "x_2",
              black_rating = "rtg_2",
              black_club_or_city = "club_city_2",
              black_points = "pts_2",
              white_rank = "no",
              black_rank = "no_2"),
         list(title = "x",
              rating = "rtg",
              federation = "fed",
              points = "pts",
              starting_rank = "s_no"))
  return(column_names)
}

transpose_tournament_information <- function(tournament_data) {
  tournament_data <- tournament_data |>
    t() |>
    janitor::row_to_names(1) |>
    tibble::as_tibble() |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character), stringr::str_trim))
  return(tournament_data)
}

split_tournament_information <- function(tournament_data) {
  columns <- colnames(tournament_data)
  if ("date" %in% columns) {
    tournament_data <- tournament_data |>
      tidyr::separate_wider_delim("date",
                                  delim = " to ",
                                  names = c("start_date", "end_date"),
                                  too_few = "align_start")
    if (is.na(tournament_data["end_date"])) {
      tournament_data["end_date"] <- tournament_data["start_date"]
    }
  }
  if ("rating_o_average_age" %in% columns) {
    tournament_data <- tournament_data |>
      tidyr::separate_wider_delim("rating_o_average_age",
                                  delim = " / ",
                                  names = c("average_rating", "average_age"))
  }
  for (i in c("organizer", "tournament_director", "arbiter",
              "chief_arbiter", "deputy_chief_arbiter",
              "rating_calculation", "pairing_program")) {
    if (i %in% columns) {
      tournament_data[i] <- tournament_data[i] |>
        unlist() |>
        stringr::str_replace("[,]{1,}$", "")
      tournament_data <- tournament_data |>
        tidyr::separate_wider_delim(dplyr::all_of(i),
                                    delim = stringr::regex("[,;]\\s*"),
                                    names_sep = "_")
    }
  }
  for (i in c("standard", "rapid", "blitz", "bullet")) {
    if (any(grepl(i, columns))) {
      tournament_data <- tournament_data |>
        cbind(i = TRUE)
      names(tournament_data)[ncol(tournament_data)] <-
        i
      tournament_data <- tournament_data |>
        dplyr::rename_with(~ paste0("time_control"),
                           dplyr::contains("time_control"))
      tournament_data <- tournament_data |>
        dplyr::relocate(
          names(tournament_data)[ncol(tournament_data)],
          .after = "time_control")
    }
  }
  return(tournament_data)
}

fix_tournament_information_data <- function(tournament_data) {
  columns <- colnames(tournament_data)
  if ("federation" %in% columns) {
    tournament_data["federation"][1,1] <-
      gsub(".*\\( (.+) \\).*", "\\1",
           tournament_data["federation"][1,1])
  }
  for (i in c("number_of_rounds", "average_rating",
              "average_age", "fide_event_id")) {
    if (i %in% columns) {
      tournament_data[c(i)] <-
        lapply(tournament_data[c(i)], as.integer)
    }
  }
  if ("start_date" %in% columns) {
    tournament_data[c("start_date", "end_date")] <-
      lapply(tournament_data[c("start_date", "end_date")],
             readr::parse_date)
  }
  for (i in c("name", "location", "time_control")) {
    if (i %in% columns) {
      tournament_data[i] <- tournament_data[i] |>
        unlist() |>
        stringr::str_replace("[,]{1,}$", "")
    }
  }
  tournament_data <- tournament_data |>
    tibble::as_tibble()
  return(tournament_data)
}

fix_tournament_information <- function(tournament_data) {
  tournament_data <- tournament_data[[1]]
  if (!is.data.frame(tournament_data)) {
    return(NA)
  }
  tournament_data <- tournament_data |>
    transpose_tournament_information() |>
    janitor::clean_names() |>
    dplyr::rename(
      dplyr::any_of(
        unlist(column_names()[[1]]))) |>
    split_tournament_information() |>
    fix_tournament_information_data()
  return(tournament_data)
}

fix_names_and_remove_comma <- function(tournament_data) {
  columns <- colnames(tournament_data)
  for (i in columns) {
    if (i %in% c("name", "club_or_city", "white", "black",
                 "white_club_or_city", "black_club_or_city")) {
      tournament_data[i] <- tournament_data[i] |>
        unlist() |>
        stringr::str_replace("[,]{1,}$", "")
      if (i %in% c("name", "black", "white")) {
        tournament_data[i] <-
          sub("(^.*),\\s(.*$)","\\2 \\1", tournament_data[[i]])
      }
    }
  }
  return(tournament_data)
}

fix_starting_rank_data <- function(tournament_data) {
  columns <- colnames(tournament_data)
  for (i in c("name", "club_or_city")) {
    if (i %in% columns) {
      tournament_data[i] <- tournament_data[i] |>
        unlist() |>
        stringr::str_replace("[,]{1,}$", "")
    }
  }
  if ("sex" %in% columns) {
    tournament_data["sex"] <-
      lapply(tournament_data["sex"],
             stringr::str_to_upper)
  }
  tournament_data <- fix_names_and_remove_comma(tournament_data)
  if ("title" %in% columns) {
    tournament_data["title"] <- lapply(tournament_data["title"],
                                       as.character)
  }
  tournament_data[] <-
    lapply(tournament_data, function(x) { attributes(x) <- NULL; x })
  return(tournament_data)
}

fix_starting_rank <- function(tournament_data) {
  tournament_data <- tournament_data[[2]]
  tournament_data <- tournament_data |>
    subset(select = -c(1))
  tournament_data <- tournament_data |>
    tibble::as_tibble(.name_repair = "universal_quiet") |>
    janitor::clean_names() |>
    dplyr::rename(
      dplyr::any_of(
        unlist(column_names()[[2]]))) |>
    fix_starting_rank_data()
  return(tournament_data)
}

fix_playing_schedule_data <- function(tournament_data) {
  columns <- colnames(tournament_data)
  if ("date" %in% columns) {
    tournament_data["date"] <- lapply(tournament_data["date"],
                                      readr::parse_date)
  }
  if ("time" %in% columns) {
    tournament_data["time"] <- lapply(tournament_data["time"],
                                      readr::parse_time)
  }
  return(tournament_data)
}

fix_playing_schedule <- function(tournament_data) {
  tournament_data <- tournament_data[[3]]
  if (identical(tournament_data$Date[1], "unknown")) {
    return(NA)
  }
  tournament_data <- tournament_data |>
    subset(select = -c(1))
  tournament_data <- tournament_data |>
    janitor::clean_names() |>
    fix_playing_schedule_data()
  return(tournament_data)
}

split_rounds <- function(tournament_data) {
  tournament_data <- tournament_data |>
    tidyr::separate_wider_delim("result",
                                delim = " - ",
                                names = c("white_result",
                                          "black_result"),
                                too_few = "align_start")
  return(tournament_data)
}

fix_rounds_data <- function(tournament_data) {
  columns <- colnames(tournament_data)
  tournament_data <- fix_names_and_remove_comma(tournament_data)
  for (i in columns) {
    if (i %in% c("white_result", "black_result",
                 "white_points", "black_points")) {
      tournament_data[tournament_data == "+"] <- "1"
      tournament_data[tournament_data == "-"] <- "0"
      tournament_data[i] <- lapply(tournament_data[i],
                                   function(x) gsub("\u00BD", ".5", x))
      tournament_data[i] <- lapply(tournament_data[i],
                                   readr::parse_double)
    }
  }
  for (i in c("white_title", "black_title", "white", "black")) {
    tournament_data[i] <- lapply(tournament_data[i],
                                 as.character)
  }
  for (i in c("white_rating", "black_rank",
              "black_rating", "white_rank")) {
    if (i %in% columns) {
      tournament_data[i] <- lapply(tournament_data[i],
                                   as.integer)
    }
  }
  tournament_data[] <-
    lapply(tournament_data, function(x) { attributes(x) <- NULL; x })
  return(tournament_data)
}

fix_rounds <- function(tournament_data) {
  tournament_data <- tournament_data[[4]]
  if (identical(tournament_data, list())) {
    return(NA)
  }
  for (i in 1:length(tournament_data)) {
    tournament_data[[i]] <- tournament_data[[i]] |>
      subset(select = -c(1))
    tournament_data[[i]] <- tournament_data[[i]] |>
      tibble::as_tibble(.name_repair = "minimal") |>
      janitor::clean_names() |>
      dplyr::rename(
        dplyr::any_of(
          unlist(column_names()[[3]]))) |>
      split_rounds() |>
      fix_rounds_data()
  }
  return(tournament_data)
}

fix_closing_rank_data <- function(tournament_data) {
  columns <- colnames(tournament_data)
  for (i in c("title", "federation")) {
    if (i %in% columns) {
      tournament_data[i] <- lapply(tournament_data[i],
                                   as.character)
    }
  }
  if ("rating" %in% columns) {
    tournament_data["rating"] <-
      dplyr::na_if(tournament_data[["rating"]], 0)
    tournament_data["rating"] <- lapply(tournament_data["rating"],
                                        as.integer)
  }
  if ("points" %in% columns) {
    tournament_data["points"] <- sub(",", ".", tournament_data[["points"]])
    tournament_data["points"] <- lapply(tournament_data["points"],
                                        readr::parse_double)
  }
  for (i in columns) {
    if (grepl("tb", i, fixed = TRUE)) {
      tournament_data[i] <- gsub(",", ".", tournament_data[[i]],
                                 fixed = TRUE)
      tournament_data[i] <- lapply(tournament_data[i],
                                   readr::parse_double)
    }
  }
  for (i in columns) {
    if (grepl("tb", i, fixed = TRUE)) {
      names(tournament_data) <- sub("tb", "tie_breaker_",
                                    names(tournament_data),
                                    fixed = TRUE)
    }
  }
  tournament_data <- fix_names_and_remove_comma(tournament_data)
  tournament_data[] <-
    lapply(tournament_data, function(x) { attributes(x) <- NULL; x })
  return(tournament_data)
}

fix_closing_rank <- function(tournament_data) {
  tournament_data <- tournament_data[[5]]
  if (!is.data.frame(tournament_data)) {
    return(NA)
  }
  tournament_data <- tournament_data |>
    subset(select = -c(1))
  tournament_data <- tournament_data |>
    janitor::clean_names() |>
    dplyr::rename(
      dplyr::any_of(
        unlist(column_names()[[4]]))) |>
    fix_closing_rank_data()
  return(tournament_data)
}

fix_list_names <- function(tournament_data) {
  names(tournament_data) <- c("tournament_information",
                              "tournament_starting_rank",
                              "playing_schedule",
                              "rounds",
                              "closing_rank")
  return(tournament_data)
}
