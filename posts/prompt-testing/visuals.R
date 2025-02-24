library(tidyverse)
library(tidyr)
library(knitr)
results <- read_csv("C:\\Users\\gioc4\\Documents\\blog\\gcirco_blog\\posts\\prompt-testing\\results.csv")

res <- with(results, aov(f1score ~ as.factor(model_ver) + as.factor(feature)))

broom::tidy(res) %>% kable()

results %>%
  group_by(model_ver) %>%
  summarise(mean(f1score), mean(acc))

tbl_change <- results %>%
  group_by(feature) %>%
  summarise(var = var(f1score))



results %>%
  left_join(tbl_change) %>%
  mutate(`Model Version` = as.factor(model_ver),
         feature = fct_reorder(feature, var)) %>%
  ggplot() +
  geom_point(aes(
    x = feature,
    y = f1score,
    shape = `Model Version`,
    color = `Model Version`
  ),
  size = 2.5) +
  labs(y = "Weighted F1 Score") +
  scale_color_manual(values = c('#EE7733', '#0077BB', '#33BBEE', '#EE3377')) +
  coord_flip() +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        axis.title.y = element_blank(),
        axis.text = element_text(size = 10, color = 'black'))

