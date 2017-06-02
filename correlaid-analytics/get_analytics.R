library(httr)
library(twitteR)
library(jsonlite)
library(RCurl)
library(stringr) 
library(purrr)
library(dplyr)
rm(list = ls())

# 0. SETUP
# 0.1. working directory
# set dynamically based on user 
if(Sys.info()[["user"]] == "frie"){
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-utils/correlaid-analytics/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/correlaid/correlaid-utils/correlaid-analytics")
}

# 1. TWITTER
# 1.2. get data
creds <- read.csv("aux_data/twitter_credentials", stringsAsFactors = F)

setup_twitter_oauth(creds$c_key, creds$c_secret, creds$a_key, creds$a_secret)

correlaid <- getUser("CorrelAid")

fc <- followersCount(correlaid)


# 1.2. UPLOAD TO FTP
# load r file
load("twitter_data/twitter_daily.rda")

# add todays value
twitter <- rbind(twitter, c(as.character(Sys.Date()), fc))
twitter <- unique(twitter)

# save r file
save(twitter, file = "twitter_data/twitter_daily.rda")

# save json
json <- toJSON(twitter)
write(json, file = "twitter_data/twitter_daily.json")

# 2. NEWSLETTER
# 2.0. read in existing data
load("newsletter_data/newsletter_daily.rda")

# 2.1. read in mailchimp data (api key etc)
mc <- read.csv("aux_data/mcapi.txt", sep = ",", strip.white = T)

# 2.2. get the  data 
mcurl <- paste("https://", mc$apitype, ".api.mailchimp.com/export/1.0/list/?id=", 
               mc$listid, "&apikey=", mc$apikey, sep="")

req <- GET(url = mcurl)
rm(mc) # remove mc object

# 2.3. data cleaning 
# parse the content 
j <- content(req, "text") 
js <- str_split(j, "\n") # unpack lines

# delete empty entries
js <- unlist(js)
js <- js[nchar(js) > 0]

# read each one 
objs <- purrr::map(js, jsonlite::fromJSON)

# convert to data frame 
current <- plyr::ldply(objs)
colnames(current) <- current[1, ] # first row are column names
current <- current[2:nrow(current), ] # delete first row and keep only email and first name

# subscriber count
sc <- nrow(current)

# add to old newsletter data
newsletter <- rbind(newsletter, c(as.character(Sys.Date()), sc))
newsletter <- unique(newsletter)

# write to file
save(newsletter, file = "aux_data/newsletter_daily.rda")

json <- toJSON(newsletter)
write(json, file = "newsletter_data/newsletter_daily.json")

# 3. UPLOAD WEEKLY
# read in days 
dates <- seq(from = as.Date("2016-02-29"), Sys.Date(), by = "weeks")

# check whether today is a relevant week day
if ((max(dates) + 7) == Sys.Date()){
  # add todays date
  dates <- c(dates, Sys.Date())

  # newsletter_weekly
  newsletter_weekly <- newsletter$y[as.numeric(as.Date(newsletter$x)) %in% dates]

  # twitter_weekly
  twitter_weekly <- twitter$y[as.numeric(as.Date(twitter$x)) %in% dates]
  
  # save json
  # days
  json <- toJSON(format(as.Date(dates), format="%b %d, %Y"))
  writeBin(charToRaw(json), con = "days.json", endian = "little")
  
  json <- toJSON(newsletter_weekly)
  writeBin(charToRaw(json), con = "newsletter_data/newsletter_weekly.json", endian = "little")
  
  json <- toJSON(twitter_weekly)
  writeBin(charToRaw(json), con = "twitter_data/twitter_weekly.json", endian = "little")
  
  # upload to server
  ftpUpload(what = "days.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/days.json")
  
  ftpUpload(what = "newsletter_data/newsletter_weekly.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/newsletter.json")
  
  ftpUpload(what = "twitter_data/twitter_weekly.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/twitter.json")
  
  }
