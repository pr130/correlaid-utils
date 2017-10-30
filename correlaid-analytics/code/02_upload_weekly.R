# 
# 02_upload_weekly.R #
#
library(RCurl)
library(mongolite)
library(purrr)
library(dplyr)

rm(list = ls())

# SETUP ------------------------------------------------------------------------
# set dynamically based on user 
if(Sys.info()[["user"]] == "frie"){
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-utils/correlaid-analytics/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/correlaid/correlaid-utils/correlaid-analytics")
}

# source utils file 
source("code/utils.R")


# ADDITIONAL FUNCTIONS ---------------------------------------------------------
extract_mondays <- function(df){
  
  dates <- seq(from = as.Date("2016-02-29"), Sys.Date(), by = "weeks")
  df$date <- as.Date(df$date)
  
  df <- df %>% 
    filter(date %in% dates)
  return(df)
}


# EXTRACT DATA FROM MLAB -------------------------------------------------------
# get all the collections from mlab
# friep is our user
colls <- c("facebook", "twitter", "newsletter")
out <- colls %>% 
  map(get_collection, dbuser = "friep") %>% 
  map(extract_mondays) %>% 
  set_names(colls)
rm(colls)

all <- reduce(out, full_join)

# UPLOAD TO WEBSITE ------------------------------------------------------------

all <- all %>% 
  mutate_at(vars(facebook, twitter, newsletter), funs(as.numeric)) %>% 
  mutate(days = format(as.Date(all$date), format="%b %d, %Y"))

json <- jsonlite::toJSON(as.list(all %>% select(-date)))
writeBin(charToRaw(json), con = "data/all_weekly.json", endian = "little")

# upload to server
ftpUpload(what = "data/all_weekly.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org/all_weekly.json")
