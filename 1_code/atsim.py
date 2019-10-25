"""
atsim.py
"""
import pandas as pd, numpy as np
tnicall = pd.read_csv('/scratch/ou/hohn/TNIC_AllPairsDistrib/tnicall_combined.txt',
                   delimiter='\t', header=0, index_col=['gvkey1', 'gvkey2', 'year'])
upload = pd.read_csv('/scratch/ou/hohn/upload.csv', index_col=['gvkey1', 'gvkey2', 'year'])

atsim = upload.join(tnicall, how='left', sort=True)
atsim.to_csv('/scratch/ou/hohn/atsim.csv')