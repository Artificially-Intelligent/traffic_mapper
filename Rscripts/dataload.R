## Load data source to DB

#Load data functions
source("global.R")
source("server/s_data.R")

#Load geo data for location lookup
auspostjson_source_file = 'https://www.matthewproctor.com/Content/postcodes/australian_postcodes.json'
geojson_source_file = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\mapshaper.org\\aus_postcodes\\POA_2016_AUST(TopoJSON 10%).json"
source("dataload/d_geosources.R")

#Load traffic monitoring locations and write to DB
trafficlocation_source_files = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\discover.data.vic.gov.au\\vicroads\\VicRoads_Bike_Site_Number_Listing.xlsx"
source("dataload/d_traffic_locations.R")

#Load traffic data and merge with traffic_location for DB, write result to DB
trafficdata_source_directory = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\discover.data.vic.gov.au\\vicroads\\Bicycle_Volume_Speed_2020\\"
source("dataload/d_traffic_data.R")
