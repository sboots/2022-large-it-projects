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

# Note: these are now for comparison purposes only;
# the map function below handles both cases and
# uses project_tables_filtered as input.
project_tables_4c <- project_tables_filtered %>%
  filter(table_col_n == 4)

project_tables_5c <- project_tables_filtered %>%
  filter(table_col_n == 5)

# Use with a map function to rename the columns
# This function also uses the column names to determine whether the 
# table is in English or French.
# Finally it looks for specific text that indicates a 
# second or third header row, and marks those in another column.
rename_internal_columns <- function(df) {
  
  # Determine the language by using the first column name
  names <- names(df)
  
  
  if (ncol(df) == 4) {
    #print("4 cols")
    first_col_name = names[[1]]
    
    output <- df %>%
      rename(
        description = 1,
        summary = 2,
        total_budget = 3,
        estimated_completion_date = 4
      ) %>%
      mutate(
        other_description = ""
      )
    
  } else if (ncol(df) == 5) {
    #print("5 cols")
    first_col_name = names[[2]]
    
    # Typically (in all but a handful of cases) the second column is empty in 5-column tables.
    # Will cover the other cases manually.
    output <- df %>%
      rename(
        description = 1,
        other_description = 2,
        summary = 3,
        total_budget = 4,
        estimated_completion_date = 5
      ) 
  }
  
  
  
  output <- output %>%
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
project_tables_renamed <- project_tables_filtered %>% 
  mutate(
    renamed_project_table = map(project_table, rename_internal_columns)
  ) %>%
  select(! project_table)


project_tables_unnested <- project_tables_renamed %>% 
  unnest(
    cols = c(renamed_project_table), 
    names_repair = "universal",
    keep_empty = TRUE
  )

project_tables_reduced <- project_tables_unnested %>%
  filter(header_row == FALSE) %>%
  filter(language != "fr")

project_tables_cleaned <- project_tables_reduced %>%
  rename(
    total_budget_raw = total_budget,
    estimated_completion_date_raw = estimated_completion_date
  ) %>%
  mutate(
    total_budget = parse_number(total_budget_raw),
    estimated_completion_date = parse_date(estimated_completion_date_raw)
  ) %>%
  select(! language) %>%
  select(! header_row)

project_tables_cleaned %>%
  select(
    table_id,
    description,
    summary,
    other_description,
    total_budget_raw,
    total_budget,
    estimated_completion_date_raw,
    estimated_completion_date
    ) %>%
  write_csv("data/out/projects_merged_raw.csv")


# Missing tables (with different numbers of columns?)

project_tables_missing <- project_tables_raw %>%
  slice(5:n()) %>%
  filter(table_col_n != 4 & table_col_n != 5) %>%
  filter(table_row_n != 0)

# Note: the missing tables don't appear here; will add these 
# manually from the Word doc.
