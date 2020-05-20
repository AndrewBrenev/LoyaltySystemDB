CREATE TABLE CARDS  (
    card_id number PRIMARY KEY,
    pan VARCHAR2(50) NOT NULL UNIQUE,
    issuing_date date,
    expiration_date date,
    parant_card number NOT NULL,
    client_id number NOT NULL,
    constraint card_fk FOREIGN KEY (parant_card) REFERENCES CARDS (card_id)
);


insert into cards values (1,'f46dda67c2de71ece19c0d3048d809f230b193d3',TO_DATE('2018/05/03', 'yyyy/mm/dd'),TO_DATE('2020/05/03', 'yyyy/mm/dd'),1,1);
insert into cards values (2,'a53c3aa1982cb80b83f639f0cb916cf6ddd68ba1',TO_DATE('2018/06/29', 'yyyy/mm/dd'),TO_DATE('2020/11/29', 'yyyy/mm/dd'),1,2);
insert into cards values (3,'c713ef2a39ca986ebaf7a29f1a8eab27669c5586',TO_DATE('2017/08/12', 'yyyy/mm/dd'),TO_DATE('2021/03/28', 'yyyy/mm/dd'),3,2);
insert into cards values (4,'1eeb45e376f054ef998768974f35997209393660',TO_DATE('2019/09/02', 'yyyy/mm/dd'),TO_DATE('2020/08/07', 'yyyy/mm/dd'),4,3);
insert into cards values (5,'c0a6bf8c168c88c2c83409a337bce422890d6bb2',TO_DATE('2018/10/01', 'yyyy/mm/dd'),TO_DATE('2020/10/12', 'yyyy/mm/dd'),4,4);
insert into cards values (6,'1583df6e775b211a58bad5b5205dac59674f442a',TO_DATE('2020/01/30', 'yyyy/mm/dd'),TO_DATE('2021/01/01', 'yyyy/mm/dd'),1,5);
insert into cards values (7,'f58b1b630450308dc68f6a9dc6e1a6f1915825cc',TO_DATE('2019/12/29', 'yyyy/mm/dd'),TO_DATE('2022/01/29', 'yyyy/mm/dd'),1,1);
insert into cards values (8,'c4940c0f5162b254a0cd635109f434929c537977',TO_DATE('2018/05/01', 'yyyy/mm/dd'),TO_DATE('2021/05/20', 'yyyy/mm/dd'),3,5);
insert into cards values (9,'d554126d7ce6f3cfa9d1d371efa10837861a6913',TO_DATE('2020/04/29', 'yyyy/mm/dd'),TO_DATE('2020/12/28', 'yyyy/mm/dd'),9,5);
insert into cards values (10,'606e0cf47ad6fe91461732139ecbeb014c8e2bad',TO_DATE('2019/03/17', 'yyyy/mm/dd'),TO_DATE('2022/07/05', 'yyyy/mm/dd'),9,5);
insert into cards values (11,'22fcf0cd2cf07841d4214d6a14b2b28c1e15be24',TO_DATE('2019/10/24', 'yyyy/mm/dd'),TO_DATE('2020/11/29', 'yyyy/mm/dd'),3,7);

CREATE TABLE CASHBACK_LOG  (
    log_id number PRIMARY KEY,
    operations_count number NOT NULL,
    amount number NOT NULL,
    period date NOT NULL,
    card_id number NOT NULL,
    constraint cashback_log_card_fk FOREIGN KEY (card_id) REFERENCES CARDS (card_id)
);

CREATE TABLE CONFIGS  (
    config_id number PRIMARY KEY,
    name varchar(30) NOT NULL,
    value number NOT NULL
);

insert into CONFIGS values(1,'min_oper_count',10);
insert into CONFIGS values (2,'min_cashbaсk_amount',10000);
insert into CONFIGS values (3,'max_cashbaсk_amount',300000);
insert into CONFIGS values (4,'default_procent',1);
insert into CONFIGS values (5,'return_date',10);

CREATE TABLE MERCHANTS  (
    merchant_id number PRIMARY KEY,
    company varchar(20),
    point_id varchar(20)
);
insert into merchants values (1,'LENTA1234','Bolshay 2');
insert into merchants values (2,'Gigant 12','Vibornaya 122');
insert into merchants values (3,'LENTA6532','Gogolya 24');

CREATE TABLE MCC  (
    mcc_id number PRIMARY KEY,
    mcc_code varchar(4) NOT NULL UNIQUE,
    name varchar(20),
    group_name varchar(20)
);


insert into mcc values (1,1799,'Contracts','Others');
insert into mcc values (2,4215,'Courier services','Others');
insert into mcc values (3,5122,'Drugs','Pharmacy');
insert into mcc values (4,5172,'Oil','Fuel');
insert into mcc values (5,5309,'Duty Free','Stores');
insert into mcc values (6,5411,'Supermarkets','Stores');
insert into mcc values (7,5441,'Pastry','Stores');
insert into mcc values (8,5717,'Alcohol','Stores');
insert into mcc values (9,5814,'Fastfood','Stores');


