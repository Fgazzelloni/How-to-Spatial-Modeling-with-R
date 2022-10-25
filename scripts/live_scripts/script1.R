library(tidyverse)
library(oregonfrogs)
# library(OpenStreetMap)
library(ggmap)

library(spocc)
?spocc



do_gbif <- occ("Rana pretiosa Baird & Girard, 1853",
               from = "gbif",
               limit = 1000,
               has_coords = TRUE
)



do_gbif1 <- data.frame(do_gbif$gbif$data)
do_gbif1%>%names

do_gbif2 <- do_gbif1%>%
  rename(longitude=Rana_pretiosa_Baird_._Girard._1853.longitude,
         latitude=Rana_pretiosa_Baird_._Girard._1853.latitude)



states<- map_data("state")
oregon <- states %>% filter(region=="oregon")

ggplot(data = states, mapping = aes(long,lat,group=group))+
  geom_polygon(color="grey",fill=NA) +
  geom_polygon(data = oregon, 
               inherit.aes = TRUE, 
               color="pink",fill="pink") +
  geom_point(data = do_gbif2,
             mapping = aes(x=longitude, y=latitude),
             inherit.aes = FALSE, 
             alpha=0.5,size=0.5)+
  coord_quickmap() +
  theme_bw()



View(rgdal::make_EPSG())


frogs_coord <- oregonfrogs %>%
  select(UTME_83, UTMN_83)


frogs_coord <-
  frogs_coord %>%
  # transform to simple features as geometry
  sf::st_as_sf(coords = c(1,2),
               crs = "+proj=utm +zone=10") %>%
  # utm tranformation to longlat
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")  %>%
  tibble()

frogs_location <- tibble(Detection = oregonfrogs$Detection,
                         Subsite = oregonfrogs$Subsite,
                         Frequency = oregonfrogs$Frequency,
                         lat = unlist(map(frogs_coord$geometry, 2)),
                         long = unlist(map(frogs_coord$geometry, 1)))

frogs_location%>%head(3)


library(ggmap)

box=c(43.764375,-121.824775,43.814821,-121.764923)
crane_reservoir <- get_stamenmap(bbox = c(left = -121.824775,
                                          bottom = 43.764375,
                                          right = -121.764923,
                                          top = 43.814821),
                                 zoom = 13, color = c("color"),
                                 maptype = "terrain-background")
base_map <- ggmap(crane_reservoir) +
  geom_point(data = frogs_location,
             aes(x = long, y = lat),
             shape=21,stroke=0.2, size =  4,
             color="grey40") +
  xlab("Longitude (°E)") + ylab("Latitude (°S)")

base_map


frogs_location_tm <- tibble(ReportedDay = oregonfrogs$Ordinal,
                            geometry=frogs_coord$geometry) %>%
  mutate(time = as.Date("2018-01-01") + ReportedDay,
         month=lubridate::month(time))


base_map+
  geom_sf(data = frogs_location_tm,
          aes(col = factor(month), geometry=geometry),
          inherit.aes = F) +
  scale_color_discrete(labels=c("September","October","November"))+
  guides(color=guide_legend(title="Month"))+
  facet_wrap(~cut(time, "1 months")) +
  theme_void()


frogs_coord <- tibble(oregonfrogs$UTME_83, 
                      oregonfrogs$UTMN_83,
                      oregonfrogs$Frequency)


crs=4326

points <- sf::st_as_sf(x = frogs_coord,
                       coords = c(1,2),
                       crs = "+proj=utm +zone=10") %>%
  sf::st_transform(frogs_coord,
                   crs = "+proj=longlat +datum=WGS84")


library(sf)
grid = st_make_grid(st_as_sfc(st_bbox(points)),
  what = "centers",
  cellsize = .002,
  square = F)


ggplot()+
  geom_sf(data=grid,size=0.3)+
  geom_sf(data=points)+
  coord_sf()+
  ggthemes::theme_map()





























































