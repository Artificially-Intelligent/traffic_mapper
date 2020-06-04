library(leaflet)

# Choices for drop-downs
vars <- c(
  "Measurement Location" = "location",
  "Traffic Volume" = "count",
  "Speed" = "avg_speed"
)

pallet_vars <- rownames(brewer.pal.info)

# pallet_vars <- rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
if (use_mongo) {
  mgo_traffic_locations <-
    mongo(db = "primary",
          collection = "traffic_by_location",
          url = azure$mongo_url)
  traffic_locations <- mgo_traffic_locations$find()
} else{
  conn <- poolCheckout(db_pool)
  traffic_locations <- get_locations(conn = conn)
  poolReturn(conn)
}

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
        
        h3("Traffic Summary"),
        column(6,selectInput("color", "Color", vars)),
        column(6,selectInput("size", "Size", vars, selected = "count")),
        # checkboxInput("legend", "Show legend", TRUE),
        
        # conditionalPanel("input.color == 'count' || input.size == 'count'",
        #   # Only prompt for threshold when coloring or sizing by superzip
        #   numericInput("threshold", "Volume threshold (> n % of total)", 2)
        # ),
        
        
        valueBoxOutput(width = 6,"valueBox_speed"),
        valueBoxOutput(width = 6,"valueBox_volume"),
        plotlyOutput("lollipop_VolumeChangeByTime", height = 160),
        plotlyOutput("histogram_SpeedDistrubution", height = 160)
        
        
        # ,
        # girafeOutput("line_SpeedByTime", height = 200)
      ),
      
      tags$div(
        id = "cite",
        'Data compiled for ',
        tags$em('Artificially-Intelligent'),
        ' by Stuart Thomas.'
      )
    )
  ),
  
  # tabPanel(
  #   "Summary",
  #   fluidRow(
  #     column(
  #     3,
  #     selectInput("summary.suburb", "Suburbs", c(
  #       "All Suburbs" = "", unique(traffic_locations$locality)
  #     ), multiple = TRUE)
  #   )
  #   ,
  #   column(
  #     3,
  #     conditionalPanel(
  #       "input.summary.suburb",
  #       selectInput(
  #         "summary.location_description",
  #         "Measurement Location",
  #         c("All locations" = "", (traffic_locations$location_description)),
  #         multiple = TRUE
  #       )
  #     )
  #   ),
  #   # column(3,
  #   #   conditionalPanel("input.states",
  #   #     selectInput("zipcodes", "Zipcodes", c("All zipcodes"=""), multiple=TRUE)
  #   #   )
  #   # )
  #   
  #   ),
  #   
  #   hr(),
  #   fluidRow(
  #     column(width = 6,
  #            girafeOutput("summary.area_VolumeByTime")
  #            ),
  #     column(width =  6)
  #   ),
  #   fluidRow(
  #     column(width =  6),
  #     column(width =  6)
  #   ) 
  # ),
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
        "input.suburb",
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
  ),
  tabPanel("Settings",
           fluidRow(column(3,selectInput("map_pallet", "Map Colour Pallet", pallet_vars, selected = "YlOrRd") ))
           # ,
           # fluidRow(column(3,selectInput("graph_pallet", "Graph Colour Pallet", pallet_vars, selected = "YlOrRd") ))
  )
  
)