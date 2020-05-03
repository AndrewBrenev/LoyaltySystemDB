PL/SQL Developer Test script 3.0
57
-- Created on 28.04.2020 by ¿Õƒ–≈… 
declare 

type file_row_data is table of FILE_DATA%rowtype;
  new_rows file_row_data := file_row_data();
  
  type files_data is table of FILES%rowtype;
  new_fils files_data := files_data();
  
   Cursor cur_new_files is 
         select *
         from FILES
         where status = 'new'; 
         
  Cursor cur_new_rows (p_id Number )is 
         select *
         from FILE_DATA
         where file_id = p_id AND status = 'new'
         order by row_id; 
  v_limit number := 1000;
begin

  open cur_new_files;
  loop
    DBMS_OUTPUT.put_line(new_fils.count);
    FETCH cur_new_files BULK COLLECT INTO new_fils limit v_limit;
    DBMS_OUTPUT.put_line(new_fils.count);
    if cur_new_files%notfound then 
      DBMS_OUTPUT.put_line('Not found');
      else 
        DBMS_OUTPUT.put_line('Found');
        end if;
    exit when cur_new_files%notfound;
    
    /* actions with new file*/
    FOR i IN new_fils.FIRST .. new_fils.LAST
    LOOP
      DBMS_OUTPUT.put_line(i);
      DBMS_OUTPUT.put_line(new_fils(i).name);
      /*
        open cur_new_rows(new_fils(i).file_id);
        loop
          FETCH cur_new_rows BULK COLLECT INTO new_rows limit v_limit;
          exit when cur_new_rows%notfound;
           FOR j IN new_rows.FIRST .. new_rows.LAST
             loop
               DBMS_OUTPUT.put_line(new_rows(j).value);
             end loop;

        END LOOP;
        close cur_new_rows;
        */
    end loop;
  end loop;
  close cur_new_files;     

end;
0
0
