library(tidyverse)
library(archive)

archive_lines <- function(archive_filename) {
    archive(archive_filename) %>%
        rowwise %>%
        reframe(archive_read(archive_filename, path) %>%
                read_lines %>%
                tibble(path=path, line=.))
}

count_found <- function(n, line, ...) {
  seps <- list(...)  # Collect arbitrary number of separators in a list

  case_when(
      # Loop over the list of separators, checking each one by position.
      # For the triple-bang see: https://rlang.r-lib.org/reference/splice-operator.html
      !!!purrr::imap(seps, ~ { line == .x ~ ifelse(n == .y - 1, .y, n)}),
      TRUE ~ n)
}

htaccesses <- archive_lines("htaccesses.tar") %>%
    mutate(.by = path,
           wordpress_block_step = accumulate(
               line, .init=0,
               count_found, "# BEGIN WordPress", "# END WordPress") %>%
               .[-1])
