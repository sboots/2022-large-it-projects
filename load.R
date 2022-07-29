# Extract tabular data from the sessional paper with 
# current Government of Canada IT projects over $1M

# Thanks to
# https://github.com/lchski/gc-privacy-breaches-data/blob/main/load.R
# from which this code is adapted.

library(tidyverse)
library(docxtractr)
library(purrr)

# load PDF that's been converted by Word
projects_docx <- docxtractr::read_docx("data/source/8530-441-13-505-b-rotated.docx")

project_tables_raw <- tibble(project_table = docx_extract_all_tbls(projects_docx)) %>%
  mutate(
    table_id = row_number(),
    table_col_n = map_dbl(project_table, ncol),
    table_row_n = map_dbl(project_table, nrow)
  ) %>%
  select(table_id, project_table, everything())

# project_tables_raw %>% slice(5:n()) %>% select(project_table) %>% head(n = 10) %>% pull(project_table)

project_tables_filtered <- project_tables_raw %>%
  slice(5:n()) %>%
  filter(table_col_n == 4 | table_col_n == 5)

# Some tables have a spurious empty column in between 
# so we'll handle 4-column and 5-column entries differently

project_tables_4c <- project_tables_filtered %>%
  filter(table_col_n == 4)

# Use with a map function to rename the columns
# This function also uses the column names to determine whether the 
# table is in English or French.
# Finally it looks for specific text that indicates a 
# second or third header row, and marks those in another column.
rename_internal_columns <- function(df) {
  
  # Determine the language by using the first column name
  names <- names(df)
  first_col_name = names[[1]]
  
  output <- df %>%
    rename(
      description = 1,
      summary = 2,
      total_budget = 3,
      estimated_completion_date = 4
    ) %>%
    mutate(
      language = case_when(
        str_starts(!!first_col_name, "what") ~ "en",
        str_starts(!!first_col_name, "quels") ~ "fr",
        TRUE ~ NA_character_
      )
    ) %>%
    mutate(
      header_row = case_when(
        str_starts(description, "description") ~ TRUE,
        str_starts(description, "\\(i\\)") ~ TRUE,
        description == "" ~ TRUE,
        TRUE ~ FALSE
      )
    )

  # Thanks to
  # https://stackoverflow.com/a/56174969/756641
  # for the note about searching for text with parentheses.
    
  return(output)
}

# Bring in the renamed list-column table and remove the original one.
project_tables_4c <- project_tables_4c %>% 
  mutate(
    renamed_project_table = map(project_table, rename_internal_columns)
  ) %>%
  select(! project_table)


project_tables_4c <- project_tables_4c %>% 
  unnest(
    cols = c(renamed_project_table), 
    names_repair = "universal",
    keep_empty = TRUE
  )

project_tables_4c_filtered <- project_tables_4c %>%
  filter(header_row == FALSE) %>%
  filter(language != "fr")
