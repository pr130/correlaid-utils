# utils.R

# FUNCTION TO CONNECT TO MLAB API ----------------------------------------------
connect_mlab <- function(dbuser, collection){
  require(readr)
  require(mongolite)
  dbpw <- read_lines("data/aux_data/mlab_dbpw.txt")
  url <- paste0("mongodb://", dbuser, ":", dbpw, "@ds032887.mlab.com:32887/correlaid-data")
  m <- mongo(db = "correlaid-data", url = url, collection = collection)
  return(m)
}


get_collection <- function(dbuser, collection){
  require(readr)
  require(mongolite)
  
  m <- connect_mlab(dbuser, collection)
  
  df <- m$find()
  colnames(df) <- c("date", collection)
  return(df)
}

