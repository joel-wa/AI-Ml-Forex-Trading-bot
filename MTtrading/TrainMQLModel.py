#Train MQL Linear Model
import pandas as pd
import numpy as np
#Importing Linear Model
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error
import joblib

version = '3p'

def trainBullBear(X,y,Xv,yv):
    BBModel = LinearRegression(fit_intercept = True)
    BBModel.fit(X,y)

    linear_pred = BBModel.predict(Xv)
    linear_error = mean_absolute_error(yv,linear_pred)
    print(f"BB Accuracy is {linear_error}")
    return BBModel

def trainModel(X,y,Xv,yv):
    linearModel = LinearRegression(fit_intercept= True)
    linearModel.fit(X,y)

    linear_pred = linearModel.predict(Xv)

    linear_error = mean_absolute_error(yv,linear_pred)
    print(f"Accuracy is {linear_error}")
    return linearModel

def trainFullModel(Xf,yf):
    linearModel = LinearRegression(fit_intercept= True)
    linearModel.fit(Xf,yf)
    return linearModel

def exportModel(model):
    modelFileName = version + 'EURUSDModel23'
    joblib.dump(model,modelFileName)
    return

def exportBBModel(model):
    modelFileName = version + 'BBEURUSDModel23'
    joblib.dump(model,modelFileName)
    return

new_csv = pd.read_csv('3EURUSD_MQLScrape.csv')

selectedData = new_csv


halfer = 350
halfdata = selectedData.iloc[:halfer,:]
features = ['Open','High','Low','Volume','PreviousType']
X = halfdata[features]
y = halfdata.Close
Xf = selectedData[features]
yf = selectedData.Close

bbfeatures = ['Open','High','Low','Volume','PreviousType']
bX = halfdata[bbfeatures]
yb = halfdata.PreviousType

bXf = selectedData[bbfeatures]
ybf = selectedData.PreviousType

trydata = selectedData.iloc[halfer:,:]
Xv = trydata[features]
yv = trydata.Close

bXv = trydata[bbfeatures]
ybv = trydata.PreviousType

trainModel(X,y,Xv,yv)
exportModel(trainFullModel(Xf,yf))

# trainBullBear(bX,yb,bXv,ybv)
# exportBBModel(trainFullModel(bXf,ybf))