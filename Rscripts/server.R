


## Data Load ##########################################

if (use_mongo) {
  mgo_traffic_by_location <-
    mongo(db = "primary",
          collection = "traffic_by_location",
          url = azure$mongo_url)
  traffic_by_location <- mgo_traffic_by_location$find()

  # mgo_traffic_by_location_weekly <-
  #   mongo(db = "primary",
  #         collection = "traffic_by_location_weekly",
  #         url = azure$mongo_url)
  # traffic_by_location_weekly <- mgo_traffic_by_location_weekly$find()

  mgo_traffic_by_location_monthly <-
    mongo(db = "primary",
          collection = "traffic_by_location_monthly",
          url = azure$mongo_url)
  traffic_by_location_monthly <- mgo_traffic_by_location_monthly$find()

} else{
  conn <- poolCheckout(db_pool)
  
  traffic_locations <- get_locations(conn = conn)
  
  traffic_by_location_monthly <- get_traffic_by_location_monthly(db_table,conn) 
  
  poolReturn(conn)
  
  # conn <- poolCheckout(db_pool)
  # 
  # traffic_by_location_weekly <- get_traffic_by_location_weekly(db_table,conn) 
  # 
  # poolReturn(conn)
  
  conn <- poolCheckout(db_pool)
  
  traffic_by_location <- get_traffic_by_location(db_table,conn) 
  
  poolReturn(conn)
  
}


cleantable <- traffic_by_location %>%
  select(
    Suburb = locality,
    Postcode = postcode,
    Location = location_description,
    Lat = latitude,
    Long = longitude,
    Volume = count,
    AvgSpeed = avg_speed,
    AvgWheelbase = avg_wheelbase,
    AvgHeadway = avg_headway,
    AvgGap = avg_gap,
    AvgRho = avg_rho
  )



