create or replace package file_saver is

  -- Author  : ¿Õƒ–≈…
  -- Created : 13.05.2020 17:52:06
  -- Purpose : 


  -- Public function and procedure declarations
  function createNewFile(p_file varchar2,p_file_hash varchar2) return number;
  function insertRowIntoFile(p_file_id number, row_text varchar2) return number;

end file_saver;
/
create or replace package body file_saver is

function insertRowIntoFile(p_file_id number, row_text varchar2) return number
  is
   v_row_count number;
  begin
    select count(*) into v_row_count from FILE_DATA;
   insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values
    (v_row_count+1,p_file_id,row_text,'new'); 
    
    return v_row_count+1;
    end insertRowIntoFile;

  function createNewFile(p_file varchar2,p_file_hash varchar2) return number
  is
  v_row_count number;
  begin
    select count(*) into v_row_count from files;
    insert into FILES (file_id,file_hash, files.  name,type,FORM_DATE,UPD_DATE,Status) values 
    (v_row_count+1,p_file_hash,p_file,'output',sysdate,sysdate,'new');
    
    return v_row_count+1;
    exception
    when others then 
      raise;
  end;


end file_saver;
/
