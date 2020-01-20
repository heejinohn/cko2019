"""
tnic_industry.py
"""
import os
import pandas as pd
DIRECTORY = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
TNIC_INDUSTRY = pd.read_pickle('~/tnic_industry.pkl')
for filename in os.listdir(DIRECTORY):
    if filename.endswith('.pkl'):
        tnic = pd.read_pickle(os.path.join(
            DIRECTORY, filename), compression='gzip')
        for i in range(1, 3):
            TNIC_INDUSTRY.rename(
                columns={'score' + '_' + str(i): 'score'}, inplace=True)
            TNIC_INDUSTRY.index = TNIC_INDUSTRY.index.set_levels(
                TNIC_INDUSTRY.index.levels[1] + 1, level=1)
            TNIC_INDUSTRY.update(tnic, join='left', overwrite=False)
            TNIC_INDUSTRY.rename(
                columns={'score': 'score' + '_' + str(i)}, inplace=True)
        TNIC_INDUSTRY.index = TNIC_INDUSTRY.index.set_levels(
            TNIC_INDUSTRY.index.levels[1] - 2, level=1)
        del tnic


TNIC_INDUSTRY.to_pickle('/scratch/ou/hohn/tnic_ind_update.pkl')
