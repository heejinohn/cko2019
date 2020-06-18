option nolabel;
/************** Run Total Similarity Tests using firms within TNIC3 ***************/

**** import variable of interest;
* import tnic3 data;
data WORK.tnic3;
	infile 'C:\Users\hohn\Dropbox\mylib\Data\tnic3_allyears_extend_scores.txt'
	delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat score best32. ;
	informat gvkey1 best32. ;
	informat gvkey2 best32. ;
	informat year best32. ;
	format score best12. ;
	format gvkey1 best12. ;
	format gvkey2 best12. ;
	format year best12. ;
	input
		score
		gvkey1
		gvkey2
		year
;
run;

proc sort data = tnic3;
	by gvkey1 year;
run;

proc univariate data = tnic3 noprint;
	by gvkey1 year;
	var score;
	output out = TotalSim mean = tm n = t;
run;

data totalsim;
	set totalsim;
	where tm ne .;
	rename year = fyear;
run;

* import m&a firm-year and disclosure data;
libname mnadata 'C:\Users\hohn\Dropbox\mylib\Data';
data disclosure (keep = gvkey gvkey1 fyear datadate cusip tic md_a disclosure proforma sg sales_t sales_t_1);
	set mnadata.heejin3_20150302;
	if md_a >= 3 then disclosure = 1;
	else disclosure = 0;
	gvkey1 = input(gvkey, 8.);
run;
data disclosure;
	set disclosure;
	if md_a >=3 or proforma = "C" then disclosure_1 = 1;
	else disclosure_1 = 0;
run;

%hashmerge(disclosure, totalsim, gvkey1 fyear, tm, disclosure);

data totalsim1;
	set totalsim;
	fyear = fyear + 1;
	rename tm = tm1;
run;
data totalsim_1;
	set totalsim;
	fyear = fyear - 1;
	rename tm = tm_1;
run;
data totalsim_2;
	set totalsim;
	fyear = fyear - 2;
	rename tm = tm_2;
run;
%hashkeep(disclosure, totalsim1, gvkey1 fyear, tm1, disclosure);
%hashkeep(disclosure, totalsim_1, gvkey1 fyear, tm_1, disclosure);
%hashkeep(disclosure, totalsim_2, gvkey1 fyear, tm_2, disclosure);
%clean(totalsim totalsim1 totalsim_1 totalsim_2);
data disclosure;
	set disclosure;
	if tm ne . and tm1 ne . and tm < tm1 then D_tm = 1;
	if tm ne . and tm1 ne . and tm >= tm1 then D_tm = 0;
run;


* generate master file for WRDS imports;
proc sort data = disclosure out = master;
	by gvkey fyear;
run;
**** import permno;
%SignOn2WRDS;
rsubmit;
proc upload data = master out = getthese;
run;

proc sql;
	create table master as
	select a.*, b.permno 
	from getthese as a left join 
		(select gvkey, lpermno as permno, linkdt, linkenddt, linktype, linkprim from crspa.ccmxpf_linktable
			where lpermno ne .
			and linktype in ("LC" "LN" "LU" "LX" "LD" "LS")
			and linkprim IN ("C", "P")) as b
	on a.gvkey = b.gvkey
	where ((datadate >= linkdt)  or linkdt = .B) and ((datadate <= linkenddt) or linkenddt = .E);
quit;
proc download data = master out = master;
run;
endrsubmit;
proc sort data = master;
	by gvkey datadate;
run;

/* total risk estimated as the volatility of monthly returns*/
data getthese;
	set master (keep= gvkey datadate permno);
	date = intnx("month", datadate, 1)-1;
/*	date1 = intnx("month", datadate, 13)-1;*/
/*	date2 = intnx("month", datadate, 25)-1;*/
/*	date3 = intnx("month", datadate, 37)-1;*/
/*	format date0-date3 date9.0;*/
run;
data getthese(drop = i);
	set getthese;
	date = intnx("month", datadate, 4)-1;
	i = 1;
	do while (i<=12);
		output;
		date = intnx("month", date, 0)-1;
