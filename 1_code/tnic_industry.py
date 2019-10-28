"""
tnic_industry.py
"""
import pandas as pd, numpy as np, os
directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
tnic_industry = pd.read_pickle('/scratch/ou/hohn/tnic_industry.pickle')
for filename in os.listdir(directory):
    if filename.endswith('.txt'):
        tnic = pd.read_csv(os.path.join(directory, filename),
                           delimiter='\t', usecols=['gvkey1', 'gvkey2', 'year', 'score'],
                           dtype={'gvkey1':'int16', 'gvkey2':'int16', 'year':'int16', 'score':'float64'},
                           na_values='nan')
        tnic.drop_duplicates(subset=['gvkey1', 'gvkey2', 'year'], inplace=True)
        tnic.set_index(['gvkey1', 'gvkey2', 'year'], inplace=True)
        for i in range(3):
            tnic_industry.rename(columns={'score' + '_' + str(i):'score'})
            tnic_industry.update(tnic, join='left', overwrite=False)
            tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] + 1, level=1)
            tnic_industry.rename(columns={'score':'score' + '_' + str(i)})
        del tnic

        tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] - 3, level=1)
        tnic.to_pickle(os.path.join(directory, filename[:-3] + 'pickle'))

tnic_industry.to_pickle('/scratch/ou/hohn/tnic_industry.pickle')
