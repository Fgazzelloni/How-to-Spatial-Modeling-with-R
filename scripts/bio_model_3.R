# source: https://www.youtube.com/watch?v=1C1zVJO-Rk0
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


wrld_simpl%>%filter()
plot(wrld_simpl,xlim=c(-125,-100),ylim=c(35,55),axes=T)
points(do_gbif$Rana_pretiosa_Baird_._Girard._1853.longitude,
       do_gbif$Rana_pretiosa_Baird_._Girard._1853.latitude)

frogs <-data.frame(long=do_gbif$Rana_pretiosa_Baird_._Girard._1853.longitude,
           lat=do_gbif$Rana_pretiosa_Baird_._Girard._1853.latitude)
climate <- getData("worldclim",download = T,var="bio",res=2.5)
saveRDS(climate,"climate.rds")
plot(climate)

df <- extract(climate,frogs)
df%>%as.data.frame()%>%
  DataExplorer::profile_missing()
saveRDS(df,"df.rds")

library(dismo)
bioclim.mod <- dismo::bioclim(df)
pairs(bioclim.mod,pa="p")

library(tidyverse)
doParallel::registerDoParallel()
predictors <- stack(climate$bio1,climate$bio2,climate$bio3,
                    climate$bio4,climate$bio5,
                    climate$bio6,climate$bio7,climate$bio8,
                    climate$bio9,climate$bio10,climate$bio11,
                    climate$bio12,climate$bio13,climate$bio14,
                    climate$bio15,climate$bio16,climate$bio17,
                    climate$bio18,climate$bio19)
predictions <- predict(predictors,bioclim.mod)
saveRDS(predictions,"predictions.rds")

plot(predictions,xlim=c(-125,-100),ylim=c(35,55),axes=T)
