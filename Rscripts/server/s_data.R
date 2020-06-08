#data retrival functions

get_locations <- function(table = "traffic_locations", conn) {
  
  traffic_locations <- pool::dbReadTable(conn, table) %>%
    filter(postcode < 3900 & postcode >= 3000 ) %>%
    mutate(
      location = paste(locality , "-", location_description)
    )
  return(traffic_locations)
}

get_traffic <- function(group_by = c('location'), table = "traffic", conn) {
 
  aggregated_traffic <- pool::dbReadTable(conn, table) %>%
    filter(postcode < 3900 & postcode >= 3000 ) %>%
    mutate(
      datetime = as.POSIXct(datetime),
      location = paste(locality , "-", location_description),
      weekday = factor(
        format(datetime, '%A'),
        levels = c(
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
          "Saturday",
          "Sunday"
        ),
      ),
      # date = round(datetime, unit = "days"),
      # date = format( round(datetime, '%Y-%m-%d')),
      date = as.Date(datetime),
      week_start_date = cut(date, "week"),
      month = cut(date, "month"),
      time = format(datetime, '%H:%M:%S'),
      hour = as.numeric(format(datetime, format = "%H")),
      hour_group = factor(case_when(
        hour <  6 ~ "00:00-06:00",
        hour < 10 ~ "06:00-10:00",
        hour < 14 ~ "10:00-14:00",
        hour < 18 ~ "14:00-18:00",
        hour < 24 ~ "18:00-24:00",
        TRUE ~ as.character(hour)
      )),
      hour_group = factor(case_when(
        hour <  6 ~ "00:00-06:00",
        hour < 10 ~ "06:00-10:00",
        hour < 14 ~ "10:00-14:00",
        hour < 18 ~ "14:00-18:00",
        hour < 24 ~ "18:00-24:00",
        TRUE ~ as.character(hour)
      )),
      direction = factor(case_when(
          direction == "N" ~ "North",
          direction == "S" ~ "South",
          direction == "E" ~ "East",
          direction == "W" ~ "West",
          TRUE ~ direction
        )),
      total_count = sum(count),
      max_speed = max(sum_speed)
    ) %>%
    group_by_at(group_by) %>%
    summarise(
      latitude = as.numeric(mean(lat)),
      longitude =  as.numeric(mean(long)),
      total_speed = as.numeric(sum(sum_speed)),
      count = as.numeric(sum(count)),
      count_pct = as.numeric(round(100 * count / mean(total_count) , digits = 1)),
      day_count = as.numeric(length(unique(date))),
      avg_speed =  as.numeric(round(total_speed / count, digits = 1)),
      avg_speed_pct =  as.numeric(round(avg_speed /  max(max_speed), digits = 1)),
      avg_daily_count =  as.numeric(round(count / day_count, digits = 1)),
      avg_wheelbase = as.numeric(round( sum(sum_wheelbase) / count, digits = 1)),
      avg_headway =  as.numeric(round(sum(sum_headway) / count, digits = 1)),
      avg_gap = as.numeric(round(sum(sum_gap) / count, digits = 1)),
      avg_rho = as.numeric(round(sum(sum_rho) / count, digits = 1))
    )

  return(aggregated_traffic)
}

get_traffic_by_location_monthly  <- function(db_table,conn) {
  conn <- poolCheckout(db_pool)
  get_traffic(
    table = db_table,
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
  poolReturn(conn)
}


get_traffic_by_location_weekly  <- function(db_table,conn) {
  get_traffic(
    table = db_table,
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
}

get_traffic_by_location  <- function(db_table,conn) {
  get_traffic(
    table = db_table,
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
}

# Find postcode function. It takes logitude/latitude vectors
# and returns a vector of postcodes.
find_postcode <- function(lat, long, sp_polygon = aus.geojson) {
  postcode <- character(0)
  cnt = 1
  # Iterate the vector data one by one
  for (lo in long) {
    la <- lat[cnt]
    # Check whether the point belongs to any of polygons.
    which.row <-
      sf::st_contains(sp_polygon, sf::st_point(c(lo, la)), sparse = FALSE) %>%
      grep(TRUE, .)
    
    # If the point doesn't belong to any polygons, return NA.
    if (identical(which.row, integer(0)) == TRUE) {
      postcode <- c(postcode, NA)
    } else {
      d <- sp_polygon[which.row, ]
      area <- d$AREASQKM16
      geometry <- d$geometry
      postcode <- c(postcode, paste0(d$POA_CODE16))
    }
    cnt <- cnt + 1
  }
  return (postcode)
}

find_location_info <- function( lat, long, sp_polygon = aus.geojson, location_info = location_info) {
  selected_postcode <- find_postcode(lat,long)  %>%
    data.table()
  colnames(selected_postcode) <- 'postcode'
  selected_location_info <- location_info[selected_postcode, on = 'postcode']
  
  return(selected_location_info)
}
  
find_location_name <- function( lat, long, sp_polygon = aus.geojson, location_info = location_info) {
  selected_location_info <-  find_location_info( lat, long, sp_polygon,location_info)
  return(janitor::make_clean_names(selected_location_info$locality, case = "title"))
}

