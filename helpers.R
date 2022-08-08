# Helper files for other scripts

library(tidyverse)
library(janitor)

sheets_input_formatting <- function(df) {
  df <- df %>%
    mutate(
      total_budget = parse_number(total_budget),
      estimated_completion_date = parse_date(estimated_completion_date, format = "%B %d, %Y")
    )
  return(df)
}

sheets_description_formatting <- function(df) {
  df <- df %>%
    mutate(
      description = str_squish(str_replace_all(description, "[\r\n]" , " "))
    )
  return(df)
}
