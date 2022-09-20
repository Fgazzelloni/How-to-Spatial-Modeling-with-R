library(tidyverse)
library(oregonfrogs) 

View(rgdal::make_EPSG())


frogs_coord <- oregonfrogs %>%
  select(UTME_83, UTMN_83)

# Tranform it to lat and long
frogs_coord <- 
  frogs_coord %>% 
  # transform to simple features as geometry
  sf::st_as_sf(coords = c(1,2), 
               crs = "+proj=utm +zone=10") %>%
  # utm tranformation to longlat
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")  %>%
  tibble()

map <- openmap(c(43.764375,-121.824775),c(43.814821,-121.764923))
wider_map <- openproj(map)

base_map <- OpenStreetMap::autoplot.OpenStreetMap(wider_map) + 
  geom_point(data = frogs_location,
             aes(x = long, y = lat), 
             shape=21,stroke=0.2, size =  4,
             color="grey40") +
  xlab("Longitude (°E)") + ylab("Latitude (°S)")

base_map


library(purrr)
frogs_location_tm <- tibble(ReportedDay = oregonfrogs$Ordinal,
                            geometry=frogs_coord$geometry) %>%
  mutate(time = as.Date("2018-01-01") + ReportedDay,
         month=lubridate::month(time))


base_map+
  geom_sf(data = frogs_location_tm,
          aes(col = factor(month), geometry=geometry),
          inherit.aes = F) +
  facet_wrap(~cut(time, "1 months")) + 
  theme_void()




