"""
tnic_industry.py
"""
import pandas as pd
import numpy as np, os
directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
tnic_industry = pd.read_pickle('/scratch/ou/hohn/tnic_industry.pkl')
for filename in os.listdir(directory):
    if filename.endswith('.pkl'):
        tnic = pd.read_pickle(os.path.join(directory, filename))
        for i in range(1,3):
            tnic_industry.rename(columns={'score' + '_' + str(i):'score'}, inplace=True)
            tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] + 1, level=1)
            tnic_industry.update(tnic, join='left', overwrite=False)
            tnic_industry.rename(columns={'score':'score' + '_' + str(i)})
        tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] - 2, level=1)
        del tnic


tnic_industry.to_pickle('/scratch/ou/hohn/tnic_ind_update.pkl')
