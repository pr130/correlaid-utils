################################################################################
# 01_get_daily_analytics.R                                                     #
################################################################################
library(smcounts)
library(tibble)
library(dplyr)

# read renviron file
print("COLLECTING DATA")
readRenviron(here::here("correlaid-analytics/.Renviron"))
today <- Sys.Date()

# nonstandard path of slackr file - skip and execute manually
today_df <- smcounts::collect_data() 
print(today_df)

print("LOADING EXISTING DATA AND APPENDING NEW DATA")
# load all daily data and append new data
all_days <- readr::read_csv(here::here("correlaid-analytics/data/all_daily.csv"))

# make sure there are no existing data for this date, drop them if we do
# this is mostly relevant when actively developing and executing the script multiple times per day by hand - but 
# it's always good to be sure ;)
all_days <- all_days %>% 
  filter(date != today)
# add new data 
new_df <- rbind(all_days, today_df)
new_df %>% readr::write_csv(here::here("correlaid-analytics/data/all_daily.csv"))
