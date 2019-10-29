#!/usr/bin/env python
# coding: utf-8

# # CKO JAR Revision

# In[49]:


import pandas as pd
import numpy as np
import rpy2.rinterface #ggplot tool


# ## Review TNIC-3 data

# In[56]:


"""
Hoberg and Philips TNIC3 database
"""
tnic = pd.read_csv('/Users/ohn0000/Project/cko/0_data/external/tnic3_data.txt', 
                   delimiter='\t', header=0, index_col=['gvkey1', 'year', 'gvkey2'])
tnic.dropna(inplace=True)


# In[57]:


"""
Subset to firms with more than 20 competitors each year
"""
tnic_industry = tnic.groupby(level=['gvkey1', 'year'])['score'].nlargest(20).reset_index(level=(0,1), drop=True)
tnic_industry = tnic_industry.groupby(level=['gvkey1', 'year']).filter(lambda x: x.size == 20)
tnic_industry = tnic_industry.to_frame(name='score')


# In[58]:


tnic_industry


# In[19]:


# tnic_industry['gvkey1'] = tnic_industry['gvkey1'].apply(lambda x: str(x).zfill(6))
# tnic_industry['gvkey2'] = tnic_industry['gvkey2'].apply(lambda x: str(x).zfill(6))


# Remeber that _year_ in __tnic_industry__ is the base year for identifying close competitors. Accordingly, _lead1_ is the M&A year and _lead2_ is the year following M&A.

# Readme_tnic3.txt explains that _year_ equals the first four digits of the __compustat__ _datadate_.

# Shift years in __tnic_indutry__ to get _lead1_ adn _lead2_ similarity scores

# In[53]:


tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] + 1, level=1)
tnic_industry.rename(columns={'score':'score_0'}, inplace=True)
tnic_industry['score'] = np.NaN
tnic_industry.update(tnic)
tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] + 1, level=1)
tnic_industry.rename(columns={'score':'score_1'}, inplace=True)
tnic_industry['score'] = np.NaN
tnic_industry.update(tnic)
tnic_industry.rename(columns={'score':'score_2'}, inplace=True)
tnic_industry.index = tnic_industry.index.set_levels(tnic_industry.index.levels[1] - 2, level=1)


# Shift years one more time to get _lead2_ similarity scores.

# In[79]:


tnic_industry.to_pickle('../2_pipeline/tnic_industry.pickle')
get_ipython().system('scp ../2_pipeline/tnic_industry.pickle $WRDS:/scratch/ou/hohn')


# Run __*tnic_industry.py*__ on _WRDS_. 

# In[ ]:


get_ipython().system('scp $WRDS:/scratch/ou/hohn/ ../2_pipeline/tnic_industry.pickle ')


# Average TNIC similarity score across 20-closest competitors.  
# Remeber that in __TNIC_ALL__ most of the scores equals to zero. The _z\__ might be the more suitable.

# In[27]:


avg_sim = tnic_industry.groupby(level=['gvkey1','year']).mean()
avg_sim = avg_sim.join(tnic_industry.groupby(level=['gvkey1','year']).count().add_prefix("n_"))
avg_sim = avg_sim.join(tnic_industry.fillna(0).groupby(level=['gvkey1','year']).mean().add_prefix("z_"))


# In[28]:


avg_sim


# In[29]:


# avg_sim.dropna() 
# # 54963 observations with non-missing scores

# avg_sim[(avg_sim['n_score'] == 20) & (avg_sim['n_score_lead1'] == 20) & (avg_sim['n_score_lead2'] == 20)]
# # 991 observations with all 20 competitors present in TNIC


# ## IV candidates

# The materiality measure based on deal value will be the last resort for the IV.   
# Alternatively, 2SLS using multiple IVs is feasible.
# 
# Candidates
# * Max deal value
# * Sum deal value
# * Datedif between _dateeff_ and _datadate_
#     * _dateeff_ of the first M&A
#     * _dateeff_ of the largest M&A
#     * weighted average of _dateeff_ 

# ## Import previously constructed datasets

# ### Materiality of M&A

# In[30]:


material = pd.read_csv('/Users/ohn0000/Project/cko/0_data/external/materiality.csv')
material.set_index(["year", "gvkey1"], inplace=True, verify_integrity=True)


# # M&A Disclosure

# Disclosure also might need additonal data collection.

# In[31]:


disc = pd.read_csv('/Users/ohn0000/Project/cko/0_data/manual/disc.csv', parse_dates=['DATADATE'])
disc['CIK'] = disc['CIK'].apply(lambda x: str(int(x)).zfill(10) if pd.notnull(x) else None)


