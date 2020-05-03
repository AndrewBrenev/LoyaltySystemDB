PL/SQL Developer Test script 3.0
26
-- Created on 01.05.2020 by ÀÍÄĞÅÉ 
declare
  return_test_data row_parser.return_row;
  test_data row_parser.purchase_row;
  row_id number := 1;
      
begin
  test_data.card_id :='22fcf0cd2cf07841d4214d6a14b2b28c1e15be24';
  test_data.purchare_id := 12345678;
  test_data.purchase_date := to_date( '20200430','yyyymmdd');
  test_data.amount :=  150000;
  test_data.merchant := 'Gigant 12';
  test_data.mcc := 5411;
  test_data.p_comment := ' Êàññà 7 Òåğìèíàë 71';
  --row_id := inserter.insertPurchase(test_data,row_id);

  return_test_data.card_id := '22fcf0cd2cf07841d4214d6a14b2b28c1e15be24';
  return_test_data.return_id  := '13579R1';
  return_test_data.return_date :=  to_date( '20200430','yyyymmdd');
  return_test_data.amount := 2000;
  return_test_data.merchant := 'LENTA1234';
  return_test_data.purchase_id := '12345678';
  
  row_id := inserter.insertReturn(return_test_data,row_id);

end;
0
0
