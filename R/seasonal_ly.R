#'  Seasonality Visualization of Time Series Object
#' @export
#' @param ts.obj a univariate time series object of a class "ts", "zoo" or "xts" (support only series with either monthly or quarterly frequency)
#' @param type The type of the seasonal plot - 
#' "normal" to split the series by full cycle units, or
#' "cycle" to split by cycle units, or
#' "box" for box-plot by cycle units, or
#' "polar"  for polar plot
#' @param Ygrid logic,show the Y axis grid if set to TRUE
#' @param Xgrid logic,show the X axis grid if set to TRUE
#' @description Visualize time series object by it periodicity, currently support only monthly and quarterly frequency
#' @examples
#' # Seasonal box plot
#' seasonal_ly(AirPassengers, type = "box") 
#' # Seasonal polar plot
#' seasonal_ly(AirPassengers, type = "polar") 

seasonal_ly <- function(ts.obj, type = "normal", Ygrid = FALSE, Xgrid = FALSE) {
  
  `%>%` <- magrittr::`%>%`
  df <- df_wide <- p <- obj.name <- NULL
  
  obj.name <- base::deparse(base::substitute(ts.obj))
  # Error handling
  if(type != "normal" & type != "cycle" & 
     type != "box" & type != "polar"){
    type <- "normal"
    warning("The 'type' parameter is invalide,", 
            "using the default option - 'normal'")
  }
  
  if (stats::is.ts(ts.obj)) {
    if (stats::is.mts(ts.obj)) {
      warning("The 'ts.obj' has multiple columns, only the first column will be plot")
      ts.obj <- ts.obj[, 1]
    }
    df <- base::data.frame(dec_left = floor(stats::time(ts.obj)), 
                     dec_right = stats::cycle(ts.obj), value = base::as.numeric(ts.obj))
    if(stats::frequency(ts.obj) == 12){
      df$dec_right <- base::factor(df$dec_right,
                             levels = base::unique(df$dec_right),
                             labels = base::month.abb[as.numeric(base::unique(df$dec_right))])
    } else if(stats::frequency(ts.obj) == 4){
      df$dec_right <- base::paste("Qr.", df$dec_right, sep = " ")
    } else {
      stop("The frequency of the series is invalid, ",
           "the function support only 'monthly' or 'quarterly' frequencies")
    }
  } else if (xts::is.xts(ts.obj) | zoo::is.zoo(ts.obj)) {
    if (!is.null(base::dim(ts.obj))) {
      if (base::dim(ts.obj)[2] > 1) {
        warning("The 'ts.obj' has multiple columns, only the first column will be plot")
        ts.obj <- ts.obj[, 1]
      }
    }
    freq <- xts::periodicity(ts.obj)[[6]]
    if (freq == "quarterly") {
      df <- base::data.frame(dec_left = lubridate::year(ts.obj), 
                       dec_right = lubridate::quarter(ts.obj), 
                       value = as.numeric(ts.obj))
    } else if (freq == "monthly") {
      df <- base::data.frame(dec_left = lubridate::year(ts.obj), 
                       dec_right = lubridate::month(ts.obj), value = as.numeric(ts.obj))
      df$dec_right <- base::factor(df$dec_right,
                                   levels = base::unique(df$dec_right),
                                   labels = base::month.abb[as.numeric(base::unique(df$dec_right))])
    # } else if (freq == "weekly") {
    #   df <- data.frame(dec_left = lubridate::year(ts.obj), 
    #                    dec_right = lubridate::week(ts.obj), value = as.numeric(ts.obj))
    # } else if (freq == "daily") {
    #   df <- data.frame(dec_left = lubridate::month(ts.obj), 
    #                    dec_right = lubridate::day(ts.obj), value = as.numeric(ts.obj))
    } else if (freq != "quarterly" & freq != "monthly") {
      stop("The frequency of the series is invalid,",
           "the function support only 'monthly' or 'quarterly' frequencies")
    }
    
  }
seasonal_sub <- function(df, type, Xgrid, Ygrid){  
  p <- NULL
  if(type == "normal"){
    df_wide <- reshape2::dcast(df, dec_right ~ dec_left)
  } else if(type == "cycle" | type == "box"){
    df_wide <- reshape2::dcast(df, dec_left ~ dec_right)
  }
  
  p <- plotly::plot_ly()
  if(type == "box"){
    for (f in 2:ncol(df_wide)) {
    p <- p %>% plotly::add_trace(y = df_wide[, f], 
                                 type = "box", 
                                 name = colnames(df_wide)[f],
                                 boxpoints = "all", jitter = 0.3,
                                 pointpos = -1.8
                                 )
      }
  } else if(type == "polar"){
    p <- plotly::plot_ly(r = df$value, t = df$dec_right) %>% 
      plotly::add_area(color = factor(df$dec_left, ordered = TRUE)) %>%
      plotly::layout(orientation = -90, 
                     autosize = T, 
                     # width = 600, 
                     # height = 600, 
                     margin = list(
                       l = 50,
                       r = 50,
                       b = 100,
                       t = 100,
                       pad = 4
                     ))
  } else{
  for (f in 2:ncol(df_wide)) {
    p <- p %>% plotly::add_trace(x = df_wide[, 1], y = df_wide[, f], 
                                 name = names(df_wide)[f], 
                                 mode = "lines", 
                                 type = "scatter")
  }
  }
  p <- p %>% plotly::layout(title = paste("Seasonality Plot -", obj.name, 
                                          sep = " "), 
                            xaxis = list(title = "", autotick = F, 
                                         showgrid = Xgrid, 
                                         dtick = 1), 
                            yaxis = list(title = obj.name, showgrid = Ygrid))
  return(p)
}

p <- seasonal_sub(df = df, type = type, Xgrid = Xgrid, Ygrid = Ygrid)

  return(p)
}
