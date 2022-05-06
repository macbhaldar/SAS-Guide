/*This code reads in data and transforms variables to be used for regression. */

libname LogReg 'C:\Users\Public';

/*data import*/
proc import datafile='C:\Users\Public\Data.csv' 
	out=LogReg.Data dbms=csv replace;
run;

/*dropping the sequence number variable seqnum*/
data LogReg.Data_temp;
set LogReg.Data;
drop seqnum LogReg.Data;
run;

/***resetting ordinal variables**/
data LogReg.Data2;
set  LogReg.Data;

*******************************************************;
array origf[10](0, 1, 2,  3,  4,  5,   6,   7,    8,    9);
array newf[10] (0,25,75,150,350,750,3000,7500,15000,30000);
retain origf1-origf10 newf1-newf10; 
do i=1 to dim(origf); 
 if PWAPAR=origf[i] then PWAPAR2=newf[i];
 if PAANHA=origf[i] then PAANHA2=newf[i];
 if PPERSA=origf[i] then PPERSA2=newf[i];
end;
drop origf1--origf10 newf1--newf10 i; 
*******************************************************;

array orig[10](0,  1, 2, 3, 4, 5, 6, 7, 8,  9);
array new[10] (0,5.5,17,30,43,56,69,82,94,100);
retain orig1-orig10 new1-new10; 
do i=1 to dim(orig); 
if MAUT1  =orig[i] then MAUT12 =new[i];
if MAUT2  =orig[i] then MAUT22 =new[i];
if MAUT0  =orig[i] then MAUT02 =new[i];
if MFALLE =orig[i] then MFALLE2 =new[i];
if MFWEKI =orig[i] then MFWEKI2 =new[i];
if MGODPR =orig[i] then MGODPR2 =new[i];
if MGODRK =orig[i] then MGODRK2 =new[i];
if MHHUUR =orig[i] then MHHUUR2 =new[i];
if MINKGE =orig[i] then MINKGE2 =new[i];
if MOPLHO =orig[i] then MOPLHO2 =new[i];
if MRELGE =orig[i] then MRELGE2 =new[i];
if MSKA   =orig[i] then MSKA2 =new[i];
if MSKB1  =orig[i] then MSKB12 =new[i];
if MSKB2  =orig[i] then MSKB22 =new[i];
if MSKC   =orig[i] then MSKC2 =new[i];

end;
drop orig1--orig10 new1--new10 i;
*************************************************;
run;

/*deleting the old ordinal variables*/
data LogReg.Data3;
set  LogReg.Data2;
drop PAANHA
PPERSA
PWAPAR
MGODRK
MGODPR
MRELGE
MFALLE
MFWEKI
MOPLHO
MSKA
MSKB1
MSKB2
MSKC
MHHUUR
MAUT1
MAUT2
MAUT0
MINKGE
;
run;

/**resetting categorical to binary variables using macros*/
data LogReg.Data4;
set LogReg.Data3;

%macro binarycreate(varname, numcat);
%do i=1 %to &numcat;
if &varname =&i then &varname&i=1; else &varname&i=0;
%end;
%mend;

%binarycreate(moshoo, 10);
%binarycreate(mostyp, 41);
%binarycreate(mgemle, 10);

drop moshoo mostyp mgemle;

run;

/*dropping the variables which are not significant - have very less std dev*/
data LogReg.model_vars;
set LogReg.Data4 (drop=AMOTSC APERSA AWAPAR moshoo2 moshoo4 mostyp4 mostyp5 mostyp6 mostyp7 mostyp19 mostyp22 mostyp24 mostyp25 mostyp27 mostyp35 mostyp36 mostyp37 mostyp38 mostyp39 mostyp40 mostyp41 mgemle7 mgemle8 mgemle9 mgemle10);
run;

/*dataset model_vars has the final set of variables to be used for modelling*/

/*creating test and training data*/
data LogReg.model_ds;
set  LogReg.model_vars;

rand=ranuni(092765);
testdata=0;
if rand <=.7 then Resptest=.;
else if rand  >.7 then do;
	testdata=1;
    Resptest=Resp;
   	Resp=.;
end;
run;

/*creating standardized dataset with mean=0 and sd=1 to get standardized estimates*/
proc standard data=LogReg.model_vars MEAN=0 STD=1 replace out=LogReg.model_vars_std (drop= seqnum);
run;
/*creating test and training data for standardized data*/

