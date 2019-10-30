import pandas as pd
import numpy as np
import os

directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
for filename in os.listdir(directory):
    if filename.endswith('.txt'):
        tnic = pd.read_csv(os.path.join(directory, filename),
                           delimiter='\t', usecols=['gvkey1', 'year', 'gvkey2','score'],
                           dtype={'gvkey1':'int16', 'gvkey2':'int16', 'year':'int16', 'score':'float64'},
                           na_values='nan')
        tnic = tnic[['gvkey1', 'year', 'gvkey2', 'score']]
        tnic.dropna(inplace=True)
        tnic.drop_duplicates(subset=['gvkey1', 'year', 'gvkey2'], inplace=True)
        tnic.set_index(['gvkey1', 'year', 'gvkey2'], inplace=True)
        tnic.to_pickle(os.path.join(directory, filename[:-3] + 'pkl'), compression='gzip')
        del tnic
