create or replace package inserter is

  -- Author  : ¿Õƒ–≈…
  -- Created : 19.04.2020 10:19:58
  -- Purpose : insert file rows into tables & check data validity
  
  -- Public function and procedure declarations
  procedure processHeader(p_data row_parser.header_row);
  procedure insertPurchase(p_data row_parser.purchase_row,p_row_id number) ;
  procedure insertReturn(p_data row_parser.return_row,p_row_id number);

end inserter;
/
create or replace package body inserter is
procedure processHeader(p_data row_parser.header_row) is
  unique_flag boolean := true;
  begin
    DBMS_OUTPUT.put_line('Wow! We are processing header now!');
  end;
  
 procedure insertPurchase(p_data in row_parser.purchase_row,p_row_id number) is
   v_new_id NUMBER;
   v_mcc_id NUMBER;
   v_merchant_id NUMBER;
   v_mcc_prog_id NUMBER;
   v_merchant_prog_id NUMBER;
   v_def_coef NUMBER;
   begin
     select count(*) into v_new_id from TRANSACTIONS;
     select mcc_id into   v_mcc_id  from mcc where mcc_code = p_data.mcc;
     select merchant_id into v_merchant_id from MERCHANTS where company = p_data.merchant;
     
     select mcc_prog_id into v_mcc_prog_id from MCC_PROGRAMS where 
     mcc_id = v_mcc_id AND begin_date <= p_data.purchase_date AND end_date >=  p_data.purchase_date;
     
     select merch_prog_id into v_merchant_prog_id from MERCHANTS_PROGRAMS where 
     merchant_id = v_merchant_id AND begin_date <= p_data.purchase_date AND end_date >=  p_data.purchase_date;
     
     select value into v_def_coef from configs where name = 'default_procent';
/*  
     insert into TRANSACTIONS values
     (new_id+1,'P',null,p_data.amount,p_data.purchase_date,card_id,merchant_prog_id,mcc_prog_id,p_row_id);
*/  
 cashback_analyzer.processNewOperation(v_new_id+1);
 end insertPurchase;
   
  procedure insertReturn(p_data in row_parser.return_row,p_row_id number)is
    begin
      DBMS_OUTPUT.put_line('Return '||p_data.return_id||' '||p_row_id);
    end insertReturn;

end inserter;
/
