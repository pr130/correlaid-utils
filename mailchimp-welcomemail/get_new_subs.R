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
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-utils/mailchimp-welcomemail/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail")
}

sink("logs/log_get_new_subs.txt") 

# 0.2. define timeframe 
# we always send the emails in the morning at 5 am for those people who signed up the day before
# read in the date for which we last checked new subscribers, i.e. the day before the script was last run
from_day <- as.Date(readLines("aux_data/lastrun"))

# we want to include people up to yesterday 
upto_day <- Sys.Date() - 1

# 0.3. overwrite lastrun
fileConn<-file("aux_data/lastrun")
writeLines(as.character(Sys.Date()), fileConn)
close(fileConn)

# 0.4. delete the old sendto file
tmpfile <- list.files(pattern = "sendto.+?\\.csv")
if (length(tmpfile) > 0) file.remove(tmpfile)

# 1. MAILCHIMP
# 1.1. read in mailchimp data (api key etc)
mc <- read.csv("aux_data/mcapi.txt", sep = ",", strip.white = T)

# 1.2. get the  data 
mcurl <- paste("https://", mc$apitype, ".api.mailchimp.com/export/1.0/list/?id=", 
             mc$listid, "&apikey=", mc$apikey, sep="")

req <- GET(url = mcurl)
rm(mc) # remove mc object

# 2. DATA CLEANING 
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

# confirm day as date
current$confirm_date <- as.Date(current$CONFIRM_TIME)

# only keep relevant variables
current <- current[, str_detect(colnames(current), "[Ee]mail|[Vv]orname|CONFIRM_TIME|Kontaktsprache")]

# 3. SUBSET FOR NEW SUBSCRIBERS 
# all accounts with confirm date >= from_day and <= upto_day should be sent an email to
sendto <- current[current$confirm_date >= from_day & current$confirm_date <= upto_day, ]

sendto <- sendto[, str_detect(colnames(sendto), "[Ee]mail|[Vv]orname|Kontaktsprache")]
colnames(sendto) <- c("email", "vorname", "kontaktsprache")

write.csv(sendto, file = paste("sendto_", Sys.Date(), ".csv", sep = ""), row.names = F)

rm(list = ls())
sink()
