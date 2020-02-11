proc import datafile='/scratch/upenn/yaera/dealnum_to_gvkey.csv' dbms=csv
	out=sdc_link;
run;

proc sort data=sdc_link nodupkey dupout=dup;
	by dealnumber;
run;

proc sort data=sdc.ma_details(where=(missing(dateeff)=0)) out=sdc_sort;
	by master_deal_no descending acusip;
run;
proc sort data=sdc_sort nodupkey dupout=sdcdup;
	by master_deal_no;
run;
data sdc_sort;
	set sdc_sort;
	where 1995 <= year(dateeff) <= 2017 and anationcode='US';
	/* Year & Nation criteria */
run;

proc sql;
	create table sdc_gvkey as
	select a.*, b.amanames, b.acusip, b.apublic, b.attitude, b.form, b.dateann, b.dateeff,
           b.datefin, b.ebitltm, b.amv,entval, b.bookvalue, b.eqval,mv, b.netass, b.niltm,
           b.pct_cash, b.pct_stk, b.pct_other, b.pct_unknown, b.pr,
           b.rankval, b.salesltm, b.tmanames, b.tnationcode, b.tpublic, b.master_cusip, b.tticker
    from sdc_link a left join sdc_sort b
    on a.dealnumber = b.master_deal_no
    where missing(acusip)=0 and apublic='Public';
    /* Only matching observations & public acquirers */
run;
