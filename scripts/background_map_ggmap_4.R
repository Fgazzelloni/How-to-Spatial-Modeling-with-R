library(ggmap)

box=c(43.764375,-121.824775,43.814821,-121.764923)
crane_reservoir <- get_stamenmap(bbox = c(left = -121.824775, 
                                          bottom = 43.764375, 
                                          right = -121.764923, 
                                          top = 43.814821),
                                 zoom = 13, color = c("color"),
                                 maptype = "terrain-background")

points <- data.frame(x = c(-121.80, -121.75, -121.82), # random points
                     y = c(43.8, 43.7, 43.78))

ggmap(crane_reservoir) + 
  geom_point(data = points, aes(x = x, y = y), 
             color = "red") 

