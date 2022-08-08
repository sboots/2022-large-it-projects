# Compares and merges the 3 years of data into one, to facilitate
# manual project labelling/matching.

library(tidyverse)
library(janitor)

data_2022 <- read_csv("data/out/projects_merged_raw_with_owners.csv") %>%
  rename(
    dept_acronym = owner_org,
    project_name = description,
    description = summary
  ) %>% mutate(
    source = "8530-441-13-505",
    as_of_date = "April 25, 2022",
    original_document_order = row_number()
  )

sheets_input_formatting <- function(df) {
  df <- df %>%
    mutate(
      total_budget = parse_number(total_budget),
      estimated_completion_date = parse_date(estimated_completion_date, format = "%B %d, %Y")
    )
  return(df)
}

data_2016 <- read_csv("data/source/data_2016.csv") %>%
  clean_names() %>%
  sheets_input_formatting()
data_2019 <- read_csv("data/source/data_2019.csv") %>%
  clean_names() %>%
  sheets_input_formatting()



# Bind these together, and only keep the description and summary rows
combined_data <- data_2022 %>%
  #select(dept_acronym, project_name, description, source, as_of_date, original_document_order) %>%
  bind_rows(data_2016) %>%
  bind_rows(data_2019) %>%
  select(dept_acronym, shortcode, project_name, description, total_budget, estimated_completion_date, source, as_of_date, original_document_order) 

combined_data <- combined_data %>%
  arrange(dept_acronym, project_name)

combined_data %>% write_csv("data/out/combined_data_descriptions.csv", na = "")
