library(mlbench)
library(bnstruct)
library(superml)
library(xgboost)
library(dplyr)
library(caret)
library(boot)
library(ROCR)

options(scipen = 5)

df <- read.csv('/Users/eoinpc/Desktop/UCF/eco_4444/R/data/hmda.csv', header = TRUE)

df <- rename(df, di_total = s46, selfemp = s27a, pmi_deny = s53, pcred = s44, ccred = s43, mcred = s42, income = s17,
             loan = s6, appraisal = s50, cosigner = s55, SLP = s49, glmet = s40, credlines = s41, lassets = s35)
attach(df)

approve <- ifelse(df$s7 == 3, 0, 1) # using s7 - action taken

df <- df %>% mutate(hsei = s45 / 100, loan_appraised = loan / appraisal)

marital <- ifelse(df$s23a == 'S' | df$s23a == 'U' | is.na(df$s23a), 0, 1)
hse_income <- ifelse(df$hsei > 0.3, 1, 0)
race <- ifelse(df$s13 == 3, 1, 0)
appraised_low <- ifelse(df$loan_appraised <= 0.8, 1, 0)
appraised_medium <- ifelse(df$loan_appraised <= 0.95 & df$loan_appraised > 0.8, 1, 0)
appraised_high <- ifelse(df$loan_appraised > 0.95, 1, 0)

df <- data.frame(df, approve, hse_income, race, marital)
df <- data.frame(df, appraised_high, appraised_low, appraised_medium)

######################### logit
costfunc <- function(approve, pred_prob) {
  weight_fn = 1
  weight_fp = 1
  c_fn <- (approve == 1) & (pred_prob < optimal_cutoff)
  c_fp <- (approve == 0) & (pred_prob >= optimal_cutoff)
  cost <- mean(weight_fn * c_fn + weight_fp * c_fp)
  return(cost)
}

xvars <- c('race', 'marital', 'selfemp', 'school')
x <- df[xvars]
dat <- data.frame(x, approve)

logit <- glm(approve ~ ., data = dat, family = binomial)

pred_prob <- predict.glm(logit, type = c('response'))

prob_seq <- seq(0.01, 1, 0.01)
cvcost <- rep(0, length(prob_seq))

for(i in (1:length(prob_seq))) {
  optimal_cutoff <- prob_seq[i]
  cvcost[i] <- cv.glm(data = dat, glmfit = logit, cost = costfunc, K = 10)$delta[2]
}

optimal_cutoff_cv <- prob_seq[which(cvcost == min(cvcost))]
optimal_cutoff_cv

class_prediction <- ifelse(pred_prob > optimal_cutoff_cv, 1, 0)
class_prediction <- factor(class_prediction)
approve <- factor(approve)

confusionMatrix(class_prediction, approve, positive = '1')

# ROC
pred <- prediction(pred_prob, approve)

perf <- performance(pred, 'tpr', 'fpr')

plot(perf, colorize = TRUE, main = 'Logit ROC')

sn <- slotNames(pred)
sapply(sn, function(x) length(slot(pred, x)))
sapply(sn, function(x) class(slot(pred, x)))

# obtaining auc
auc <- unlist(slot(performance(pred, 'auc'), 'y.values'))
auc

######################### xgb
xvars <- c('race', 'pmi_deny', 'pcred', 'ccred', 'mcred', 'di_total', 'school', 'income', 'loan_appraised',
           'glmet', 'lassets')
X <- df[xvars]

X$school[X$school == 999999.4] <- NA
X$income[X$income == 999999.4] <- NA
X$lassets[X$lassets == 999999.4] <- NA
X$glmet[X$glmet == 666] <- 0

X <- data.frame(knn.impute(as.matrix(X), k = 10, cat.var = 1:5, to.impute = 1:nrow(X), using = 1:nrow(X)))

y <- approve

