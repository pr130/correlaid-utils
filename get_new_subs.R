rm(list = ls())
library(httr)
library(stringr) 
library(jsonlite)
library(purrr)

sink("log_get_new_subs.txt")
setwd("/home/fripi/mailchimp-welcomemail")

# setwd("/home/frie/Documents/correlaid_my/mailchimp/")

# we always send the emails in the morning at 5 am for those people who signed up the day before
# read in the date for which we last checked new subscribers, i.e. the day before the script was last run
from_day <- as.Date(readLines("lastrun"))

# we want to include people up to yesterday 
upto_day <- Sys.Date() - 1

# overwrite lastrun
fileConn<-file("lastrun")
writeLines(as.character(Sys.Date()), fileConn)
close(fileConn)

# read in mailchimp data (api key etc)
mc <- read.csv("mcapi.txt", sep = ",", strip.white = T)

# # read old data
# currentfile <- list.files(pattern = "current_.+?\\.csv")
# 
# if (length(currentfile) == 1){
#   # can read in data 
#   old <- read.csv(currentfile, stringsAsFactors = F)
#   file.remove(currentfile)
# }
# 

# delete the old sendto file 
tmpfile <- list.files(pattern = "sendto.+?\\.csv")
if (length(tmpfile) > 0) file.remove(tmpfile)

# get the  data 
mcurl <- paste("https://", mc$apitype, ".api.mailchimp.com/export/1.0/list/?id=", 
             mc$listid, "&apikey=", mc$apikey, sep="")

req <- GET(url = mcurl)

rm(mc) # remove mc object

# parse the content 
j <- content(req, "text")

js <- str_split(j, "\n")

# delete empty entries
js <- unlist(js)
js <- js[nchar(js) > 0]
 
# read each one 
objs <- purrr::map(js, jsonlite::fromJSON)
 
# convert to data frame 
current <- plyr::ldply(objs)
colnames(current) <- current[1, ] # first row are column names
current <- current[2:nrow(current), str_detect(colnames(current), "[Ee]mail|[Vv]orname|CONFIRM_TIME|Kontaktsprache")] # delete first row and keep only email and first name

# confirm day
current$confirm_date <- as.Date(current$CONFIRM_TIME)

# all accounts with confirm date >= from_day and <= upto_day should be sent an email to
sendto <- current[current$confirm_date >= from_day & current$confirm_date <= upto_day, ]

sendto <- sendto[, str_detect(colnames(sendto), "[Ee]mail|[Vv]orname|Kontaktsprache")]
colnames(sendto) <- c("email", "vorname", "kontaktsprache")

write.csv(sendto, file = paste("sendto_", Sys.Date(), ".csv", sep = ""), row.names = F)


# # get the new email addresses 
# new_indizes <- which(!current[, str_detect(colnames(current), "[Ee]mail")] %in% old[, str_detect(colnames(old), "[Ee]mail")])
# new <- current[new_indizes, ]
#  
# write.csv(current, file = paste("current_", Sys.Date(), ".csv", sep = ""), row.names = F)
# write.csv(new, file = paste("new_", Sys.Date(), ".csv", sep = ""), row.names = F)
# 
sink()
