option nolabel;
FILENAME REFFILE '/scratch/ou/hohn/get_these.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.master(keep=gvkey1 year fyear permno datadate);
	GETNAMES=YES;
RUN;


/* total risk estimated as the volatility of monthly returns*/
/* data getthese; */
/* 	set master (keep= gvkey datadate permno); */
/* 	date = intnx("month", datadate, 1)-1; */
/*	date1 = intnx("month", datadate, 13)-1;*/
/*	date2 = intnx("month", datadate, 25)-1;*/
/*	date3 = intnx("month", datadate, 37)-1;*/
/*	format date0-date3 date9.0;*/
/* run; */
/* data getthese(drop = i); */
/* 	set getthese; */
/* 	date = intnx("month", datadate, 4)-1; */
/* 	i = 1; */
/* 	do while (i<=12); */
/* 		output; */
/* 		date = intnx("month", date, 0)-1; */
/*		date1 = intnx("month", date1, 0)-1;*/
/*		date2 = intnx("month", date2, 0)-1;*/
/*		date3 = intnx("month", date3, 0)-1;*/
/* 		i = i+1; */
/* 		format date date9.; */
/* 	end; */
/* run; */
/* proc upload data = getthese; */
/* run; */
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

/* proc sql; */
/* 	create table monthlyreturns as */
/* 	select a.*, b.ret */
/* 	from getthese a left join */
/* 		(select permno,intnx("month", date, 1) -1 as date, ret */
/* 			from crspa.msf */
/* 			where 1996 <= year(date)) as b */
/* 	on a.permno = b.permno */
/* 	where a.date = b.date; */
/* quit; */

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
/* proc sort data = monthlyreturns; */
/* 	by gvkey datadate; */
/* run; */
/* proc means data = monthlyreturns noprint; */
/* 	by gvkey datadate; */
/* 	var ret; */
/* 	output out = totalrisk(drop = _type_ _freq_) */
/* 	n = months var(ret) = risk; */
/* run; */
/* %hashkeep(master,totalrisk, gvkey datadate, risk, master); */
/* %clean(getthese /*mret0-mret3 monthlyreturns0-monthlyreturns3 monthlyreturns totalrisk); */

* calculate asset growth, income/assets, r&d/sales, firm age for all years;
* mtb, asset growth, income, age, r&d/sales, and negative earnings;
data getthese;
	set master;
	gvkey = put(gvkey1, z6.);
	keep gvkey1 gvkey;
run;

proc sort data = getthese nodupkey;
	by gvkey;
run;


proc sql;
	create table compdata as
		select b.* from
		getthese a left join 
			(select gvkey, fyear, datadate, at, csho, sale, xrd, epspx from comp.funda 
			where fyear >= 1998 and consol = 'C' and indfmt in ('INDL', 'FS') and
			datafmt = 'STD' and popsrc = 'D' and curcd in ('USD', 'CAD')) b
			on a.gvkey = b.gvkey
	order by gvkey, fyear;
quit;
data compdata;
	set compdata;
	where not missing(gvkey);
run;
proc sql;
	create table compcontrol as
	select a.*, b.year1 as start_year
	from compdata as a left join comp.names as b
	on a.gvkey = b.gvkey;
run;
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

%hashmerge(compcontrol, scratch.mb, gvkey fyear, mb, compcontrol);
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
data master;
	set master;
	gvkey = put(gvkey1, z6.);
run;
%hashkeep(master, compcontrol, gvkey fyear, mb atg income r_d age neg_ni, master);

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
					from crsp.mport1) as b
				on a.permno = b.permno
			where year(a.date) = b.year;
		create table cusip as
			select a.*, b.ncusip as cusip
			from getthese as a left join
				(select permno, ncusip, namedt, nameendt
					from crsp.dsenames) as b
				on a.permno = b.permno
				where ((a.date >= b.namedt)  or namedt = .B)
					and ((a.date <= b.nameendt) or nameendt = .E);

	quit;
/*%end;*/
/*%mend; %capassgin;*/

%clean(getthese);
%hashkeep(master, capassign, gvkey datadate, capn, master);
data master;
	length cusip $8.;
	call missing(cusip);
	if _n_=1 then do;
		declare hash h(dataset:"cusip");
		h.defineKey('gvkey', 'datadate');
		h.defineData('cusip');
		h.defineDone();
	end;
	set master;
 	if h.find()=0 then found =1;
	else found = 0;
run;
