library(tidyverse)
library(pROC)
library(glmnet)
library(randomForest)
library(smotefamily)

set.seed(978545)

# load data
# impute single missing value with median of education (8)
df <-
  haven::read_sav("C:/Users/gioc4/Documents/blog/data/savry.sav") %>%
  select(Reoffending, age, education, familyincome, contains("SAVRY"), P1:P6) %>%
  replace_na(list(education = 8)) %>%
  mutate(across(familyincome:P6, as.factor))

# indices of train-test
test_size <- round(nrow(df)*(1-.8))
test_idx <- sample(1:nrow(df), test_size)
train_idx <- setdiff(1:nrow(df), test_idx)

# set up data values
# test and train

y <- df$Reoffending
X <- model.matrix(~ . - 1, data = df[-1])

#
y_test = y[test_idx]
X_test = X[test_idx,]
y_train = y[train_idx]
X_train = X[train_idx,]


# fit multiple linear models

# logit, no regularization & random forest
fit_1_glm <- glmnet(X_train,y_train, family = "binomial", alpha = 0, lambda = 0)
fit_1_rf <- randomForest(X_train ,as.factor(y_train))

pred_df <- data.frame(
  predict(fit_1_glm, X_test , type = 'response'),
  predict(fit_1_rf, X_test , "prob")[,2]
) %>%
  set_names(c("glm","lasso","randomforest"))

# get auc
roc(y_test, pred_df$glm)
roc(y_test, pred_df$lasso)
roc(as.factor(y_test), pred_df$randomforest)

# OK, so what if we use SMOTE?
smote_df <- data.frame(X_train,y_train)
smote_model <- SMOTE(smote_df[-63], target = smote_df[63], dup_size = 3)

X_smote <- smote_model$data[-63]
y_smote <- as.numeric(smote_model$data$class)

# classes are just about equal
table(y_smote)

fit_2_glm_smote <- glmnet(X_smote,y_smote, family = "binomial", alpha = 0, lambda = 0)
fit_2_rf_smote <- randomForest(X_smote ,as.factor(y_smote))

roc(y_test, predict(fit_2_glm_smote, X_test, type = 'response'))
roc(y_test, predict(fit_2_rf_smote, X_test , "prob")[,2])
