library(httr)
library(twitteR)
library(jsonlite)
library(RCurl)
library(stringr) 
library(purrr)
library(dplyr)
library(Rfacebook)
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


# 1.2. add to old file
# load r file
load("twitter_data/twitter_daily.rda")

# add todays value
twitter <- rbind(twitter, c(as.character(Sys.Date()), fc))
twitter <- unique(twitter)

# save r file
save(twitter, file = "twitter_data/twitter_daily.rda")

# save json
json <- jsonlite::toJSON(twitter)
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
save(newsletter, file = "newsletter_data/newsletter_daily.rda")

json <- jsonlite::toJSON(newsletter)
write(json, file = "newsletter_data/newsletter_daily.json")

# 3. FACEBOOK

# 3.0. read in old data
load("facebook_data/facebook_daily.rda")

# 3.1. authentification and function definition
# authentification was done following http://thinktostart.com/analyzing-facebook-with-r/
# uncomment to execute only once every two months (that's how long the token is valid)
# fb_oauth <- fbOAuth(app_id="1888833184724735", app_secret="2ee6aeb6ad76a20846ba1cc0e15ac113", scope="manage_pages")
# save(fb_oauth, file="aux_data/fb_oauth")
load("aux_data/fb_oauth")

coll_data <- function(object){
  json <- jsonlite::toJSON(object)
  dflist <- jsonlite::fromJSON(json)$data$values # get data frame
  return(dflist)
}

# 3.2. create list of dataframes and initial call
dataframes <- list()
tmp <- callAPI("https://graph.facebook.com/WeAreCorrelAid/insights/page_fans", token = fb_oauth)

# 3.3. pagination

# paginate forward (that's where the newest data is)
nextlink <- tmp$paging$`next`
current <- tmp

while(!is.null(nextlink)){
  print(nextlink)
  current <- callAPI(nextlink, token = fb_oauth)
  
  df <- coll_data(current) # get list with data frame
  count_mean <- mean(unlist(df[[1]]$value)) # calculate mean
  dataframes <- c(dataframes, df) # add data frame to list of dataframes
  nextlink <- current$paging$`next` # update prevlink
}

facebook_new <- bind_rows(dataframes)

# 3.4. data cleaning and saving
# unlist list columns
facebook_new$end_time <- unlist(facebook_new$end_time)
facebook_new$value <- unlist(facebook_new$value)

# date
facebook_new$date <- as.Date(facebook_new$end_time, "%Y-%m-%dT%H:%M:%S%z")
facebook_new$date <- facebook_new$date - 1 # end time is midnight of the day (which is displayed as 00:00 of the next day)
facebook_new$end_time <- NULL

# arrange variables and colnames
facebook_new <- facebook_new %>% 
  select(x = date, y = value)

# bind the new rows
facebook <- rbind(facebook, facebook_new[!facebook_new$x %in% facebook$x, ])

# write to file
save(facebook, file = "facebook_data/facebook_daily.rda")

json <- jsonlite::toJSON(facebook)
write(json, file = "facebook_data/facebook_daily.json")


# 4. UPLOAD WEEKLY
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
  
  facebook_weekly <- facebook$y[as.numeric(as.Date(facebook$x)) %in% dates] 
  
  # save json
  # days
  json <- jsonlite::toJSON(format(as.Date(dates), format="%b %d, %Y"))
  writeBin(charToRaw(json), con = "days.json", endian = "little")
  
  json <- jsonlite::toJSON(newsletter_weekly)
  writeBin(charToRaw(json), con = "newsletter_data/newsletter_weekly.json", endian = "little")
  
  json <- jsonlite::toJSON(twitter_weekly)
  writeBin(charToRaw(json), con = "twitter_data/twitter_weekly.json", endian = "little")
  
  
  json <- jsonlite::toJSON(facebook_weekly)
  writeBin(charToRaw(json), con = "facebook_data/facebook_weekly.json", endian = "little")
  
  # upload to server
  ftpUpload(what = "days.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/days.json")
  
  ftpUpload(what = "newsletter_data/newsletter_weekly.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/newsletter.json")
  
  ftpUpload(what = "twitter_data/twitter_weekly.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/twitter.json")
  
  ftpUpload(what = "facebook_data/facebook_weekly.json",
            to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/facebook.json")
  
  }
