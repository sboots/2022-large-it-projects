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


consolidated_data <- consolidated_data %>%
  mutate(
    budget_delta = latest_budget - original_budget,
    budget_delta_percentage = round((budget_delta / original_budget) * 100, digits = 2),
  ) %>%
  mutate(
    dates_delta = round((original_estimated_completion_date %--% latest_estimated_completion_date) / years(1), digits = 2)
  ) %>%
  mutate(
    budget_delta_percentage = case_when(
      budget_delta == 0 ~ NA_real_,
      TRUE ~ budget_delta_percentage
    ),
    budget_delta = case_when(
      budget_delta == 0 ~ NA_real_,
      TRUE ~ budget_delta
    ),
    dates_delta = case_when(
      dates_delta == 0 ~ NA_real_,
      TRUE ~ dates_delta
    ),
  )

# Final arrange ordering

consolidated_data <- consolidated_data %>%
  arrange(dept_acronym, unique_id)

consolidated_data %>%
  export_formatted_yearly_csvs("data/out/gc-it-projects-combined-2022.csv")
