

build_plot_monthly_volume_by_hour <- function(plot_data, pallet = graphColorPallet){
  
  if (nrow(plot_data) == 0)
    return(NULL)
 
  gg <- plot_data %>%
  group_by(month,hour_group) %>%
  summarise(count = sum(count),
            day_count = sum(day_count),
            avg_daily_count = count / day_count ) %>%
    ggplot(
    aes(
      x = month,
      y = avg_daily_count,
      group = hour_group,
      
      # colour = hour_group,
      fill = hour_group,
      tooltip = hour_group,
      data_id = hour_group,
      hover_css = "fill:none;",
    )
  ) +
  labs(
    title = "Daily Average Traffic Volume",
    subtitle = waiver(),
    caption = waiver(),
    tag = waiver(),
    fill = "Hour"
  ) +
  ylab("Traffic Volume") +
  xlab("Month") +
  geom_area(alpha=0.6 ) +
  scale_fill_viridis(discrete = T) +
  scale_y_continuous( labels = comma) +
  theme_ipsum() +
  theme(
    plot.title = element_text(hjust = 0.5),
      axis.title.x = element_text( hjust = 0.5, size=18),
      axis.title.y = element_text( hjust = 0.5, size=18),
      axis.text.x = element_text(angle = 60, hjust = 1, size = 12),
      axis.text.y = element_text(hjust = 1, size = 12)
      # axis.title=element_text(size=24,face="bold")
    )
  
  return(gg)
  # x <- girafe(ggobj = gg, width = 8)
  # x <- girafe_options(x = x
  #                     # ,
  #                     # opts_hover(css = "fill:orange")
  #                     )
  # if (interactive())
  #   print(x)
}

build_plot_volume_change_by_date <- function(plot_data, pallet = graphColorPallet){
  
  if (nrow(plot_data) == 0)
    return(NULL)
  
  date_column <- case_when('week_start_date' %in% colnames(plot_data) ~  'week_start_date',
                           TRUE ~ 'month')
  if(date_column == "week_start_date"){
    plot_data$date <- plot_data$week_start_date
  }
  if(date_column == "month"){
    plot_data$date <- plot_data$month
  }
  
  p_data <- plot_data  %>%
    group_by(date) %>%
    summarise(count = as.numeric(sum(count)),
              avg_speed = sum(sum_speed)/count,
              day_count = sum(day_count),
              avg_daily_count = count / day_count ) %>%
    mutate(
      delta_count = count - lag(count),
      delta_speed = avg_speed - lag(avg_speed),
      # tooltip = paste( as.character(date),tags$br(),"Count:",count, tags$br(),"Change:", 100 * round(delta_count/count,2), "%" ),
      colour = case_when(delta_count >= 0 ~ 'increase',
                         delta_count < 0 ~ 'decrease'),
      tooltip = paste( "Change:", 100 * round(delta_count/count,2), "%" )
    )  %>%
    filter( !is.na(colour) &  !is.na(date) & (as.Date(date) >= as.Date('2019-01-01')))
  

  
 gg <-  ggplot( data = p_data[2:nrow(p_data),],
    aes(
      x = date,
      y = delta_count,
      tooltip = tooltip,
      # data_id = date
      # ,
      # hover_css = "fill:none;"
    )
  ) +
    geom_segment(aes(
      x = date,
      xend = date,
      y = 0,
      yend = delta_count
    ),
    color = "grey") +
    geom_point(aes(color = colour), size = 2) +
    # geom_smooth(method = "lm") + 
    theme_light() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.border = element_blank(),
      axis.ticks.x = element_blank()
    ) +
    xlab(make_clean_names( date_column , case = "title")) +
    ylab("Change in Traffic Volume") +
    scale_fill_viridis(discrete = T) +
    scale_y_continuous(labels = comma) +
    theme(
      legend.position = "none",
      plot.title = element_text(hjust = 0.5),
      axis.title.x = element_text(hjust = 0.5, size = 9),
      axis.title.y = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(
        angle = 60,
        hjust = 1,
        size = 7
      ),
      axis.text.y = element_text(hjust = 1, size = 7)
      # axis.title=element_text(size=24,face="bold")
    )
  
 return(gg)
  # x <- girafe(ggobj = gg, width = 8, height = 6 )
  # x <- girafe_options(x = x)
  # if (interactive())
  #   print(x)
}


