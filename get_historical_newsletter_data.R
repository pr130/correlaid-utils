library(purrr)

rm(list = ls())
setwd("/home/frie/Documents/correlaid/codes_and_presentations/mailchimp-welcomemail/")

current <- read.csv("current_subscribers.csv", stringsAsFactors = F, na.strings = "")
current$confirm_date <- as.Date(current$confirm_date)

# fill in missing days 
# first and last day so far
datemin <- min(current$confirm_date)
datemax <- max(c(current$confirm_date, Sys.Date()))

# create data frame with one row for each day
alldays <- data.frame(date = seq(datemin, datemax, by = 1))

# function to count all subs < given date
count_subs <- function(row){
  return(sum(current$confirm_date <= row$date))
}

# apply to all days / rows
alldays <- by_row(.d = alldays, ..f = count_subs, .collate = "cols", .to = "subs")

write.csv(alldays, "historical_newsletter_data.csv", row.names = F)
