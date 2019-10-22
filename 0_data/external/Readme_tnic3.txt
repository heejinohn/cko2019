*****************************************************
TOP LEVEL NOTE: This is the TNIC database we recommend for most research purposes as it is calibrated to be as granular as three-digit SIC codes.  This is why we call the database the TNIC-3 database.

****** NOTE: Please read the technical descriptions below before using the data.  


*****************

This file accompanies the TNIC-3 industry databases and describes where the data comes from,
the papers that should be cited when providing academic references, and some very important technical details regarding its usage.
Please read the technical details in full before using this data.  These details are critically important to ensure proper usage.

This data includes for each firm the "industry" firms that we classify as being related based on the details below.  Note that
there are still multiple "competitor" firms for each firm in this classification.  We include the firm identifier, and in each row, 
the list of firms that we classify as being in its industry as described below.  

We also include score data in this release.  The score data can be used to identify which rivals are "nearer" rivals than others.  A higher score indicates a higher degree of similarity and firm pairs with a higher score are nearer rivals.  See technical note 5 below.
Also note that the score in this database indicates the amount by which the pairwise score exceeded the similarity threshold for being
included in the TNIC database.  Hence, the distribution of the score variable has a lower end that starts near zero.  
A score near zero means that the firm just exceeded the minimum similarity threshold needed to be included in the database. 

**************************************************************************************************************
**************************************************************************************************************
********************************************** Background ****************************************************
********************************************** Background ****************************************************
********************************************** Background ****************************************************
**************************************************************************************************************
**************************************************************************************************************

For an extensive description of this data, please read the data and methodology sections of the studies noted below.  Here is a 
brief description.

This data is based on web crawling and text parsing algorithms that process the text in the business descriptions of 10-K annual 
filings on the SEC Edgar website from 1996 to present.  These product descriptions are legally required to be accurate, as Item 101 
of Regulation S-K legally requires that firms describe the significant products they offer to the market, and these descriptions 
must also be updated and representative of the current fiscal year of the 10-K.  We merge each firm's text product description to 
the CRSP/COMPUSTAT universe using the central index key (CIK) [We thank the Wharton Research Data Service (WRDS) for providing us 
with an expanded historical mapping of SEC CIK to COMPUSTAT gvkey, as the base CIK variable in COMPUSTAT only contains current links].  
Our resulting database is based on all publicly traded firms (domestic firms traded on either NYSE, AMEX, or NASDAQ) for which we have 
COMPUSTAT and CRSP data.

We calculate our firm-by-firm pairwise similarity scores by parsing the product descriptions from the firm 10Ks and forming word vectors 
for each firm to compute continuous measures of product similarity for every pair of firms in our sample in each year (a pairwise 
similarity matrix).  This is done using the cosine similarity method, which is applied after basic screens to eliminate common words are
applied (see studies noted below).   For any two firms i and j, we thus have a product similarity, which is a real number in the 
interval [0,1] describing how similar the words used by firms i and j are.

The TNIC-3 classification data we are distributing only records firms having pairwise similarities with a given firm i that are 
above a threshold as required based on the coraseness of the three digit SIC classification.  The level of coarseness of TNIC-3 thus matches 
that of three digit SIC codes, as both classifications result in the same number of firm pairs being deemed related.  For example, if one picks 
two firms at random from the CRSP/COMPUSTAT universe, the likelihood of them being in the same three digit SIC code is 2.05%.  Analgously, when
the TNIC-3 cutoff is specified using our approach, the likelihood of two randomly drawn firms being deemed related in their TNIC-3 is also 2.05%.  Hence, TNIC-3 is constructed to be "as coarse" as are three digit SIC codes.

Note:  TNIC industries are also purged for vertical relationships from the input/output tables (see paper for details).
Note 2: The words used to construct TNIC industries only include nouns or proper nouns (see paper for details) and we exclude geographic terms.


