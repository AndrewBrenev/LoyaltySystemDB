PL/SQL Developer Test script 3.0
119
-- Created on 28.04.2020 by ÀÍÄÐÅÉ 
declare
   type purchases_list is table of row_parser.purchase_row index by pls_integer;
   type returns_list is table of row_parser.return_row  index by pls_integer;
   new_purchases purchases_list;
   new_returns returns_list;
  
   new_data row_parser.file_row; 

   type file_row_data is table of FILE_DATA%rowtype;
   new_rows file_row_data := file_row_data();
   
   type files_data is table of FILES%rowtype;
   new_fils files_data := files_data();
  
   Cursor cur_new_files is 
         select *
         from FILES
         where type = 'input' and status = 'new'; 
   
   Cursor cur_new_rows (p_id Number )is 
         select *
         from FILE_DATA
         where file_id = p_id AND status = 'new'
         order by row_id; 
         
  v_new_trsn_row_id number;
  v_return_str_name Varchar2(200);
  v_limit number := 1;
begin
  

  -- fetch new files from bank
  open cur_new_files;
  loop
    FETCH cur_new_files BULK COLLECT INTO new_fils limit v_limit;
    exit when cur_new_files%notfound;
    
    -- actions with new files
    FOR i IN new_fils.FIRST .. new_fils.LAST
    LOOP
      savepoint previus_file_condition;
      declare
        header_found boolean;
        closer_found boolean;
        new_row_id number;
        closer_p_count number;
        closer_r_count number;
      begin
        open cur_new_rows(new_fils(i).file_id);
        loop
          FETCH cur_new_rows BULK COLLECT INTO new_rows limit v_limit;
     
          exit when cur_new_rows%notfound;
           new_purchases.delete();
           new_returns.delete();
          
           FOR j IN new_rows.FIRST .. new_rows.LAST
             loop
             -- process file new row
               --parse text row to object
           new_data := row_parser.parseRow(new_rows(i).value,';');
           
           --process current row
           case new_data.row_type
             when 'H' then
               header_found := true;
               inserter.processHeader(new_data.h);
             when 'P' then
               new_purchases(new_rows(i).row_id) := new_data.p;
             when 'R' then
               new_returns(new_rows(i).row_id) := new_data.r;
             when 'T' then
               closer_found := true;
               closer_p_count := new_data.t.p_count;
               closer_r_count := new_data.t.r_count;
             else
                 raise_application_error(-20002,'Unknown row type at file with id "'||new_fils(i).file_id||'"');
             end case;
             
             update FILE_DATA set
                 status = 'processed'
                 where row_id = new_rows(i).row_id;  
             
             
              if new_purchases.count > 0 then
                for i in new_purchases.FIRST .. new_purchases.LAST
                loop 
                  new_row_id := inserter.insertPurchase(new_purchases(i),i);
                end loop;
              end if;
              
              if new_returns.count > 0 then
                for i in new_returns.FIRST .. new_returns.LAST
                loop 
                  new_row_id := inserter.insertReturn(new_returns(i),i);
                end loop;
              end if;
 
             end loop;

        END LOOP;
        close cur_new_rows;
        
        commit;
      
      --file string processing exceptions
      exception
        when row_parser.file_format_error then 
          rollback to previus_file_condition;
          update FILES set
          status = 'deny', upd_date = sysdate
          where file_id = new_fils(i).file_id; 
      
      end;
    end loop;
  end loop;
  close cur_new_files; 
end;
0
0
