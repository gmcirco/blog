import numpy as np

from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import cross_val_score

class ALSOe():
    """ Initializes a regression-based outlier detector
    """

    def __init__(self, N = 100) -> None:

        self.param_list = []
        self.model_list = []
        self.anom_list = []
    
        self.N = N
        self.std_scaler = StandardScaler()

    def fit(self, data):
        """ Fit an ensamble detector
        """

        # standardize data
        self.std_scaler = self.std_scaler.fit(X = data)
        data = self.std_scaler.transform(data)

        # fit N models
        for i in range(0, self.N):

            # define sample space
            n = data.shape[0]
            p = data.shape[1]
            s = [min([n, 50]), min(n,1000)]

            # draw s random samples from dataframe X
            s1 = np.random.randint(low = s[0], high = s[1])
            p1 = np.random.randint(low = 0, high = p)
            ind = np.random.choice(n, size = s1, replace = False)

            # define random y and X 
            df = data[ind]
            y = df[:,p1]
            X = np.delete(df, p1, axis=1)

            # initalize RF regressor
            rf = RandomForestRegressor(n_estimators=10)

            # fit & predict
            rf.fit(X, y)

            # add fitted models & y param to list
            self.model_list.append(rf)
            self.param_list.append(p1)

    def predict(self, newdata):

        """ Get anomaly scores from fitted models
        """

        # standardize data
        newdata = self.std_scaler.transform(newdata)    

        for i,j in zip(self.model_list, self.param_list):

            # define X, y
            y = newdata[:,j]
            X = np.delete(newdata, j, axis=1)

            # get predictions on model i, dropping feature j
            yhat = i.predict(X)

            # rmse
            resid = np.sqrt(np.square(y - yhat))
            resid = (resid - np.mean(resid)) / np.std(resid) 

            # compute and apply weights
            cve = cross_val_score(i, X, y, cv=3, scoring='neg_root_mean_squared_error')
            w = 1 - min(1, np.mean(cve)*-1)

            resid = resid*w

            self.anom_list.append(resid)

        # export results as min-max scaled
        anom_score = np.array(self.anom_list).T
        anom_score = np.mean(anom_score, axis = 1)

        # rescale and export
        anom_score = StandardScaler().fit_transform(anom_score.reshape(-1,1))
        anom_score = anom_score.flatten()

        return anom_score
