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

#Data Packages
  library(dplyr)
  library(data.table)
  library(OneR)
  library(readxl)
  library(geojsonio)
  library(sf)
  
  
#DB Packages
  library(RMySQL)
  library(DBI)
  library(pool)
  library(mongolite)
  # library(here)

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
  library(leaflet.extras)

})

# load functions
source("server/s_data.R")
source("server/s_plots.R")


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
