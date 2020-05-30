#### Installed Library Dependencies ####
#install.packages("readxl")
#install.packages("DT")
#install.packages("data.table")
#install.packages("dygraphs") 
#install.packages("formattable")
#install.packages("scales") #
#install.packages("shinycssloaders")
#install.packages("shinydashboard")
#install.packages("shiny")
#install.packages("shinyjs")
#install.packages("shinyWidgets")
#install.packages("summarytools")
#install.packages("tidyverse")
#install.packages("magrittr")
#install.packages("lubridate")
#install.packages("plotly")
#install.packages("devtools")
#install.packages("vtreat")
#install.packages("xgboost")
#install.packages("skimr")
#install.packages("xts")
#install.packages("plotly")
#install.packages("forcats")
#install.packages("highcharter")
#install.packages("purrr")

#install.packages("readr")
#install.packages("DataExplorer")
#install.packages("dplyr")
#install.packages("rpart")
#install.packages("rpart.plot")
#install.packages("rattle")
#install.packages("Metrics")
#install.packages("ipred")
#install.packages("caret")
#install.packages("randomForest")
#install.packages("xgboost")
#install.packages("magick")
#install.packages('httr')
#install.packages('jsonlite')
#install.packages('RMySQL')
#install.packages('DBI')
#install.packages('aws.s3')
#install.packages('glue')

#install.packages('leaflet')
#install.packages('shinydashboardPlus')
#install.packages('pool')
#install.packages('janitor')
#install.packages('timevis')
#install.packages('sf')
#install.packages("leaflet.extras")
#install.packages("writexl")
#install.packages("wkb")
#install.packages("shinycssloaders")


#### Additional Library Dependencies ####

setup_packages <- c('config')
shiny_packages <- c('shiny','shinycssloaders','shinyjs','shinyWidgets')
formatting_packages <- c('stringr','scales','waiter','lubridate')
data_packages <- c('dplyr', 'readxl', 'data.table', 'geojsonio', 'sf')
db_packages <- c('RMySQL', 'DBI', 'pool','mongolite','here')
graph_packages <-
  c('ggplot2', 'ggiraph', 'ggiraphExtra', 'RColorBrewer','viridis','hrbrthemes','lattice')
map_packages <- c('leaflet')

packages_required <-c(
  setup_packages,
  shiny_packages,
  formatting_packages,
  data_packages,
  db_packages,
  graph_packages,
  map_packages,
  c()
)

custom_version_required <- c('mongolite')

additional_packages <- packages_required[!(packages_required %in% c(custom_version_required, installed.packages()[,"Package"]))]

if(! 'mongolite' %in% c(custom_version_required, installed.packages()[,"Package"])) install.packages("mongolite", repos = "https://cran.microsoft.com/snapshot/2018-08-01")

if(length(additional_packages) >0)
  install.packages(additional_packages, repos='http://cran.rstudio.com/', dependencies = TRUE)

install.packages('ggiraph')

Sys.getenv(PKG_CONFIG_PATH)

