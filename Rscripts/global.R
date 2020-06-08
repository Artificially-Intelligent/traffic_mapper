
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


#config db connection pool
config_file <-  Sys.getenv("R_CONFIG_FILE", "conf/config.yml")

if(file.exists(config_file)){
  print(paste('Loading config from',config_file))
  config <-
    config::get(file = config_file)
  dw <- config$datawarehouse
  azure <- config$azure_primary
}
if(nchar(Sys.getenv('AZURE_URL'))> 0){
  print(paste('Loading azure connection URL from env variable "AZURE_URL"'))
  azure <- data.table( mongo_url = Sys.getenv('AZURE_URL'))
  azure$db <- "primary"
}

use_mongo = TRUE

if (!use_mongo) {
  db_table <- 'traffic'
  
  db_pool <- pool::dbPool(
    drv = RMariaDB::MariaDB(),
    host = dw$server,
    dbname = dw$database,
    user = dw$uid,
    password = dw$pwd
  )
}