**************************************************************************************************************
**************************************************************************************************************
********************************************** Citations *****************************************************
********************************************** Citations *****************************************************
********************************************** Citations *****************************************************
**************************************************************************************************************
**************************************************************************************************************

This data is the result of a large research project initiated in early 2006 by Gerard Hoberg and Gordon Phillips.
The intent of the project is to better understand the role of industry, product market competition, and relatedness 
through the product market.  The data in its current state is the result of innovations described in the following
two papers.  As such, both should be cited when using this data for the purpose of academic research.

Product Market Synergies and Competition in Mergers and Acquisitions: A Text-Based Analysis
Gerard Hoberg and Gordon Phillips, Review of Financial Studies (October 2010), 23 (10), 3773-3811.

Text-Based Network Industries and Endogenous Product Differentiation
Gerard Hoberg and Gordon Phillips, Journal of Political Economy(October 2016), 124 (5) 1423-1465.

**********************************************************************************************************************
**********************************************************************************************************************
********************************************** Technical Details *****************************************************
********************************************** Technical Details *****************************************************
********************************************** Technical Details *****************************************************
**********************************************************************************************************************
**********************************************************************************************************************

Please read the following carefully to ensure proper usage of this data.

Technical Note 1) The data here is the full square relatedness matrix for firm pairs exceeding the threshold for relatedness described above.
Therefore, every pair of gvkey1 and gvkey2 will appear twice [once as gvkey1, gvkey2 and again as its mirror image gvkey2, gvkey1].  This is intentional as any use of the industry classification to construct an industry control (as discussed in papers above) should compute averages for each
firm over all of its rivals.  The entire matrix is needed to do this calculation properly. 

Technical Note 2) For convenience, these classifications DO include a record for the firm itself.  Thus, for all firms in the sample in a given year, one observation will appear in which gvkey1 and gvkey2 are the same.  For some calculations (for example to construct an industry control that excludes the firm itself), these records (those with gvkey1=gvkey2) should be dropped.  However, for other applications, it is important to keep the firm itself in the classification.  Hence we include these records to provide the most flexiblity possible.

Technical Note 3) Each file contains a gvkey1 and a gvkey2 variable in addition to the score variable.  It is important to note that we already did 
the merge to COMPUSTAT, so you do not have to repeat this.  The data contained here is not lagged.  Consider a COMPUSTAT firm with a fiscal year ending 
on Sept 30th, 1997, for example (i.e., the CSTAT variable datadate is 19970930).  The corresponding observations for this firm in the TNIC database would have the
year set to 1997. These observations would be baed on the product description of the 10-K report that was associated with this 9/30/1997 fiscal year end.  More generally, 
the year field in the TNIC database is always set to be the first four digits of the datadate variable (the year part) so the database uses the calendar year convention for
convenience.  Because this data is merged by fiscal year end, the pairwise links in this file should conveniently be viewed as being time-synchronous based on the year
identified as the first four digits of the datadate Compustat variable.

Technical Note 4) If you wish to control for an industry characteristic using TNIC industries, the easiest way is to use an average across 
related firms (a kernel-approach).  For example, if a reasercher wants to know firm i's industry level of characteristic variable "X", 
the researcher can compute the average of characteristic X over all firms that are deemed related to firm i using this TNIC data.
That is, the researcher can merge the characteristic values of X by gvkey2, and then take the average over each value of 
gvkey1 in each year (an "average by" statement, or a "proc means; by gvkey1 year;" statement in SAS).

Technical Note 5) The score field is included for those whose research can benefit from knowing which TNIC rivals are "closer rivals" relative to others.  A 
higher score indicates that the text of the two firms' business descriptions has more common vocabulary than do a pair of firms with a lower score.  The score
data can be used to identify a firm's "nearest 5" or "nearest 10" rivals as the rivals can be sorted by this field.  For users who do not need the score variable,
it can be disregarded and the other two data fields (gvkey1 and gvkey2) would then indicate the TNIC relatedness network in an equal weighted manner among peers.
