PL/SQL Developer Test script 3.0
38
declare 
  
  type files_data is table of FILES%rowtype;
  new_fils files_data := files_data();
  
  cursor cur_new_files is 
         select *
         from FILES
         where status = 'new'; 
         
 p_limit NATURAL := 1;
begin

  open cur_new_files;
  loop
    DBMS_OUTPUT.put_line('New loop iteration');
    DBMS_OUTPUT.put_line('   New files table contains ' || new_fils.count || ' rows.');
    FETCH cur_new_files BULK COLLECT INTO new_fils limit p_limit;
    DBMS_OUTPUT.put_line('   New files table contains ' || new_fils.count || ' rows.');
    
    if cur_new_files%notfound then 
      DBMS_OUTPUT.put_line('   Not found new rows');
      else 
        DBMS_OUTPUT.put_line('   Found ' ||cur_new_files%rowcount || ' new files: ');
        end if;
     
    exit when cur_new_files%notfound;
    
      /* actions with new file*/
    FOR i IN new_fils.FIRST .. new_fils.LAST
    LOOP
      DBMS_OUTPUT.put_line('      New file ' || new_fils(i).name);
    end loop;
    
  end loop;
  close cur_new_files;     

end;
0
0
