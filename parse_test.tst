PL/SQL Developer Test script 3.0
19
-- Created on 10.04.2020 by АНДРЕЙ 
declare 
  -- Local variables here
  i integer;
  h_str varchar(700) :='H;D20200319ONL;20200320091500';
  p_str varchar2(90) :='P;22fcf0cd2cf07841d4214d6a14b2b28c1e15be24;12345678;20200319143746;150000;LENTA1234;5411;Касса 7 Терминал 71';
  r_str varchar2(90) :='R;23696bdc044f068ce78a3d70de9c5f4d6ab4b3bd;13579R1;20200319120048;5700;PYATEROCHKA12;13579;Остаток чека 12300';
  c_str varchar2(30) := 'T;2;1';
  del varchar(1) := ';';
  row row_parser.file_row;
begin
  -- Test statements here
  row := row_parser.parseRow(h_str,del);
  exception
    when row_parser.file_format_error then
            DBMS_OUTPUT.PUT_LINE('File error');
    when others then 
      DBMS_OUTPUT.PUT_LINE(sqlcode);
end;
0
0
