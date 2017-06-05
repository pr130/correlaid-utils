# required packages
library(httr)
library(purrr)
library(stringr)
library(jsonlite)
library(dplyr)
library(RCurl)
rm(list = ls())

# 0. SETUP
# 0.1. working directory
# set dynamically based on user 
if(Sys.info()[["user"]] == "frie"){
  setwd("/home/frie/Documents/correlaid/codes_and_presentations/correlaid-utils/correlaid-analytics/")
} else if(Sys.info()[["user"]] == "fripi"){
  setwd("/home/fripi/correlaid/correlaid-utils/correlaid-analytics")
}

# 1. GET DATA FROM MAILCHIMP
# read api key
mc <- read.csv("aux_data/mcapi.txt", sep = ",", strip.white = T, stringsAsFactors = F)

# get the  data 
mcurl <- paste("https://", mc$apitype, ".api.mailchimp.com/export/1.0/list/?id=", 
               mc$listid, "&apikey=", mc$apikey, sep="")
req <- GET(url = mcurl)

# remove mc object
rm(mc) 


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
current <- current[2:nrow(current), ] # delete first row and keep only email and first name

# empty strings as NA
current[current == ""] <- NA

rm(j, js, objs, req, mcurl)

# 2. DATA CLEANING AND EXPORT

# export gender
current$Gender[current$Gender == "männlich"] <- "Männlich"
current$Gender[current$Gender == "weiblich"] <- "Weiblich"

gender_t <- table(current$Gender[!is.na(current$Gender)])
gender_de <- list(labels = names(gender_t), values = as.numeric(gender_t))
gender_en <- list(labels = c("Male", "Female", "Don't want to say/define it this way"), values = as.numeric(gender_t))
rm(gender_t)

# export country
country <- current$`In welchem Land lebst du hauptsächlich?`
country_t <- table(country[!is.na(country)])
country_en <- list(labels = names(country_t), values = as.numeric(country_t))
country_de <- country_en # for now, do not recode country names
rm(country_t, country)

# export job
job <- current$`An welchem Programm nimmst du gerade teil?`
job_t <- table(job[!is.na(job)])
job_de <- list(labels = names(job_t), values = as.numeric(job_t))
job_en <- list(labels = c("BA", "I have a job.", "I do something else.", "MA", "PhD", "PostDoc"), values = as.numeric(job_t))
rm(job_t, job)

# export program
program_t <- table(current$Studienrichtung[!is.na(current$Studienrichtung)])
program_de <- list(labels = names(program_t), values = as.numeric(program_t))
program_en <- list(labels = c("Other", "Humanities",  "Natural Sciences", "Social Sciences", "Engineering", "Economics"),
                   values = as.numeric(program_t))
rm(program_t)

# export stat. languages
languages <- c("R", "Excel", "Andere", "Stata", "SPSS")
counts <- lapply(languages, function(lang){
  count <- sum(str_detect(current$`Welche Statistiksoftware nutzt du hauptsächlich?`, lang), na.rm = T)
  return(data.frame(lang = lang, count = count, stringsAsFactors = F))
})
counts <- bind_rows(counts)
statistics_de <- list(labels = counts$lang, values = as.numeric(counts$count))
statistics_en <- list(labels = c("R", "Excel", "Other", "Stata", "SPSS"), values = as.numeric(counts$count))
rm(counts, languages)

# export lang
languages <- c("HTML", "CSS", "JavaScript", "Python", "Ruby")
counts <- lapply(languages, function(lang){
  count <- sum(str_detect(current$`Welche Markup- und Programmiersprachen nutzt du?`, lang), na.rm = T)
  return(data.frame(lang = lang, count = count, stringsAsFactors = F))
  
})
counts <- bind_rows(counts)
programming_de <- list(labels = counts$lang, values = as.numeric(counts$count))
programming_en <- programming_de # no German specific labels 

rm(counts, languages)

# export os
languages <- c("Windows", "Mac OS", "Linux")
counts <- lapply(languages, function(lang){
  count <- sum(str_detect(current$`Welches Betriebssystem nutzt du hauptsächlich?`, lang), na.rm = T)
  return(data.frame(lang = lang, count = count, stringsAsFactors = F))
})
counts <- bind_rows(counts)
os_de <- list(labels = counts$lang, values = as.numeric(counts$count))
os_en <- os_de
rm(counts, languages)

# german 
export_de <- list(gender = gender_de,
               residence = country_de,
               program = program_de,
               job = job_de,
               statisticalProgramming = statistics_de,
               programmingLang = programming_de,
               OS = os_de)


# english
export_en <- list(gender = gender_en,
               residence = country_en,
               program = program_en,
               job = job_en,
               statisticalProgramming = statistics_en,
               programmingLang = programming_en,
               OS = os_en)


export <- toJSON(list(en = export_en, de = export_de), pretty = T)
writeLines(export, con = "network_data.json", useBytes = T)



# upload
ftpUpload(what = "network_data.json",
          to = "ftp://gsi_7309_1data:hqjjqOcVOIV7_@correlaid.org:21/network_data.json")

