PROC ANOVA dataset;
CLASS Variable;
MODEL Variable1=variable2;
MEANS;

data marriage;
            input region $ age;
cards;
S          27
S          22
S          22
S          24
N          24
N          27
N          28
N          30
E          33
E          29
E          30
E          27
W          34
W          35
W          37
W          29
;
run; 
%* ANOVA using SAS; 
proc anova data=marriage;
 class region;
 MODEL  age =region;
run;
