rm(list = ls())
library(httr)
library(stringr) 
library(purrr)
library(RCurl)
library(jsonlite)
library(dplyr)

load("newsletter_data/newsletter_daily.rda")

# create weekly data frame
newsletter_weekly <- data.frame(dates = seq(from = as.Date("2016-02-29"), Sys.Date(), by = "weeks"))

# join data on numeric date
newsletter$dates <- as.numeric(as.Date(newsletter$x))

newsletter_weekly$dates <- as.numeric(newsletter_weekly$dates)
newsletter_weekly <- left_join(newsletter_weekly, newsletter, by = "dates")

save(newsletter_weekly, file = "newsletter_data/newsletter_weekly.rda")

# save json
# weekly
# y
json <- toJSON(newsletter_weekly[, c("x", "y")])

writeBin(charToRaw(json), con = "newsletter_data/newsletter_weekly.json", endian = "little")

# x/days
json <- toJSON(format(as.Date(newsletter_weekly$x), format="%b %d, %Y"))
writeBin(charToRaw(json), con = "newsletter_data/days.json", endian = "little")


# upload to server

ftpUpload(what = "newsletter_data/newsletter_weekly.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/newsletter_weekly.json")

ftpUpload(what = "newsletter_data/days.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/days.json")






