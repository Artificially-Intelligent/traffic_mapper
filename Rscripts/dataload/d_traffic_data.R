#Load traffic data and merge with traffic_location for DB, write result to DB

# trafficdata_source_directory = "\\\\unraiden.slink42.duckdns.org\\home\\stuart\\shared\\documents\\data\\discover.data.vic.gov.au\\vicroads\\Bicycle_Volume_Speed_2020\\"

# Read source data for bike traffic stats
trafficdata_source_files <-
  list.files(
    trafficdata_source_directory,
    pattern = "*.csv",
    full.names = TRUE,
    recursive = TRUE
  )

bike_traffic_data <-
  data.table::rbindlist(lapply(trafficdata_source_files, 
                               function(x){
                                 sourcefile <- file.path(substr(str_extract(dirname(x), pattern = '\\/\\/.*$'), 3, 256),basename(x))
                                 data <- read.csv(x)  %>%
                                   data.frame(inserttime =  Sys.time(),
                                              sourcefile = file.path(substr(str_extract(dirname(x), pattern = '\\/\\/.*$'), 3, 256),basename(x))
                                              )
                               }
                               ))


colnames(bike_traffic_data) <-
  janitor::make_clean_names(colnames(bike_traffic_data))


bike_traffic_data_grouped <- bike_traffic_data %>%
  mutate(
    location_id = paste(sep = "",  "D" , tis_data_request, "X", site_xn_route, "P"),
    time = as.factor(paste(sep = "", substr(time, 1, 3), "00:00"))
  ) %>%
  mutate(datetime =  as.POSIXct(strptime(paste(date, time), format = '%d/%m/%Y %H:%M:%S'))) %>%
  mutate(datetime = format(datetime, '%Y-%m-%d %H:%M:%S')) %>%
  group_by(
    location_id,
    loc_leg,
    direction,
    lane,
    datetime,
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
    sum_speed = sum(speed),
    sum_wheelbase = sum(wheelbase),
    sum_headway =  sum(headway),
    sum_gap = sum(gap),
    sum_rho = sum(rho)
  ) %>%
  data.table()

conn <- poolCheckout(db_pool)
traffic_location <- dbReadTable(db_pool, "traffic_location")  %>%
  data.table()

# Merge traffic data and traffic location into a single datset
bike_traffic <-
  traffic_location[bike_traffic_data_grouped, on = 'location_id']

# Prepare metadata for insert
sourcefiles <- file.path(substr(str_extract(dirname(trafficdata_source_files), pattern = '\\/\\/.*$'), 3, 256),basename(trafficdata_source_files)) %>%
  data.frame(inserttime =  Sys.time())
colnames(sourcefiles) <- c("file","inserttime")

bike_traffic_missinglocationinfo <- bike_traffic[is.na(bike_traffic$location),]
print(paste(sep = "", "Missing location info: " , nrow(bike_traffic_missinglocationinfo) , "/", nrow(bike_traffic), " (", round(100 *  nrow(bike_traffic_missinglocationinfo) / nrow(bike_traffic), digits = 1), "%)"  ))


dbBegin(conn)
dbWriteTable(conn,
             "traffic",
             bike_traffic,
             overwrite = TRUE,
             row.names = FALSE)
dbSendQuery(conn,
            "ALTER TABLE all_traffic MODIFY datetime datetime;")
dbWriteTable(conn,
             "meta_traffic",
             sourcefiles,
             append = TRUE,
             row.names = FALSE)

dbCommit(conn)   # or dbRollback(conn) if something went wrong
poolReturn(conn)

# glimpse(bike_traffic)
install.packages('mongolite', repos = 'https://cran.microsoft.com/snapshot/2018-08-01')
library(mongolite)
url <- "mongodb://shiny:H26KAgdzCIkVsK5Njh8SlFCDV8O41SD0YbHY6dZnvUv6Ec70FNyKxMb8cvzso1FFSA0FYdZ6gkKCgw96onyEjA==@shiny.documents.azure.com:10255/mean-dev?ssl=true"

# Write result to Cosmos DB

bike_traffic <- bike_traffic[! is.na(bike_traffic$location),]

mgo <- mongo(db = "primary", collection = "bike_traffic", url=azure$mongo_url)
mgo$insert(bike_traffic)


