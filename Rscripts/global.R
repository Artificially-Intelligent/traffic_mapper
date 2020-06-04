
suppressPackageStartupMessages({
  # Setup Packages
  library(config)
  #Shiny Packages
  library(shiny)
  library(shinyjs)
  library(shinyWidgets)
  library(shinycssloaders)
  library(shinydashboard)
  
  #Formatting Packages
  library(stringr)
  library(scales)
  library(waiter)
  library(lubridate)
  library(janitor)
  
  #Data Packages
  library(dplyr)
  library(data.table)
  library(OneR)
  library(readxl)
  library(geojsonio)
  library(sf)
  
  
  #DB Packages
  library(RMariaDB)
  library(DBI)
  library(pool)
  library(mongolite)
  # library(here)
  
  #Graph Packages
  library(ggplot2)
  library(ggiraph)
  library(plotly)
  library(ggiraphExtra)
  library(RColorBrewer)
  library(viridis)
  library(hrbrthemes)
  library(lattice)
  #Map Packages
  library(leaflet)
  library(leaflet.extras)
  
})

# load functions
source("server/s_data.R")
source("server/s_plots.R")

print("File list:")
print(list.files(recursive = TRUE))
print(paste("Config path:", Sys.getenv("R_CONFIG_FILE", "conf/config.yml")))

print("*********************************************************************")
print("Full File list:")
print(list.files(recursive = TRUE), path = "/")

#config db connection pool
# 
# config <-
#   config::get(file = Sys.getenv("R_CONFIG_FILE", "conf/config.yml"))
# dw <- config$datawarehouse
# azure <- config$azure_primary

azure <- data.table( mongo_url = Sys.getenv('AZURE_URL'))
                       
use_mongo = TRUE

db_table <- 'traffic_test'
if (!use_mongo) {
  db_pool <- pool::dbPool(
    drv = RMariaDB::MariaDB(),
    host = dw$server,
    dbname = dw$database,
    user = dw$uid,
    password = dw$pwd
  )
}