build_plot_speed_histogram <- function(plot_data, pallet = graphColorPallet){
  
  if (nrow(plot_data) == 0)
    return(NULL)
  
  p_data <- plot_data   %>%
    mutate(speed_group = case_when(speed_group == '40-45' ~ '40+',
                                   speed_group == '45-50' ~ '40+',
                                   speed_group == '50-55' ~ '40+',
                                   speed_group == '55-60' ~ '40+',
                                   speed_group == '60+' ~ '40+',
                                   TRUE ~ speed_group
                                   
                                   )) %>%
    filter( !is.na(speed_group) ) %>%
    group_by(speed_group) %>%
    summarise(count = as.numeric(sum(count))) 
  # %>%
  #   mutate(
  #     tooltip = paste( speed_group , "KM/H",tags$br(),"Count:",count )
  #   ) 
  
  
  
   gg <- ggplot( data = p_data,
                 aes(
                   x = speed_group,
                   y = count,
                   # group = speed_group,
                   fill = speed_group,
                   # tooltip = tooltip,
                   # data_id = speed_group
                   # ,
                   # hover_css = "fill:none;"
                 )
  ) +
    geom_bar(stat = "identity") +
    theme_light() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.border = element_blank(),
      axis.ticks.x = element_blank()
    ) +
    xlab("Speed KM/H") +
    ylab("Traffic Volume") +
    scale_fill_viridis(discrete = T) +
    scale_y_continuous(labels = comma) +
    theme(
      legend.position = "none",
      plot.title = element_text(hjust = 0.5),
      axis.title.x = element_text(hjust = 0.5, size = 9),
      axis.title.y = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(
        angle = 60,
        hjust = 1,
        size = 7
      ),
      axis.text.y = element_text(hjust = 1, size = 7)
      # axis.title=element_text(size=24,face="bold")
    )
  return(gg)
  # x <- girafe(ggobj = gg, width = 8, height = 3 )
  # x <- girafe_options(x = x)
  # if (interactive())
  #   print(x)
}

build_plot_weekly_speed_by_hour <- function(plot_data){
  
  conn <- poolCheckout(db_pool)
  
  plot_data <- get_traffic(
    group_by = c("location"), conn = conn
  ) %>%
    data.frame()
  poolReturn(conn)
  
  # plot_data <- traffic_by_location_weekly %>%
  #   group_by(date,hour_group) %>%
  #   summarise(count = sum(count),
  #             day_count = sum(day_count),
  #             avg_speed = mean(avg_speed),
  #             avg_daily_count = count / day_count )
  #
  
  if (nrow(plot_data) == 0)
    return(NULL)
  
  gg <- plot_data2  %>%
    ggplot(
      aes(
        x = location,
        y = avg_speed,
        # group = location,
        # colour = location,
        # # fill = location,
        tooltip = location,
        data_id = location,
        hover_css = "size:4;",
      )
    ) +
    labs(
      title = "Average Speed by Date",
      subtitle = waiver(),
      caption = waiver(),
      tag = waiver(),
      colour = "Hour"
    ) +
    ylab("KM/H") +
    xlab("Date") +
    geom_line(size=1) +
    scale_fill_viridis(discrete = T) +
    scale_y_continuous( labels = comma) +
    # theme_ipsum()
    theme_minimal() +  
    theme_ipsum() +
    theme(
      legend.position = "none",
    # #   plot.title = element_text(hjust = 0.5),
    # #   # axis.title.x = element_text( hjust = 0.5, size=18),
    # #   axis.title.y = element_text( hjust = 0.5, size=18),
      axis.text.x = element_text(angle = 60, hjust = 1, size = 8)
    #   # ,
    # #   axis.text.y = element_text(hjust = 1, size = 12)
    #   # axis.title=element_text(size=24,face="bold")
    )

  return(gg)
  # x <- girafe(ggobj = gg, width = 8)
  # x <- girafe_options(x = x,
  #                     opts_hover(css = "colour:red"))
  # if (interactive())
  #   print(x)
}