data LogReg.model_ds_std;
set  LogReg.model_vars_std;

rand=ranuni(092765);
testdata=0;
if rand <=.7 then Resptest=.;
else if rand  >.7 then do;
	testdata=1;
    Resptest=Resp;
   	Resp=.;
end;
run;

/*logistic model 1*/
*Model Iteration 1: all variables and non standardized data;
proc logistic data=LogReg.model_ds descending;
model resp=
MAUT02
MAUT12
MAUT22
MFALLE2
MFWEKI2
MGEMOM
MHHUUR2
MINKGE2
MOPLHO2
MRELGE2
MGODRK2
MGODPR2
MSKA2
MSKB12
MSKB22
MSKC2
PAANHA2
PPERSA2
PWAPAR2
mgemle1
mgemle2
mgemle3
mgemle4
mgemle5
mgemle6
moshoo1
moshoo3
moshoo5
moshoo6
moshoo7
moshoo8
moshoo9
moshoo10
mostyp1
mostyp2
mostyp3
mostyp8
mostyp9
mostyp10
mostyp11
mostyp12
mostyp13
mostyp14
mostyp15
mostyp16
mostyp17
mostyp18
mostyp20
mostyp21
mostyp23
mostyp26
mostyp28
mostyp29
mostyp30
mostyp31
mostyp32
mostyp33
mostyp34
/selection=stepwise;
output out=LogReg.scored p=pred;
run;

/*logistic model 2*/
*Model Iteration 2: all variables and standardized data;

proc logistic data=LogReg.model_ds_std descending;
model resp=
MAUT02
MAUT12
MAUT22
MFALLE2
MFWEKI2
MGEMOM
MHHUUR2
MINKGE2
MOPLHO2
MRELGE2
MSKA2
MSKB12
MSKB22
MSKC2
PAANHA2
PPERSA2
PWAPAR2
mgemle1
mgemle2
mgemle3
mgemle4
mgemle5
mgemle6
moshoo1
moshoo3
moshoo5
moshoo6
moshoo7
moshoo8
moshoo9
moshoo10
mostyp1
mostyp2
mostyp3
mostyp8
mostyp9
mostyp10
mostyp11
mostyp12
mostyp13
mostyp14
mostyp15
mostyp16
mostyp17
mostyp18
mostyp20
mostyp21
mostyp23
mostyp26
mostyp28
mostyp29
mostyp30
mostyp31
mostyp32
mostyp33
mostyp34
/selection=stepwise;
output out=LogReg.scored_std p=pred;
run;

/*creating data for gains chart*/
proc sort data=LogReg.scored;
by testdata;
run;

proc rank data=LogReg.scored groups=10 ties=high out=LogReg.scoredrank;
by testdata;
var pred;
ranks mscore;
run;

proc sql;
create table LogReg.tt as
select ((100-mscore)/100) as rank, ((100-mscore)/100) as random, sum(resp) as resp_development, sum(resptest) as resp_test
from LogReg.scoredrank
group by 1,2
order by 1,2
;
quit;

proc sql;
create table tt_10_3 as 
select distinct(
(mscore = 9)) as rank,
mean(mostyp15) as of_single_Youth ,
mean(mostyp17) as Driven_Growers, 
mean(mostyp28) as Cruising_Seniors,
mean(MRELGE2) as singles,
mean(MSKB12)as High_lvl_ed, 
mean(moshoo9) as avg_families
from LogReg.scoredrank
group by rank 
order by rank;
quit;

/*creating data for gains chart*/
proc sort data=LogReg.scored_std;
by testdata;
run;

proc rank data=LogReg.scored_std groups=100 ties=high out=LogReg.scoredrank_std;
by testdata;
var pred;
ranks mscore;
run;

proc sql;
create table LogReg.tt_std as
select ((100-mscore)/100) as rank, ((100-mscore)/100) as random, sum(resp) as resp_development, sum(resptest) as resp_test
from LogReg.scoredrank_std
group by 1,2
order by 1,2
;
quit;

/*save the model for execution*/

proc logistic data=LogReg.model_ds descending
			outmodel=LogReg.log_resp_model;
model resp= mostyp28 moshoo9 mgodrk2 mgodpr2 mostyp17 MSKB12;
run;
quit;
