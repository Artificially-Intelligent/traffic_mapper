#aggregate data and insert into azure cosmos

conn <- poolCheckout(db_pool)

traffic_locations <- get_locations(conn = conn)

traffic_by_location_weekly <-
  get_traffic(
    group_by = c(
      "location",
      "postcode",
      "location_id",
      "locality",
      "location_description" ,
      "week_start_date",
      "hour_group"
    ), conn = conn
  ) %>%
  data.frame()
traffic_by_location <-
  get_traffic(
    group_by = c(
      "location",
      "postcode",
      "location_id",
      "locality",
      "location_description"
    ), conn = conn
  ) %>%
  data.frame()

poolReturn(conn)


# Write location list result to Cosmos DB

mgo_traffic_locations <- mongo(db = "primary", collection = "traffic_locations", url=azure$mongo_url)
mgo_traffic_locations$drop()
mgo_traffic_locations$insert(traffic_locations)

# Write location summary result to Cosmos DB

traffic_by_location <- all_traffic[! is.na(traffic_by_location$location),]
mgo_traffic_by_location <- mongo(db = "primary", collection = "traffic_by_location", url=azure$mongo_url)
mgo_traffic_by_location$drop()
mgo_traffic_by_location$insert(traffic_by_location)

# Write location weekly summary result to Cosmos DB

traffic_by_location_weekly <- all_traffic_timeseries[! is.na(traffic_by_location_weekly$location),]
mgo_traffic_by_location_weekly <- mongo(db = "primary", collection = "traffic_by_location_weekly", url=azure$mongo_url)
mgo_traffic_by_location_weekly$drop()
mgo_traffic_by_location_weekly$insert(traffic_by_location_weekly)

