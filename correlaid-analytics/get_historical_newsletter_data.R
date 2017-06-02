library(purrr)

rm(list = ls())
setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-analytics/mailchimp-welcomemail/")

# 1.1. read in mailchimp data (api key etc)
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

# confirm day as date
current$confirm_date <- as.Date(current$CONFIRM_TIME) # only keep relevant variables

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

write.csv(alldays, "newsletter_data/historical_newsletter_data.csv", row.names = TRUE)
