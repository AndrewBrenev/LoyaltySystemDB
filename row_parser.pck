create or replace package row_parser is

  -- Author  : ¿Õƒ–≈…
  -- Created : 05.04.2020 12:44:34
  -- Purpose : parse input file rows
  
  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  --<VariableName> <Datatype>;
  
  --exception declaration
  row_format_error exception;
  pragma exception_init(row_format_error, -20001);

  file_format_error exception;
    pragma exception_init(file_format_error, -20002); 
  -- Public type declarations
  type header_row IS RECORD (
       file_id        VARCHAR2(12),
       date_forming   DATE 
  );
  
 type purchase_row IS RECORD (
       card_id          VARCHAR(40),
       purchare_id      VARCHAR2(12),
       purchase_date    DATE,
       amount           NUMBER(10),
       merchant         VARCHAR2(30),
       mcc              NUMBER(4),
       p_comment        VARCHAR2(2000)          
  );
  
  type return_row IS RECORD (
       card_id            VARCHAR(40),
       return_id          VARCHAR2(12),
       return_date        DATE,
       amount             NUMBER(10),
       merchant           VARCHAR2(30),
       purchase_id        VARCHAR2(12),
       r_comment          VARCHAR2(2000)
       
  );
  
  type closer_row IS RECORD (
       p_count  NUMBER,
       r_count  NUMBER
  );
  
  type file_row IS RECORD (
       row_type        VARCHAR2(1), -- 'H','P','R','T'
       h               header_row,
       p               purchase_row,
       r               return_row,
       t               closer_row
  );
  
  -- Public function and procedure declarations
  function parseRow(str in out VARCHAR2, delimitor IN VARCHAR2) return file_row; 

