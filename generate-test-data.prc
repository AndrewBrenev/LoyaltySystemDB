create or replace procedure generateTestData(test_size in number)   is
 const_max_amount number := 300000;

 new_file_id number;
 new_row_id number;
 
 files_count number;
 file_rows_count number;
 
 file_name varchar2(40);
 file_hash varchar2(12);
 
 p_count number;
 r_count number;
begin
  files_count :=  round(dbms_random.value(1,20));
  file_rows_count := round ( test_size / files_count);
  
   for i in 1..files_count loop
     --create file
     file_name := 'test_'|| dbms_random.string('l',8)||'.csv';
     file_hash := dbms_random.string('x',12);
     new_file_id := file_saver.createNewFile(file_name,file_hash,true);
     
      p_count := 0;
      r_count := 0;
     --create header
      new_row_id := file_saver.insertRowIntoFile(new_file_id,'H;'||file_hash||';'||to_char(sysdate,'YYYYMMDDHH24MISS'));
                 
      declare
       transaction_type number; -- 0 - 'P'; 1 - 'R'; 
       v_res_str varchar2(500);
       tmp_str varchar2(40);
       
       rand_tmp number;
       tmp_count number; 

      begin
        for j in 1 .. file_rows_count loop
          transaction_type :=  round(dbms_random.value(0,1));
          if transaction_type = 0 then
            --create purcase
            v_res_str := 'P;';
            
            --select new card
            select count(*) into tmp_count from cards; 
            rand_tmp := round(dbms_random.value(1,tmp_count));
            select pan into tmp_str from cards where card_id = rand_tmp;
            v_res_str := v_res_str || tmp_str || ';';
            
             --transaction id
            v_res_str := v_res_str || dbms_random.string('x',12) || ';';
            
            --add purchase date
            rand_tmp := dbms_random.value(0,10);
            v_res_str := v_res_str || to_char(sysdate - rand_tmp ,'YYYYMMDDHH24MISS') || ';';
            
            -- add amount
            rand_tmp := round(dbms_random.value(0,const_max_amount));
            v_res_str := v_res_str || rand_tmp || ';';
            
            --add merchant
            select count(*) into tmp_count from merchants;
            rand_tmp := round(dbms_random.value(1,tmp_count));
            select company into tmp_str from merchants where merchant_id = rand_tmp;
            v_res_str := v_res_str || tmp_str || ';';
            
            --add mcc
            select count(*) into tmp_count from mcc; 
            rand_tmp := round(dbms_random.value(1,tmp_count));
            select mcc_code into tmp_str from mcc where mcc_id = rand_tmp;
            v_res_str := v_res_str || tmp_str || ';'; 
            
            new_row_id := file_saver.insertRowIntoFile(new_file_id,v_res_str);
            
            p_count := p_count + 1;

          else
            --create return
            v_res_str := 'R;';
            
            --select new card
            select count(*) into tmp_count from cards; 
            rand_tmp := round(dbms_random.value(1,tmp_count));
            select pan into tmp_str from cards where card_id = rand_tmp;
            v_res_str := v_res_str || tmp_str || ';';
            
            --transaction id
            v_res_str := v_res_str || dbms_random.string('x',12) || ';';
            
            --add purchase date
            rand_tmp := dbms_random.value(0,10);
            v_res_str := v_res_str || to_char(sysdate - rand_tmp ,'YYYYMMDDHH24MISS') || ';';
            
            -- add amount
            rand_tmp := round(dbms_random.value(0,const_max_amount));
            v_res_str := v_res_str || rand_tmp || ';';
            
            --add merchant
            select count(*) into tmp_count from merchants;
            rand_tmp := round(dbms_random.value(1,tmp_count));
            select company into tmp_str from merchants where merchant_id = rand_tmp;
            v_res_str := v_res_str || tmp_str || ';';
            
            --get random purchase transaction
            select hash
            into tmp_str
            from (
                   select hash
                   from transactions
                   where type = 'P'
                   order by dbms_random.value )
            where rownum = 1;
            
            v_res_str := v_res_str || tmp_str || ';';
            
            new_row_id := file_saver.insertRowIntoFile(new_file_id,v_res_str);

            r_count := r_count + 1;
          end if;
        end loop;
      end;
      
      --save tailer
       new_row_id := file_saver.insertRowIntoFile(new_file_id,'T;'||p_count||';'||r_count);
       
  end loop;
end generateTestData;
/
