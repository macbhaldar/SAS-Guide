* Correlation of all Variables
proc corr data=sashelp.iris;
run;

* Correlation between Two Variables
PROC CORR DATA=sample;
   VAR weight height;
RUN;

* Correlation Matrix
proc corr data=sashelp.iris plots=matrix(histogram);
run;

