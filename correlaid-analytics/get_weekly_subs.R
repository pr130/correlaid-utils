rm(list = ls())
library(httr)
library(stringr) 
library(purrr)
library(RCurl)
library(jsonlite)
library(dplyr)

# 0. SETUP
# 0.1. working directory
# set dynamically based on user 
if(Sys.info()[["user"]] == "frie"){
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/mailchimp-welcomemail/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/mailchimp-welcomemail")
}

# 1. READ IN DAILY DATA AND SUBSET
# load r file
load("newsletter_data/newsletter_daily.rda")
load("newsletter_data/newsletter_weekly.rda")

lastweek <- as.Date(max(newsletter_weekly$x))
# add value of next monday
new_y <- newsletter$y[newsletter$x == lastweek + 6]
if(length(new_y) > 0){
  newsletter_weekly <- rbind(newsletter_weekly, 
                             c(as.numeric(lastweek + 6), as.Date(lastweek + 6), new_y))
  
}

# save r file
save(newsletter_weekly, file = "newsletter_data/newsletter_weekly.rda")

# save json
json <- toJSON(newsletter_weekly$y)
writeBin(charToRaw(json), con = "newsletter_data/weekly_y.json", endian = "little")


json <- toJSON(format(as.Date(newsletter_weekly$x), format="%b %d, %Y"))
writeBin(charToRaw(json), con = "newsletter_data/days.json", endian = "little")


# upload to server
ftpUpload(what = "newsletter_data/weekly_y.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/newsletter_weekly.json")



ftpUpload(what = "newsletter_data/days.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/days.json")

rm(list = ls())

