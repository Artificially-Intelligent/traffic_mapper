
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

packages_active <-
  suppressPackageStartupMessages(lapply(
    packages_required,
    require,
    character.only = TRUE
  ))


write.csv(packages_required, file = 'packages.csv' ,row.names = FALSE ,quote = FALSE,eol=",")

# load functions
source("server/s_data.R")


#config db connection pool

config <- config::get(file = Sys.getenv("R_CONFIG_FILE", "conf/config.yml"))
dw <- config$datawarehouse
azure <- config$azure_primary

db_pool <- pool::dbPool(
  drv = RMySQL::MySQL(),
  host = dw$server,
  dbname = dw$database,
  user = dw$uid,
  password = dw$pwd
)
