create or replace procedure processNewFiles as
   
   type purchases_list is table of row_parser.purchase_row index by pls_integer;
   type returns_list is table of row_parser.return_row  index by pls_integer;
   new_purchases purchases_list;
   new_returns returns_list;
  
   new_data row_parser.file_row; 

   type file_row_data is table of FILE_DATA%rowtype;
   new_rows file_row_data := file_row_data();
   
   type files_data is table of FILES%rowtype;
   new_fils files_data := files_data();
  
   cursor cur_new_files is 
         select *
         from FILES
         where type = 'input' and status = 'new'; 
   
   cursor cur_new_rows (p_id Number )is 
         select *
         from FILE_DATA
         where file_id = p_id AND status = 'new'
         order by row_id; 
         
  v_limit number := 100;
begin
  

  -- fetch new files from bank
  open cur_new_files;
  loop
    FETCH cur_new_files BULK COLLECT INTO new_fils limit v_limit;
       
    -- actions with new files
    FOR i IN new_fils.FIRST .. new_fils.LAST
    LOOP
      savepoint previous_file_condition;
      
      declare
        header_found boolean;
        closer_found boolean;
        closer_p_count number := 0;
        closer_r_count number := 0;
        
        v_cur_collection_iteam number;
        
        v_e_rows_count number :=0;
        v_s_rows_count number :=0;
       
        v_new_file_id number;
        v_new_row_id number;
      
        v_report_id varchar2(40);
      begin
        open cur_new_rows(new_fils(i).file_id);
        
        v_report_id:= 'report_' || new_fils(i).file_id||'.csv';
        v_new_file_id := file_saver.createNewFile( v_report_id, 'RP'||new_fils(i).file_id||'LY');
          
        --save header
        v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
        'H;'|| new_fils(i).file_hash || ';' ||to_char(sysdate,'YYYYMMDDHH24MISS'));
        
                            
        new_purchases.delete();
        new_returns.delete();
        
        --process file contain
        loop
          FETCH cur_new_rows BULK COLLECT INTO new_rows  limit v_limit;

           for j in new_rows.FIRST .. new_rows.LAST
             loop
               --parse text row to object
               new_data := row_parser.parseRow(new_rows(j).value,';');
               
               case new_data.row_type
                 when 'H' then
                   if new_returns.count = 0 and new_purchases.count = 0 then
                      header_found := true;
                      update FILE_DATA set
                     status = 'processed'
                     where row_id = new_rows(j).row_id;
                   else
                     raise_application_error(-20002,'Wrong file structure. H record is not firsrt row in  file.');
                   end if;
                 when 'P' then
                   new_purchases(new_rows(j).row_id) := new_data.p;
                   closer_p_count := closer_p_count + 1;
                 when 'R' then
                   new_returns(new_rows(j).row_id) := new_data.r;
                   closer_r_count := closer_r_count + 1;
                 when 'T' then
                   if  closer_p_count = new_data.t.p_count and closer_r_count = new_data.t.r_count then
                     closer_found := true;
                     
                     update FILE_DATA set
                     status = 'processed'
                     where row_id = new_rows(j).row_id;
                   else 
                     raise_application_error(-20002,'The number of P and R in the trailer does not match the actual.');
                   end if;
                   
                 else
                   raise_application_error(-20002,'Unknown row type at file with id "'||new_fils(i).file_id||'"');
               end case;
             end loop;

           exit when cur_new_rows%notfound;
        end loop;
        close cur_new_rows;

         
        if header_found and closer_found then
              
             -- process new purchases
               if new_purchases.count > 0 then
                 v_cur_collection_iteam :=  new_purchases.FIRST;
               
                while v_cur_collection_iteam is not null
                loop
                  declare
                    new_row_id number;
                    v_operation_cashback number;
                    v_current_cashback number;
                    
                    --error processing
                    v_err_msg varchar2(2000);
                    v_err_code number;
                  begin
                    new_row_id := inserter.insertPurchase(new_purchases(v_cur_collection_iteam),v_cur_collection_iteam);
                    
                    select cashback into v_operation_cashback from transactions where transaction_id = new_row_id;
                    v_current_cashback :=  cashback_analyzer.getCurCashback(new_purchases(v_cur_collection_iteam).card_id,  trunc(new_purchases(v_cur_collection_iteam).purchase_date ,'MONTH'));
                    
                    v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
                    'S;'|| new_purchases(v_cur_collection_iteam).card_id|| ';' || new_purchases(v_cur_collection_iteam).purchare_id || ';' ||
                     v_operation_cashback || ';'||v_current_cashback  );
                     
                     update FILE_DATA set
                     status = 'processed'
                     where row_id = v_cur_collection_iteam;
                     
                     v_s_rows_count := v_s_rows_count + 1;
                    
                  exception
                    when row_parser.row_format_error then
                      v_err_msg :=sqlerrm;
                      v_err_code := sqlcode;
                    
                      v_e_rows_count := v_e_rows_count + 1;
                      --save error to return file
                      v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
                      'E;'|| new_purchases(v_cur_collection_iteam).card_id|| ';' || new_purchases(v_cur_collection_iteam).purchare_id || ';' ||
                      v_err_code || ';'||v_err_msg  );
                      
                      
                      --set error to table
                      update FILE_DATA set
                      status = 'error', err_code = v_err_code, err_msg = v_err_msg
                      where row_id = v_cur_collection_iteam;
                      
                    when others then
                      dbms_output.put_line(sqlcode || ';'||sqlerrm  );
                     
                  end;
                  v_cur_collection_iteam := new_purchases.next(v_cur_collection_iteam);
                end loop;
              end if;
              
               --process new_returns
               if new_returns.count > 0 then
                 v_cur_collection_iteam :=  new_returns.FIRST;
               
                while v_cur_collection_iteam is not null
                loop
                  declare
                    new_row_id number;
                    v_operation_cashback number;
                    v_current_cashback number;
                    
                    --error processing
                    v_err_msg varchar2(2000);
                    v_err_code number;
                  begin
                    
                    new_row_id := inserter.insertReturn(new_returns(v_cur_collection_iteam),v_cur_collection_iteam);
                    
                    select cashback into v_operation_cashback from transactions where transaction_id = new_row_id;
                    v_current_cashback :=  cashback_analyzer.getCurCashback(new_returns(v_cur_collection_iteam).card_id,
                      trunc(new_returns(v_cur_collection_iteam).return_date ,'MONTH'));
                    
                    v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
                    'S;'|| new_returns(v_cur_collection_iteam).card_id|| ';' || new_returns(v_cur_collection_iteam).return_id || ';' ||
                     v_operation_cashback || ';'||v_current_cashback  );
                     
                     update FILE_DATA set
                     status = 'processed'
                     where row_id = v_cur_collection_iteam;
          
                     v_s_rows_count := v_s_rows_count + 1;
                    
                  exception
                    when row_parser.row_format_error then
                      v_err_msg :=sqlerrm;
                      v_err_code := sqlcode;
                      
                      v_e_rows_count := v_e_rows_count + 1;
                      -- save error to report file
                      v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
                      'E;'|| new_returns(v_cur_collection_iteam).card_id|| ';' || new_returns(v_cur_collection_iteam).return_id || ';' ||
                      v_err_code || ';'||v_err_msg  );
                      
                      --set error to table
                      update FILE_DATA set
                      status = 'error', err_code = v_err_code, err_msg = v_err_msg
                      where row_id = v_cur_collection_iteam;
                     
                  end;
                  v_cur_collection_iteam := new_returns.next(v_cur_collection_iteam);
                end loop;
              end if;
              
          
                 
         --save tailer
         v_new_row_id := file_saver.insertRowIntoFile(v_new_file_id,
         'T;'|| v_s_rows_count ||';'|| v_e_rows_count || ';' ); 
        
          update FILES set
          status = 'processed', upd_date = sysdate
          where file_id = new_fils(i).file_id;
          DBMS_OUTPUT.PUT_LINE( 'Commit!');
          --commit;
        else
          raise_application_error(-20002,'Wrong file structure. "H" or "T" file row does not exsists.');
        end if;
          
      
      --file string processing exceptions
      exception
        when row_parser.file_format_error then 

          rollback to previous_file_condition;
          update FILES set
          status = 'deny', upd_date = sysdate
          where file_id = new_fils(i).file_id; 
      
      end;
    end loop;
    
    exit when cur_new_files%notfound;  
  end loop;
  close cur_new_files; 
end processNewFiles;
/
