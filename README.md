# chessResults

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/chessResults)](https://cran.r-project.org/package=chessResults)
<!-- badges: end -->

The goal of chessResults is to make it easier to scrape [chess-results.com](https://chess-results.com) in R. It currently returns a list of 5 elements: tournament information, starting rank, playing schedule, pairings/results for rounds, and closing rank. It does all of this in a polite manner to ensure that the [chess-results.com](https://chess-results.com) servers are not overwhelmed. Just supply the URL or the ID that is in the URL to the function and you are done.

**NOTE: the package currently does not support scraping tournament information for tournaments older than 5 days, and you will be warned about it when you scrape those pages.**

## Installation

You can install the latest version of chessResults from CRAN like so:

```r
install.packages("chessResults")
```

## Example

```r
library(chessResults)

data <- chess_results("1445162")
dplyr::glimpse(data)
# List of 5
#  $ tournament_information  : tibble [1 × 20] (S3: tbl_df/tbl/data.frame)
#   ..$ tournament_name      : chr "Kamyshin OPEN rapid 2026"
#   ..$ federation           : chr "RUS"
#   ..$ tournament_director_1: chr "Cherenkov"
#   ..$ tournament_director_2: chr "Andrey FIDE ID: 4185315"
#   ..$ chief_arbiter_1      : chr "Sevostjanov"
#   ..$ chief_arbiter_2      : chr "Roman FIDE ID: 24148482"
#   ..$ time_control         : chr "10'+5\""
#   ..$ rapid                : logi TRUE
#   ..$ location             : chr "Kamyshin"
#   ..$ number_of_rounds     : int 11
#   ..$ tournament_type      : chr "Swiss-System"
#   ..$ rating_calculation_1 : chr "Rating national"
#   ..$ rating_calculation_2 : chr "Rating international"
#   ..$ fide_event_id        : int 483777
#   ..$ start_date           : Date[1:1], format: "2026-07-09"
#   ..$ end_date             : Date[1:1], format: "2026-07-10"
#   ..$ average_rating       : int 1685
#   ..$ average_age          : int 24
#   ..$ pairing_program_1    : chr "Swiss-Manager from Heinz Herzog"
#   ..$ pairing_program_2    : chr "Swiss-Manager tournamentfile"
#  $ tournament_starting_rank: tibble [45 × 5] (S3: tbl_df/tbl/data.frame)
#   ..$ title     : chr [1:45] NA NA NA NA ...
#   ..$ name      : chr [1:45] "Андрей Федотов" "Андрей Андреевич Черенков" "Вячеслав Васекин" "Никита Алексеевич Карулин" ...
#   ..$ fide_id   : int [1:45] 24197351 4185315 55715265 34339663 34479767 24166804 55895549 24244732 24177580 55791565 ...
#   ..$ federation: chr [1:45] "RUS" "RUS" "RUS" "RUS" ...
#   ..$ rating    : int [1:45] 2094 2077 1940 2116 2098 1961 2026 1895 1930 1901 ...
#  $ playing_schedule        : tibble [11 × 2] (S3: tbl_df/tbl/data.frame)
#   ..$ date: Date[1:11], format: "2026-07-09" "2026-07-09" ...
#   ..$ time: 'hms' num [1:11] 16:00:00 16:30:00 17:00:00 17:30:00 ...
#   .. ..- attr(*, "units")= chr "secs"
#  $ rounds                  :List of 11
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#   ..$ : tibble [23 × 12] (S3: tbl_df/tbl/data.frame)
#  $ closing_rank            : tibble [45 × 9] (S3: tbl_df/tbl/data.frame)
#   ..$ starting_rank: int [1:45] 9 4 5 6 2 10 13 12 1 3 ...
#   ..$ title        : chr [1:45] NA NA NA NA ...
#   ..$ name         : chr [1:45] "Павел Кузуб" "Никита Алексеевич Карулин" "Тимофей Тютюнов" "Владислав Бельский" ...
#   ..$ federation   : chr [1:45] "RUS" "RUS" "RUS" "RUS" ...
#   ..$ rating       : int [1:45] 1930 2116 2098 1961 2077 1901 1853 1835 2094 1940 ...
#   ..$ points       : num [1:45] 9 9 8 8 8 7 7 7 6.5 6.5 ...
#   ..$ tie_breaker_1: num [1:45] 0 0 1 2 3 0 0 0 0 0 ...
#   ..$ tie_breaker_2: num [1:45] 77 76 78 76 76.5 75 69 64.5 78.5 75 ...
#   ..$ tie_breaker_3: num [1:45] 72 71.5 73 71.5 71 71 64.5 62 74 70 ...
```
