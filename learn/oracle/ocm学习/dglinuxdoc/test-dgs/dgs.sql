sys/iBoxPay_301B@OFLBOX01 as sysdba
spool .\result\dgs.log
SET ECHO ON
set head off
SELECT UTL_INADDR.GET_HOST_ADDRESS, 
SYS_CONTEXT('userenv', 'ip_address')
FROM DUAL;
/*
CREATE DATABASE LINK dgs
 CONNECT TO system
 IDENTIFIED BY iBoxPay_301B
 USING '(DESCRIPTION=
    (ADDRESS=
      (PROTOCOL=TCP)
      (HOST=172.16.6.12)
      (PORT=1521)
    )
    (CONNECT_DATA=
      (SERVICE_NAME=oflbox01dg)
    )
  )';
CREATE DATABASE LINK dgp
 CONNECT TO system
 IDENTIFIED BY iBoxPay_301B
 USING '(DESCRIPTION=
    (ADDRESS=
      (PROTOCOL=TCP)
      (HOST=172.16.6.11)
      (PORT=1521)
    )
    (CONNECT_DATA=
      (SERVICE_NAME=oflbox01)
    )
  )';
CREATE TABLESPACE dat_txy DATAFILE 
  '/data01/oradata/oflbox01/dat_txy01.dbf ' SIZE 10m AUTOEXTEND ON NEXT 1280K MAXSIZE UNLIMITED
LOGGING
ONLINE
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

select * from dba_data_files@dgs where TABLESPACE_NAME='DAT_TXY';
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/

--在主库切换日志 
alter system switch logfile;
select sequence# from v$archived_log; 
alter system switch logfile; 
select sequence# from v$archived_log; 
--在备库进行验证：
exec dbms_lock.sleep(1);
select sequence#,applied from v$archived_log@dgs;

--drop tablespace dat_txy including contents and datafiles;

create user txy identified by txy default tablespace dat_txy;
grant connect,resource to txy;
alter user txy quota unlimited on dat_txy;
SELECT * FROM DBA_USERS WHERE USERNAME='TXY';
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
*/
conn txy/txy@OFLBOX01

create table big_table tablespace dat_txy
as
select rownum id, a.*
  from all_objects a
 where 1=2
;
declare
    l_cnt number;
    l_rows number := 100000;
begin
    insert /* append */
    into big_table
    select rownum, a.*
      from all_objects a
     where rownum <= l_rows;

    l_cnt := sql%rowcount;

    commit;

    while (l_cnt < l_rows)
    loop
        insert /* APPEND */ into big_table
        select rownum+l_cnt,
               OWNER, OBJECT_NAME, SUBOBJECT_NAME,
               OBJECT_ID, DATA_OBJECT_ID,
               OBJECT_TYPE, CREATED, LAST_DDL_TIME,
               TIMESTAMP, STATUS, TEMPORARY,
               GENERATED, SECONDARY,namespace,edition_name
          from big_table
         where rownum <= l_rows-l_cnt;
        l_cnt := l_cnt + sql%rowcount;
        commit;
    end loop;
end;
/

conn sys/iBoxPay_301B@OFLBOX01 as sysdba
select count(1) from txy.big_table@dgp
union all
select count(1) from txy.big_table@dgs;
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(5);
/
exec dbms_lock.sleep(5);
/
exec dbms_lock.sleep(5);
/


spool off
exit
