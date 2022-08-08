# Cleanup old CSV files

source("helpers.R")

data_2016 <- read_csv("data/source/data_2016.csv") %>%
  clean_names() %>%
  sheets_input_formatting() %>%
  sheets_description_formatting()
data_2019 <- read_csv("data/source/data_2019.csv") %>%
  clean_names() %>%
  sheets_input_formatting() %>%
  sheets_description_formatting()

if(menu(c("Yes", "No"), title="Update CSV files?") == 1L) {
  print("Updating CSV files")
  
  data_2016 %>%
    clean_names(case = "lower_camel") %>%
    write_csv("data/source/data_2016.csv", na = "")
  data_2019 %>%
    clean_names(case = "lower_camel") %>%
    write_csv("data/source/data_2019.csv", na = "")
  
  
}