end row_parser;
/
create or replace package body row_parser is
 
  function parseHeaderString(p_str in  Varchar2,delimitor IN VARCHAR2) 
    return header_row
   as
    header header_row;
    sub_str VARCHAR2(2500);
    str VARCHAR2(2500);
    comma_location NUMBER := 0;
    prev_comma_location NUMBER := 0;
   begin
     str := p_str || delimitor;
     --  parse file id 
     comma_location := INSTR(str,delimitor,comma_location+1);
     sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
     prev_comma_location := comma_location;
    
     if LENGTH(sub_str) > 12 then
       raise_application_error(-20002,'Incorrect file id "'||sub_str||'"');
     else
         header.file_id := sub_str;
     end if;
    
     -- parse date forming
     comma_location := INSTR(str,delimitor,comma_location+1);
     sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
     prev_comma_location := comma_location;
     header.date_forming:= to_date(sub_str,'YYYYMMDDHH24MISS');
    
     --parse end of file
     comma_location := INSTR(str,delimitor,comma_location+1);
     sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location) ;
     if sub_str is not null then
       raise_application_error(-20002,'Incorrect headre file format: "'||p_str||'"');
     end if;
     
     return header;
     
     exception
       when others then
         raise_application_error(-20002,'Incorrect header in file : "'||p_str||'"');
    end;

  function parsePurchaseRowString(str in Varchar2,delimitor IN VARCHAR2) return purchase_row
    as
    purchase purchase_row;
    sub_str VARCHAR2(2500);
    comma_location NUMBER := 0;
    prev_comma_location NUMBER := 0;
    begin
    
    --  parse card sha
      comma_location := INSTR(str,delimitor,comma_location+1);
      sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
      prev_comma_location := comma_location;
      if LENGTH(sub_str) != 40 then
        raise_application_error(-20001,'Wrong card SHA-1 hash : "'||sub_str||'"');
      else
        purchase.card_id := sub_str;
      end if;
    
    -- parse transaction id
       comma_location := INSTR(str,delimitor,comma_location+1);
       sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
       prev_comma_location := comma_location;
    
       if LENGTH(sub_str) > 12 then
         raise_application_error(-20002,'Incorrect transaction id "'||sub_str||'"');
       else
         purchase.purchare_id := sub_str;
       end if;
    
    --parse transaction date
       comma_location := INSTR(str,delimitor,comma_location+1);
       sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
       prev_comma_location := comma_location;
       purchase.purchase_date:= to_date(sub_str,'YYYYMMDDHH24MISS');
    
    --parse amount
       comma_location := INSTR(str,delimitor,comma_location+1);
       sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
       prev_comma_location := comma_location;
       purchase.amount := to_number(sub_str);
    
     --  parse merchant id
       comma_location := INSTR(str,delimitor,comma_location+1);
       sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
       prev_comma_location := comma_location;
       if LENGTH(sub_str) > 30  then
         raise_application_error(-20001,'Wrong merchant id : "'||sub_str||'"');
       else
         purchase.merchant := sub_str;
       end if;
     
      --  parse mcc code
       comma_location := INSTR(str,delimitor,comma_location+1);
       sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
       prev_comma_location := comma_location;
       if LENGTH(sub_str) != 4 then
         raise_application_error(-20001,'Wrong mcc code : "'||sub_str||'"');
       else
         purchase.mcc := to_number(sub_str);
       end if;
    
    --parse comment
       sub_str := SUBSTR(str,prev_comma_location + 1) ;
       purchase.p_comment := sub_str;
       return purchase;
       
       exception
         when others then 
           raise_application_error(-20001,'Incorrect purchase file row format : "'||str||'"');
    end;
  
  function parseReturnRowString(str in  Varchar2,delimitor IN VARCHAR2) return return_row
    as
    return_obj return_row;
    sub_str VARCHAR2(2500);
    comma_location NUMBER := 0;
    prev_comma_location NUMBER := 0;
    
    begin
    --  parse card sha
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    if LENGTH(sub_str) != 40 then
      raise_application_error(-20001,'Wrong card SHA-1 hash : "'||sub_str||'"');
    else
      return_obj.card_id := sub_str;
    end if;
    
    -- parse return id
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    
    if LENGTH(sub_str) > 12 then
      raise_application_error(-20002,'Incorrect transaction id "'||sub_str||'"');
    else
      return_obj.return_id := sub_str;
    end if;
    
    --parse return date
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    return_obj.return_date := to_date(sub_str,'YYYYMMDDHH24MISS');
    
    --parse return amount
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    return_obj.amount := to_number(sub_str);
    
    --  parse merchant id
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    if LENGTH(sub_str) > 30  then
      raise_application_error(-20001,'Wrong merchant id : "'||sub_str||'"');
    else
      return_obj.merchant := sub_str;
    end if;
     
    -- parse transaction id
    comma_location := INSTR(str,delimitor,comma_location+1);
    sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
    prev_comma_location := comma_location;
    
    if LENGTH(sub_str) > 12 then
      raise_application_error(-20002,'Incorrect purcase id "'||sub_str||'"');
    else
      return_obj.purchase_id := sub_str;
    end if;
    
    --parse comment
    sub_str := SUBSTR(str,prev_comma_location + 1) ;
    return_obj.r_comment := sub_str;
    return return_obj;
    
    exception
      when others then 
        raise_application_error(-20001,'Incorrect return file row format : "'||str||'"');
  end;
  
  function parseCloserString(p_str in  Varchar2,delimitor IN VARCHAR2) return closer_row
    as
    closer closer_row;
    sub_str VARCHAR2(2500);
    str VARCHAR2(2500);
    comma_location NUMBER := 0;
    prev_comma_location NUMBER := 0;
    
    begin
      str := p_str || delimitor;
    --  parse purcases count 
      comma_location := INSTR(str,delimitor,comma_location+1);
      sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
      prev_comma_location := comma_location;
      closer.p_count := to_number(sub_str);
    
    -- parse returns count
      comma_location := INSTR(str,delimitor,comma_location+1);
      sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location -1) ;
      prev_comma_location := comma_location;
      closer.r_count := to_number(sub_str);
    
    --parse end of file
      comma_location := INSTR(str,delimitor,comma_location+1);
      sub_str := SUBSTR(str,prev_comma_location + 1, comma_location-prev_comma_location) ;
      if sub_str is not null then
        raise_application_error(-20002,'Incorrect closer file format: "'||p_str||'"');
      end if;
      return closer;
      exception
        when others then 
          raise_application_error(-20002,'Incorrect closer in file : "'||p_str||'"');
    end ;
  

  function parseRow(str in out VARCHAR2, delimitor IN VARCHAR2) return file_row
  as  
  f_row file_row;
  row_type VARCHAR2(1);
  sub_str VARCHAR2(2500);
  comma_location NUMBER := 0;
   begin
    comma_location := INSTR(str,delimitor,comma_location+1);
    row_type := SUBSTR(str, 1, comma_location-1);
    sub_str := SUBSTR(str,comma_location+1) ;
    case row_type
      when 'H' then
        f_row.h := parseHeaderString(sub_str,delimitor);
      when 'P' then
        f_row.p := parsePurchaseRowString(sub_str,delimitor);
      when 'R' then
         f_row.r := parseReturnRowString(sub_str,delimitor);
      when 'T' then
         f_row.t := parseCloserString(sub_str,delimitor);
      ELSE
         raise_application_error(-20002,'Unknown operation code at string "'||str||'"');
    end case;

    f_row.row_type := row_type;
    return f_row;
          
    exception
        when value_error then
          raise_application_error(-20002,'Operation code contain more then one letter at string "'||str||'"');
  end;

end row_parser;
/
