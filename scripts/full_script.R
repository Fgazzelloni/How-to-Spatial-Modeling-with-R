
library(tidyverse)
library(oregonfrogs)
library(spocc)
library(dismo)
library(sf)
library(ggmap)
library(ggthemes)



# load("data/case_study_1.RData")
# spocc::occ()

do_gbif <- occ("Rana pretiosa Baird & Girard, 1853",
               from = "gbif",
               limit = 1000,
               has_coords = TRUE)
do_gbif

do_gbif1 <- data.frame(do_gbif$gbif$data)

do_gbif1%>%names


do_gbif2 <- do_gbif1%>%
  rename(longitude=Rana_pretiosa_Baird_._Girard._1853.longitude,
         latitude=Rana_pretiosa_Baird_._Girard._1853.latitude)


states<- map_data("state")
states%>%names

oregon <- states %>% filter(region=="oregon")

centroids<- oregon %>% 
   mutate(cent_long=terra::weighted.mean(long),
         cent_lat=terra::weighted.mean(lat),
         .after=long) %>%
  count(cent_long,cent_lat)
  

ggplot(data = states, 
       mapping = aes(x = long,y = lat, group=group))+
  geom_polygon(color="grey",fill=NA) +
  geom_polygon(data = oregon, 
               inherit.aes = TRUE, 
               color="pink",fill="pink",alpha=0.3) +
  geom_point(data = do_gbif2,
             mapping = aes(x=longitude, y=latitude),
             inherit.aes = FALSE, 
             alpha=0.5,size=0.5)+
   geom_text(data= centroids,
            mapping=aes(x=cent_long,y=cent_lat,label="Oregon"),
            inherit.aes = FALSE,hjust=1.3) + 
  coord_quickmap() +
  theme_bw()



# install.packages("remotes")
remotes::install_github("fgazzelloni/oregonfrogs")

library(oregonfrogs)  


oregonfrogs%>%head(3)


# Build a tibble with the geo-location information
frogs_coord <- oregonfrogs %>%
  dplyr::select(UTME_83, UTMN_83)


View(rgdal::make_EPSG()) # WGS84, (World Geodetic System 1984, known as EPSG:4326)

# Tranform it to lat and long
frogs_coord1 <- 
  frogs_coord %>% 
  # transform to simple features as geometry
  sf::st_as_sf(coords = c(1,2), 
               crs = "+proj=utm +zone=10") %>%
  # utm tranformation to longlat
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")  %>%
  tibble()

frogs_coord1%>%head(3)



library(purrr) # for the map() function
frogs_location <- tibble(Detection = oregonfrogs$Detection,
                         Subsite = oregonfrogs$Subsite,
                         Frequency = oregonfrogs$Frequency,
                         lat = unlist(map(frogs_coord1$geometry, 2)),
                         long = unlist(map(frogs_coord1$geometry, 1)))

frogs_location%>%head(3)



## Look at oregonfrogs data
ggplot(data = frogs_location, aes(x=long,y=lat))+
  geom_point() +
  geom_smooth(method = "loess") +
  theme_bw()



### Let's map the lake! 

# library(OpenStreetMap)
# map <- openmap(c(43.764375,-121.824775),c(43.814821,-121.764923))
# 
# OpenStreetMap::plot.OpenStreetMap(map)
# wider_map <- openproj(map)
# base_map <- OpenStreetMap::autoplot.OpenStreetMap(wider_map) + 
# geom_point(data = frogs_location,
# aes(x = long, y = lat), 
# shape=21,stroke=0.2, size =  4,
# color="grey40") +
# xlab("Longitude (°E)") + ylab("Latitude (°S)")


library(ggmap)

box=c(43.764375,-121.824775,43.814821,-121.764923)
crane_reservoir <- get_stamenmap(bbox = c(left = -121.824775, 
bottom = 43.764375, 
right = -121.764923, 
top = 43.814821),
zoom = 13, color = c("color"),
maptype = "terrain-background")

ggmap(crane_reservoir)

base_map <- ggmap(crane_reservoir) + 
geom_point(data = frogs_location,
aes(x = long, y = lat), 
shape=21,stroke=0.2, size =  4,
color="grey40") +
xlab("Longitude (°E)") + ylab("Latitude (°S)")

base_map



## Time as coordinate

frogs_location_tm <- tibble(ReportedDay = oregonfrogs$Ordinal,
                            geometry = frogs_coord1$geometry) %>%
mutate(time = as.Date("2018-01-01") + ReportedDay, 
       month=lubridate::month(time))


base_map+
geom_sf(data = frogs_location_tm,
        aes(color = factor(month), geometry = geometry),
        inherit.aes = F) +
scale_color_discrete(labels=c("September","October","November"))+
guides(color=guide_legend(title="Month"))+
facet_wrap(~cut(time, "1 months")) + 
theme_void()


## Make a grid

frogs_coord_freq <- tibble(oregonfrogs$UTME_83, 
                           oregonfrogs$UTMN_83,
                           oregonfrogs$Frequency)

points <- sf::st_as_sf(x = frogs_coord_freq, 
                       coords = c(1,2), 
                       crs = "+proj=utm +zone=10") %>%
  sf::st_transform(frogs_coord, 
                   crs = "+proj=longlat +datum=WGS84")  

grid = sf::st_make_grid(
  sf::st_as_sfc(sf::st_bbox(points)),
  what = "centers",
  cellsize = .002, 
  square = F)


ggplot()+
  geom_sf(data=grid,size=0.3)+
  geom_sf(data=points)+
  coord_sf()+
  ggthemes::theme_map()



# we can use the frequency of the frogs per day
oregonfrogs%>%
  mutate(SurveyDate=as.Date(SurveyDate,"%m/%d/%Y"))%>%
  arrange(SurveyDate)%>%
  count(SurveyDate,Ordinal)%>%
  head(3)



## Work with Models

library(dismo)  # for modeling

world <- map_data("world")
gbi_coords<- tibble(x=do_gbif2$longitude,
                    y=do_gbif2$latitude)

ggplot(world)+
  geom_polygon(aes(long,lat,group=group),fill="grey90",color="grey30") +
  geom_polygon(data=states, aes(long,lat,group=group),color="grey40") +
  geom_point(data = gbi_coords, aes(x,y),
             color="pink") +
  coord_sf(xlim=c(-125,-90),ylim=c(35,65))+
  ggthemes::theme_map()


frogs <-data.frame(long=do_gbif2$longitude,lat=do_gbif2$latitude)

# it takes long time
# climate <- getData("worldclim",download = T,var="bio",res=2.5)

# load climate directly from the .RData
climate

plot(climate,legend=FALSE)



frog_climate <- extract(climate,frogs)




frog_climate %>% head(3)



require(dismo)
bioclim.mod <- dismo::bioclim(frog_climate)




pairs(bioclim.mod,pa="pa")



doParallel::registerDoParallel()
predictors <- stack(climate$bio1,climate$bio2,climate$bio3,
                    climate$bio4,climate$bio5,
                    climate$bio6,climate$bio7,climate$bio8,
                    climate$bio9,climate$bio10,climate$bio11,
                    climate$bio12,climate$bio13,climate$bio14,
                    climate$bio15,climate$bio16,climate$bio17,
                    climate$bio18,climate$bio19)
predictions <- predict(predictors,bioclim.mod)


 ch2-18-1,eval=TRUE, include=FALSE}
predictions




plot(predictions,xlim=c(-125,-100),ylim=c(35,55),axes=T)




knitr::include_graphics("images/frogs_location_raster.png")





save.image("data/case_study_1.RData")


