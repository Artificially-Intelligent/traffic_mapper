#data retrival functions

get_locations <- function(table = "traffic_locations", conn) {
  
  traffic_locations <- pool::dbReadTable(conn, table) %>%
    filter(postcode < 3900 & postcode >= 3000 ) %>%
    mutate(
      location = paste(locality , "-", location_description)
    )
  return(traffic_locations)
}

add_attributes_to_traffic <- function(traffic_dataframe) {
  return(
    traffic_dataframe %>%
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
        date = as.Date(datetime),
        latitude = lat,
        longitude = long,
        week_start_date = cut(date, "week"),
        month = cut(date, "month"),
        time = format(datetime, '%H:%M:%S'),
        hour = as.numeric(format(datetime, format = "%H")),
        hour_group = factor(
          case_when(
            hour <  6 ~ "00:00-06:00",
            hour < 10 ~ "06:00-10:00",
            hour < 14 ~ "10:00-14:00",
            hour < 18 ~ "14:00-18:00",
            hour < 24 ~ "18:00-24:00",
            TRUE ~ as.character(hour)
          )
        ),
        direction = factor(
          case_when(
            direction == "N" ~ "North",
            direction == "S" ~ "South",
            direction == "E" ~ "East",
            direction == "W" ~ "West",
            TRUE ~ as.character(direction)
          )
        ),
        total_count = sum(count),
        max_speed = max(sum_speed)
        
      )
  )
}

aggregate_traffic  <- function(traffic_dataframe,group_by = c(
  "location",
  "postcode",
  "location_id",
  "locality",
  "location_description" ,
  "month",
  "hour_group",
  "speed_group"
) ) {
  return(
    traffic_dataframe  %>%
      mutate(total_count =  as.numeric(sum(count))
      ) %>%
      group_by_at(c(group_by, "total_count")) %>%
      summarise(
        latitude = as.numeric(mean(latitude)),
        longitude =  as.numeric(mean(longitude)),
        count = as.numeric(sum(count)),
        sum_speed = as.numeric(sum(sum_speed)),
        max_speed = as.numeric(max(max_speed)),
        min_speed = as.numeric(min(min_speed)),
        var_speed = as.numeric(sum(var_speed)),
        sum_wheelbase = as.numeric(sum(sum_wheelbase)),
        sum_headway = as.numeric(sum(sum_headway)),
        sum_gap = as.numeric(sum(sum_gap)),
        sum_rho = as.numeric(sum(sum_rho)),
        var_wheelbase = as.numeric(sum(var_wheelbase)),
        var_headway = as.numeric(sum(var_headway)),
        var_gap = as.numeric(sum(var_gap)),
        var_rho = as.numeric(sum(var_rho))
      ) %>%
      mutate(
        count_pct = as.numeric(round(100 * count / total_count , digits = 1)),
        avg_speed =  as.numeric(round(sum_speed / count, digits = 1)),
        # avg_speed_pct =  as.numeric(round(avg_speed /  max(max_speed), digits = 1)),
        avg_wheelbase = as.numeric(round( sum_wheelbase / count, digits = 1)),
        avg_headway =  as.numeric(round(sum_headway / count, digits = 1)),
        avg_gap = as.numeric(round(sum_gap / count, digits = 1)),
        avg_rho = as.numeric(round(sum_rho / count, digits = 1))
      )  %>%
      data.table()
  )
}

get_traffic <- function(group_by = c('location'), table = "traffic", conn) {
  
  aggregated_traffic <- pool::dbReadTable(conn, table) %>%
    filter(postcode < 3900 & postcode >= 3000 ) %>%
    add_attributes_to_traffic() %>%
    aggregate_traffic(group_by)
  
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

