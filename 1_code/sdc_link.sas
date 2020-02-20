proc import datafile='/scratch/upenn/yaera/dealnum_to_gvkey.csv' dbms=csv
    out=sdc_link;
run;

proc sort data=sdc_link nodupkey dupout=dup;
    by dealnumber;
run;

data sdc_link;
	set sdc_link;
	where agvkey <> tgvkey and missing(agvkey) = 0;
run;
proc sort data=sdc.ma_details(where=(missing(dateeff)=0)) equals out=sdc_sort;
    by master_deal_no descending salesltm;
run;
proc sort data=sdc_sort nodupkey dupout=sdcdup;
    by master_deal_no;
run;
data sdc_sort;
    set sdc_sort;
    where 1995 <= year(dateeff) <= 2017 and anationcode in ('US','CA');
	/* Year (1995 to 2017) & 
            acquirer nation criteria (US and Canadian)*/
run;

proc sql;
    create table sdc_gvkey as 
    select a.*, b.amanames, b.acusip, b.apublic, b.attitude, b.form,
            b.statuscode, b.dateann, b.dateeff, b.datefin, b.ebitltm, b.amv,entval,
            b.bookvalue, b.eqval,mv, b.netass, b.niltm, b.pct_cash, b.pct_stk,
            b.pct_other, b.pct_unknown, b.pr, b.rankval, b.salesltm, b.tmanames,
            b.tnationcode, b.tpublic, b.master_cusip, b.tticker
    from sdc_link a left join sdc_sort b
    on a.dealnumber = b.master_deal_no
    where missing(dateeff)=0 and missing(agvkey)=0
    group by a.dealnumber;
        /* Only matching observations & public acquirers */
run;


proc export data=sdc_gvkey outfile='/scratch/upenn/yaera/sdc_gvkey.csv' dbms=csv;
run;