# chessResults

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of chessResults is to make it easier to scrap [chess-results.com](https://chess-results.com) in R.

## Installation

You can install the development version of chessResults like so:

```r
pak::pak("git::https://codeberg.org/SirfHaru/chessResults.git")
```

## Example

```r
library(chessResults)

data <- chess_results("1443765")
dplyr::glimpse(data)
# List of 2
#  $ tournament_information  : tibble [1 × 11] (S3: tbl_df/tbl/data.frame)
#   ..$ federation          : chr "HKG"
#   ..$ chief_arbiter_1     : chr "GM Andres Gallego"
#   ..$ time_control        : chr "Standard: 90min +30sec increment per move starting from move 1"
#   ..$ pairing_program_1   : chr "ChessManager"
#   ..$ location            : chr "Hong Kong"
#   ..$ number_of_rounds    : int 5
#   ..$ tournament_type     : chr "Swiss-System"
#   ..$ rating_calculation_1: chr "Rating international"
#   ..$ start_date          : Date[1:1], format: "2026-07-03"
#   ..$ end_date            : Date[1:1], format: "2026-07-05"
#   ..$ average_rating      : int 1650
#  $ tournament_starting_rank: tibble [26 × 6] (S3: tbl_df/tbl/data.frame)
#   ..$ title       : chr [1:26] "CM" "CM" "FM" NA ...
#   ..$ name        : chr [1:26] "Kao, Jamison Edrich" "Jimenez Alvarado, Jimmy Joseph" "Lam, Daniel King Wai" "Nguyen, Paul Ashton" ...
#   ..$ fide_id     : int [1:26] 6007937 4427360 6001238 6007996 6009727 6009999 6002552 6002340 6021212 6012710 ...
#   ..$ rating      : int [1:26] 2242 2031 1986 1915 1905 1905 1845 1793 1723 1711 ...
#   ..$ sex         : chr [1:26] "M" "M" "M" "M" ...
#   ..$ club_or_city: logi [1:26] NA NA NA NA NA NA ...
```
