################################################################################
# 01_get_daily_analytics.R                                                     #
################################################################################
library(smcounts)
library(tibble)

# read renviron file
readRenviron(here::here("correlaid-analytics/.Renviron"))
today <- Sys.Date()

# nonstandard path of slackr file - skip and execute manually
today_df <- smcounts::collect_data(slack = FALSE) 
slack <- smcounts::ca_slack(here::here("correlaid-analytics/.slackr"))
today_df <- rbind(today_df, slack)

# write daily json
path <- glue::glue(here::here("correlaid-analytics/data/days/{today}.json"))
today_df %>% jsonlite::write_json(path)
today_list <- jsonlite::read_json(path) # read back in to get list (too lazy to manually transform)

# load all daily data and append new data
all_days <- jsonlite::read_json(here::here("correlaid-analytics/data/all_daily.json"))
new_list <- c(all_days, today_list)
new_list %>% jsonlite::write_json(here::here("correlaid-analytics/data/all_daily.json"))
