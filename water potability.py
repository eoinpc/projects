import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import xgboost as xgb
from sklearn.preprocessing import MinMaxScaler
from sklearn.impute import KNNImputer
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import confusion_matrix, accuracy_score, roc_auc_score, roc_curve
from sklearn.inspection import permutation_importance

data = pd.read_csv('C:/Users/eoinp/Downloads/water_potability1.csv')

data.head()
data.describe()

data.isnull().sum()
# lots of missing values in pH, sulfate, and trihalomethanes columns

data['Potability'].value_counts()
# no alarming imbalance between classes of response

sns.heatmap(data.corr())
sns.pairplot(data)
# little to no correlation between features - no multicollinearity problems

# scaling data for KNN imputer - it is based on euclidean distance between datapoints
scaler = MinMaxScaler()
scaled_df = pd.DataFrame(scaler.fit_transform(data), columns = data.columns)

# using KNN imputer for missing values in data
imputer = KNNImputer(n_neighbors = 5)
scaled_df = pd.DataFrame(imputer.fit_transform(scaled_df), columns = scaled_df.columns)

scaled_df.isnull().sum()
scaled_df.describe()

# creating x and y and splitting data
x = scaled_df.drop('Potability', axis = 1)
y = scaled_df['Potability']

x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.3, random_state = 4724)

############################################# RANDOM FOREST ########################################################
# hyperparameter tuning for random forest
params = {'n_estimators':[150, 175, 200],
          'max_depth':[8, 9, 10],
          'min_samples_split':[0.0025, 0.005, 0.01],
          'max_features':['sqrt', 'log2', 'auto']}

rfc = RandomForestClassifier()
model = GridSearchCV(rfc, params, cv = 10, n_jobs = -1)

model.fit(x_train, y_train)

model.best_params_
model.best_score_

# predictions
rfc_best = RandomForestClassifier(max_depth = 9, max_features = 'sqrt', min_samples_split = 0.005, n_estimators = 175)
rfc_best.fit(x_train, y_train)

# evaluating performance of model
# confusion matrix and accuracy
y_pred = rfc_best.predict(x_test)
print(confusion_matrix(y_test, y_pred))
print('Accuracy: ', accuracy_score(y_test, y_pred))

# roc and auc
auc = roc_auc_score(y_test, y_pred)
print('Model AUC:', auc)

fpr, tpr, _ = roc_curve(y_test, y_pred)
plt.plot(fpr, tpr)
plt.title('Model AUC')
plt.show()
# this classifier reaches 60% sensitivity (TPR) at a cost of about 45% FPR, which is not too good

# feature importances
rfc_best.feature_importances_
plt.barh(x.columns.values, rfc_best.feature_importances_)
# sulfate and pH are the two most important features for this random forest model
# turbidity, trihalomethanes, and organic carbon are among the least useful for the model

# hyperparameter tuning 
'''
{'max_depth': 6,
 'max_features': 'log2',
 'min_samples_split': 0.05,
 'n_estimators': 100}

  score: 0.642

{'max_depth': 7,
 'max_features': 'log2',
 'min_samples_split': 0.025,
 'n_estimators': 125}

  score: 0.664
  
{'max_depth': 8,
 'max_features': 'auto',
 'min_samples_split': 0.01,
 'n_estimators': 150}

  score: 0.675
  
  *****************************
{'max_depth': 9,
 'max_features': 'sqrt',
 'min_samples_split': 0.005,
 'n_estimators': 175}

  score: 0.682
  *****************************
  
{'max_depth': 10,
 'max_features': 'auto',
 'min_samples_split': 0.0025,
 'n_estimators': 200}

  score: 0.687
'''

############################################## XGBOOST #############################################################
# hyperparameter tuning for xgboost
params = {'eta':[0.04, 0.05, 0.06],
          'gamma':[5, 6, 7],
          'max_depth':[6, 7, 8],
          'subsample':[0.7, 0.75, 0.8]}

xgbc = xgb.XGBClassifier()
model = GridSearchCV(xgbc, params, cv = 10, n_jobs = -1)

model.fit(x_train, y_train)

model.best_params_
model.best_score_

# predictions
xgb_best = xgb.XGBClassifier(eta = 0.05, gamma = 6, max_depth = 7, subsample = 0.75)
xgb_best.fit(x_train, y_train)

# evaluating performance of model
# confusion matrix and accuracy
y_pred = xgb_best.predict(x_test)
print(confusion_matrix(y_test, y_pred))
print('Accuracy: ', accuracy_score(y_test, y_pred))

# roc and auc
auc = roc_auc_score(y_test, y_pred)
print('Model AUC:', auc)

fpr, tpr, _ = roc_curve(y_test, y_pred)
plt.plot(fpr, tpr)
plt.title('Model AUC')
plt.show()

xgb_best.feature_importances_
plt.barh(x.columns.values, xgb_best.feature_importances_)

# hyperparameter tuning
'''
{'eta': 0.1,
 'gamma': 5,
 'max_depth': 6,
 'subsample': 0.75}
  
  score: 0.689

{'eta': 0.05,
 'gamma': 5,
 'max_depth': 7,
 'subsample': 0.75}

  score: 0.691
  
{'eta': 0.05, 
 'gamma': 6, 
 'max_depth': 7, 
 'subsample': 0.75}

  score: 0.695
'''