/*		date1 = intnx("month", date1, 0)-1;*/
/*		date2 = intnx("month", date2, 0)-1;*/
/*		date3 = intnx("month", date3, 0)-1;*/
		i = i+1;
		format date date9.;
	end;
run;
proc upload data = getthese;
run;
/*%macro mret1;*/
/*%do i = 0 %to 3;*/
/*	proc sql;*/
/*		create table mret as*/
/*			select a.*, b.LPERMNO as PERMNO*/
/*			from getthese as a left join*/
/*				(select GVKEY, LPERMNO, LINKDT, LINKENDDT*/
/*					from crspa.ccmxpf_linktable*/
/*					where LPERMNO ne .*/
/*					and LINKTYPE in ("LC" "LU" "LN" "LS")*/
/*					and LINKPRIM IN ("C", "P")) as b*/
/*				on a.GVKEY = b.GVKEY*/
/*				where ((a.date&i >= b.LINKDT)  or LINKDT = .B)*/
/*					and ((a.date&i <= b.LINKENDDT) or LINKENDDT = .E)*/
/*	;*/
/*	quit;		*/
/*	proc download data = mret&i;	*/
/*	run;*/
/*%end;*/
/*%mend; %mret1;*/

proc sql;
	create table monthlyreturns as
	select a.*, b.ret
	from getthese a left join
		(select permno,intnx("month", date, 1) -1 as date, ret
			from crspa.msf
			where 1996 <= year(date)) as b
	on a.permno = b.permno
	where a.date = b.date;
quit;
proc download data = monthlyreturns;
run;
endrsubmit;
signoff;
/*%macro mret2;*/
/*%do i = 0 %to 3;*/
/*	data monthlyreturns&i (keep = permno date&i ret&i);*/
/*		set monthlyreturns;*/
/*		date&i = intnx("month", date,  1) - 1;*/
/*		format date&i date9.;*/
/*		rename ret = ret&i;*/
/*	run;*/
/*%end;*/
/*%mend; %mret2;*/
/*%hashkeep(mret0, monthlyreturns0, permno date0, ret0, mret0);*/
/*%hashkeep(mret1, monthlyreturns1, permno date1, ret1, mret1);*/
/*%hashkeep(mret2, monthlyreturns2, permno date2, ret2, mret2);*/
/*%hashkeep(mret3, monthlyreturns3, permno date3, ret3, mret3);*/
/*%hashkeep(getthese, mret0, gvkey date0, ret0, mret);*/
/*%hashkeep(mret, mret1, gvkey date1, ret1, mret);*/
/*%hashkeep(mret, mret2, gvkey date2, ret2, mret);*/
/*%hashkeep(mret, mret3, gvkey date3, ret3, mret);*/
proc sort data = monthlyreturns;
	by gvkey datadate;
run;
proc means data = monthlyreturns noprint;
	by gvkey datadate;
	var ret;
	output out = totalrisk(drop = _type_ _freq_)
	n = months var(ret) = risk;
run;
%hashkeep(master,totalrisk, gvkey datadate, risk, master);
%clean(getthese /*mret0-mret3 monthlyreturns0-monthlyreturns3*/monthlyreturns totalrisk);

* calculate asset growth, income/assets, r&d/sales, firm age for all years;
* mtb, asset growth, income, age, r&d/sales, and negative earnings;
proc sort data = master out = getthese(keep = gvkey) nodupkey;
	by gvkey;
run;
%SignOn2WRDS;
rsubmit;
proc upload data = getthese;
run;
proc sql;
	create table compdata as
		select b.* from
		getthese a left join 
			(select gvkey, fyear, datadate, at, csho, sale, xrd, epspx from compm.funda where fyear >= 1993) b
		on a.gvkey = b.gvkey;
