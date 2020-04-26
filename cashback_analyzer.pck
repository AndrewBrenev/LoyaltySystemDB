create or replace package 
cashback_analyzer is

  -- Author  : ¿Õƒ–≈…
  -- Created : 19.04.2020 14:25:00
  -- Purpose : process all cashback operations


  -- Public function and procedure declarations
 procedure processNewOperation(p_trnctn_id Number);

end 
cashback_analyzer;
/
create or replace package body 
cashback_analyzer is

procedure processNewReturnRow(p_return_row_id Number) is
  begin
    DBMS_OUTPUT.put_line(' We are processing reurn now!');
  end;
  
  procedure processNewPurchaseRow(p_purchase_row_id Number) is
    begin
      DBMS_OUTPUT.put_line(' We are processing purchase now!');
    end;



 procedure processNewOperation(p_trnctn_id Number) is
   v_trns TRANSACTIONS%rowtype;
   begin 
     select * into v_trns  from TRANSACTIONS where transaction_id = p_trnctn_id;
   end processNewOperation;
     
end cashback_analyzer;
/
