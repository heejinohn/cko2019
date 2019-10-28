"""
tnic_industry.py
"""
import pandas as pd, numpy as np, os
directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
tnic_industry = pd.read_pickle(csv'/scratch/ou/hohn/upload.csv', index_col=['gvkey1', 'gvkey2', 'year'],
                    dtype={'gvkey1':'Int64', 'gvkey2':'Int64', 'year':'Int64', 'score':'float64'}, na_values='NaN')    
tnic_industry['score'] = np.NaN
for filename in os.listdir(directory):
    if filename.endswith('.txt'):
        tnic = pd.read_csv(os.path.join(directory, filename), 
                           delimiter='\t', usecols=['gvkey1','gvkey2','year','score'],
                           dtype={'gvkey1':'Int16', 'gvkey2':'Int16', 'year':'Int16', 'score':'float64'}, na_values='NaN')    
        tnic.drop_duplicates(subset=['gvkey1', 'gvkey2', 'year'], inplace=True)
        tnic.set_index(['gvkey1', 'gvkey2', 'year'], inplace=True)
        tnic_industry.update(tnic, join='left')
        del tnic

tnic_industry.to_csv('/scratch/ou/hohn/tnic_industry.csv')