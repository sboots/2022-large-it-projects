# Loads a manually-parsed CSV and does additional analysis.

library(tidyverse)

# Fixes for department-specific number formatting:

working_file <- "data/out/projects_merged_raw_with_owners.csv"
date_corrections_file <- "data/out/date_corrections.csv"

project_tables <- read_csv(working_file)

# Fix number formatting based on the indicator columns
project_tables_updated <- project_tables %>%
  mutate(
    total_budget = case_when(
      in_thousands == TRUE ~ parse_number(total_budget_raw) * 1000L,
      in_millions == TRUE ~ parse_number(total_budget_raw) * 1000000L,
      TRUE ~ parse_number(total_budget_raw)
    )
  ) %>%
  mutate(
    estimated_completion_date = parse_date(estimated_completion_date_raw)
  )


# See the results:

project_tables_updated %>%
  select(owner_org, total_budget_raw, total_budget, in_thousands, in_millions) %>%
  View()

project_tables_updated %>%
  select(owner_org, estimated_completion_date_raw, estimated_completion_date) %>%
  View()


# Remove spurious entries that aren't actual projects:
project_tables_updated <- project_tables_updated %>%
  filter(!is.na(total_budget_raw))

# TODO: Handle fiscal-year-type dates. (e.g. "2022-23", "Fiscal Year 24/25 3", "Q4 2024/25" etc.)

date_corrections <- project_tables %>%
  filter(is.na(estimated_completion_date)) %>%
  select(estimated_completion_date_raw) %>%
  distinct() %>%
  arrange(estimated_completion_date_raw)

date_corrections <- date_corrections %>%
  mutate(
    estimated_completion_date_fixed = str_replace_all(estimated_completion_date_raw, "September 20", "September 30, 20"),
    estimated_completion_date_fixed = str_replace_all(estimated_completion_date_fixed, "March 20", "March 31, 20"),
  ) %>%
  mutate(
    corrected_date = parse_date(estimated_completion_date_fixed, format = "%B %d, %Y")
  ) %>%
  mutate(
    corrected_date = case_when(
      is.na(corrected_date) ~ parse_date(estimated_completion_date_fixed, format = "%m/%d/%Y"),
      TRUE ~ corrected_date
    )
  ) %>%
  mutate(
    corrected_date = case_when(
      is.na(corrected_date) ~ parse_date(estimated_completion_date_fixed, format = "%d/%m/%Y"),
      TRUE ~ corrected_date
    )
  ) %>%
  mutate(
    corrected_date = case_when(
      is.na(corrected_date) ~ parse_date(estimated_completion_date_fixed, format = "%m-%d-%Y"),
      TRUE ~ corrected_date
    )
  ) %>%
  mutate(
    corrected_date = case_when(
      is.na(corrected_date) ~ parse_date(estimated_completion_date_fixed, format = "%d-%m-%Y"),
      TRUE ~ corrected_date
    )
  )

date_corrections %>%
  View()

date_corrections %>%
  select(estimated_completion_date_raw, corrected_date) %>%
  write_csv(date_corrections_file)

# Optionally write the data back:
project_tables_updated %>% write_csv(working_file)
