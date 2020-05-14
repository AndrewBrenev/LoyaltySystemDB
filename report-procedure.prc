create or replace procedure generateReportForPeriod (p_period in Date) is
     log_list cashback_analyzer.cashback_list;
     v_max_cashback number;
     
     
     cursor max_cashback_cur is
            select value from configs where name = 'max_cashbañk_amount';
   begin
     -- get list cards with valid cashback from this month
     log_list := cashback_analyzer.getReportForMonth(p_period);
     
     if log_list is empty then
          DBMS_OUTPUT.PUT_LINE(' There is no card with cashback for period ' || to_char(p_period,'mm.yyyy') );
     else 
     open max_cashback_cur;
     fetch  max_cashback_cur into v_max_cashback;
     
     -- if max cashback limit is not setted
     if max_cashback_cur%notfound then
        DBMS_OUTPUT.PUT_LINE('! Warning : There is no cashback maximum limit.');
        v_max_cashback := 99999999999999;
     end if;    
     close max_cashback_cur;
     
     --form return file
     declare 
      v_new_file_id number;
      v_new_row_id number;
      v_card_hash  varchar2(40);
      
      v_report_id varchar2(40);
      
     begin
       v_report_id:= 'report' || to_char(p_period,'yyyymm');
       v_new_file_id := file_saver.createNewFile(v_report_id);
       
       --save the header
       v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
       'H;'||to_char(sysdate,'YYYYMMDDHH24MISS')||';'||to_char(p_period,'yyyymm'));
       
       for i in log_list.FIRST .. log_list.LAST
         loop
           if log_list(i).amount > v_max_cashback then
             log_list(i).amount := v_max_cashback;
           end if;
           
           select pan into v_card_hash from cards where card_id = log_list(i).card_id; 
           
            v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
            'C;'||v_card_hash||';'||log_list(i).amount);

        end loop;
        
        -- save the tail
         v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
         'T;'||log_list.count());
     end;
     end if;
   end generateReportForPeriod;
/
