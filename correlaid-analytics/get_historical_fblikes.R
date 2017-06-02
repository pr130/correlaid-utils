library(Rfacebook)
library(jsonlite)
library(dplyr)
library(zoo)

rm(list = ls())
# 0. SETUP / AUTHENTIFICATION
# uncomment to execute only once every two months (that's how long the token is valid)
# fb_oauth <- fbOAuth(app_id="1888833184724735", app_secret="2ee6aeb6ad76a20846ba1cc0e15ac113", scope="manage_pages")
# save(fb_oauth, file="aux_data/fb_oauth")

load("aux_data/fb_oauth")

# 1. DATA COLLECTION
# 1.1. collect data function from object returned by API

coll_data <- function(object){
  json <- jsonlite::toJSON(object)
  dflist <- jsonlite::fromJSON(json)$data$values # get data frame
  return(dflist)
}

# 1.2. create list of dataframes and initial call
dataframes <- list()
tmp <- callAPI("https://graph.facebook.com/WeAreCorrelAid/insights/page_fans", token = fb_oauth)
df <- coll_data(tmp)
dataframes <- c(dataframes, df)

# 1.3. pagination
# paginate backwards
current <- tmp
prevlink <- current$paging$previous

while(count_mean > 0){
  print(prevlink)
  current <- callAPI(prevlink, token = fb_oauth)
  
  df <- coll_data(current) # get list with data frame
  count_mean <- mean(unlist(df[[1]]$value)) # calculate mean
  dataframes <- c(dataframes, df) # add data frame to list of dataframes
  prevlink <- current$paging$previous # update prevlink
}

# paginate forward
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

facebook <- dplyr::bind_rows(dataframes)

# 2. DATA CLEANING
# unlist list columns
facebook$end_time <- unlist(facebook$end_time)
facebook$value <- unlist(facebook$value)

# date
facebook$date <- as.Date(facebook$end_time, "%Y-%m-%dT%H:%M:%S%z")
facebook$date <- facebook$date - 1 # end time is midnight of the day (which is displayed as 00:00 of the next day)
facebook$end_time <- NULL

# arrange
facebook <- facebook %>% 
  arrange(date) %>% 
  select(date, value)

colnames(facebook) <- c("x", "y")

# extrapolate missing values
tmp <- data.frame(x = seq(min(facebook$x), max(facebook$x), by = "days"))

facebook <- left_join(tmp, facebook, by = "x")

facebook <- facebook %>% 
  arrange(x)

# zoo to intrapolate missing values
fbzoo <- zoo(facebook$y, facebook$x)
fbzoo <- na.approx(fbzoo)
facebook <- fortify(fbzoo)
colnames(facebook) <- c("x", "y")

# round off numerical values
facebook$y <- round(facebook$y)
save(facebook, file = "facebook_data/facebook_daily.rda")