function(input, output, session) {
  # Leaflet bindings are a bit slow; for now we'll just sample to compensate
  if (nrow(traffic_by_location) > 10000) {
    set.seed(100)
    location_data <-
      traffic_by_location[sample.int(nrow(traffic_by_location), 10000), ]
  } else{
    location_data <- traffic_by_location
  }
  
  print("File list:")
  print(list.files(recursive = TRUE))
  print(paste("Config path:", Sys.getenv("R_CONFIG_FILE", "conf/config.yml")))
  
  
  # weekly_location_data <- traffic_by_location_weekly
  monthly_location_data <- traffic_by_location_monthly
  # By ordering by centile, we ensure that the (comparatively rare) SuperZIPs
  # will be drawn last and thus be easier to see
  location_data <- location_data[order(location_data$count), ]
  
  
  ## Interactive Map ###########################################
  
  # Create the map
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
               attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>')  %>%
      addFullscreenControl() %>%
      # fitBounds(~ min(traffic_by_location$longitude), ~ min(traffic_by_location$latitude),
      #           ~ max(traffic_by_location$longitude), ~ max(traffic_by_location$latitude))
      setView(lng = 144.9886,
              lat = -37.8167,
              zoom = 11.25)
  })
  
  waiter_hide()
  
  # A reactive expression that returns the set of zips that are
  # in bounds right now
  locationsInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(location_data[FALSE, ])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(
      location_data,
      latitude >= latRng[1] & latitude <= latRng[2] &
        longitude >= lngRng[1] & longitude <= lngRng[2]
    )
  })
  
  
  # weeklyLocationInBounds <- reactive({
  #   if (is.null(input$map_bounds))
  #     return(location_data[FALSE, ])
  #   bounds <- input$map_bounds
  #   latRng <- range(bounds$north, bounds$south)
  #   lngRng <- range(bounds$east, bounds$west)
  #   
  #   subset(
  #     weekly_location_data,
  #     latitude >= latRng[1] & latitude <= latRng[2] &
  #       longitude >= lngRng[1] & longitude <= lngRng[2]
  #   )
  # })
  
  monthlyLocationInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(location_data[FALSE, ])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(
      monthly_location_data,
      latitude >= latRng[1] & latitude <= latRng[2] &
        longitude >= lngRng[1] & longitude <= lngRng[2]
    )
  })
  
  
  
  
  output$valueBox_volume <- renderValueBox({
    count <- sum(locationsInBounds()$count)
    label <- "Traffic Volume"
    valueBox(
      value = formatC(count, digits = 0, format = "f"),
      subtitle = label
      # ,
      # icon = icon("bicycle")
      # ,
      # color = if (download_rate >= input$rateThreshold) "yellow" else "aqua"
    )
  })
  
  output$valueBox_speed <- renderValueBox({
    speed <-
      sum(locationsInBounds()$total_speed) / sum(monthlyLocationInBounds()$count)
    label <- "Average Speed(Km/h)"
    valueBox(
      value = formatC(speed, digits = 1, format = "f"),
      subtitle = label
      # ,
      # icon = icon("tachometer")
      # ,
      # color = if (download_rate >= input$rateThreshold) "yellow" else "aqua"
    )
  })
  
  output$area_VolumeByTime <- renderPlotly({
    graphColorPallet <- input$graph_pallet
    build_plot_monthly_volume_by_hour(monthlyLocationInBounds())
  })
  
  output$line_SpeedByTime <- renderPlotly({
    graphColorPallet <- input$graph_pallet
    build_plot_weekly_speed_by_hour(monthlyLocationInBounds())
    
  })
  
  
  output$lollipop_VolumeChangeByTime <- renderPlotly({
    graphColorPallet <- input$graph_pallet
    build_plot_volume_change_by_date(monthlyLocationInBounds())
  })
  
  output$histogram_SpeedDistrubution <- renderPlotly({
    graphColorPallet <- input$graph_pallet
    build_plot_speed_histogram(monthlyLocationInBounds())
  }) 
  
  
  output$summary.area_VolumeByTime <- renderPlotly({
    build_plot_monthly_volume_by_hour(monthly_location_data)
    
  })
  
  # # Precalculate the breaks we'll need for the two histograms
  # volumeBreaks <-
  #   hist( monthly_location_data$avg, breaks = 10)
  # 
  # output$histVolume <- renderPlot({
  #   # If no postcodes are in view, don't plot
  #   if (nrow(locationsInBounds()) == 0)
  #     return(NULL)
  #   
  #   hist(
  #     # locationsInBounds()$count,
  #     breaks = volumeBreaks,
  #     main = "Location Traffic Volume (visible only)",
  #     xlab = "Percentile",
  #     xlim = range(traffic_by_location$count),
  #     col = '#00DD00',
  #     border = 'white'
  #   )
  # })
  
  # output$scatterCollegeIncome <- renderPlot({
  #   # If no postcodes are in view, don't plot
  #   if (nrow(locationsInBounds()) == 0)
  #     return(NULL)
  #
  #   print(xyplot(income ~ college, data = zipsInBounds(), xlim = range(traffic_by_location$college), ylim = range(traffic_by_location$income)))
  # })
  
  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  observe({
    colorBy <- input$color
    sizeBy <- input$size
    mapColorPallet <- input$map_pallet
    showLegend <- input$legend
    
    if (colorBy == "location") {
      # Color and palette are treated specially in the "superzip" case, because
      # the values are categorical instead of continuous.
      # colorData <- ifelse(location_data$postcode >= (100 - input$threshold), "yes", "no")
      colorData <- location_data$location
      pal <- colorFactor(mapColorPallet, colorData)
    } else {
      colorData <- location_data[[colorBy]]
      pal <- colorBin(mapColorPallet, colorData, 7, pretty = FALSE)
    }
    
    if (sizeBy == "location") {
      # Radius is treated specially in the "superzip" case.
      radius <- 300
    } else {
      radius <-
        location_data[[sizeBy]] / max(location_data[[sizeBy]]) * 1500
    }
    
    leafletProxy("map", data = location_data) %>%
      clearShapes() %>%
      addCircles(
        ~ longitude,
        ~ latitude,
        radius = radius,
        layerId =  ~ location_id,
        stroke = FALSE,
        fillOpacity = 0.4,
        fillColor = pal(colorData)
      ) %>%
      addLegend(
        "bottomleft",
        pal = pal,
        values = colorData,
        title = colorBy,
        layerId = "colorLegend"
      )
  })
  
  # Show a popup at the given location
  showLocationPopup <- function(location_id, lat, lng) {
    selected_location <-
      traffic_by_location[traffic_by_location$location_id == location_id, ]
    content <- as.character(
      tagList(
        tags$h5(HTML(
          sprintf(
            "%s - %s",
            selected_location$locality,
            selected_location$location_description
          )
        )),
        "Traffic Volume:",
        as.integer(selected_location$count),
        "(" ,
        selected_location$count_pct ,
        "% of total)",
        tags$br(),
        "Daily Average Volume:",
        as.integer(selected_location$avg_daily_count),
        tags$br(),
        "Avg Speed:",
        as.integer(selected_location$avg_speed),
        "Km/h"
        # ,
        # sprintf("Median household income: %s", dollar(selected_location$income * 1000)), tags$br(),
        # sprintf("Percent of adults with BA: %s%%", as.integer(selected_location$college)), tags$br(),
        # sprintf("Adult population: %s", selected_location$adultpop)
      )
    )
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = location_id)
  }
  
  # When map is clicked, show a popup with city info
  observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_shape_click
    if (is.null(event))
      return()
    
    isolate({
      showLocationPopup(event$id, event$lat, event$lng)
    })
  })
  
  
  ## Data Explorer ###########################################
  
  observe({
    cities <- if (is.null(input$states))
      character(0)
    else {
      filter(cleantable, State %in% input$states) %>%
        `$`('City') %>%
        unique() %>%
        sort()
    }
    stillSelected <- isolate(input$cities[input$cities %in% cities])
    updateSelectizeInput(
      session,
      "cities",
      choices = cities,
      selected = stillSelected,
      server = TRUE
    )
  })
  
  observe({
    postcodes <- if (is.null(input$suburb))
      character(0)
    else {
      cleantable %>%
        filter(
          Suburb %in% input$suburb,
          is.null(input$location_description) |
            Location %in% input$location_description
        ) %>%
        `$`('Postcode') %>%
        unique() %>%
        sort()
    }
    stillSelected <-
      isolate(input$postcodes[input$postcodes %in% postcodes])
    updateSelectizeInput(
      session,
      "postcodes",
      choices = postcodes,
      selected = stillSelected,
      server = TRUE
    )
  })
  
  observe({
    if (is.null(input$goto))
      return()
    isolate({
      map <- leafletProxy("map")
      map %>% clearPopups()
      dist <- 0.02
      location <- input$goto$location
      lat <- input$goto$lat
      lng <- input$goto$lng
      showLocationPopup(location, lat, lng)
      map %>% fitBounds(lng - dist, lat - dist, lng + dist, lat + dist)
    })
  })
  
  output$locationTable <- DT::renderDataTable({
    df <- cleantable %>%
      filter(
        # Score >= input$minScore,
        # Score <= input$maxScore,
        is.null(input$suburb) | Suburb %in% input$suburb,
        is.null(input$location_description) |
          Location %in% input$location_description,
        is.null(input$postcodes) | Postcode %in% input$postcodes
      ) %>%
      mutate(
        Action = paste(
          '<a class="go-map" href="" data-lat="',
          Lat,
          '" data-long="',
          Long,
          '" data-location="',
          Location,
          '"><i class="fa fa-crosshairs"></i></a>',
          sep = ""
        )
      )
    action <-
      DT::dataTableAjax(session, df, outputId = "locationTable")
    
    DT::datatable(df, options = list(ajax = list(url = action)), escape = FALSE)
  })
}
