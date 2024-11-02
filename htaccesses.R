library(archive)

archive_lines <- function(archive_filename) {
    archive(archive_filename) %>%
        rowwise %>%
        reframe(archive_read(archive_filename, path) %>%
                read_lines %>%
                tibble(path=path, lines=.))
}

htaccesses_tar <- archive_lines("htaccesses.tar")

