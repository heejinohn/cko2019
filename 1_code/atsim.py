"""
atsim.py
"""
import pandas as pd, numpy as np, os
directory = '/scratch/ou/hohn/TNIC_AllPairsDistrib/'
atsim = pd.read_csv('/scratch/ou/hohn/upload.csv', index_col=['gvkey1', 'gvkey2', 'year'])

for filename in os.listdir(directory):
    if filename.endswith('.txt'):
        tnic = pd.read_csv(os.path.join(directory, filename), delimiter='\t', header=0, index_col=['gvkey1', 'gvkey2', 'year'])
        atsim = atsim.join(tnic, how='left', sort=True)
    
atsim.to_csv('/scratch/ou/hohn/atsim.csv')