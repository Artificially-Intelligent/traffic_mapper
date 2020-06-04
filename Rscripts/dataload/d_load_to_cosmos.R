#aggregate data and insert into azure cosmos

reload_cosmos_db <- function(table = "traffic") {
  conn <- poolCheckout(db_pool)
  
  traffic_locations <- get_locations(conn = conn)
  
  traffic_by_location_monthly <-
    get_traffic(
      table = table,
      group_by = c(
        "location",
        "postcode",
        "location_id",
        "locality",
        "location_description" ,
        "month",
        "hour_group",
        "speed_group"
      ),
      conn = conn
    ) %>%
    data.frame()
  
  traffic_by_location_weekly <-
    get_traffic(
      table = table,
      group_by = c(
        "location",
        "postcode",
        "location_id",
        "locality",
        "location_description" ,
        "week_start_date",
        "hour_group",
        "speed_group"
      ),
      conn = conn
    ) %>%
    data.frame()
  traffic_by_location <-
    get_traffic(
      table = table,
      group_by = c(
        "location",
        "postcode",
        "location_id",
        "locality",
        "location_description"
      ),
      conn = conn
    ) %>%
    data.frame()
  
  poolReturn(conn)
  
  
  # Write location list result to Cosmos DB
  
  mgo_traffic_locations <-
    mongo(db = "primary",
          collection = "traffic_locations",
          url = azure$mongo_url)
  mgo_traffic_locations$drop()
  mgo_traffic_locations$insert(traffic_locations)
  
  # Write location summary result to Cosmos DB
  
  traffic_by_location <-
    all_traffic[!is.na(traffic_by_location$location), ]
  mgo_traffic_by_location <-
    mongo(db = "primary",
          collection = "traffic_by_location",
          url = azure$mongo_url)
  mgo_traffic_by_location$drop()
  mgo_traffic_by_location$insert(traffic_by_location)
  
  # Write location weekly summary result to Cosmos DB
  
  traffic_by_location_weekly <-
    traffic_by_location_weekly[!is.na(traffic_by_location_weekly$location), ]
  mgo_traffic_by_location_weekly <-
    mongo(db = "primary",
          collection = "traffic_by_location_weekly",
          url = azure$mongo_url)
  mgo_traffic_by_location_weekly$drop()
  mgo_traffic_by_location_weekly$insert(traffic_by_location_weekly)
  
  traffic_by_location_monthly <-
    traffic_by_location_monthly[!is.na(traffic_by_location_monthly$location), ]
  mgo_traffic_by_location_monthly <-
    mongo(db = "primary",
          collection = "traffic_by_location_monthly",
          url = azure$mongo_url)
  mgo_traffic_by_location_monthly$drop()
  mgo_traffic_by_location_monthly$insert(traffic_by_location_monthly)
}