## Load data source to DB

library(readxl)
library(geojsonio)
library(sf)

#Load data functions
source("global.R")
source("server/s_data.R")

#Load geo data for location lookup
auspostjson_source_file = 'https://www.matthewproctor.com/Content/postcodes/australian_postcodes.json'
geojson_source_file = "data/POA_2016_AUST(TopoJSON 10%).json"
source("dataload/d_geosources.R")

#Load traffic monitoring locations and write to DB
source("dataload/d_traffic_locations.R")
load_traffic_locations_to_db(trafficlocation_source_uri = "https://vicroadsopendatastorehouse.vicroads.vic.gov.au/opendata/Traffic_Measurement/Bicycle_Volume_and_Speed/VicRoads_Bike_Site_Number_Listing.xlsx")
  

#Load traffic data and merge with traffic_location for DB, write result to DB
source("dataload/d_traffic_data.R")
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
  load_traffic_to_db(
    db_table = table_name,
    full_db_reload = full_db_reload,
    trafficdata_source_uri = trafficdata_source_uri[i]
  )
}

#Aggregate traffic data and upload to cosmos DB
source("dataload/d_load_to_cosmos.R")
reload_cosmos_db(db_table = table_name) 