# In[32]:


disc.rename(columns={"GVKEY":"gvkey1", "FYEAR":"year"}, inplace=True)
disc.set_index(["year", "gvkey1"], inplace=True, verify_integrity=True)


# In[33]:


manual = disc.join(material)[['DATADATE', 'CIK', 'TGTAT_ACQAT', 'TGTDVAL_ACQAT', 'MD_A', 'PROFORMA']].sort_index()


# ### SDC and Compustat Link File

# The link file is from [Michael Ewens](https://github.com/michaelewens/SDC-to-Compustat-Mapping.git). Cite papers below.

# ```
# @article{phillips2013r,
#   title={R\&D and the Incentives from Merger and Acquisition Activity},
#   author={Phillips, Gordon M and Zhdanov, Alexei},
#   journal={The Review of Financial Studies},
#   volume={26},
#   number={1},
#   pages={34--78},
#   year={2013},
#   publisher={Society for Financial Studies}
#   }
#  ```

# ```
# @article{ewensPetersWang2018,
#  title={Acquisition prices and the measurement of intangible capital},
#  author={Ewens, Michael and Peters, Ryan and Wang, Sean},
#  journal={Working Paper}
#  year={2018}
#  }
# ```

# In[89]:


sdc_link = pd.read_csv('/Users/ohn0000/Project/cko/0_data/external/dealnum_to_gvkey.csv', 
                       dtype={'DealNumber':'Int64', 'agvkey':'Int64', 'tgvkey':'Int64'}, index_col='DealNumber')


# In[35]:


# import wrds
# db = wrds.Connection(wrds_username = "yaera")
# ma_details_desc = db.describe_table('sdc', 'ma_details').sort_values('name')
# with pd.option_context('display.max_rows', None):
#     print(ma_details_desc)


# |     Variable | Description                    |
# |:------------:|:-------------------------------|
# |bookvalue     |Target Book Value (\$mil)       |
# |compete       |Competing Bidder (Y/N)          |
# |competecode   |Competing Bid Deal Code         |  
# |dateann       |Date Announced                  |
# |dateannest    |_dateann_ is estimated (Y/N)    | 
# |dateeff       |Date Effective                  | 
# |ebitltm       |Target EBIT LTM (\$mil)         |
# |pct_cash      |Percentage of consideration paid in cash|
# |pct_other|Percentage of consideration paid in other then cash or stock|
# |pct_stk|Percentage of consideration paid in stock|
# |pct_unknown|Percentage of consideration which is unknown|
# |ptincltm|Target Pre-Tax Income LTM (\$mil)|
# |salesltm|Target Sales LTM (\$mil)|
# |rankval|Ranking Value incl Net Debt of Target (\$mil)|

# Run sql query below on _WRDS_

# In[36]:


# import wrds
# sdc_query = """
# select master_deal_no as DealNumber, 
#         bookvalue, 
#         compete, 
#         competecode, 
#         dateann, 
#         dateannest, 
#         dateeff, 
#         ebitltm, 
#         pct_cash,
#         pct_other,
#         pct_stk,
#         pct_unknown,
#         ptincltm,
#         salesltm,
#         rankval
# from sdc.ma_details
# where dateeff is not null 
# """
# # and master_deal_no in %(deal_no)s
# sdc = db.raw_sql(sdc_query, date_cols=['dateann', 'dateeff'])
# sdc.to_pickle('/home/upenn/yaera/sdc.pkl')


# In[87]:


sdc = pd.read_pickle('/Users/ohn0000/Project/cko/0_data/external/sdc.pkl')
sdc.drop_duplicates('dealnumber', inplace = True)
sdc['dealnumber'] = sdc['dealnumber'].apply(int)

# clear up values and change dtype to 'float'
for column in ['bookvalue', 'ebitltm', 'pct_cash', 'pct_other', 'pct_stk', 'pct_unknown', 'ptincltm', 'salesltm', 'rankval']:
    sdc[column] = sdc[column].apply(lambda x: np.NaN if x == '*********' else (np.NaN if pd.isna(x) else (float(x.replace(',', '')) if isinstance(x, str) else float(x))))
    sdc[column].astype('float16')


# In[90]:


sdc_sub = pd.merge(sdc_link, sdc, left_index=True, right_on='dealnumber').drop('dealnumber', axis='columns')
sdc_sub.index.name = 'dealnumber'


# In[91]:


sdc_sub.sort_values(['agvkey', 'dateeff'], inplace=True)


