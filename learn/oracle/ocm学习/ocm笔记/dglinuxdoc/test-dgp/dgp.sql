sys/iBoxPay_301B@OFLBOX01DG as sysdba
spool .\result\dgp.log
SET ECHO ON
set head off
SELECT UTL_INADDR.GET_HOST_ADDRESS, 
SYS_CONTEXT('userenv', 'ip_address')
FROM DUAL;
/*
drop DATABASE LINK dgs;
drop DATABASE LINK  dgp;
CREATE DATABASE LINK dgs
 CONNECT TO system
 IDENTIFIED BY password
 USING '(DESCRIPTION=
    (ADDRESS=
      (PROTOCOL=TCP)
      (HOST=192.168.74.131)
      (PORT=1521)
    )
    (CONNECT_DATA=
      (SERVICE_NAME=orcldg)
    )
  )';
  drop DATABASE LINK dgp;
CREATE DATABASE LINK dgp
 CONNECT TO system
 IDENTIFIED BY password
 USING '(DESCRIPTION=
    (ADDRESS=
      (PROTOCOL=TCP)
      (HOST=192.168.74.130)
      (PORT=1521)
    )
    (CONNECT_DATA=
      (SERVICE_NAME=orcl.localdomain)
    )
  )';
  */

  select   current_scn from v$database@dgp
union all
select   current_scn from v$database@dgs;
CREATE TABLESPACE dat_dg DATAFILE 
  '/data01/oradata/oflbox01/dat_dg01.dbf ' SIZE 10m AUTOEXTEND ON NEXT 1280K MAXSIZE UNLIMITED
LOGGING
ONLINE
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

select * from dba_data_files@dgs where TABLESPACE_NAME='DAT_DG';
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.sleep(1);
/
exec dbms_lock.slee(1);
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

--在备库切换日志 
alter system switch logfile;
select sequence# from v$archived_log@dgs; 
alter system switch logfile; 
select sequence# from v$archived_log@dgs; 
--在主库进行验证：
exec dbms_lock.sleep(1);
select sequence#,applied from v$archived_log@dgp;
select   current_scn from v$database@dgp
union all
select   current_scn from v$database@dgs;
--drop tablespace dat_dg including contents and datafiles;

create user dg identified by dg default tablespace dat_dg;
grant connect,resource to dg;
alter user dg quota unlimited on dat_dg;
SELECT * FROM DBA_USERS WHERE USERNAME='DG';
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
conn dg/dg@OFLBOX01DG

create table big_table tablespace dat_dg
as
select rownum id, a.*
  from all_objects a
 where 1=2
;
declare
    l_cnt number;
    l_rows number := 10000;
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

conn sys/iBoxPay_301B@OFLBOX01DG as sysdba
select count(1) from dg.big_table@dgs
union all
select count(1) from dg.big_table@dgP;
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


spool off
exit