# adding/transforming vars
X <- X %>% mutate(di_total2 = (di_total) ** 2)
X <- X %>% mutate(di_total3 = (di_total) ** 3)
X <- X %>% mutate(income2 = (income) ** 2)
X <- X %>% mutate(log_income = log(income + 0.01))
X <- X %>% mutate(loan_appraised2 = (loan_appraised) ** 2)
X <- X %>% mutate(log_la = log(loan_appraised))
X <- X %>% mutate(loan2 = (loan) ** 2)
X <- X %>% mutate(pmi_ccred = (pmi_deny) * (ccred))
X <- X %>% mutate(pmi_di_total = (pmi_deny) * (di_total))
X <- X %>% mutate(pmi_di_total2 = (((pmi_deny) * (di_total)) ** 2))
X <- X %>% mutate(pmi_income = (pmi_deny) * (income))
X <- X %>% mutate(income_pcred = (pcred) * (income))
X <- X %>% mutate(pcred_mcred = (pcred) * (mcred))
X <- X %>% mutate(pcred_ccred = (pcred) * (ccred))

control <- rfeControl(functions = rfFuncs, method = "cv", number = 10)
results <- rfe(X, as.factor(approve), sizes = c(1:ncol(X)), rfeControl = control)

print(results)
predictors(results)
plot(results, type = c("g", "o"))

xgb_grid = expand.grid(nrounds = c(1000, 1500),
                       max_depth = c(5, 6),
                       eta = c(0.03, 0.05),
                       gamma = c(1, 2),
                       subsample = c(0.5, 0.6),
                       colsample_bytree = c(0.6, 0.75),
                       min_child_weight = 1)

xgb_trcontrol = trainControl(method = "cv",
                             number = 10,
                             verboseIter = TRUE,
                             returnData = FALSE,
                             returnResamp = "all",
                             allowParallel = TRUE)

xmatrix <- as.matrix(X)
ymatrix <- as.matrix(as.factor(approve))
dmat <- xgb.DMatrix(xmatrix, label = ymatrix)

xgb_train <- train(x = X,
                   y = approve,
                   trControl = xgb_trcontrol,
                   tuneGrid = xgb_grid,
                   method = "xgbTree")

xgb_train$bestTune

fulldata <- data.frame(X, approve)
y_pred <- predict(xgb_train, newdata = fulldata)

prob_seq <- round(seq(0.01, 1.00, 0.01), 2)
cvcost <- rep(0, length(prob_seq))

for(i in (1:length(prob_seq))) {
  optimal_cutoff <- prob_seq[i]
  cv <- xgb.cv(data = dmat,
               nfold = 10,
               objective = 'binary:logistic',
               metrics = paste('error@', optimal_cutoff),
               nrounds = 1000,
               max_depth = 5,
               eta = 0.05,
               gamma = 2,
               colsample_bytree = 0.75,
               min_child_weight = 1,
               subsample = 0.5)
  
  if(optimal_cutoff == 0.1 | optimal_cutoff == 0.2 | optimal_cutoff == 0.3 | optimal_cutoff == 0.4 | optimal_cutoff == 0.6 | optimal_cutoff == 0.7 | optimal_cutoff == 0.8 | optimal_cutoff == 0.9 | optimal_cutoff == 1.0) {
    cvcost[i] <- min(cv[["evaluation_log"]][[sprintf("test_error@%.1f_mean", optimal_cutoff)]])
  } else {
    cvcost[i] <- min(cv[["evaluation_log"]][[sprintf("test_error@%.2f_mean", optimal_cutoff)]])
  }
}

optimal_cutoff_cv <- prob_seq[which(cvcost == min(cvcost)) & cvcost != 0]
optimal_cutoff_cv <- 0.53

prediction <- as.numeric(y_pred > optimal_cutoff_cv)

xgb_grid2 = expand.grid(nrounds = 1000,
                        max_depth = 5,
                        eta = 0.05,
                        gamma = 2,
                        subsample = 0.5,
                        colsample_bytree = 0.75,
                        min_child_weight = 1)

# re-estimating model
xgb_full <- train(x = X,
                  y = approve,
                  tuneGrid = xgb_grid2,
                  method = "xgbTree")

fulldata <- data.frame(X, approve)
y_pred <- predict(xgb_full, newdata = fulldata)

prediction2 <- as.numeric(y_pred > optimal_cutoff_cv)

pred <- as.factor(prediction2)
true <- as.factor(approve)

confusionMatrix(pred, true, positive = '1')

preds <- prediction(y_pred, approve)

perf <- performance(preds, 'tpr', 'fpr')

plot(perf, colorize = TRUE, main = 'ROC')

auc <- unlist(slot(performance(preds, 'auc'), 'y.values'))
auc
