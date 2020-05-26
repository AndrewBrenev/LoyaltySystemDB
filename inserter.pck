create or replace package inserter is

  -- Author  : ¿Õƒ–≈…
  -- Created : 19.04.2020 10:19:58
  -- Purpose : insert file rows into tables & check data validity
  
  -- Public function and procedure declarations
  function insertPurchase(p_data row_parser.purchase_row,p_row_id number) return number;
  function insertReturn(p_data in row_parser.return_row,p_row_id number) return number;

end inserter;
/
create or replace package body inserter is

function insertPurchase(p_data in row_parser.purchase_row,p_row_id number) return number is
   v_new_id NUMBER;
   v_mcc_id NUMBER;
   v_merchant_id NUMBER;
   v_mcc_prog_id NUMBER;
   v_merchant_prog_id NUMBER;
   v_cashback_procent number;
   v_card_id number;
   v_files_rows_cout number;
   
   programm_found_flag boolean := false;
   
   cursor cur_mcc_id (p_mcc NUMBER) is 
    select mcc_id from mcc where mcc_code = p_mcc;
    
   cursor cur_merchant_id (p_mrch_comp Varchar2) is 
    select merchant_id from MERCHANTS where company = p_mrch_comp;
   
   cursor cur_mcc_prog_except (p_mcc_id number,p_date date ) is 
    select mcc_prog_id
    from MCC_PROGRAMS
    where mcc_id = p_mcc_id AND begin_date <= p_date AND end_date >=  p_date and cashback_proc  = 0;
   
   cursor cur_mcc_prog (p_mcc_id number,p_date date ) is 
    select mcc_prog_id
    from MCC_PROGRAMS
    where 
    mcc_id = p_mcc_id AND begin_date <= p_date AND end_date >=  p_date and cashback_proc  > 0; 
    
   cursor cur_merch_prog_except (p_merch_id number,p_date date ) is 
    select merch_prog_id
    from merchants_programs
    where merch_prog_id = p_merch_id AND begin_date <= p_date AND end_date >=  p_date and cashback_proc  = 0;
   
   cursor cur_merch_prog (p_merch_id number,p_date date ) is 
    select merch_prog_id
    from merchants_programs
    where merch_prog_id = p_merch_id AND begin_date <= p_date AND end_date >=  p_date and cashback_proc  > 0;
    
   cursor cur_def_proc is
    select value from configs where name = 'default_procent';
   
   begin
     select count(*) into v_new_id from TRANSACTIONS;
     select count(*) into v_files_rows_cout from file_data;
     if p_row_id > v_files_rows_cout then 
       raise TOO_MANY_ROWS;
     end if;
     begin
       select card_id into v_card_id from cards where pan = p_data.card_id;
     exception
       when no_data_found then
         raise_application_error(-20001,'Incorrect card id "'||p_data.card_id||'"');
       when too_many_rows then
         DBMS_OUTPUT.put_line('Exception: there is more then one card in system with sha : '|| p_data.card_id);
     end;
     
     -- Get mcc id    
     open cur_mcc_id(p_data.mcc);
     fetch cur_mcc_id into v_mcc_id;
     if cur_mcc_id%notfound then
       raise_application_error(-20001,'Incorrect mcc "'||p_data.mcc||'". This mcc is not loaded into system.');
     end if;
     close cur_mcc_id;
     
     --get merchant id
     open cur_merchant_id(p_data.merchant);
     fetch cur_merchant_id into v_merchant_id;
     if cur_merchant_id%notfound then
       raise_application_error(-20001,'Unknown merchant "'||p_data.merchant||'". This merchant is not loaded into system.');
     end if;
     close cur_merchant_id;
     
     --check merchant exception program;
     open cur_merch_prog_except(v_merchant_id,p_data.purchase_date);
     fetch cur_merch_prog_except into v_merchant_prog_id;
     if cur_merch_prog_except%found then
       programm_found_flag := true;       
       insert into TRANSACTIONS 
       values (v_new_id+1,'P',p_data.purchare_id ,null,p_data.amount,p_data.purchase_date,v_card_id,v_merchant_prog_id,null,p_row_id,0);
     end if;
     close cur_merch_prog_except;
     
     -- check mcc exception program;
     if not programm_found_flag then
       open cur_mcc_prog_except(v_mcc_id,p_data.purchase_date);
       fetch cur_mcc_prog_except into v_mcc_prog_id;
       if cur_mcc_prog_except%found then
         programm_found_flag := true;
         insert into TRANSACTIONS 
         values (v_new_id+1,'P',p_data.purchare_id,null,p_data.amount,p_data.purchase_date,v_card_id,null,v_mcc_prog_id,p_row_id,0);
       end if;
       close cur_mcc_prog_except;
     end if; 
     
     --process merchant program
     if not programm_found_flag then
        open cur_merch_prog(v_merchant_id,p_data.purchase_date);
        fetch cur_merch_prog into v_merchant_prog_id;
        if cur_merch_prog%found then
          programm_found_flag := true;
          
          select mp.cashback_proc into v_cashback_procent
          from MERCHANTS_PROGRAMS mp 
          where mp.merch_prog_id= v_merchant_prog_id;
          
          insert into TRANSACTIONS values
          (v_new_id+1,'P',p_data.purchare_id,null,p_data.amount,p_data.purchase_date,v_card_id,v_merchant_prog_id,null,p_row_id,p_data.amount*v_cashback_procent / 100);
        end if;
        close cur_merch_prog;
     end if;
     
     --process mcc program
     if not programm_found_flag then
        open cur_mcc_prog(v_mcc_id,p_data.purchase_date);
        fetch cur_mcc_prog into v_mcc_prog_id;
        if cur_mcc_prog%found then
          programm_found_flag := true;
          select mp.cashback_proc into v_cashback_procent
          from mcc_programs mp 
          where mp.mcc_prog_id = v_mcc_prog_id;
          
          insert into TRANSACTIONS values
          (v_new_id+1,'P',p_data.purchare_id,null,p_data.amount,p_data.purchase_date,v_card_id,null,v_mcc_prog_id,p_row_id,p_data.amount*v_cashback_procent / 100);
        end if;
        close cur_mcc_prog;
     end if;
     
     --default procent
     if  not programm_found_flag then
       open cur_def_proc;
       fetch cur_def_proc into v_cashback_procent;
       insert into transactions values 
       (v_new_id+1,'P',p_data.purchare_id,null,p_data.amount,p_data.purchase_date,v_card_id,null,null,p_row_id,p_data.amount*v_cashback_procent / 100);
       close cur_def_proc;
     end if;
     -- in any case process incoming transaction
     cashback_analyzer.processNewOperation(v_new_id+1);
     
     return v_new_id+1;
 exception 
   when no_data_found then
     raise_application_error(-20001,sqlerrm);
  when too_many_rows then
    raise_application_error(-20001,sqlerrm);
 end insertPurchase;
   