run;
proc sql;
	create table compcontrol as
	select a.*, b.year1 as start_year
	from compdata as a left join comp.names as b
	on a.gvkey = b. gvkey;
run;
proc download data = compcontrol;
run;
endrsubmit;
signoff;
proc sort data = compcontrol;
	by gvkey fyear;
run;
data compcontrol;
	set compcontrol;
	lag_at = ifn(gvkey = lag(gvkey) and fyear = lag(fyear)+1, lag(at), .);
run;

data compcontrol;
	set compcontrol;
	atg = at/lag_at - 1;
	income = (csho*epspx)/at;
	if missing(xrd) then  r_d = 0;
	else r_d = xrd / sale;
	age = fyear - start_year + 1;
	neg_ni = (epspx < 0);
	keep gvkey fyear datadate atg income r_d age neg_ni;
run;
data mtb (keep = gvkey fyear mtb);
	set mylib.mb_comp_crsp;
	mtb = coalesce(mb_comp, mb_crsp);
run;
%hashmerge(compcontrol, mtb, gvkey fyear, mtb, compcontrol);
/*data compcontrol;*/
/*	set compcontrol;*/
/*/*	rename fyear = year0;*/*/
/*run;*/
/*%macro compcontrol;*/
/*	%do i = 0 %to 3;*/
/*		data compcontrol&i;*/
/*			set compcontrol;*/
/*			rename fyear = year&i mtb = mtb&i atg = atg&i income = income&i r_d = r_d&i age = age&i neg_ni = neg_ni&i;*/
/*		run;*/
/*	%end;*/
/*%mend; */
/*%compcontrol;*/
;
%hashkeep(master, compcontrol, gvkey fyear, mtb atg income r_d age neg_ni, master);
%clean(compcontrol);

* assign size deciles;
data getthese;
	set master;
	keep gvkey datadate permno;
run;
data getthese;
	set getthese;
	date = intnx("month", datadate, 1) - 1;
/*	date1 = intnx("month", datadate, 13) - 1;*/
/*	date2 = intnx("month", datadate, 25) - 1;*/
/*	date3 = intnx("month", datadate, 37) - 1;*/
	format date date9.;
run;
%SignOn2WRDS;
rsubmit;
proc upload data = getthese;
run;
/*%macro capassgin;*/
/*%do i = 0 %to 3;*/
	proc sql;
/*		create table linktable&i as*/
/*			select a.*, b.LPERMNO as PERMNO*/
/*			from getthese as a left join*/
/*				(select GVKEY, LPERMNO, LINKDT, LINKENDDT*/
/*					from crspa.ccmxpf_linktable*/
/*					where LPERMNO ne .*/
/*					and LINKTYPE in ("LC" "LU" "LN" "LS")*/
/*					and LINKPRIM IN ("C", "P")) as b*/
/*				on a.GVKEY = b.GVKEY*/
/*				where ((a.date&i >= b.LINKDT)  or LINKDT = .B)*/
/*					and ((a.date&i <= b.LINKENDDT) or LINKENDDT = .E)*/
/*		;*/
		create table capassign as
			select a.*, b.capn/100 as capn
			from getthese as a left join 
				(select permno, capn, year
					from crspa.mport1) as b
				on a.permno = b.permno
			where year(a.date) = b.year;
	quit;
	proc download data = capassign;	
	run;
/*%end;*/
/*%mend; %capassgin;*/
endrsubmit;
signoff;
%clean(getthese);
%hashkeep(master, capassign, gvkey datadate, capn, master);

* get m&a firm years;
libname mnadata 'C:\Users\hohn\Dropbox\mylib\Data';
* identify competitors using tnic scores;
data tnic(rename= (year = fyear));
	retain gvkey competitor;
	set mylib.tnic;
	where gvkey1 <> gvkey2;
	gvkey = put(gvkey1, z6.);
	competitor = put(gvkey2, z6.);
	drop gvkey1 gvkey2;
