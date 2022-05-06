PROC PRINT DATA = LIB.zip_sub(OBS = 20);
RUN;

DATA LIB.MYCENSUS;
SET LIB.zip_sub;
where STATEABR = 'MI' and NIELCODE in ('A','B','C','D' );

RUN;

proc print data = LIB.MYCENSUS;
run;

%macro missvalue(dsn);
*checking for missing values and storing in a tem dataset;
proc means data = LIB.MYCENSUS ;
output nmiss= out = temp;
run;


proc print data = temp;
run;

proc means data=LIB.MYCENSUS n nmiss maxdec=0;
run;

data temp;
	set  LIB.&dsn;
	nummiss=nmiss(of &varlist);
run;

proc print data = temp;
run;

data missing;
	set  temp;
	if  nummiss>0;
run;


*count total number of missing values;
proc means data= missing sum ;
	var nummiss;
run;

proc means data = LIB.&dsn nmiss ;
run;

%mend missvalue;


%macro miss_var(dsn);

proc means data = LIB.&dsn nmiss noprint ;
output nmiss= out = temp_nmiss;
run;

%varlist(var_temp);

data temp_51(keep = &varlist);
set temp_nmiss;
run;

options nosymbolgen;
%global count miss_vars varlist1 cal_num;

%let miss_vars=;
%let varlist1=;


/* open the dataset */
 	%let dsid=%sysfunc(open(temp_51));

	/* count the number of variables in the dataset */
 	%let count=%sysfunc(attrn(&dsid,nvars));

%do i=1 %to &count;
		
	%let varlist1= %sysfunc(varname(&dsid,&i));
		
		data _null_;
		set temp_51;
		call SYMPUTX('miss_val', &varlist1);
		run;
		

		 %if &miss_val > 0 %then %do;
		
			 %let miss_vars = &miss_vars %sysfunc(varname(&dsid,&i));
			
		%end;

 	%end;
	%put '&miss_vars  ' &miss_vars;
	/* close the dataset */
 	%let rc=%sysfunc(close(&dsid));

	data miss_dataset(keep = &miss_vars count);
	set temp_51;
	count = sum(of &miss_vars);
	run;

	proc print data = miss_dataset;	
	title "variables with missing values and no of missing variables";
	run; 
	

%mend;

%macro delete_row_val(dsn);
	
	%miss_var(&dsn);

	data miss_delvar(keep = &miss_vars);
	set temp_51;
	run;

	options nosymbolgen;
 	
	%let varlist3=;

	/* open the dataset */
 	%let dsid=%sysfunc(open(miss_delvar));

	/* count the number of variables in the dataset */
 	%let cnt3=%sysfunc(attrn(&dsid,nvars));

	data lib.MYCENSUS_CLEAN;
	set lib.MYCENSUS;
	run;

 	%do i=1 %to &cnt3;
 		%let varlist3= %sysfunc(varname(&dsid,&i));
			
		DATA lib.MYCENSUS_CLEAN;
  			SET lib.MYCENSUS_CLEAN;
 			 IF  (&varlist3 ^= .);
			run;

 	%end;

	%let rc=%sysfunc(close(&dsid));

	
	proc means data = lib.MYCENSUS_CLEAN nmiss ;
	title "clean data with empty values delted";
	run;

%mend;



%macro varlist(dsn);

	options nosymbolgen;
 	%global varlist cnt;
	%let varlist=;

	/* open the dataset */
 	%let dsid=%sysfunc(open(&dsn));

	/* count the number of variables in the dataset */
 	%let cnt=%sysfunc(attrn(&dsid,nvars));

 	%do i=1 %to &cnt;
 		%let varlist=&varlist %sysfunc(varname(&dsid,&i));
 	%end;

	/* close the dataset */
 	%let rc=%sysfunc(close(&dsid));
	%put &varlist;
	
%mend varlist;

%macro standardize(dsn=, nc=, method=);


%if %bquote(%upcase(&method))=NONE %then %do;
	data temp;
		set lib.&dsn;
	run;
%end;
%else %do;
	proc stdize data=lib.&dsn method=&method out=temp;
		var &inputs;
	run;
%end;

proc fastclus data=temp maxc=&nc out=clusters noprint;
	var &inputs;
run;

title1 "Method: %upcase(&method)";
proc freq data=clusters;
	tables &group*cluster/norow nocol nopercent chisq out=temp;
	output chisq out=stats;
run;

data sum;
	set temp(where=(cluster NE .)) end=eof;
	by &group;
	retain members mode;
	if first.&group then do;
		members=0; 
		mode=0;
	end;
	members+count;		
	if count > mode then mode=count;
	if last.&group then	misc+(members-mode);
	if eof then output sum;
run;

data results;
	merge sum(keep=misc) stats;
	if 0 then modify results;
	method="&method";
	misclassified=misc;
	chisq=_pchi_;
	pchisq=p_pchi;
	cramersv=round(_cramv_,0.00001);
	output results;
run;

proc print data = results;
run;

%mend standardize;

*Declaring the Cluster Macro;
%macro cluster(method1=,method2=, dsn=);

	proc distance data=LIB.&dsn method= &method1 out=temp61;
       var interval(&inputs/std=range);    
