create or replace package file_saver is

  -- Author  : ¿Õƒ–≈…
  -- Created : 13.05.2020 17:52:06
  -- Purpose : 


  -- Public function and procedure declarations
  function createNewFile(p_file varchar2,p_file_hash varchar2,input_type boolean default false) return number;
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
    
    exception
    when too_many_rows then
      raise_application_error(-20001,'There is already exsists row with row_id ' ||v_row_count+1||', file_id : '||p_file_id  );
    end insertRowIntoFile;

  function createNewFile(p_file varchar2,p_file_hash varchar2,input_type boolean DEFAULT false) return number
  is
  v_row_count number;
  v_file_type varchar2(12);
  begin
    select count(*) into v_row_count from files;
    if  input_type then
      v_file_type := 'input';
    else
      v_file_type := 'output';
    end if;
    
    insert into FILES (file_id,file_hash, name,type,FORM_DATE,UPD_DATE,Status) values 
    (v_row_count+1,p_file_hash,p_file,v_file_type,sysdate,sysdate,'new');
    
    return v_row_count+1;
    exception
    when too_many_rows then
      raise_application_error(-20001,'There is already exsists file with file_id ' ||v_row_count+1||
      ', file name : '||p_file|| ', file_hash : ' || p_file_hash  );
  end;


end file_saver;
/