function insertReturn(p_data in row_parser.return_row,p_row_id number) return number is
     v_new_id NUMBER;
     v_merchant_id NUMBER;
     v_cashback_procent number;
     v_card_id number;
     v_files_rows_cout number;
     v_parent_transaction transactions%rowtype;
     
     v_purcase_without_returns number;
      
      cursor cur_sum_without_returns (p_parant_id number) is 
            select amount  - (select sum(amount)
                              from transactions
                              where parant_transaction = p_parant_id )
            from transactions 
            where transaction_id = p_parant_id;
     
     cursor cur_merchant_id (p_mrch_comp Varchar2) is
            select merchant_id from MERCHANTS where company = p_mrch_comp;
    
    begin
       select count(*) into v_new_id from TRANSACTIONS;
       select count(*) into v_files_rows_cout from file_data;
       if p_row_id > v_files_rows_cout then 
         raise_application_error(-20001,'Table "FILE_DATA" does not contain row '||p_row_id);
       end if;
       v_new_id:= v_new_id+1;
       v_card_id := cashback_analyzer.getCardId(p_data.card_id);
       select * into v_parent_transaction from transactions where HASH = p_data.purchase_id;
       
        -- check sum of returns is less then purchase
      open cur_sum_without_returns(v_parent_transaction.transaction_id);
      fetch cur_sum_without_returns into v_purcase_without_returns;
      
      if v_purcase_without_returns < 0 then
        raise_application_error(-20001,'Sum of returns is greater then amount of purchase.' );   
      end if;
      
      if v_parent_transaction.trstn_date > p_data.return_date then
         raise_application_error(-20001,'Return transaction occurred before purchase.' );
      end if;
      
       
       v_cashback_procent := cashback_analyzer.getCashbackPersent(v_parent_transaction);
       
     --get merchant id for check, then such merchant exsists;
     open cur_merchant_id(p_data.merchant);
     fetch cur_merchant_id into v_merchant_id;
     if cur_merchant_id%notfound then
       raise_application_error(-20001,'Unknown merchant:"'||p_data.merchant||'".');
     end if;
     close cur_merchant_id;
     
     insert into TRANSACTIONS 
       values (v_new_id,'R',p_data.return_id ,v_parent_transaction.transaction_id,p_data.amount,p_data.return_date,v_card_id,null,null,p_row_id,
       -p_data.amount*v_cashback_procent/100 );
    
     cashback_analyzer.processNewOperation(v_new_id);
     return v_new_id;
     
      exception 
        when no_data_found then
          raise_application_error(-20001,sqlerrm);
        when DUP_VAL_ON_INDEX then
          raise_application_error(-20001,sqlerrm);
        when too_many_rows then
          raise_application_error(-20001,sqlerrm);
     
    end insertReturn;

end inserter;
/
