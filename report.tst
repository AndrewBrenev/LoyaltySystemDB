PL/SQL Developer Test script 3.0
8
-- Created on 13.05.2020 by ÀÍÄĞÅÉ 
declare 
test_period date;
test_return cashback_analyzer.cashback_list;  
begin
  test_period := to_date('13052020','ddmmyyyy');
  test_return := cashback_analyzer.getReportForMonth(test_period);
end;
0
0
