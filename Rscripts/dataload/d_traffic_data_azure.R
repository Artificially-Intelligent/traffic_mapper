#Load traffic data and merge with traffic_location for DB, write result to DB

load_traffic_to_cosmos <-
  function(full_db_reload = FALSE,
           traffic_locations = traffic_locations,
           trafficdata_source_uri =  paste(
             "https://vicroadsopendatastorehouse.vicroads.vic.gov.au/opendata/Traffic_Measurement/Bicycle_Volume_and_Speed/Bicycle_Volume_Speed_",
             format(Sys.Date() - 5, '%Y'),
             ".zip",
             sep = ""
           )) {
    mgo_traffic_by_location_hourly <-
      mongo(db = azure$db,
            collection = "traffic_by_location_hourly",
            url = azure$mongo_url)
    
    print(
      paste(
        mgo_traffic_by_location_hourly$info()$collection ,
        "starting record count:",
        mgo_traffic_by_location_hourly$count()
      )
    )
    
    mgo_traffic_by_location_hourly$distinct("sourcefile")
    
    meta_traffic <- data.frame(file = character(0))
    if(mgo_traffic_by_location_hourly$count() > 0){
      meta_traffic <- data.frame(file = mgo_traffic_by_location_hourly$distinct("sourcefile"))
    }
    
    
    
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
    
    for (file in trafficdata_source_files) {
      sourcefile <- file.path(basename(dirname(file)), basename(file))
      data <- read.csv(file)
      print(paste(
        "Reading file:",
        sourcefile,
        "columns:",
        ncol(data),
        "rows:",
        nrow(data)
      ))
      if (nrow(data) > 0) {
        bike_traffic_data <- data %>%
          data.frame(inserttime =  Sys.time(),
                     sourcefile = sourcefile)
        
        #remove source file
        unlink(file)
        
        colnames(bike_traffic_data) <-
          janitor::make_clean_names(colnames(bike_traffic_data))
        
        bike_traffic_data_grouped <- bike_traffic_data %>%
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
          group_by(
            location_id,
            loc_leg,
            direction,
            lane,
            datetime,
            speed_group,
            vehicle,
            class,
            axle,
            axle_grouping,
            data_type,
            inserttime,
            sourcefile
          ) %>%
          summarise(
            count = n(),
            var_speed = var(speed),
            sum_speed = sum(speed),
            var_wheelbase = var(wheelbase),
            sum_wheelbase = sum(wheelbase),
            var_headway = var(headway),
            sum_headway =  sum(headway),
            var_gap = var(gap),
            sum_gap = sum(gap),
            var_rho = var(rho),
            sum_rho = sum(rho)
          ) %>%
          data.table()
        
        # conn <- poolCheckout(db_pool)
        # traffic_locations <- dbReadTable(db_pool, "traffic_location")  %>%
        #   data.table()
        # poolReturn(conn)
        
        # Merge traffic data and traffic location into a single datset
        bike_traffic <-
          traffic_locations[bike_traffic_data_grouped, on = 'location_id']
        
        # # Prepare metadata for insert
        # sourcefiles <-
        #   file.path(basename(dirname(trafficdata_source_files)),
        #             basename(trafficdata_source_files)) %>%
        #   data.frame(inserttime =  Sys.time())
        # colnames(sourcefiles) <- c("file", "inserttime")
        
        # bike_traffic_missinglocationinfo <-
        #   bike_traffic[is.na(bike_traffic$location),]
        # print(paste(
        #   sep = "",
        #   "Missing location info: " ,
        #   nrow(bike_traffic_missinglocationinfo) ,
        #   "/",
        #   nrow(bike_traffic),
        #   " (",
        #   round(
        #     100 *  nrow(bike_traffic_missinglocationinfo) / nrow(bike_traffic),
        #     digits = 1
        #   ),
        #   "%)"
        # ))
        
        mgo_traffic_by_location_hourly$insert(bike_traffic)
      }
    }
    # conn <- poolCheckout(db_pool)
    # dbBegin(conn)
    # dbWriteTable(
    #   conn,
    #   db_table,
    #   bike_traffic,
    #   append = !full_db_reload,
    #   overwrite = full_db_reload,
    #   row.names = FALSE
    # )
    # dbSendQuery(conn,
    #             paste("ALTER TABLE ", db_table, " MODIFY datetime datetime;"))
    # dbWriteTable(
    #   conn,
    #   paste("meta_", db_table, sep = ""),
    #   sourcefiles,
    #   append = !full_db_reload,
    #   overwrite = full_db_reload,
    #   row.names = FALSE
    # )
    #
    # dbCommit(conn)   # or dbRollback(conn) if something went wrong
    # poolReturn(conn)
    
    #remove source data
    unlink(trafficdata_source_files, recursive = TRUE)
    
    print("db load completed")
  }