PROC REG DATA = dataset;
MODEL variable1 = variable2;

* Linear Regression Between Two Variables
proc reg data=sashelp.class;
model weight= height ;
run;

