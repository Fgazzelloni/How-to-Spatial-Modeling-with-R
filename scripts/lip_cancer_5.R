
library(tidyverse)
library(SpatialEpi)
data("scotland")
names(scotland)


ggplot(data=scotland$geo, aes(x=x,y=y,color=county.names))+
  geom_point(show.legend = F) +
  labs(title="Saptials of Scotland data")+
  ggthemes::theme_map()


map <- fortify(scotland$spatial.polygon)

ggplot(data=scotland$data,
       aes(map_id = county.names)) +
  geom_map(map = map,aes(fill=cases)) +
  expand_limits(x = map$long, y = map$lat) +
  labs(title="Scotland cases") +
  ggthemes::theme_map()+
  theme(legend.position = "bottom")


ggplot(data=scotland$data,
       aes(map_id = county.names)) +
  geom_map(map = map,aes(fill=expected)) +
  expand_limits(x = map$long, y = map$lat) +
  labs(title="Scotland expected") +
  ggthemes::theme_map()+
  theme(legend.position = "bottom")



map <- fortify(scotland$spatial.polygon)

case_map <- ggplot(data=scotland$data,
                   aes(map_id = county.names)) +
  geom_map(map = map,aes(fill=cases)) +
  expand_limits(x = map$long, y = map$lat) +
  labs(title="Scotland cases") +
  ggthemes::theme_map()+
  theme(legend.position = "bottom") 

expected_map <- ggplot(data=scotland$data,
                       aes(map_id = county.names)) +
  geom_map(map = map,aes(fill=expected)) +
  expand_limits(x = map$long, y = map$lat) +
  labs(title="Scotland expected") +
  ggthemes::theme_map() +
  theme(legend.position = "bottom")


library(patchwork)

case_map + expected_map +
  plot_annotation(
    title = "Lip Cancer Spatial model -cases vs expected - Scotland",
    caption = "Source: Scotland dataset in SpatialEpi_data"
  )


#model

scotland_data <- scotland$data
model_data<- scotland_data %>%
  left_join(map, by=c("county.names"="id"))

fit <- lm(formula=cases~long+lat ,data=model_data)
# summary(fit)


pred <- predict(fit)

model_data_pred<-cbind(model_data,predict=predict(fit))%>%
  select(county.names,cases,expected,predict,lat,long)


# model with tidymodels

library(tidymodels)
tidymodels_prefer()

lm_mod<- linear_reg()%>%
  set_engine(engine = "lm")%>%
  set_mode(mode="regression")


lm_mod_pred<-lm_mod%>%
  fit.model_spec(formula=cases~long+lat,data=model_data)%>%
  predict(new_data=NULL)


model_data_pred2<-cbind(model_data,lm_mod_pred)
model_data_pred2 <- model_data_pred2%>%
  select(county.names,cases,expected,.pred,lat,long)

ggplot(data=model_data_pred,aes(map_id = county.names))+
  geom_map(map = map,aes(fill=cases))+
  expand_limits(x = map$long, y = map$lat)+
  ggthemes::theme_map()+
  theme(legend.position = "bottom")

ggplot(data=model_data_pred,aes(map_id = county.names))+
  geom_map(map = map,aes(fill=predict))+
  expand_limits(x = map$long, y = map$lat)+
  ggthemes::theme_map()+
  theme(legend.position = "bottom")


cases_plot2<- ggplot(data=model_data_pred,aes(map_id = county.names))+
  geom_map(map = map,aes(fill=cases))+
  expand_limits(x = map$long, y = map$lat)+
  ggthemes::theme_map()+
  theme(legend.position = "bottom")

pred_plot2<- ggplot(data=model_data_pred,aes(map_id = county.names))+
  geom_map(map = map,aes(fill=predict))+
  expand_limits(x = map$long, y = map$lat)+
  ggthemes::theme_map()+
  theme(legend.position = "bottom")


library(patchwork)
cases_plot2 + pred_plot2 + plot_annotation(
  title = "Pattern of Lip Cancer in Scotland - cases vs predicted",
  caption = "Source: Scotland dataset in SpatialEpi_data"
)


