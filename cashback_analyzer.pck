create or replace package 
cashback_analyzer is

  -- Author  : ¿Õƒ–≈…
  -- Created : 19.04.2020 14:25:00
  -- Purpose : process all cashback operations


  -- Public function and procedure declarations
 function getCashbackPersent(p_transaction TRANSACTIONS%rowtype) return number;
 function getCardId(p_hash Varchar2) return number;
 function getParentCardId(p_hash Varchar2) return number;
 procedure processNewOperation(p_trnctn_id Number);

end 
cashback_analyzer;
/
create or replace package body 
cashback_analyzer is

 function getCardId(p_hash Varchar2) return number is
   p_card_id number;
   
   cursor cur_card_id ( p_hash varchar2) is
          select card_id from cards where pan = p_hash;
   begin 
     open cur_card_id (p_hash);
     fetch cur_card_id into p_card_id;
     close cur_card_id;
     return p_card_id;
     
     exception
       when no_data_found then
         DBMS_OUTPUT.put_line('Exception: there is no card with sha : '|| p_hash);
       when too_many_rows then
         DBMS_OUTPUT.put_line('Exception: there is more then one card in system with sha : '|| p_hash);
   end getCardId;
   
 function getParentCardId(p_hash Varchar2) return number is
     p_card_id number;
     p_parent_id number;
     
     cursor cur_get_parent_hash (p_id number) is
      select parant_card from cards where card_id = p_id;
   begin
     p_card_id := cashback_analyzer.getCardId(p_hash);
     open cur_get_parent_hash(p_card_id);
     fetch cur_get_parent_hash into p_parent_id;
     close cur_get_parent_hash;
     if p_card_id = p_parent_id then
       return p_card_id;
       else 
       return p_parent_id;
       end if;
   end;

 function getCashbackPersent(p_transaction TRANSACTIONS%rowtype) return number is
    v_cashback_prcnt number;
    begin  
      if p_transaction.type = 'P' then 
        if p_transaction.mrch_prog_id is not NULL then
           --return merchant_program
           select cashback_proc into v_cashback_prcnt from merchants_programs where merchant_id = p_transaction.mrch_prog_id; 
          elsif  p_transaction.mcc_prog_id is not NULL then
            --return mcc program
            select cashback_proc into v_cashback_prcnt from mcc_programs where mcc_id = p_transaction.mcc_prog_id; 
          elsif  p_transaction.mrch_prog_id is NULL and p_transaction.mcc_prog_id is null then
            --return default percent
            select value into v_cashback_prcnt from configs where name = 'default_procent';
          else
            raise no_data_found;
          end if;
          return v_cashback_prcnt;
       elsif p_transaction.type = 'P' then 
         DBMS_OUTPUT.put_line('Return has no cashback program');
       else 
        raise no_data_found;
      end if;
    end;
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
