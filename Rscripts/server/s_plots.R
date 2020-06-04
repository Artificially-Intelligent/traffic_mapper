

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
  geom_area_interactive(alpha=0.6 ) +
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
  
  x <- girafe(ggobj = gg, width = 8)
  x <- girafe_options(x = x
                      # ,
                      # opts_hover(css = "fill:orange")
                      )
  if (interactive())
    print(x)
}

build_plot_weekly_volume_change <- function(plot_data, pallet = graphColorPallet){
  
  if (nrow(plot_data) == 0)
    return(NULL)
  
  p_data <- plot_data  %>%
    group_by(week_start_date) %>%
    summarise(count = sum(count),
              avg_speed = sum(total_speed)/count,
              day_count = sum(day_count),
              avg_daily_count = count / day_count ) %>%
    mutate(
      delta_count = count - lag(count),
      delta_speed = avg_speed - lag(avg_speed),
      tooltip = paste(week_start_date, tags$br(),"Count:",count, tags$br(),"Change:", 100 * round(delta_count/count,2), "%" ),
      colour = case_when(delta_count >= 0 ~ 'increase',
                         delta_count < 0 ~ 'decrease')
    )  %>%
    filter( !is.na(colour) )
  
  gg <- ggplot( data = p_data,
    aes(
      x = week_start_date,
      y = delta_count,
      tooltip = tooltip,
      data_id = tooltip
      # ,
      # hover_css = "fill:none;"
    )
  ) +
    geom_segment(aes(
      x = week_start_date,
      xend = week_start_date,
      y = 0,
      yend = delta_count
    ),
    color = "grey") +
    geom_point_interactive(aes(color = colour), size = 8) +
    # geom_smooth(method = "lm") + 
    theme_light() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.border = element_blank(),
      axis.ticks.x = element_blank()
    ) +
    xlab("Week Start Date") +
    ylab("Change in Traffic Volume") +
    scale_fill_viridis(discrete = T) +
    scale_y_continuous(labels = comma) +
    theme(
      plot.title = element_text(hjust = 0.5),
      axis.title.x = element_text(hjust = 0.5, size = 18),
      axis.title.y = element_text(hjust = 0.5, size = 18),
      axis.text.x = element_text(
        angle = 60,
        hjust = 1,
        size = 16
      ),
      axis.text.y = element_text(hjust = 1, size = 16)
      # axis.title=element_text(size=24,face="bold")
    )
  
  x <- girafe(ggobj = gg, width = 8)
  x <- girafe_options(x = x)
  if (interactive())
    print(x)
}


build_plot_weekly_speed_by_hour <- function(plot_data){
  
  conn <- poolCheckout(db_pool)
  
  plot_data <- get_traffic(
    group_by = c("location"), conn = conn
  ) %>%
    data.frame()
  poolReturn(conn)
  
  # plot_data <- traffic_by_location_weekly %>%
  #   group_by(week_start_date,hour_group) %>%
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
    geom_line_interactive(size=1) +
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
      axis.text.x = element_text(angle = 60, hjust = 1, size = 12)
    #   # ,
    # #   axis.text.y = element_text(hjust = 1, size = 12)
    #   # axis.title=element_text(size=24,face="bold")
    )

  
  x <- girafe(ggobj = gg, width = 8)
  x <- girafe_options(x = x,
                      opts_hover(css = "colour:red"))
  if (interactive())
    print(x)
}
