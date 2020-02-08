/* Adopted from the IBES-CRSP link macro (/wrds/wrdsmacros/iclink.sas). While
 * the original macro use both CUSIP and ticker to link observations, ticker in
 * SDC seems to provide more erroneous links than valid ones. Therefore this
 * file only uses CUSIP. */
data sdc(keep = cusip tticker names dateeff type);
	infile '/scratch/ou/hohn/sdc_cusip.csv' delimiter = ',' firstobs=2 missover dsd;
	informat cusip $9.;
	informat dateeff yymmdd10.;
	informat names $64.;
	informat tticker $5.;
	informat type $2.;
	input 
		cusip $ 
		dateeff
		names $
		tticker $
		type $
		;
	format dateeff yymmdd10.;
run;
/* Create first and last 'dateeff' for SDC link */
proc sql;
  create table _SDC
  as select *, min(dateeff) as fdate, max(dateeff) as ldate
  from sdc
  group by cusip, tticker, names;
quit;

/* Label date range variables and keep only most recent company name for CUSIP link */
data _SDC;
  set _SDC;
  by cusip tticker names;
  if last.cusip;
  label fdate="First Start date of CUSIP record";
  label ldate="Last Start date of CUSIP record";
  format fdate ldate date9.;
  drop dateeff;
run;

/* CRSP: Get all PERMNO-NCUSIP combinations */
proc sort data=CRSP.DSENAMES out=_CRSP1 (keep=PERMNO NCUSIP comnam namedt nameendt);
  where not missing(NCUSIP);
  by PERMNO NCUSIP namedt; 
run;

/* Arrange effective dates for CUSIP link */
proc sql;
  create table _CRSP2
  as select PERMNO,NCUSIP,comnam,min(namedt)as namedt,max(nameendt) as nameendt
  from _CRSP1
  group by PERMNO, NCUSIP
  order by PERMNO, NCUSIP, NAMEDT;
quit;

/* Label date range variables and keep only most recent company name */
data _CRSP2;
  set _CRSP2;
  by permno ncusip;
  if last.ncusip;
  label namedt="Start date of CUSIP record";
  label nameendt="End date of CUSIP record";
  format namedt nameendt date9.;
  cusip = substr(ncusip, 1, 6);
run;

/* Create CUSIP Link Table */ 
/* CUSIP date ranges are only used in scoring as CUSIPs are not reused for 
    different companies overtime */
proc sql;
  create table _LINK1_1
  as select *
  from _SDC as a, _CRSP2 as b
  where a.CUSIP = b.CUSIP
  order by TTICKER, PERMNO, ldate;
quit; 

/* Score links using CUSIP date range and company name spelling distance */
/* Idea: date ranges the same cusip was used in CRSP and IBES should intersect */
data _LINK1_2;
  set _LINK1_1;
  by TTICKER PERMNO;
  if last.permno; /* Keep link with most recent company name */
  name_dist = min(spedis(lowcase(names),lowcase(comnam)),spedis(lowcase(comnam),lowcase(names)));
  if (not ((ldate < namedt) or (fdate > nameendt))) and name_dist < 30 then SCORE = 0;
    else if (not ((ldate < namedt) or (fdate > nameendt))) then score = 1;
    	else if name_dist < 30 then SCORE = 2; 
	  else SCORE = 3;
  keep cusip TTICKER PERMNO names comnam score;
run;

/* Step 2: Find links for the remaining unmatched cases using Exchange Ticker */
/* Identify remaining unmatched cases */
proc sql;
  create table _NOMATCH1
  as select distinct a.*
  from _SDC (keep=tticker cusip names fdate ldate) as a 
  where missing(a.tticker) = 0 and a.tticker NOT in (select tticker from _LINK1_2)
  order by a.tticker;
quit; 

*/* Drop Step1 Tables*/;
proc sql; drop table _SDC,_CRSP1,_CRSP2; quit;
*
*
*/* Get entire list of CRSP stocks with Exchange Ticker information */
*proc sort data=CRSP.DSENAMES out=_CRSP1 (keep=ticker comnam permno ncusip namedt nameendt);
*  where not missing(ticker);
*  by permno ticker namedt; 
*run;
*
*/* Arrange effective dates for link by Exchange Ticker */
*proc sql;
*  create table _CRSP2
*  as select permno,comnam,ticker as crsp_ticker,ncusip,
*              min(namedt)as namedt,max(nameendt) as nameendt
*  from _CRSP1
*  group by permno, ticker
*  order by permno, crsp_ticker, namedt;
*quit; 
*/* CRSP exchange ticker renamed to crsp_ticker to avoid confusion with IBES TICKER */
*
*/* Label date range variables and keep only most recent company name */
*data _CRSP2;
*  set _CRSP2;
*/*  by permno crsp_ticker;*/
*/*  if  last.crsp_ticker; */
*  label namedt="Start date of exch. ticker record";
*  label nameendt="End date of exch. ticker record";
*  format namedt nameendt date9.;
*run;
*
*/* Merge remaining unmatched cases using Exchange Ticker */
*/* Note: Use ticker date ranges as exchange tickers are reused overtime */
*proc sql;
*  create table _LINK2_1
*  as select a.tticker, b.permno, a.names, b.comnam, a.cusip, b.ncusip, a.ldate
*  from _NOMATCH1 as a, _CRSP2 as b
*  where a.tticker = b.crsp_ticker and 
*	 (ldate>=namedt) and (fdate<=nameendt)
*  order by tticker, ldate;
*quit; 
*
*/* Score using company name using 6-digit CUSIP and company name spelling distance */
*data _LINK2_2;
*  set _LINK2_1;
*  name_dist = min(spedis(names,comnam),spedis(comnam,names));
*  if substr(cusip,1,6)=substr(ncusip,1,6) and name_dist < 30 then SCORE=0;
*  else SCORE=name_dist;
*run;
*
*data scratch._LINK2_2;
*	set _LINK2_2;
*run;
*/* Some companies may have more than one TICKER-PERMNO link,         */
*/* so re-sort and keep the case (PERMNO & Company name from CRSP)    */
*/* that gives the lowest score for each IBES TICKER (first.ticker=1) */
*proc sort data=_LINK2_2; 
*	by tticker score;
* run;
*data _LINK2_3;
*  set _LINK2_2;
*  by tticker score;
*  if first.tticker;
*  keep tticker permno names comnam permno score;
*run;
*
/* Step 3: Add Exchange Ticker links to CUSIP links      */ 
/* Create Labels for ICLINK dataset and variables        */
/* Create final link table and save it in prespecified directory */
;
data SDC_CRSP (label="SDC-CRSP Link Table");
  set _LINK1_2;
label NAMES = "Company Name in SDC";
label COMNAM= "Company Name in CRSP";
label SCORE= "Link Score: 0(best) - 6";
run;

/* Final Sort */
proc sort data= SDC_CRSP; by TTICKER SCORE PERMNO; run;

/* House Cleaning */
proc sql; 
drop table _CRSP1,_CRSP2,
           _LINK1_1,_LINK1_2,_LINK2_1,_LINK2_2,_LINK2_3,
           _NOMATCH1;
quit;


proc sql;
	create table scratch.sdc as
	select a.*, b.permno
	from sdc a left join sdc_crsp b
	on a.cusip = b.cusip;
quit; 

proc export data=scratch.sdc outfile='/scratch/ou/hohn/sdc.csv' replace; run;
