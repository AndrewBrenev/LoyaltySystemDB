create or replace package 
cashback_analyzer is

  -- Author  : ¿Õƒ–≈…
  -- Created : 19.04.2020 14:25:00
  -- Purpose : process all cashback operations
  
  type cashback_list is table of cashback_log%rowtype;

  -- Public function and procedure declarations
 function getReportForMonth(p_period date) return cashback_list; 
 function getCashbackPersent(p_transaction TRANSACTIONS%rowtype) return number;
 function getCardId(p_hash Varchar2) return number;
 function getParentCardId(p_card_id number) return number;
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
      
   function getParentCardId(p_card_id number) return number is
     p_parent_id number;
     
     cursor cur_get_parent_card (p_id number) is
      select parant_card from cards where card_id = p_id;
   begin
     open cur_get_parent_card(p_card_id);
     fetch cur_get_parent_card into p_parent_id;
     close cur_get_parent_card;
     if p_card_id = p_parent_id then
       return p_card_id;
       else 
       return p_parent_id;
       end if;
   end;
   
   function getParentCardId(p_hash Varchar2) return number is
     v_card_id number;
     v_res number;
   begin
     v_card_id := cashback_analyzer.getCardId(p_hash);
     v_res := cashback_analyzer.getParentCardId(v_card_id);
     return v_res; 
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
    
     function getReportForMonth(p_period date) return cashback_list is 
      list cashback_list;
      begin
        return list;
      end;
     
procedure processNewReturnRow(p_return_row_id Number) is
     v_return transactions%rowtype;
     v_log_record   cashback_log%rowtype;
     v_card_id number;
     v_purcase_without_returns number;
     v_max_return_day  number;
     v_cur_day number;
     
     
    cursor cur_get_user_cashback(v_period date, v_card_id number) is
            select * from cashback_log  where 
            period = v_period and  card_id = v_card_id;
            
     cursor cur_sum_without_returns (p_parant_id number) is 
            select amount  - (select sum(amount)
                              from transactions
                              where parant_transaction = p_parant_id )
            from transactions 
            where transaction_id = p_parant_id;
  begin
    -- get the return row
      select * into v_return from transactions where transaction_id = p_return_row_id;
      -- parent card id
      v_card_id := cashback_analyzer.getParentCardId(v_return.card_id);
      
      --fetch log record
      open cur_get_user_cashback(trunc(v_return.trstn_date,'MONTH'),v_card_id);
      fetch cur_get_user_cashback into v_log_record;
      
      -- check sum of returns is less then purchase
      open cur_sum_without_returns(v_return.parant_transaction);
      fetch cur_sum_without_returns into v_purcase_without_returns;
      
      --get max return day
      select value into v_max_return_day from configs where name = 'return_date';
      
      --get current day
      v_cur_day := extract(day from v_return.trstn_date );
      
       if trunc(v_return.trstn_date,'MONTH') = v_log_record.period OR 
         add_months(trunc(v_return.trstn_date,'MONTH'),1) = v_log_record.period AND v_cur_day <= v_max_return_day
         then
      
      if v_purcase_without_returns >= 0  then
        update cashback_log set 
        amount = v_log_record.amount + v_purchase.cashback,
        operations_count = v_log_record.operations_count - 1
        where log_id = v_log_record.log_id;      
      end if;
      
      end if;
       close cur_get_user_cashback;
  end;
  
    procedure processNewPurchaseRow(p_purchase_row_id Number) is
     v_purchase transactions%rowtype;
     v_operation_log   cashback_log%rowtype;
     v_card_id number;
     v_new_row_id number;
     
     cursor cur_get_user_cashback(v_period date, v_card_id number) is
            select * from cashback_log  where 
            period = v_period and  card_id = v_card_id;
    begin
      select * into v_purchase from transactions where transaction_id = p_purchase_row_id;
      v_card_id := cashback_analyzer.getParentCardId(v_purchase.card_id);
      open cur_get_user_cashback(trunc(v_purchase.trstn_date,'MONTH'),v_card_id);
      fetch cur_get_user_cashback into v_operation_log;
      
      if cur_get_user_cashback%found then
        update cashback_log set 
        amount = v_operation_log.amount + v_purchase.cashback,
        operations_count = v_operation_log.operations_count + 1
        where log_id = v_operation_log.log_id;
        
      else
        select count(*) into v_new_row_id from cashback_log;
        insert into cashback_log
        values (v_new_row_id+1,1,v_purchase.cashback,trunc(v_purchase.trstn_date,'MONTH') , v_card_id);
      end if;
       close cur_get_user_cashback;
    end;

 procedure processNewOperation(p_trnctn_id Number) is
   v_trns_type varchar2(1);
   begin 
     select type into v_trns_type  from TRANSACTIONS where transaction_id = p_trnctn_id;
     case v_trns_type
      when 'P' then processNewPurchaseRow(p_trnctn_id);
      when 'R' then  processNewReturnRow(p_trnctn_id);
      else  raise_application_error(-20002,'Unknown transaction type "'||v_trns_type||'"');
     end case;
   end processNewOperation;
     
end cashback_analyzer;
/