run;
* keep the 10 closest competitors;
proc sort data = tnic;
	by gvkey fyear descending score;
run;
data close_comp;
	set tnic;
	retain i;
	by gvkey fyear;
	if first.fyear then i = 1;
	else i = i+1;
	output;
run;
data close_comp;
	set close_comp;
	where i <= 10;
	drop i score;
run;
data all_mna;
	set mnadata.allfirm_mna_ann;
	where n ne .;
	keep gvkey fyear n;
	rename gvkey = competitor;
run;
/*%macro comp_mna;*/
/*	%do i = 0 %to 3;*/
/*		data all_mna&i;*/
/*			set all_mna;*/
/*			rename fyear = year&i;*/
/*		run;*/
/*	%end;*/
/*%mend; %comp_mna;*/
%hashkeep(close_comp, all_mna, competitor fyear, n, comp_mna);
/*%hashkeep(close_comp, all_mna1, gvkey year1, n, comp_mna1);*/
/*%hashkeep(close_comp, all_mna2, gvkey year2, n, comp_mna2);*/
/*%hashkeep(close_comp, all_mna3, gvkey year3, n, comp_mna3);*/
/*%macro comp_mna;*/
/*	%do i = 0 %to 3;*/
/*		data comp_mna&i;*/
/*			set comp_mna&i;*/
/*			rename n = mna_num&i found = mna_dum&i;*/
/*		run;*/
/*	%end;*/
/*%mend; %comp_mna;*/
data comp_mna;
	set comp_mna;
	if n = . then n = 0;
	drop found;
run;
proc sort data = comp_mna;
	by gvkey fyear;
run;
proc means data = comp_mna noprint;
	by gvkey fyear;
	var n;
	output out = compmna_sum sum(n) = comp_mna;
run;
proc sort data = compmna_sum;
	by fyear;
run;
proc means data = compmna_sum noprint;
	var comp_mna;
	output out = med_mna median(comp_mna) = med_mna;
run;
proc sql;
	create table compmna_sum as
	select a.*, b.med_mna 
	from compmna_sum a, med_mna b;
quit;

data compmna_sum;
	set compmna_sum;
	if med_mna < comp_mna then D_compmna = 1;
	else D_compmna = 0;
	drop med_mna found _type_ _freq_;
run;
%clean(all_mna close_comp comp_mna med_mna tnic);
%hashkeep(master, compmna_sum, gvkey fyear, comp_mna D_compmna, master);
%clean(compmna_sum);

data master;
	set master;
	age = log(age);
run;

%winsor(dsetin = master, dsetout = post_sim, byvar=none, vars =  comp_mna atg age risk, type = winsor, pctl = 1 99);
%clean(xtemp xtemp_pctl);


%correlationMatrix(dsin=post_sim, vars = D_compmna tm_1 tm_2 disclosure d_tm risk mtb atg income capn age r_d neg_ni, mCoeff = CorrCoeff, mPValues = CorrP);

proc export data = CorrCoeff outfile = 'C:\Users\hohn\Dropbox\mylib\CKO2016\CorrCoeff.xlsx' dbms = xlsx replace;
run;


proc export data = Corrp outfile = 'C:\Users\hohn\Dropbox\mylib\CKO2016\Corrp.xlsx' dbms = xlsx replace;
run;

proc univariate data = post_sim noprint nobyplot outtable=univariate(keep = _var_ _mean_ _std_ _Q1_ _median_ _q3_);
	var D_compmna tm_1 tm_2 disclosure d_tm risk mtb atg income capn age r_d neg_ni;
run;

data post_sim;
	set post_sim;
	gvkey_num = gvkey + 0;
run;
proc export data = post_sim outfile = "C:\Users\hohn\Dropbox\mylib\CKO2016\post_sim_&sysdate..dta" replace;
run;
