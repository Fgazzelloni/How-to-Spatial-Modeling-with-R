How-to-Spatial-Modeling-with-R


This is meant for people new to spatial analysis and modeling with RStudio but comfortable in making simple data visualization with ggplot2.


The workshop will take place Wednesday 21 of September 2022 at 6pm EDT (10pm UTC).

To follow along you would need to install these packages:
```{r}
my_packages <- c("tidyverse","purrr","ggthemes",
                 "maptools","OpenStreetMap",
                 "spdep","sf","spocc",
                 "dismo","SpatialEpi")

install.packages(my_packages, repos = "http://cran.rstudio.com")

install.packages("remotes")
remotes::install_github("fgazzelloni/oregonfrogs")
```

install.packages("remotes")
remotes::install_github("fgazzelloni/oregonfrogs")
```