# Use __compustat__ _datadate_ and gvkey to link the sdc data to the similarity scores

# In[40]:


import wrds
db = wrds.Connection(wrds_username = 'hohn')

sdc_quary = """
select gvkey, datadate, fyear, cusip,  cik
from comp.funda
where consol = %(consol)s and indfmt in %(indfmt)s and datafmt = %(datafmt)s and popsrc = %(popsrc)s and curcd in %(curcd)s
"""

parm = {'consol':('C'), 'indfmt' : ('INDL', 'FS'), 'datafmt': ('STD'), 'popsrc' : ('D'), 'curcd' : ('USD', 'CAD')}

funda = db.raw_sql(sdc_quary, params = parm, date_cols = ['datadate'])


# In[41]:


funda['start'] = funda['datadate'] - pd.DateOffset(months = 12) + pd.DateOffset(days = 1)
funda['gvkey'] = funda['gvkey'].astype('int64')
funda.set_index('gvkey', inplace=True)


# In[42]:


funda.fyear = funda.fyear.astype('Int16')


# In[43]:


import pandasql as ps

sql_query = '''
select a.*, b.datadate, b.fyear, b.cusip, b.cik
from sdc_sub a left join funda b
on a.agvkey = b.gvkey and a.dateeff between b.start and b.datadate
'''

newdf = ps.sqldf(sql_query, locals())


# In[44]:


col = list(newdf)
for i in range(2, 6):
    col.insert(i, col.pop(-1))
newdf = newdf.loc[:,col]


# In[45]:


for i in ['datadate', 'dateann', 'dateeff']:
    newdf[i] = newdf[i].astype('datetime64[ns]')
    
newdf['year'] = newdf['datadate'].dt.year.astype('Int16')
for i in ['fyear', 'agvkey', 'tgvkey']:
    newdf[i] = newdf[i].astype('Int64')


# In[46]:


col = list(newdf)
col.insert(col.index('datadate'), col.pop(col.index('year')))
newdf = newdf.loc[:,col]


# In[47]:


newdf = newdf.drop_duplicates(subset='dealnumber')


# In[48]:


newdf[newdf['agvkey'].notnull()]


# In[49]:


newdf['rankval'].count()


# 18994 observations with non-missing _rankval_

# In[50]:


newdf['salesltm'].count()


# 8055 observations with non-missing _salesltm_

# In[51]:


np.sum(newdf['rankval'].notnull() & newdf['salesltm'].notnull())


# 6445 observations with both _rankval_ and _salesltm_ available

# ## Append similarity score between acquirer and target

# In[69]:


upload = newdf[newdf['agvkey'].notnull() & newdf['tgvkey'].notnull() & newdf['year'].notnull()][['agvkey', 'tgvkey', 'year']].rename(columns={'agvkey':'gvkey1', 'tgvkey':'gvkey2'})
upload.to_csv('/Users/ohn0000/Project/cko/2_pipeline/upload.csv', index=False)
get_ipython().system('scp /Users/ohn0000/Project/cko/2_pipeline/upload.csv $WRDS:/scratch/ou/hohn')


# Run this on wrds server. The __TNIC_All__ files should be uploaded in scratch beforehand.

# In[ ]:


"""
The server killed the previous code that joins after combines all files. The current code instead loop over the files.
"""
# !cd /scratch/ou/hohn/TNIC_AllPairsDistrib
# !cat tnicall1996.txt > tnicall_combined.txt
# !for file in tnicall{1997..2017}.txt; do sed '1d' $file >> tnicall_combined.txt; done
# !cd ~


"""
atsim.py
"""


# In[72]:


get_ipython().system('scp atsim.py $WRDS:~')


# In[ ]:


get_ipython().system('scp $WRDS:/scratch/ou/hohn/atsim.csv /Users/ohn0000/Project/cko/2_pipeline/')


# In[ ]:


col = list(newdf)
col.insert(col.index('bookvalue'), col.pop(col.index('atsim')))
newdf = newdf.loc[:,col]


# ## Cross-sections
# * Similarity between acquirer and target 
#     - Relation stronger in diversifying
#     - Could be more of a U-shaped relation, i.e., competitors don't follow when you move far enough
# * Average value of pre-similarities between acquirer and close competitors 
#     - Prediction not clear
# * M&A performance during the completed firm-year
#     - Relation stronger when M&A was more successful <-> how do we define success of an M&A?
# * Number of close competitors of the target
#     - Potential targets are candidates of future mergers
# * How many competitors were there initially?
#     - The size of the TNIC industry
