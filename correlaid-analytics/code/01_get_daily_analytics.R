################################################################################
# 01_get_daily_analytics.R                                                     #
################################################################################


library(Rfacebook)
library(twitteR)
library(mongolite)
library(stringr)
library(purrr)
library(plyr)
library(dplyr)
library(jsonlite)

# SETUP ------------------------------------------------------------------------
# working directory
# set dynamically based on user 
if(Sys.info()[["user"]] == "frie"){
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-utils/correlaid-analytics/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/correlaid/correlaid-utils/correlaid-analytics")
}

source("code/utils.R")

# TWITTER ----------------------------------------------------------------------
# mlab connection 
mlab_tw <- connect_mlab("friep", "twitter")


# get twitter follower count 
# setup twitter auth
creds <- read_csv("data/aux_data/twitter_credentials")
setup_twitter_oauth(creds$c_key, creds$c_secret, creds$a_key, creds$a_secret)

# follower count 
correlaid <- getUser("CorrelAid")
fc <- followersCount(correlaid)

# convert and upload to mlab
tw_today <- data_frame(x = as.character(Sys.Date()), y = fc)
tw_today <- jsonlite::toJSON(tw_today)
mlab_tw$insert(tw_today)

# NEWSLETTER -------------------------------------------------------------------
mlab_nl <- connect_mlab("friep", "newsletter")
mc <- read.csv("data/aux_data/mcapi.txt", sep = ",", strip.white = T)

# get the  data 
mcurl <- paste("https://", mc$apitype, ".api.mailchimp.com/export/1.0/list/?id=", 
               mc$listid, "&apikey=", mc$apikey, sep="")

req <- GET(url = mcurl)
rm(mc) # remove mc object

# data cleaning 
# parse the content 
j <- content(req, "text") 
js <- unlist(str_split(j, "\n")) # unpack lines
js <- js[nchar(js) > 0] # delete empty entries

# read json from each one and convert to data frame 
objs <- purrr::map(js, jsonlite::fromJSON)
current <- plyr::ldply(objs)
colnames(current) <- current[1, ] # first row are column names
current <- current[2:nrow(current), ] # delete first row 

# empty strings as NA
current[current == ""] <- NA

# subscriber count
sc <- nrow(current)

# newest entry to  mlab
nl_today <- data_frame(x = as.character(Sys.Date()), y = sc)
nl_today <- jsonlite::toJSON(nl_today)

mlab_nl$insert(nl_today)

# FACEBOOK ---------------------------------------------------------------------

# 1. mlab connection
mlab_fb <- connect_mlab("friep", "facebook")

# 2. credentials and authentification 
fb_creds <- read_csv("data/aux_data/facebook_credentials")

# authentification was done following http://thinktostart.com/analyzing-facebook-with-r/
# uncomment to execute only once every two months (that's how long the token is valid)
fb_oauth <- fbOAuth(app_id = fb_creds$appid, app_secret = fb_creds$appsecret, 
                    scope = "manage_pages")
save(fb_oauth, file = "data/aux_data/fb_oauth")
load("data/aux_data/fb_oauth")


# 3. collect data
# 3.1. function definition 
collect_data <- function(object){
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
  
  df <- collect_data(current) # get list with data frame
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
fb_today <- facebook_new %>% 
  select(x = date, y = value) %>% 
  filter(x == Sys.Date())

fb_today <- jsonlite::toJSON(fb_today)

mlab_fb$insert(fb_today)


# CREATE DAILY DUMP ------------------------------------------------------------
colls <- c("facebook", "twitter", "newsletter")
out <- colls %>% 
  map(get_collection, dbuser = "friep") %>% 
  set_names(colls)
rm(colls)


all <- reduce(out, full_join)

all <- all %>% 
  mutate_at(vars(facebook, twitter, newsletter), funs(as.numeric)) %>% 
  mutate(days = format(as.Date(all$date), format="%b %d, %Y"))

json <- jsonlite::toJSON(all)
writeBin(charToRaw(json), con = "data/all_daily.json", endian = "little")


