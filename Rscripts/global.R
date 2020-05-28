suppressPackageStartupMessages({
# Setup Packages
    library(config)
#Shiny Packages  
  library(shiny)
  library(shinycssloaders)
  library(shinyjs)
  library(shinyWidgets)
  library(shinycssloaders)

#Formatting Packages
  library(stringr)   
  library(scales)   
  library(waiter)   
  library(lubridate)

#Data Packages
  library(dplyr)
  library(readxl)
  library(data.table)
  # library(geojsonio)
  # library(sf)
  
#DB Packages
  library(RMySQL)
  library(DBI)
  library(pool)
  library(mongolite)
  library(here)

#Graph Packages
  library(ggplot2)
  library(ggiraph)
  library(ggiraphExtra)
  library(RColorBrewer)
  library(viridis)
  library(hrbrthemes)
  library(lattice)
#Map Packages
  library(leaflet)

})

# load functions
source("server/s_data.R")


#config db connection pool

config <- config::get(file = Sys.getenv("R_CONFIG_FILE", "conf/config.yml"))
dw <- config$datawarehouse
azure <- config$azure_primary

use_mongo = TRUE

db_pool <- pool::dbPool(
  drv = RMySQL::MySQL(),
  host = dw$server,
  dbname = dw$database,
  user = dw$uid,
  password = dw$pwd
)
