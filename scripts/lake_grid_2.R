library(tidyverse)
library(oregonfrogs)

# make a grid
frogs_coord <- tibble(oregonfrogs$UTME_83, oregonfrogs$UTMN_83,
                      oregonfrogs$Frequency)

points <- sf::st_as_sf(x = frogs_coord, 
                       coords = c(1,2), 
                       crs = "+proj=utm +zone=10") %>%
  sf::st_transform(frogs_coord, 
                   crs = "+proj=longlat +datum=WGS84")  

library(sf)
grid = st_make_grid(
  st_as_sfc(st_bbox(points)),
  what = "centers",
  cellsize = .002, 
  square = F)


ggplot()+
  geom_sf(data=grid,size=0.3)+
  geom_sf(data=points)+
  coord_sf()+
  ggthemes::theme_map()