run; 

/* generate hierarchical clustering solution (Ward's method)*/
proc cluster data= temp61 outtree=tree method= &method2;
run;

/*proc tree horizontal;
run;*/
%mend cluster;





*- program execution starts-;
data var_temp(drop = STATEABR NIELCODE zipcode);
	set LIB.MYCENSUS;
	run;

%varlist(var_temp);

*to display no of missing values;
%missvalue(MYCENSUS);
%miss_var(MYCENSUS);


/**** if choose to delete the record   OUTPUT = LIB.MYCENSUS_CLEAN;

%delete_row_val(MYCENSUS);

*****/

*  if choose to Standardizing the data;
PROC STANDARD DATA=lib.MYCENSUS REPLACE OUT=lib.MYCENSUS_CLEAN;
RUN;

*check the missing values in MYCENSUS_CLEAN ;
%missvalue(MYCENSUS_CLEAN);
%miss_var(MYCENSUS_CLEAN);

*getting variable names for varclus clustering;
%varlist(var_temp);

ods graphics on;
*proc varclus to find the clusters;
proc varclus data=lib.MYCENSUS_CLEAN outtree=tree maxeigen=1.0;
	var &varlist;
run;

%let group  = zipcode ;
%global inputs;
*most impactful variables from clusters;
%let inputs = OOHVI PRCNCD3 PRC65P PRCTHRE PRCWHTE PRC200K MEDSCHYR;
data results;
	length method$ 12;
	length misclassified 8;
	length chisq 8;
	length pchisq 8;
	length cramersv 8;
	stop;
run;
ods graphics off;
* test to find the appropriate standardize method ;
%standardize(dsn=MYCENSUS_CLEAN,nc=7,method=EUCLEN);
%standardize(dsn=MYCENSUS_CLEAN,nc=7,method=IQR);
%standardize(dsn=MYCENSUS_CLEAN,nc=7,method=MAXABS);
%standardize(dsn=MYCENSUS_CLEAN,nc=7,method=MEAN);
%standardize(dsn=MYCENSUS_CLEAN,nc=7,method=MEDIAN);

proc sort data=results;
	by descending cramersv misclassified;
run;

title1 'Results';
proc print data=results;
	var method cramersv misclassified ;
run;
*Standardizing with IQR afer the check;
proc 	 data=lib.MYCENSUS_CLEAN method=IQR out=lib.MYCENSUS_STD;
		var &inputs;
	run;

*creating the sample data of 300 obs using survey select;
proc surveyselect data = lib.MYCENSUS_CLEAN out = lib.MYCENSUS_SAMPLE method = srs n=300 seed=12;
run;


proc print data =   lib.MYCENSUS_SAMPLE;
run;

*to create the rest of the dataset for scoring;
DATA holdout1;
 MERGE lib.MYCENSUS_CLEAN (IN=A) lib.MYCENSUS_SAMPLE (IN=B);
 BY zipcode;
IF A AND NOT B;
RUN;

proc print data = holdout1;
run;

* Check for distance and cluster method based on Root-Mean-Square Distance;
%cluster(method1=EUCLID,method2=ward,dsn=MYCENSUS_SAMPLE);
%cluster(method1=CITYBLOCK,method2=ward, dsn=MYCENSUS_SAMPLE);
%cluster(method1=SQEUCLID,method2=ward,dsn=MYCENSUS_SAMPLE);
%cluster(method1=EUCLID,method2=CENTROID,dsn=MYCENSUS_SAMPLE);
%cluster(method1=CITYBLOCK,method2=CENTROID,dsn=MYCENSUS_SAMPLE);
%cluster(method1=SQEUCLID,method2=CENTROID,dsn=MYCENSUS_SAMPLE);
%cluster(method1=SQEUCLID,method2=AVERAGE,dsn=MYCENSUS_SAMPLE);


*runing proc distance with cityblock after the check of root mean square distance;
proc distance data=lib.MYCENSUS_SAMPLE method=EUCLID out=lib.MYCENSUS_SAMPLE_DIST;
	var interval(&inputs/std=range); 
copy zipcode;
run;


*running proc cluster;
proc cluster data= lib.MYCENSUS_SAMPLE_DIST outtree=tree method= ward;
ID zipcode;
run;
*printing the dendogram;
proc tree data = tree  N =6 out=treedata  ;
copy zipcode;
run;


*running proc freq for tree data;
proc freq data = treedata; 
tables zipcode*cluster;
run;

data final(drop = _NAME_);
set treedata;
run;
*zipcode, cluster, cluster name;
proc print data = final;
run;


data sample_com(keep = &inputs zipcode);
set lib.MYCENSUS_SAMPLE;
run;

proc sort data=final;
	by zipcode;
run;

proc sort data =  sample_com;
by zipcode;
run;

*merging two the sample output dataset with the standardized dataset and impactful variables;
data ulti;
merge sample_com final;
by zipcode;
run;

proc print data = ulti;
run;
*scatter plot for all the impact variables in cluster;
proc sgscatter data = ulti;
	matrix &inputs/ group = cluster;
run;
*scatter plot for all the impact variables in zipcode;
proc sgscatter data = ulti;
	matrix &inputs/ group = zipcode;
run;
