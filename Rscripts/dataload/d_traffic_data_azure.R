#Load traffic data and merge with traffic_location for DB, write result to DB

subset_colclasses <- function(DF, colclasses = "numeric") {
  DF[, sapply(DF, function(vec, test)
    class(vec) %in% test, test = colclasses)]
}


load_traffic_to_cosmos <-
  function(full_db_reload = FALSE,
           traffic_locations = traffic_locations,
           trafficdata_source_uri =  paste(
             "https://vicroadsopendatastorehouse.vicroads.vic.gov.au/opendata/Traffic_Measurement/Bicycle_Volume_and_Speed/Bicycle_Volume_Speed_",
             format(Sys.Date() - 5, '%Y'),
             ".zip",
             sep = ""
           )) {
    mgo_traffic_by_location_aggregated <-
      mongo(db = azure$db,
            collection = "traffic_by_location_aggregated",
            url = azure$mongo_url)
    mgo_traffic_by_location_hourly <-
      mongo(db = azure$db,
            collection = "traffic_by_location_hourly",
            url = azure$mongo_url)
    mgo_traffic_by_location_daily <-
      mongo(db = azure$db,
            collection = "traffic_by_location_daily",
            url = azure$mongo_url)
    mgo_traffic_by_location_monthly <-
      mongo(db = azure$db,
            collection = "traffic_by_location_monthly",
            url = azure$mongo_url)
    mgo_traffic_by_location <-
      mongo(db = azure$db,
            collection = "traffic_by_location",
            url = azure$mongo_url)
    
    if (full_db_reload) {
      mgo_traffic_by_location_aggregated$drop()
      # mgo_traffic_by_location_hourly$drop()
      mgo_traffic_by_location_daily$drop()
      mgo_traffic_by_location_monthly$drop()
      mgo_traffic_by_location$drop()
    }
    
    
    mgo_traffic_by_location_aggregated_start_count <- mgo_traffic_by_location_aggregated$info()$collection
    print(
      paste(
        mgo_traffic_by_location_aggregated$info()$collection ,
        "starting record count:",
        mgo_traffic_by_location_aggregated_start_count
      )
    )
    
    
    meta_traffic <- data.frame(file = character(0))
    if (mgo_traffic_by_location$count() > 0) {
      meta_traffic <-
        data.frame(file = mgo_traffic_by_location$distinct("sourcefile"))
    }
    
    traffic_by_location_sourefiles <- mgo_traffic_by_location$distinct("sourcefile") 
    traffic_by_location_aggregated_sourefiles <- mgo_traffic_by_location_aggregated$distinct("sourcefile")
    incomplete_load_sourefiles <- traffic_by_location_aggregated_sourefiles[! traffic_by_location_aggregated_sourefiles %in% traffic_by_location_sourefiles]
    
    
    for (sourefiles in incomplete_load_sourefiles) {
      print(paste("incomplete load detected, removing records from",sourefiles))
      json_filter <-
        paste('{"sourcefile" : "', sourefiles , '"}', sep =  "")
      
      before <- mgo_traffic_by_location_aggregated$count()
      mgo_traffic_by_location_aggregated$remove(json_filter)
      print(
        paste(
          "removed",
          mgo_traffic_by_location_aggregated$count() - before,
          "records from",
          mgo_traffic_by_location_aggregated$info()$collection
        )
      )
      
      before <- mgo_traffic_by_location_daily$count()
      mgo_traffic_by_location_daily$remove(json_filter)
      print(
        paste(
          "removed",
          mgo_traffic_by_location_daily$count() - before,
          "records from",
          mgo_traffic_by_location_daily$info()$collection
        )
      )
      
      before <- mgo_traffic_by_location_monthly$count()
      mgo_traffic_by_location_monthly$remove(json_filter)
      print(
        paste(
          "removed",
          mgo_traffic_by_location_monthly$count() - before,
          "records from",
          mgo_traffic_by_location_monthly$info()$collection
        )
      )
    }
    
    
    mgo_traffic_by_location_aggregated$index(add  = "location")
    mgo_traffic_by_location_aggregated$index(add  = "sourcefile")
    mgo_traffic_by_location_aggregated$index(add  = "inserttime")
    mgo_traffic_by_location_aggregated$index(add  = "month")
    mgo_traffic_by_location_aggregated$index(add  = "date")
    mgo_traffic_by_location_aggregated$index(add  = "hour_group")
    mgo_traffic_by_location_aggregated$index(add  = "hour")
    mgo_traffic_by_location_aggregated$index(add  = "datetime")
    
    mgo_traffic_by_location_hourly$index(add  = "location")
    mgo_traffic_by_location_hourly$index(add  = "sourcefile")
    mgo_traffic_by_location_hourly$index(add  = "inserttime")
    mgo_traffic_by_location_hourly$index(add  = "month")
    mgo_traffic_by_location_hourly$index(add  = "hour_group")
    mgo_traffic_by_location_hourly$index(add  = "date")
    mgo_traffic_by_location_hourly$index(add  = "hour")
    
    mgo_traffic_by_location_daily$index(add  = "location")
    mgo_traffic_by_location_daily$index(add  = "sourcefile")
    mgo_traffic_by_location_daily$index(add  = "inserttime")
    mgo_traffic_by_location_daily$index(add  = "month")
    mgo_traffic_by_location_daily$index(add  = "hour_group")
    mgo_traffic_by_location_daily$index(add  = "date")
    
    mgo_traffic_by_location_monthly$index(add  = "location")
    mgo_traffic_by_location_monthly$index(add  = "sourcefile")
    mgo_traffic_by_location_monthly$index(add  = "inserttime")
    mgo_traffic_by_location_monthly$index(add  = "month")
    mgo_traffic_by_location_monthly$index(add  = "hour_group")
    
    mgo_traffic_by_location$index(add  = "location")
    mgo_traffic_by_location$index(add  = "sourcefile")
    mgo_traffic_by_location$index(add  = "inserttime")
    
    # location_count <- mgo_traffic_by_location$aggregate('[{"$group":{"_id":"$location", "count": {"$sum":1}}}]')
    
    
    
    # trafficdata_source_directory = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\discover.data.vic.gov.au\\vicroads\\Bicycle_Volume_Speed_2020\\"
    trafficdata_source_zip <-
      file.path('data', 'Bicycle_Volume_Speed.zip')
    download.file(trafficdata_source_uri,
                  destfile = trafficdata_source_zip,
                  mode = "wb")
    
    zip_file_list <- unzip(trafficdata_source_zip, list = TRUE)
    
    # zip_file_list <-
    #   zip_file_list[!zip_file_list$Name %in% paste(str_extract(meta_traffic$file, '^(.+?)IND'), ".zip", sep =
    #                                                  ''),]
    # zip_file_list <- zip_file_list[1:5,]
    
    exdir_path <- file.path('data', 'Bicycle_Volume_Speed_zip')
    unzip(trafficdata_source_zip,
          exdir = exdir_path,
          files = zip_file_list$Name)
    file.remove(trafficdata_source_zip)
    
    
    trafficdata_source_directory <-
      file.path('data', 'Bicycle_Volume_Speed')
    print('unzipping source files')
    
    #Remove any existing unziped files in destination folder
    unlink(trafficdata_source_directory, recursive = TRUE)
    
    lapply(list.files(
      path = exdir_path,
      pattern = '*.zip',
      full.names = TRUE
    ), function(x) {
      exdir_folder <- basename(x) %>% str_extract('^(.+?)[.]')
      exdir_folder <-
        substring(exdir_folder, 1 , nchar(exdir_folder) - 1)
      print(file.path(trafficdata_source_directory, exdir_folder))
      unzip(x, exdir = file.path(trafficdata_source_directory, exdir_folder))
    })
    print('unzipping complete')
    
    unlink(exdir_path, recursive = TRUE)
    
    # Read source data for bike traffic stats
    trafficdata_source_files <-
      list.files(
        trafficdata_source_directory,
        pattern = "*.csv",
        full.names = TRUE,
        recursive = TRUE
      )
    
    # Filter out files already loaded to DB
    trafficdata_source_files <-
      trafficdata_source_files[!file.path(basename(dirname(trafficdata_source_files)), basename(trafficdata_source_files)) %in% meta_traffic$file]
    
    for (traffic_source_file in trafficdata_source_files) {
      sourcefile <-
        file.path(basename(dirname(traffic_source_file)), basename(traffic_source_file))
      bike_traffic_data_raw <- read.csv(traffic_source_file)
      print(paste(
        "Reading file:",
        sourcefile,
        "columns:",
        ncol(data),
        "rows:",
        nrow(data)
      ))
      unlink(traffic_source_file)
      
      if (nrow(bike_traffic_data_raw) > 0) {
        # bike_traffic_data <- data %>%
        #   data.frame(inserttime =  Sys.time(),
        #              sourcefile = sourcefile)
        #
        #remove source file
        
        
        colnames(bike_traffic_data_raw) <-
          janitor::make_clean_names(colnames(bike_traffic_data_raw))
        
        bike_traffic_data_aggregated <- bike_traffic_data_raw  %>%
          data.frame(inserttime =  Sys.time(),
                     sourcefile = sourcefile) %>%
          mutate(
            location_id = paste(sep = "",  "D" , tis_data_request, "X", site_xn_route, "P"),
            time = as.factor(paste(sep = "", substr(time, 1, 3), "00:00")),
            speed_group = as.factor(
              case_when(
                speed >  0 & speed <=  5 ~ "00-05",
                speed >  5 & speed <= 10 ~ "05-10",
                speed > 10 & speed <= 15 ~ "10-15",
                speed > 15 & speed <= 20 ~ "15-10",
                speed > 20 & speed <= 25 ~ "20-25",
                speed > 25 & speed <= 30 ~ "25-20",
                speed > 30 & speed <= 35 ~ "30-35",
                speed > 35 & speed <= 40 ~ "35-30",
                speed > 40 & speed <= 45 ~ "40-45",
                speed > 45 & speed <= 50 ~ "45-50",
                speed > 50 & speed <= 55 ~ "50-55",
                speed > 55 & speed <= 60 ~ "55-60",
                speed > 60  ~ "60+",
                TRUE ~ "unknown"
              )
            )
          ) %>%
          mutate(datetime =  as.POSIXct(strptime(paste(date, time), format = '%d/%m/%Y %H:%M:%S'))) %>%
          mutate(datetime = format(datetime, '%Y-%m-%d %H:%M:%S')) %>%
          group_by_at(
            c(
              "inserttime",
              "sourcefile" ,
              "datetime",
              "location_id",
              "speed_group",
              "datetime",
              "time",
              colnames(subset_colclasses(
                bike_traffic_data_raw,
                c("factor", "character", "integer")
              ))
            )
          ) %>%
          summarise(
            sum_speed = as.numeric(sum(speed)),
            max_speed = as.numeric(max(speed)),
            min_speed = as.numeric(min(speed)),
            var_speed = as.numeric(var(sum_speed)),
            sum_wheelbase = as.numeric(sum(wheelbase)),
            sum_headway = as.numeric(sum(headway)),
            sum_gap = as.numeric(sum(headway)),
            sum_rho = as.numeric(sum(rho)),
            var_wheelbase = as.numeric(var(wheelbase)),
            var_headway = as.numeric(var(headway)),
            var_gap = as.numeric(var(headway)),
            var_rho = as.numeric(var(rho)),
            count = n()
          ) %>% data.table()
        
        traffic_locations <- data.table(traffic_locations)
        
        # Merge traffic data and traffic location into a single datset
        bike_traffic_data_aggregated <-
          traffic_locations[bike_traffic_data_aggregated, on = 'location_id'] %>%
          add_attributes_to_traffic()
        
        group_by_timeseries <- c("hour_group",
                                 "speed_group")
        
        group_by_location <- c(
          "location",
          "postcode",
          "location_id",
          "locality",
          "location_description" ,
          "sourcefile",
          "inserttime"
        )
        
        bike_traffic_data_daily <- bike_traffic_data_aggregated  %>%
          aggregate_traffic(unique(
            c(group_by_timeseries, group_by_location, "month", "date")
          ))
        
        bike_traffic_data_monthly <- bike_traffic_data_daily  %>%
          aggregate_traffic(unique(c(
            group_by_timeseries, group_by_location, "month"
          )))
        
        bike_traffic_data_location <- bike_traffic_data_monthly  %>%
          aggregate_traffic(c(group_by_location))
        
        mgo_traffic_by_location_aggregated$insert(bike_traffic_data_aggregated)
        mgo_traffic_by_location_daily$insert(bike_traffic_data_daily)
        mgo_traffic_by_location_monthly$insert(bike_traffic_data_monthly)
        mgo_traffic_by_location$insert(bike_traffic_data_location)
      }
    }
    
    #remove source data
    unlink(trafficdata_source_files, recursive = TRUE)
    
    mgo_traffic_by_location_aggregated_finish_count <- mgo_traffic_by_location_aggregated$count()
    print(
      paste(
        mgo_traffic_by_location_aggregated$info()$collection ,
        "final record count:",
        mgo_traffic_by_location_aggregated_finish_count,
        "inserted:",
        mgo_traffic_by_location_aggregated_finish_count - mgo_traffic_by_location_aggregated_start_count
      )
    )
    
    print("db load completed")
  }