## Load data source to DB

library(readxl)
library(geojsonio)
library(sf)

#Load data functions
source("global.R")
source("server/s_data.R")

# db_pool <- pool::dbPool(
#   drv = RMariaDB::MariaDB(),
#   host = dw$server,
#   dbname = dw$database,
#   user = dw$uid,
#   password = dw$pwd
# )

#Load geo data for location lookup
auspostjson_source_file = 'https://www.matthewproctor.com/Content/postcodes/australian_postcodes.json'
geojson_source_file = "data/POA_2016_AUST(TopoJSON 10%).json"
source("dataload/d_geosources.R")

#Geojson created by mapshaper.org using postal areas shapefile from ABS https://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1270.0.55.003July%202016?OpenDocument
# geojson_source_file = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\mapshaper.org\\aus_postcodes\\POA_2016_AUST(TopoJSON 10%).json"
aus.geojson <-  st_read(geojson_source_file) 

# Load and clean location info
location_info <- load_location_info(auspostjson_source_file = 'https://www.matthewproctor.com/Content/postcodes/australian_postcodes.json')


#Load traffic monitoring locations and write to DB
source("dataload/d_traffic_locations.R")
traffic_locations <- load_traffic_locations(trafficlocation_source_uri = "https://vicroadsopendatastorehouse.vicroads.vic.gov.au/opendata/Traffic_Measurement/Bicycle_Volume_and_Speed/VicRoads_Bike_Site_Number_Listing.xlsx",
                                            location_info = location_info,
                                            sp_polygon = aus.geojson)



#Load traffic data and merge with traffic_location for DB, write result to DB
source("dataload/d_traffic_data_azure.R")
years_to_load = 2
full_db_reload = FALSE
table_name  = "traffic_new"
year <- format(Sys.Date() - (((1:years_to_load -1) * 365)-5), '%Y')
trafficdata_source_uri <- paste(
  "https://vicroadsopendatastorehouse.vicroads.vic.gov.au/opendata/Traffic_Measurement/Bicycle_Volume_and_Speed/Bicycle_Volume_Speed_",
  year,
  ".zip",
  sep = "")

for(i in 1:length(trafficdata_source_uri)){
  if(i > 1)
    full_db_reload = FALSE
  load_traffic_to_cosmos(
    full_db_reload = full_db_reload,
    traffic_locations = traffic_locations,
    trafficdata_source_uri = trafficdata_source_uri[i]
  )
}

# #Aggregate traffic data and upload to cosmos DB
# source("dataload/d_load_to_cosmos.R")
# insert_time <- as.character(Sys.time())
# reload_cosmos_db_traffic_locations(db_table = "traffic_locations", full_db_reload = full_db_reload ,insert_id <- insert_time )
# reload_cosmos_db(db_table = table_name , full_db_reload = full_db_reload ,insert_id <- insert_time ) 