CREATE TABLE MERCHANTS_PROGRAMS  (
    merch_prog_id number PRIMARY KEY,
    cashback_proc number not null,
    begin_date date not null,
    end_date date not null,
    merchant_id number not null,
   constraint merchant_id_fk FOREIGN KEY (merchant_id) REFERENCES MERCHANTS (merchant_id),
   constraint mrch_programs_date_check CHECK ( end_date >= begin_date),
   constraint mrch_programs_proc_check CHECK ( cashback_proc >= 0 and cashback_proc <= 100 )
);
insert into MERCHANTS_PROGRAMS values (1,0,TO_DATE('2019/03/20', 'yyyy/mm/dd'),TO_DATE('2019/05/01', 'yyyy/mm/dd'),1);
insert into MERCHANTS_PROGRAMS values (2,0,TO_DATE('2019/03/17', 'yyyy/mm/dd'),TO_DATE('2019/05/01', 'yyyy/mm/dd'),3);
insert into MERCHANTS_PROGRAMS values (3,10,TO_DATE('2019/04/01', 'yyyy/mm/dd'),TO_DATE('2019/05/01', 'yyyy/mm/dd'),2);

CREATE TABLE MCC_PROGRAMS  (
    mcc_prog_id number PRIMARY KEY,
    cashback_proc number not null,
    begin_date date not null,
    end_date date not null,
    mcc_id number not null,
   constraint mcc_id_fk FOREIGN KEY (mcc_id) REFERENCES MCC (mcc_id),
   constraint mcc_programs_date_check CHECK ( end_date >= begin_date),
   constraint mcc_programs_proc_check CHECK ( cashback_proc >= 0 and cashback_proc <= 100 )
);

CREATE TABLE FILES  (
    file_id number PRIMARY KEY,
    file_hash varchar2(12) not null UNIQUE,
    name varchar2(40) not null,
    type varchar2(12) not null,
    form_date date,
    upd_date date,
    status varchar(20) not null,
    err_code number,
    err_msg varchar2(2000),
   constraint files_date_check CHECK ( form_date <= upd_date),
   constraint files_status_check CHECK  ( status IN ('new','processed','deny')),
   constraint files_type_check CHECK  ( type IN ('input','output'))
);

insert into FILES (file_id,file_hash,name,type,FORM_DATE,Status) values 
(2342,'D20200319ONL', 'input.csv','input',TO_DATE('2020-05-20 19:34:34','YYYY-MM-DD HH24:MI:SS'),'new');
insert into FILES (file_id,file_hash,name,type,FORM_DATE,Status) values 
(2312,'LE23N20334TA','lenta2704.csv','input',TO_DATE('2020-05-12 19:34:34','YYYY-MM-DD HH24:MI:SS'),'new');
insert into FILES (file_id,file_hash,name,type,FORM_DATE,Status) values 
(2198,'GZ34509BK','gazprom3004.csv','input',TO_DATE('2020-04-30 19:05:34','YYYY-MM-DD HH24:MI:SS'),'new');

CREATE TABLE FILE_DATA  (
    row_id number PRIMARY KEY,
    file_id number not null,
    value varchar2(4000) not null,
    status varchar(20) not null,
    err_code number,
    err_msg varchar2(2000),
    constraint file_data_fk FOREIGN KEY (file_id) REFERENCES FILES (file_id),
   constraint file_data_status_check CHECK  ( status IN ('new','processed','error'))
)

insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values (1,2342,'H;D20200319ONL;20200320091500','new');
insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values (2,2342,'P;f46dda67c2de71ece19c0d3048d809f230b193d3;12345678;20200319143746;150000;LENTA1234;5411;Касса 7 Терминал 71','new');
insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values (3,2342,'P;f46dda67c2de71ece19c0d3048d809f230b193d3;12345679;20200319153214;20500;VILKA LOZHKA;5812;','new');
insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values (4,2342,'R;f46dda67c2de71ece19c0d3048d809f230b193d3;13579R1;20200319120048;5700;PYATEROCHKA12;13579;Остаток чека 12300','new');
insert into FILE_DATA (row_id,FILE_ID , VALUE,STATUS) values (5,2342,'T;2;1','new');




CREATE TABLE TRANSACTIONS  (
    transaction_id number PRIMARY KEY,
    type varchar2(1) not null,
	hash varchar(12) not null,
    parant_transaction number,
    amount number not null,
    trstn_date date not null,
    card_id number not null,
    mrch_prog_id number,
    mcc_prog_id number,
    file_row number not null,
    cashback number not null,
	comment varchar2(2000)
    constraint transaction_card_fk FOREIGN KEY (card_id) REFERENCES CARDS (card_id),
    constraint transaction_mrch_fk FOREIGN KEY (mrch_prog_id) REFERENCES MERCHANTS_PROGRAMS (merch_prog_id),
    constraint transaction_mcc_fk FOREIGN KEY (mcc_prog_id) REFERENCES MCC_PROGRAMS (mcc_prog_id),
    constraint transaction_files_fk FOREIGN KEY (file_row) REFERENCES FILE_DATA  (row_id),    
   constraint transaction_type_check CHECK ( type IN ('P','R')),
   constraint transaction_return_check CHECK  ( type = 'P' OR (type = 'R' AND parant_transaction is not null)  )
);
create index transaction_hash_index on  transactions( hash);
