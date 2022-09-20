library(tidyverse)
library(oregonfrogs)
library(tidymodels)
library(spatialsample)
tidymodels_prefer()

coords <- oregonfrogs %>%
  sf::st_as_sf(coords = c(7,8), 
               crs = "+proj=utm +zone=10") %>%
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")  %>%
  sf::st_coordinates() %>%
  as.data.frame() 
  
names(coords)<- c("x","y")

frogs1 <- coords %>%
cbind(oregonfrogs) %>%
  janitor::clean_names() %>%
  mutate(survey_date=as.Date(survey_date,"%m/%d/%Y"),
         female=as.factor(female))%>%
  arrange(ordinal) %>%
  select(-site) 

frogs1%>%DataExplorer::profile_missing()

set.seed(123)
split <- initial_split(frogs1, strata = detection, prop = 0.9)
training <- training(split)
test <- testing(split)

cv_folds <- spatialsample::spatial_clustering_cv(training,coords = c("x", "y"), v = 10)


plot_splits <- function(split) {
  p <- bind_rows(
    analysis(split) %>%
      mutate(analysis = "Analysis"),
    assessment(split) %>%
      mutate(analysis = "Assessment")
  ) %>%
    ggplot(aes(x, y, color = analysis)) +
    geom_point(size = 1.5, alpha = 0.8) +
    coord_fixed() +
    labs(color = NULL)
  print(p)
}


walk(cv_folds$splits, plot_splits)


library(themis)
recipe_interact <- recipe(detection ~ . ,training) %>% 
  step_downsample(detection) %>%
  step_date(survey_date,keep_original_cols = FALSE) %>% 
  #step_corr(all_numeric(),threshold = 0.8) %>%
  step_dummy(all_nominal(), -all_outcomes()) %>%
  step_zv(all_numeric()) %>%
  step_normalize(all_numeric()) %>%
  step_interact( ~ frequency : starts_with("hab_type_")) 


rand_forest_ranger_spec1000 <-
  rand_forest(trees = 1000) %>%
  set_engine('ranger') %>%
  set_mode('classification')

doParallel::registerDoParallel()

conflicted::conflict_prefer("spec", "yardstick")
metrics = yardstick::metric_set(accuracy, roc_auc, sens, spec)

rf_workflow <- workflow() %>%
  add_recipe(recipe_interact) %>%
  add_model(rand_forest_ranger_spec1000)  

rf_fit1000 <- rf_workflow %>%
  fit_resamples(resamples = cv_folds,
                metrics = metrics,
                control = control_resamples(save_pred = TRUE,
                                            parallel_over = "everything",
                                            save_workflow = TRUE)) 


rf_fit1000 %>%
  unnest(.predictions)%>%
  select(id,`.pred_class`:detection)%>%
  cbind(test)




roc <- rf_fit1000 %>%
  unnest(.predictions) %>% #count(id,id2)
  select(wflow_id=id,.pred_Captured,`.pred_No visual`,.pred_Visual,.pred_class,detection) %>%
  group_by(wflow_id) %>%
  yardstick::roc_curve(detection, .pred_Captured:.pred_Visual) %>%
  ungroup()

roc %>%
  #filter(wflow_id=="Repeat1") %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity, group=.level,color=.level)) +
  geom_line(size = 0.3) + # ,aes(color=wflow_id),show.legend = F) 
  geom_abline(lty = 2, alpha = 0.5,
              color = "gray50",
              size = 0.8) +
  ggthemes::scale_color_fivethirtyeight() +
  labs(x="1-Specificity",y="Sensitivity",
       color="Detection",
       title="ROC curves: Detection levels for each fold") +
  ggthemes::theme_fivethirtyeight()+
  theme(text=element_text(family="Roboto Condensed"),
        axis.title = element_text(),
        plot.background = element_rect(color="white",fill="white"),
        panel.background = element_rect(color="white",fill="white"),
        legend.background = element_rect(color="grey95",fill="grey95"),
        legend.box.background = element_blank())+
  facet_wrap(~wflow_id)


#############################################
glm_spec <- rand_forest()%>%
  set
  set_mode("regression")
lsl_form <- frequency ~ .

lsl_wf <- workflow(lsl_form, glm_spec)

doParallel::registerDoParallel()
set.seed(2021)
regular_rs <- fit_resamples(lsl_wf, cv_folds)


