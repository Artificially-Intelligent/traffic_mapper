# json file with suburb info to match against postcode
# auspostjson_source_file = 'https://www.matthewproctor.com/Content/postcodes/australian_postcodes.json'
# geojson_source_file = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\mapshaper.org\\aus_postcodes\\POA_2016_AUST(TopoJSON 10%).json"

aus_suburbs_geo <- geojsonio::topojson_read(geojson_source_file)

#Geojson created by mapshaper.org using postal areas shapefile from ABS https://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1270.0.55.003July%202016?OpenDocument
# geojson_source_file = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\mapshaper.org\\aus_postcodes\\POA_2016_AUST(TopoJSON 10%).json"
aus.geojson <-  st_read(geojson_source_file) 

# Load and clean location info
location_info <- jsonify::from_json( auspostjson_source_file )
colnames(location_info) <- janitor::make_clean_names(colnames(location_info))
location_info <- location_info[!duplicated(location_info$postcode), ]
row.names(location_info) <- location_info$postcode
location_info  <- location_info  %>%
  data.table()
