
allpcks <- c("RCurl", "mongolite", "facebook", "twitteR", # api packages etc. 
             "stringr", "dplyr", "purrr", "jsonlite", "readr", "tidyr", # tidy 
             "plyr") # other

is_installed <- sapply(allpcks, require, character.only=TRUE, quietly=FALSE, warn.conflicts=FALSE)

missing_pkgs <- names(which(is_installed == FALSE))

for(missing in missing_pkgs){
  warning(paste(missing, "is not installed. Installing...", sep = " "))
  install.packages(missing)
}

