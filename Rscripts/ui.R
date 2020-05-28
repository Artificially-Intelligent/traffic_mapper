library(leaflet)

# Choices for drop-downs
vars <- c(
  "Measurement Location" = "location",
  "Traffic Volume" = "count",
  "Speed" = "avg_speed"
)

pallet_vars <- rownames(brewer.pal.info)

# pallet_vars <- rownames(subset(brewer.pal.info, category %in% c("seq", "div")))

conn <- poolCheckout(db_pool)
traffic_locations <- get_locations(conn = conn)
poolReturn(conn)

navbarPage(
  "Traffic Mapper",
  id = "nav",
  header = tagList(use_waiter(),
                   waiter_show_on_load(tagList(
                     spin_fading_circles(),
                     div(class = 'loading-text', "Loading Source Data...")
                   ))),
  tabPanel(
    "Interactive map",
    div(
      class = "outer",
      
      tags$head(# Include our custom CSS
        includeCSS("styles.css"),
        includeScript("gomap.js"),),
      
      # If not using custom CSS, set height of leafletOutput to a number instead of percent
      leafletOutput("map", width = "100%", height = "100%")
      ,
      
      # Shiny versions prior to 0.11 should use class = "modal" instead.
      absolutePanel(
        id = "controls",
        class = "panel panel-default",
        fixed = TRUE,
        draggable = TRUE,
        top = 60,
        left = "auto",
        right = 20,
        bottom = "auto",
        width = 330,
        height = "auto",
        
        h2("Traffic Breakdown"),
        selectInput("pallet", "Pallet", pallet_vars, selected = "YlOrRd"),
        selectInput("color", "Color", vars),
        selectInput("size", "Size", vars, selected = "count"),
        # conditionalPanel("input.color == 'count' || input.size == 'count'",
        #   # Only prompt for threshold when coloring or sizing by superzip
        #   numericInput("threshold", "Volume threshold (> n % of total)", 2)
        # ),
        
        girafeOutput("area_VolumeByTime", height = 200),
        plotOutput("scatterCollegeIncome", height = 250)
      ),
      
      tags$div(
        id = "cite",
        'Data compiled for ',
        tags$em('Artificially-Intelligent'),
        ' by Stuart Thomas.'
      )
    )
  ),
  
  tabPanel(
    "Data explorer",
    fluidRow(column(
      3,
      selectInput("suburb", "Suburbs", c(
        "All Suburbs" = "", unique(traffic_locations$locality)
      ), multiple = TRUE)
    )
    ,
    column(
      3,
      conditionalPanel(
        "input.location_description",
        selectInput(
          "location_description",
          "Measurement Location",
          c("All locations" = "", (traffic_locations$location_description)),
          multiple = TRUE
        )
      )
    ),
    # column(3,
    #   conditionalPanel("input.states",
    #     selectInput("zipcodes", "Zipcodes", c("All zipcodes"=""), multiple=TRUE)
    #   )
    # )),
    # fluidRow(
    #   column(1,
    #     numericInput("minScore", "Min score", min=0, max=100, value=0)
    #   ),
    #   column(1,
    #     numericInput("maxScore", "Max score", min=0, max=100, value=100)
    #   )
    # ),
    hr(),
    DT::dataTableOutput("locationTable")
    ),
    
    conditionalPanel("false", icon("crosshair"))
  )
)