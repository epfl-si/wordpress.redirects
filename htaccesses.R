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
    filter(path != "srv/subdomains/.htaccess") %>%
    filter(! grepl("srv/subdomains/[^/]*.epfl.ch/[^/]*.epfl.ch", path)) %>%
    separate_wider_regex(
        path, c("srv/", wp_env = "[^/]*", "/", host = "[^/]*",
                "/htdocs", uri_path = ".*", ".htaccess"),
        cols_remove = FALSE) %>%
    mutate(.by = path,
           line = sub("^ *", "", line),
           wordpress_block_step = accumulate(
               line, .init=0,
               count_found, "# BEGIN WordPress", "# END WordPress") %>%
               .[-1]) %>%
    separate_wider_delim(line, " ", names=c("cmd", "args"),
                         too_few="align_start", too_many="merge",
                         cols_remove=FALSE)

redirects <- htaccesses %>%
    filter(wordpress_block_step != 1 &
           cmd %in% c("RewriteCond", "RewriteRule",
                      "redirect", "Redirect", "RedirectMatch"))

wordpress_section_anomalies <-
    htaccesses %>%
    filter((line == "# BEGIN WordPress" & wordpress_block_step != 1) |
           (line == "# END WordPress" &   wordpress_block_step != 2))
