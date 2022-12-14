# Compare all 3 years

source("helpers.R")

data_2016 <- read_csv("data/source/data_2016.csv") %>%
  clean_names() %>%
  sheets_input_formatting()
data_2019 <- read_csv("data/source/data_2019.csv") %>%
  clean_names() %>%
  sheets_input_formatting()
data_2022 <- read_csv("data/source/data_2022.csv") %>%
  clean_names() %>%
  sheets_input_formatting()

as_of_date_latest <- parse_date("2022-04-25")
as_of_year_latest <- 2022

# Merge together
combined_data <- data_2022 %>%
  bind_rows(data_2016) %>%
  bind_rows(data_2019)

combined_data <- combined_data %>%
  mutate(
    as_of_date_date = parse_date(as_of_date, format = "%B %d, %Y"),
    as_of_year = year(as_of_date_date)
  )

combined_data_with_budgets_and_dates <- combined_data %>%
  filter(! is.na(total_budget)) %>%
  filter(! is.na(estimated_completion_date))

combined_data_missing_budgets_or_dates <- setdiff(combined_data, combined_data_with_budgets_and_dates)


unique_ids <- combined_data %>%
  select(unique_id) %>%
  distinct()

budgets_by_id <- combined_data %>%
  select(unique_id, as_of_year, total_budget) %>%
  filter(! is.na(total_budget)) %>%
  rename(
    budget_as_of_year = as_of_year
  )

ecd_by_id <- combined_data %>%
  select(unique_id, as_of_year, estimated_completion_date) %>%
  filter(! is.na(estimated_completion_date)) %>%
  rename(
    ecd_as_of_year = as_of_year
  )



consolidated_data <- combined_data %>%
  select(
    dept_acronym,
    shortcode,
    unique_id,
    department,
    project_name,
    description,
    as_of_year,
  ) %>%
  arrange(as_of_year, dept_acronym, project_name) %>%
  group_by(unique_id) %>%
  mutate(
    latest_project_name = last(project_name),
    latest_description = last(description),
    num_of_entries = n(),
  ) %>%
  ungroup() %>%
  select(
    dept_acronym,
    shortcode,
    unique_id,
    department,
    latest_project_name,
    latest_description,
    num_of_entries,
  ) %>%
  distinct() %>%
  arrange(dept_acronym, latest_project_name)


# Add budget data
consolidated_data <- consolidated_data %>%
  left_join(budgets_by_id, by = "unique_id") %>%
  arrange(unique_id, budget_as_of_year) %>%
  group_by(unique_id) %>%
  mutate(
    original_budget = first(total_budget),
    latest_budget = last(total_budget),
    original_budget_source = first(budget_as_of_year),
    latest_budget_source = last(budget_as_of_year),
  ) %>%
  ungroup() %>%
  select(! c(total_budget, budget_as_of_year)) %>%
  distinct() %>%
  arrange(dept_acronym, latest_project_name)


# Add estimated completion date data
consolidated_data <- consolidated_data %>%
  left_join(ecd_by_id, by = "unique_id") %>%
  arrange(unique_id, ecd_as_of_year) %>%
  group_by(unique_id) %>%
  mutate(
    original_estimated_completion_date = first(estimated_completion_date),
    latest_estimated_completion_date = last(estimated_completion_date),
    original_estimated_completion_date_source = first(ecd_as_of_year),
    latest_estimated_completion_date_source = last(ecd_as_of_year),
  ) %>%
  ungroup() %>%
  select(! c(estimated_completion_date, ecd_as_of_year)) %>%
  distinct() %>%
  arrange(dept_acronym, latest_project_name)


# Add project comparison information
consolidated_data <- consolidated_data %>%
  mutate(
    budget_delta = latest_budget - original_budget,
    budget_delta_percentage = str_c(round((budget_delta / original_budget) * 100, digits = 2), "%"),
  ) %>%
  mutate(
    dates_delta_year = round((original_estimated_completion_date %--% latest_estimated_completion_date) / years(1), digits = 2)
  ) %>%
  mutate(
    estimated_status_has_comparison_years = case_when(
      original_estimated_completion_date_source != latest_estimated_completion_date_source ~ TRUE,
      TRUE ~ FALSE
    ),
    estimated_status_is_latest_year = case_when(
      latest_estimated_completion_date_source == as_of_year_latest ~ TRUE,
      TRUE ~ FALSE
    ),
    estimated_status = case_when(
      # For all entries
      latest_estimated_completion_date <= as_of_date_latest & dates_delta_year > 0 ~ "completed (behind schedule)",
      latest_estimated_completion_date <= as_of_date_latest & dates_delta_year < 0 ~ "completed (ahead of schedule)",
      latest_estimated_completion_date <= as_of_date_latest ~ "completed",
      
      # For entries that are in the 2022 set
      estimated_status_is_latest_year & latest_estimated_completion_date < as_of_date_latest ~ "completed",
      estimated_status_is_latest_year & dates_delta_year > 0 ~ "behind schedule",
      estimated_status_is_latest_year & dates_delta_year < 0 ~ "ahead of schedule",
      estimated_status_is_latest_year & dates_delta_year == 0 & estimated_status_has_comparison_years ~ "on schedule",
      estimated_status_is_latest_year & !is.na(latest_estimated_completion_date) ~ "new",
      estimated_status_is_latest_year ~ "unknown (no dates specified)",
      
      # For entries that aren't in the 2022 set
      latest_estimated_completion_date > as_of_date_latest ~ "unknown (past due)",
      is.na(latest_estimated_completion_date) ~ "unknown (no dates specified)",
      TRUE ~ "unknown (surprise error case)"
    )
  ) %>%
  select(! c(estimated_status_has_comparison_years,estimated_status_is_latest_year)) %>% 
  mutate(
    is_over_10M = case_when(
      latest_budget > 10000000 ~ 1,
      TRUE ~ 0
    ),
    is_over_100M = case_when(
      latest_budget > 100000000 ~ 1,
      TRUE ~ 0
    ),
  )
  
# Final cleanup before exporting
consolidated_data <- consolidated_data %>%
  mutate(
    budget_delta_percentage = case_when(
      budget_delta == 0 ~ NA_character_,
      TRUE ~ budget_delta_percentage
    ),
    budget_delta = case_when(
      budget_delta == 0 ~ NA_real_,
      TRUE ~ budget_delta
    ),
    dates_delta_year = case_when(
      dates_delta_year == 0 ~ NA_real_,
      TRUE ~ dates_delta_year
    ),
  )

# Final arrange ordering

consolidated_data <- consolidated_data %>%
  arrange(dept_acronym, unique_id)

consolidated_data %>%
  export_formatted_yearly_csvs("data/out/gc-it-projects-combined-2022.csv")
