create or replace procedure processNewFiles as

  type purchases_list is table of row_parser.purchase_row index by pls_integer;
  type returns_list is table of row_parser.return_row  index by pls_integer;
  new_purchases purchases_list;
  new_returns returns_list;
  
  new_data row_parser.file_row; 
 
  type file_row_data is table of FILE_DATA%rowtype;
  new_rows file_row_data;
  
  CURSOR row_cursor IS
  SELECT * FROM FILE_DATA
  WHERE  status = 'new';
  
  header_found boolean;
  closer_found boolean;
  closer_p_count number;
  closer_r_count number;
begin
  
 open row_cursor;
 FETCH row_cursor BULK COLLECT INTO new_rows;
 close row_cursor;

  for new_file in (
       SELECT *
       FROM FILES
       where status = 'new' and type = 'input'
  )
  loop
    begin
      
      header_found := false;
      closer_found := false;
      closer_p_count := 0;
      closer_r_count := 0;
      
      for i in new_rows.first .. new_rows.last
        loop
          if new_rows(i).file_id = new_file.file_id then 
            begin
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
                 raise_application_error(-20002,'Unknown row type at file with id "'||new_file.file_id||'"');
             end case;
             
             update FILE_DATA set
                 status = 'processed'
                 where row_id = new_rows(i).row_id;
             
             exception
               when row_parser.row_format_error then
                 update FILE_DATA set
                 status = 'error'
                 where row_id = new_rows(i).row_id;
             end;
           end if;
        end loop;
    
    if not header_found then
      raise_application_error(-20002,'Header not found.');
    end if;
    
    if closer_found AND closer_p_count = new_purchases.count AND closer_r_count = new_returns.count 
      then    
        DBMS_OUTPUT.put_line('File processed correctly');
        update FILES set
        status = 'processed', upd_date = sysdate
        where file_id = new_file.file_id; 
     else 
       raise_application_error(-20002,'Tail file errors: tail is missing or incorrect. ');
    end if;
       
    exception
      when row_parser.file_format_error then 
        update FILES set
        status = 'deny', upd_date = sysdate
        where file_id = new_file.file_id; 
    end;
  end loop;
 
 if new_purchases.count > 0 then
    for i in new_purchases.FIRST .. new_purchases.LAST
    loop 
      inserter.insertPurchase(new_purchases(i),i);
    end loop;
 end if;
 
 if new_returns.count > 0 then
    for i in new_returns.FIRST .. new_returns.LAST
    loop 
      inserter.insertReturn(new_returns(i),i);
    end loop;
 end if;
 
end processNewFiles;
/
