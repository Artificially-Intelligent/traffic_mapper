## Load traffic data and lookup location attributes using geodata. Write result to DB

# trafficlocation_source_files = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\discover.data.vic.gov.au\\vicroads\\VicRoads_Bike_Site_Number_Listing.xlsx"

# Read source data for bike traffic measurement locations and filter list for locations in bike_traffic data
bike_traffic_locations <-
  data.table::rbindlist(lapply(trafficlocation_source_files,
                               function(x) {
                                 readxl::read_xlsx(x , skip = 1)
                               })) %>%
  mutate(LOCATION_ID = str_extract(`SITE NAME`, "^.+[P]")) %>%
  # filter(LOCATION_ID %in% levels(factor(bike_traffic$LOCATION_ID))) %>%
  data.table()


bike_traffic_locations$lat <- as.numeric(str_extract(bike_traffic_locations$GPS,"[\\-\\+]\\d+.\\d+"))
bike_traffic_locations$long <- as.numeric(str_extract(bike_traffic_locations$GPS, "\\ [\\-\\+]\\d+.\\d+"))

colnames(bike_traffic_locations) <- janitor::make_clean_names(colnames(bike_traffic_locations))

bike_traffic_locations_grouped <- bike_traffic_locations %>%
  mutate(location_type =  str_extract(
    str_extract(description, pattern = "\\(.+\\)")
    ,pattern ="\\w+ \\w+" ),
    location_description =  str_extract(description, pattern = "\\ \\w+\\ \\w+")
  ) %>%
  group_by(
    site_name,
    location_id,
    location_description,
    location_type
  ) %>%
  summarise(lat = mean(lat), long = mean(long))


bike_traffic_location_info <- find_location_info(
  bike_traffic_locations_grouped$lat,
  bike_traffic_locations_grouped$long,
  location_info = location_info
)

bike_traffic_locations_grouped <-
  cbind(
    data.frame(bike_traffic_locations_grouped),
    data.frame(bike_traffic_location_info)
  )

colnames(bike_traffic_locations_grouped) <- janitor::make_clean_names(colnames(bike_traffic_locations_grouped))


bike_traffic_locations_grouped$location <-
  paste(
    bike_traffic_locations_grouped$locality ,
    "-",
    bike_traffic_locations_grouped$location_description
  )

conn <- poolCheckout(db_pool)
dbWriteTable(db_pool, "traffic_location",bike_traffic_locations_grouped,overwrite = TRUE, row.names = FALSE)
poolReturn(conn)