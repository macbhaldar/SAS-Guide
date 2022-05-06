* One Way Chi-Square Test
proc freq data = sashelp.cars;
tables origin /chisq
testp=(0.35 0.40 0.25);
run;

* Two Way Chi-Square Test
proc freq data = sashelp.cars;
tables origin*drivetrain /chisq ;
run;

