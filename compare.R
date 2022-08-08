# Compares and merges the 3 years of data into one, to facilitate
# manual project labelling/matching.

library(tidyverse)
library(janitor)

source("helpers.R")

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


# Bring back in the merged data

matched_data <- read_csv("data/out/combined_data_descriptions_matched.csv") %>%
  mutate(
    total_budget = parse_number(total_budget)
  )

# Departmental harmonizing

old_count <- combined_data %>%
  count(dept_acronym)

new_count <- matched_data %>%
  count(dept_acronym)

compare_count <- old_count %>%
  left_join(new_count, by = "dept_acronym")

compare_count <- compare_count %>%
  mutate(
    is_different = n.x != n.y
  )

compare_count %>% filter(is_different)

# Departments to fix: ECCC, INAC
# ec to eccc and isc to inac (for consistency)

combined_data <- combined_data %>% mutate(
  dept_acronym = case_when(
    dept_acronym == "ec" ~ "eccc",
    dept_acronym == "isc" ~ "inac",
    TRUE ~ dept_acronym
  )
)

joined_data <- combined_data %>%
  left_join(matched_data, by = c("dept_acronym", "project_name"))

joined_data <- joined_data %>%
  mutate(
    is_updated_shortcode = shortcode.x != shortcode.y
  )

# Find updated shortcodes in previous years

joined_data %>% filter(is_updated_shortcode) %>% select(dept_acronym, shortcode.x, shortcode.y, source.x, as_of_date.x) %>% arrange(source.x)


# Bring the shortcodes back into the 2022 data

merged_data_2022 <- data_2022 %>%
  left_join(matched_data, by = c("source", "original_document_order"))

# Confirm that that worked
merged_data_2022 %>%
  select(project_name.x, project_name.y) %>%
  View()

merged_data_2022 <- merged_data_2022 %>%
  select(
    dept_acronym.x,
    shortcode,
    project_name.x,
    description.x, 
    total_budget.x, 
    estimated_completion_date.x,
    estimated_completion_date_raw,
    source,
    as_of_date.x
  )

merged_data_2022 <- merged_data_2022 %>%
  rename(
    dept_acronym = dept_acronym.x,
    project_name = project_name.x,
    description = description.x, 
    total_budget = total_budget.x, 
    estimated_completion_date = estimated_completion_date.x,
    as_of_date = as_of_date.x
  )

merged_data_2022 <- merged_data_2022 %>% mutate(
  dept_acronym = case_when(
    dept_acronym == "ec" ~ "eccc",
    dept_acronym == "isc" ~ "inac",
    TRUE ~ dept_acronym
  )
)

merged_data_2022 <- merged_data_2022 %>%
  mutate(
    unique_id = str_c(dept_acronym, "-", shortcode)
  )

departments_table <- read_csv("data/source/org_reference.csv") %>%
  rename(
    dept_acronym = acronym_en,
    department = name_en
  )

merged_data_2022 <- merged_data_2022 %>%
  left_join(departments_table, by = "dept_acronym")

merged_data_2022 <- merged_data_2022 %>%
  relocate(
    dept_acronym,
    shortcode,
    unique_id,
    department
  )

# Export the current merged 2022 data for posterity

merged_data_2022 %>%
  sheets_description_formatting() %>%
  export_formatted_yearly_csvs("data/source/data_2022.csv")
