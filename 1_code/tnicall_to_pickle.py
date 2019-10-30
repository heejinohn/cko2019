import pandas as pd
import numpy as np
import os

directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
for filename in os.listdir(directory):
    if filename.endswith('.pickle'):
        tnic = pd.read_pickle(os.path.join(directory, filename))
        tnic.dropna(inplace=True)
        for i in range(3):
            tnic.index.set_levels(abs(tnic.index.levels[i]), level=i, inplace=True, verify_integrity=False)
        tnic = tnic.reorder_levels(['gvkey1', 'year', 'gvkey2'])
        tnic.to_pickle(os.path.join(directory, filename[:-6] + 'pklz'), compression='gzip')
        del tnic
        os.remove(os.path.join(directory, filename))
