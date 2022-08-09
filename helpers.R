# Helper files for other scripts

library(tidyverse)
library(janitor)
library(lubridate)

sheets_input_formatting <- function(df) {
  
  if(is_character(df$total_budget)) {
    df <- df %>%
      mutate(
        total_budget = parse_number(total_budget),
      )
  }
  
  if(is_character(df$estimated_completion_date)) {
    df <- df %>%
      mutate(
        estimated_completion_date = parse_date(estimated_completion_date, format = "%B %d, %Y")
      )
  }
  
  return(df)
}

sheets_description_formatting <- function(df) {
  df <- df %>%
    mutate(
      description = str_squish(str_replace_all(description, "[\r\n]" , " "))
    )
  return(df)
}

export_formatted_yearly_csvs <- function(df, filename) {
  df %>%
    # mutate(
    #   estimated_completion_date = format(estimated_completion_date, "%B %d, %Y")
    # ) %>%
    clean_names(case = "lower_camel") %>%
    write_csv(filename, na = "")
}
