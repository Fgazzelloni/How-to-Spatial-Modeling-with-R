library(tidyverse)
library(rgeos)
library(raster)
library(rgdal)
library(dismo)


library(maptools)
world <- data("wrld_simpl")


library(spocc)
do_gbif <- occ("Rana pretiosa Baird & Girard, 1853",
               from = "gbif",
               limit = 1000,
               has_coords = TRUE
)
do_gbif <- data.frame(do_gbif$gbif$data)



plot(wrld_simpl,xlim=c(-125,-100),ylim=c(35,55),axes=T)
points(do_gbif$Rana_pretiosa_Baird_._Girard._1853.longitude,
       do_gbif$Rana_pretiosa_Baird_._Girard._1853.latitude)

frogs <-data.frame(long=do_gbif$Rana_pretiosa_Baird_._Girard._1853.longitude,
                   lat=do_gbif$Rana_pretiosa_Baird_._Girard._1853.latitude)


climate <- getData("worldclim",download = T,var="bio",res=2.5)














