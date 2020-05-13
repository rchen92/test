alter user scott account unlock identified by scott;
conn scott/scott
select * from tab;
alter user hr account unlock identified by hr;
select * from hr.employees where
    HIRE_DATE>=to_date('2008/1/1','yyyy/mm/dd');

set autotrance on
select * from hr.employees where manager_id=100 order  by manager_id desc;

set autotrace on
select * from hr.employees where manager_id=100 
order by EMPLOYEE_ID;

select * from v$transaction;    --�����ѯ



select to_char(begin_time,'MM/DD HH24:MI') as "��ʼʱ��10����һ��",
undoblks "undo����",
undoblks*8/1024  "undo��Ҫ�Ĵ�С(mb)",
maxquerylen "���ѯ���룩",
unxpstealcnt "ûʧЧ��͵����*",
expstealcnt  "ʧЧ��͵����*",
ssolderrcnt "ORA-01555 occurred����",
nospaceerrcnt "no free space����*",
MAXQUERYID
from v$undostat order by 1 desc;

--����ͨ��oracle����Դ������������


select status from v$instance;      --��ѯʵ����״̬

select * from V$TRANSACTION;    --��ѯδ�ύ������

show parameter recovery_file_dest


--���
--�������ϸ�������
EXEC dbms_fga.add_policy(object_schema    =>'HR', object_name=>'EMPLOYEES', policy_name=>'EMPLOYEES$SALARY$COMM',audit_condition=>'department_id=10', audit_column=> 'SALARY,COMMISSION_PCT', enable=>TRUE, statement_types =>'SELECT,UPDATE');
EXEC dbms_fga.add_policy(object_schema =>'HR', object_name=>'EMPLOYEES', policy_name=>'EMPLOYEES$SALARY$COMM',audit_condition=>null, audit_column=> 'SALARY,COMMISSION_PCT', enable=>TRUE, statement_types =>'SELECT,UPDATE');
    --ע��:�����sysdba��
select * from DBA_FGA_AUDIT_TRAIL order by TIMESTAMP desc;
--hr  login
select salary from hr.EMPLOYEES;
select * from hr.EMPLOYEES;
select * from hr.EMPLOYEES where department_id=10;
select * from hr.EMPLOYEES where department_id=20;
select EMPLOYEE_ID,EMAIL from hr.EMPLOYEES where department_id=10;



show parameter recovery_file_dest_size;

alter system set db_recovery_file_dest_size=4G scope=spfile;


--ͳ����Ϣ
set timing on
set autotrace traceonly
set autotrace on
SELECT COUNT(*) FROM hr.employees;


--linux����autotrace
    --linux or unix
    su - oracle
    sqlplus / as sysdba

    @?/rdbms/admin/utlxplan.sql;  
    @?/sqlplus/admin/plustrce;
    grant plustrace to public;
    grant select on v_$session to public;

--�������
EXEC dbms_fga.disable_policy (object_schema => 'HR',object_name =>'EMPLOYEES',  policy_name => 'EMPLOYEES$SALARY$COMM');
--�������
EXEC dbms_fga.enable_policy (object_schema => 'HR',object_name =>'EMPLOYEES',  policy_name => 'EMPLOYEES$SALARY$COMM',  enable => true);
--ɾ�����
EXEC dbms_fga.drop_policy(object_schema => 'HR',object_name =>'EMPLOYEES',policy_name => 'EMPLOYEES$SALARY$COMM'); 


--Ŀǰ��������ͳ����Ϣ
TBL_N_MNG_HIS
select owner,min(last_analyzed),max(last_analyzed) from dba_tables group by  owner order by max(last_analyzed) desc ;
--���µ�ͳ����Ϣ��Ӧ�����ĸ���
select * from dba_tables where last_analyzed in (select max(last_analyzed) from dba_tables );
--�˹��ɼ�ͳ����Ϣ(��,�û�,ȫ��)
    ---TZERO        6    5 TABLE ACCESS              FULL                      T_EB_BATCHPAYMENT    
        set timing on
        EXEC   dbms_stats.gather_table_stats (ownname=>'hr',tabname=>'employees', method_opt =>'for all indexed columns', cascade=>TRUE,degree=>4 );
    
        with with_own_tbl as (select upper('TZERO') OWNER,upper('T_EB_BATCHPAYMENT') table_name  from dual), --**��Ҫ�޸�  TBL_N_TXN ALIPAY_QR_ORDER
            with_if_lock as (select count(1) cnt from dba_tab_statistics where (OWNER,table_name) in (select OWNER,table_name from with_own_tbl) and  stattype_locked is not null group by OWNER,table_name )
        select case when (select cnt from with_if_lock)>0 then '--1.�ñ�ͳ����Ϣ������,��Ҫ�Ƚ���,�������²ɼ�' end gather_table_stats_script from with_own_tbl
        union all
        select case when (select cnt from with_if_lock)>0 then 'exec dbms_stats.unlock_table_stats (ownname=>'''||OWNER||''',tabname=>'''||table_name||''' );' end  from with_own_tbl
        union all
        select '--2.�ɼ�ͳ����Ϣ' from dual
        union all
        select 'set timing on' from dual
        union all
        select 'EXEC   dbms_stats.gather_table_stats (ownname=>'''||OWNER||''',tabname=>'''||table_name||''', method_opt =>''for all indexed columns'', cascade=>TRUE,degree=>4 );'  from with_own_tbl;
        set timing on
        EXEC   dbms_stats.gather_table_stats (ownname=>'FSPF_POSP',tabname=>'TBL_N_TXN', method_opt =>'for all indexed columns', cascade=>TRUE,degree=>4 );
    
        select distinct OWNER,table_name��stattype_locked from dba_tab_statistics where OWNER='FSPF_POSP' and  stattype_locked is not null ORDER BY OWNER,table_name;
        select OWNER,table_name,PARTITION_NAME,stattype_locked from dba_tab_statistics where OWNER='FSPF_POSP' and  stattype_locked is not null ORDER BY OWNER,table_name,PARTITION_NAME;
        select OWNER,table_name,PARTITION_NAME,stattype_locked from dba_tab_statistics where OWNER='FSPF_CLEAR' and  stattype_locked is not null ORDER BY OWNER,table_name,PARTITION_NAME;
        --ORA-20005: object statistics are locked (stattype = ALL)
        exec dbms_stats.unlock_table_stats (ownname=>'FSPF_POSP',tabname=>'TBL_N_TXN' );
    ---�˹��ɼ�һ���û������ж����ͳ����Ϣ
        --dba or user
        set timing on
        execute dbms_stats.gather_schema_stats(ownname=>'hr',degree=>12);
    --sysdbaȫ��
        set timing on
        exec DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC;
        exec dbms_stats.set_table_prefs('hr','employees','STALE_PERCENT','13');
        
 --�Զ��ɼ�ͳ����Ϣ
    --ȫ��
    --ȷ��11g�Ƿ� �Զ��ɼ�ͳ����Ϣ
    col client_name for a35
    col status for a9
    col consumer_group for a30
    col window_group for a30
    SET TRIMSPOOL on
    --set pagesize 100
    set linesize 2000    
      select client_name,status,consumer_group,window_group 
        from dba_autotask_client where CLIENT_NAME='auto optimizer stats collection';       
    --��ʱ�Զ���ʼ��
    col WINDOW_NAME for a18;
    col REPEAT_INTERVAL for a55;
    col duration for a15
    select t1.window_name,t1.repeat_interval,t1.duration from dba_scheduler_windows t1,dba_scheduler_wingroup_members t2 
    where t1.window_name=t2.window_name and t2.window_group_name in ('MAINTENANCE_WINDOW_GROUP','BSLN_MAINTAIN_STATS_SCHED');

    --��ʱȫ��ɼ����
    select min(last_analyzed) min_last_analyzed,max(last_analyzed) max_last_analyzed from dba_tables;
    select owner,TABLE_NAME,last_analyzed from dba_tables where last_analyzed=(select max(last_analyzed) from dba_tables);

    
    --��ʱ�ñ��ͳ����Ϣ�ɼ����
    select last_analyzed from dba_tables where owner=upper('settlement') and TABLE_NAME=upper('tb_settle_detail');
NUM_ROWS    11,868,778 --������ʷ������,���ǿ���ͳ�Ƶ�ȫ����Ϣ,�ҷǳ�׼ȷ
select count(1) from txy.TBL_DC_REPORT_STAT_EXPAND_D;
11868778--ͳ����ϢҲ�����ֵ
BLOCKS    149,616


show parameter statisti;


--���ܹ���

SELECT distinct object_type FROM dba_objects order by 1;



--�����ļ�
ls $ORACLE_HOME/dbs/orapw*
strings /u01/app/oracle/product/11.1.0/dbhome_1/dbs/orapworcl
]\[Z
ORACLE Remote Password file
INTERNAL
AB27B53EDC5FEF41
8A8F025737A9097A
f?yZ
mv /u01/app/oracle/product/11.2.0/db_1/dbs/orapwocp /u01/app/oracle/product/11.2.0/db_1/dbs/orapwocp.20161106

select sysdate from dual;
�ͻ��� sqlplus  sys/password@192.168.56.15 as sysdba
--ORA-01017: invalid username/password; logon denied
--sys

sqlplus / as sysdba
shutdown immediate
startup

--�ؽ������ļ�
orapwd file=$ORACLE_HOME/dbs/orapwocp password=password entries=5       --����sys������Ϊpassword��
strings $ORACLE_HOME/dbs/orapwocp



--spfile��ԭ
--��ǰʵ�������ĸ������ļ�
show parameter pfile
su - grid
asmcmd
cp +DATA/ocp/spfileorcl.ora /u01/spfileorcl.ora
strings /u01/spfileorcl.ora
--rman��ԭ
    asmcmd
    rm +DATA/ocp/spfileocp.ora
    SQL> shutdown abort
ORACLE instance shut down.
SQL> startup
ORA-01078: failure in processing system parameters
ORA-01565: error in identifying file '+DATA/ocp/spfileocp.ora'
ORA-17503: ksfdopn:2 Failed to open file +DATA/ocp/spfileocp.ora
ORA-15056: additional error message
ORA-17503: ksfdopn:2 Failed to open file +DATA/ocp/spfileocp.ora
ORA-15173: entry 'spfileocp.ora' does not exist in directory 'ocp'
ORA-06512: at line 4

view /oraclemgr/db_bak/ rmanbaklevel0.log
including current SPFILE in backup set
channel ORA_DISK_1: starting piece 1 at 2016-11-05 15:39:15
channel ORA_DISK_1: finished piece 1 at 2016-11-05 15:39:16
piece handle=+FRA/db_bak/diskdb0_t.20161105_s.2_d.orcl tag=TAG20161105T153616 comment=NONE

    rman target /
    startup nomount 
    restore spfile from '+FRA/db_bak/diskdb0_t.20161105_s.2_d.orcl';
    shutdown abort
    startup

--spfile��ʧ������û�б��ݣ���λָ�
[oracle@oracle ~]$ view /u01/app/oracle/diag/rdbms/SID/SID/trace/alert_SID.log 
--�������ALTER SYSTEM SET�޸Ĺ��ļ�¼������Ȼ��༭һ���ı��ļ����Ƚ����ݿ���������Ȼ��������һ��spfile��


--rman���ݿ����ļ�
--�ر����ݿ�,ɾ��һ�������ļ�
SQL> shutdown immediate;
SQL> show parameter control;
NAME                     TYPE     VALUE
------------------------------------ ----------- ------------------------------
control_file_record_keep_time         integer     7
control_files                 string     +DATA/orcl/controlfile/current260.926515525, +FRA/orcl/controlfile/current.256.926515531
SQL> shutdown immediate;
--���ɾ����һ���ļ�����
 su - grid
 asmcmd -p
 rm һ���ļ�

SQL> startup
ORACLE instance started.
Total System Global Area  534462464 bytes
Fixed Size            2254952 bytes
Variable Size          377489304 bytes
Database Buffers      150994944 bytes
Redo Buffers            3723264 bytes
ORA-00205: error in identifying control file, check alert log for more info

su - oracle
rman target /
 list failure;
 --list failure all;
 advise failure; 
 repair failure;


--�ر����ݿ�,ɾ��ȫ�������ļ����б���
sqlplus / as sysdba
SHOW parameter control
shutdown immediate
[grid@oracle68 ~]$ asmcmd
ASMCMD> ls +DATA/orcl/controlfile/
current.260.927200399
ASMCMD> ls +FRA/orcl/controlfile/
Current.256.926515531
ASMCMD> rm +DATA/orcl/controlfile/current.260.927200399
ASMCMD> rm +FRA/orcl/controlfile/Current.256.926515531
SQL> startup
ORACLE instance started.
ORA-00205: error in identifying control file, check alert log for more info

su - oracle
rman target /
 list failure;
 list failure all;
 advise failure; 
 repair failure;
 --�޿��ý���
 cd /oraclemgr/db_bak
  cat rmanbaklevel0.log
    including current control file in backup set
    channel ORA_DISK_1: starting piece 1 at 2016-11-05 15:40:28
    channel ORA_DISK_1: finished piece 1 at 2016-11-05 15:40:31
    piece handle=+FRA/db_bak/diskctl0_t.20161105_s.4_d.orcl tag=TAG20161105T154021 comment=NONE
RMAN> restore controlfile from '+FRA/db_bak/diskctl0_t.20161105_s.4_d.orcl';
SQL> select status from v$instance;
RMAN> alter database mount;
RMAN> alter database open;
    RMAN-00571: ===========================================================
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00571: ===========================================================
    RMAN-03002: failure of alter db command at 11/06/2016 14:21:52
    ORA-01589: must use RESETLOGS or NORESETLOGS option for database open
RMAN> alter database open resetlogs;
    RMAN-00571: ===========================================================
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00571: ===========================================================
    RMAN-03002: failure of alter db command at 11/06/2016 14:22:04
    ORA-01190: control file or data file 1 is from before the last RESETLOGS
    ORA-01110: data file 1: '+DATA/orcl/datafile/system.256.926515101'
RMAN> recover database;
RMAN> alter database open resetlogs;
database opened


--�ر����ݿ�,ɾ��ȫ�������ļ����ޱ���
SQL> shutdown immediate
[grid@oracle68 ~]$ asmcmd
ASMCMD> ls +DATA/orcl/controlfile/
current.260.927200399
ASMCMD> ls +FRA/orcl/controlfile/
Current.256.926515531
ASMCMD> rm +DATA/orcl/controlfile/current.260.927200399
ASMCMD> rm +FRA/orcl/controlfile/Current.256.926515531
SQL> startup
ORACLE instance started.
Total System Global Area  534462464 bytes
Fixed Size            2254952 bytes
Variable Size          377489304 bytes
Database Buffers      150994944 bytes
Redo Buffers            3723264 bytes
ORA-00205: error in identifying control file, check alert log for more info
[oracle@oracle68 ~]$ view /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log     --�ҵ����������
MAXINSTANCES 8
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 100
Datafile
'+DATA/orcl/datafile/system.256.926515101',
'+DATA/orcl/datafile/sysaux.257.926515103',
'+DATA/orcl/datafile/undotbs1.258.926515103',
'+DATA/orcl/datafile/users.259.926515105'
ASMCMD> ls -s  +DATA/ORCL/onlinelog/
Block_Size  Blocks     Bytes      Space  Name
       512  102401  52429312  163577856  group_1.261.926515539
       512  102401  52429312  163577856  group_2.262.926515563
       512  102401  52429312  163577856  group_3.263.926515591
SQL> create controlfile reuse database orcl noarchivelog noresetlogs        #####�ؽ������ļ�ʱʧ��
  2  maxlogfiles 16
  3  maxinstances 8
  4  maxlogmembers 3
  5  maxloghistory 1
  6  MAXDATAFILES 100
  7  datafile
  8  '+DATA/orcl/datafile/sysaux.257.926515103',
  9  '+DATA/orcl/datafile/system.256.926515101',
 10  '+DATA/orcl/datafile/undotbs1.258.926515103',
 11  '+DATA/orcl/datafile/users.259.926515105'
 12  logfile
 13  group 1 '+DATA/ORCL/onlinelog/group_1.261.926515539' size 50M,
 14  group 2 '+DATA/ORCL/onlinelog/group_2.262.926515563' size 50M,
 15  group 3 '+DATA/ORCL/onlinelog/group_3.263.926515591' size 50M
 16  character set utf8
 17  /
SQL> alter database open;
SQL> recover database;
Media recovery complete.
SQL> alter database open;
Database altered.



--�����ļ�
SQL> shutdown abort;   
ORACLE instance shut down.
ASMCMD> cd +data
ASMCMD> cd orcl
ASMCMD> cd datafile
ASMCMD> ls
EXAMPLE.265.926515651
SYSAUX.257.926515103
SYSTEM.256.926515101
TBS_TEST_DDL.267.926609573
UNDOTBS1.258.926515103
USERS.259.926515105
ASMCMD> rm system.256.926515101
rman target /
RMAN> startup
Oracle instance started
database mounted
......
RMAN-03002: failure of startup command at 11/06/2016 14:35:07
ORA-01157: cannot identify/lock data file 1 - see DBWR trace file
ORA-01110: data file 1: '+DATA/orcl/datafile/system.256.926515101'
RMAN> list failure;
using target database control file instead of recovery catalog
List of Database Failures
=========================
Failure ID Priority Status    Time Detected Summary
---------- -------- --------- ------------- -------
965        CRITICAL OPEN      06-NOV-16     System datafile 1: '+DATA/orcl/datafile/system.256.926515101' is missing
528        CRITICAL OPEN      06-NOV-16     System datafile 1: '+DATA/orcl/datafile/system.256.926515101' needs media recovery
RMAN> restore datafile 1;
RMAN> recover datafile 1;
RMAN> sql 'alter database datafile 1 online';
RMAN> alter database open;



SQL> shutdown abort;   
ORACLE instance shut down.
ASMCMD> cd +data
ASMCMD> cd orcl
ASMCMD> cd datafile
ASMCMD> ls
EXAMPLE.265.926515651
SYSAUX.257.926515103
SYSTEM.256.926515101
TBS_TEST_DDL.267.926609573
UNDOTBS1.258.926515103
USERS.259.926515105
ASMCMD> rm system.256.926515101
RMAN> startup
Oracle instance started
database mounted
......
RMAN-03002: failure of startup command at 11/06/2016 14:35:07
ORA-01157: cannot identify/lock data file 1 - see DBWR trace file
ORA-01110: data file 1: '+DATA/orcl/datafile/system.256.926515101'
RMAN> list failure;
using target database control file instead of recovery catalog
List of Database Failures
=========================
Failure ID Priority Status    Time Detected Summary
---------- -------- --------- ------------- -------
965        CRITICAL OPEN      06-NOV-16     System datafile 1: '+DATA/orcl/datafile/system.256.926515101' is missing
528        CRITICAL OPEN      06-NOV-16     System datafile 1: '+DATA/orcl/datafile/system.256.926515101' needs media recovery

RMAN> advise failure;
......
1      Restore and recover datafile 1  
  Strategy: The repair includes complete media recovery with no data loss
  Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_3448105287.hm
RMAN> repair failure;
Strategy: The repair includes complete media recovery with no data loss
Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_3448105287.hm
contents of repair script:
   # restore and recover datafile
   restore datafile 1;
   recover datafile 1;
   sql 'alter database datafile 1 online';
Do you really want to execute the above repair (enter YES or NO)? yes
executing repair script
Starting restore at 06-NOV-16
......
repair failure complete
Do you want to open the database (enter YES or NO)? yes
database opened


--�鿴�汾��
select BANNER  from v$version;


--����ȫ�ָ�

drop tablespace test_orcl including contents and datafiles;
SQL>shutdown abort
SQL> startup mount
RMAN> restore database until time "to_date('2016-11-06 15:34:44', 'YYYY-MM-DD HH24:MI:SS')"; --<��ʱ���,���� <=
RMAN> recover database until time "to_date('2016-11-06 15:34:44', 'YYYY-MM-DD HH24:MI:SS')";
RMAN> alter database open;
RMAN> alter database open resetlogs;
--�������������ʹ��ʱ���֮������ݶ�ʧ

--����ʹ�����ݱõ�������
--dba���������û�����
drop tablespace test_orcl including contents and datafiles;
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
expdp userid=system/oracle@192.168.56.15:1521/orcl dumpfile=scott.dmp log=scott.log directory=DATA_PUMP_DIR  schemas=scott parallel=4
SQL>shutdown abort
SQL> startup mount
RMAN> restore database until time "to_date('2016-11-06 15:35:44', 'YYYY-MM-DD HH24:MI:SS')"; --<��ʱ���,���� <=
RMAN> recover database until time "to_date('2016-11-06 15:35:44', 'YYYY-MM-DD HH24:MI:SS')";
impdp system/oracle@192.168.56.15:1521/orcl dumpfile=scott.dmp logfile=scott.implog directory=DATA_PUMP_DIR  schemas=scott REMAP_SCHEMA=scott:scott REMAP_TABLESPACE=users:users table_exists_action=skip parallel=4



--�ָ���ǰ��־�ļ�
--һ�����INACTIVE��־���Աȫ������
    --alter system switch logfile;
    select * from v$log;        --������־��1��INACTIVE��
        /*
        1    1    10    52428800    512    2    YES    INACTIVE    1385322    2016/11/12 13:09:06    1385327    2016/11/12 13:09:16
        2    1    11    52428800    512    2    NO    CURRENT    1385327    2016/11/12 13:09:16    281474976710655    
        3    1    9    52428800    512    2    YES    INACTIVE    1385315    2016/11/12 13:08:49    1385322    2016/11/12 13:09:06
        */
    select lf.*,'rm '||member from v$logfile lf order by group#,member;
    su - grid
    asmcmd
    rm +DATA/orcl/onlinelog/group_1.261.927684603
    rm +FRA/orcl/onlinelog/group_1.257.927713409

    SQL> shutdown immediate;
    SQL> startup mount
    ASMCMD> rm +DATA/orcl/onlinelog/group_1.261.927684603
    ASMCMD> rm +FRA/orcl/onlinelog/group_1.257.927713409
    SQL> alter database open;
        /*alter database open
        *
        ERROR at line 1:
        ORA-03113: end-of-file on communication channel
        Process ID: 11210
        Session ID: 1 Serial number: 5
        */
    SQL> exit
    SQL> startup mount
    RMAN> list failure;
        /*
        1779       CRITICAL OPEN      12-NOV-16     Redo log group 1 is unavailable
        1785       HIGH     OPEN      12-NOV-16     Redo log file +FRA/orcl/onlinelog/group_1.257.927713409 is missing
        1782       HIGH     OPEN      12-NOV-16     Redo log file +DATA/orcl/onlinelog/group_1.261.927684603 is missing
        */
    RMAN> list failure all;
    RMAN> advise failure; 
        /*
        Option Repair Description
        ------ ------------------
        1      Clear redo log group 1  
          Strategy: The repair includes complete media recovery with no data loss
          Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_2433095712.hm
        */       
    [root@localhost ~]# cat /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_2433095712.hm
        begin
        /*Clear the Log Group*/
        execute immediate 'ALTER DATABASE CLEAR LOGFILE GROUP 1';
        end;
      
      --ALTER DATABASE CLEAR LOGFILE GROUP 1
    RMAN> repair failure;
    --RMAN> ALTER DATABASE open;

--һ����־�黵��һ����Ա
    alter system switch logfile;
    select * from v$log;
        /*      ������־��3��active��
        1    1    13    52428800    512    2    NO    CURRENT    1386670    2016/11/12 13:20:02    281474976710655    
        2    1    11    52428800    512    2    YES    INACTIVE    1385327    2016/11/12 13:09:16    1385362    2016/11/12 13:10:04
        3    1    12    52428800    512    2    YES    ACTIVE    1385362    2016/11/12 13:10:04    1386670    2016/11/12 13:20:02
        */    
    select * from v$logfile order by group#,member;

    rm +FRA/orcl/onlinelog/group_3.259.927713435
    RMAN> shutdown immediate;
    RMAN> startup mount

    rm +FRA/orcl/onlinelog/group_3.259.927713435
     list failure;
     list failure all;
     advise failure; 
    ALTER DATABASE ADD LOGFILE MEMBER '+fra'  REUSE TO GROUP 2;
    alter system switch logfile;
    ALTER DATABASE DROP LOGFILE MEMBER '+FRA/orcl/onlinelog/group_2.258.926515581';
    select * from v$logfile order by group#,member;
    rman target /
     list failure;
        --385        HIGH     OPEN      2016-08-20 09:47:10 Redo log file +DATA/ocp/onlinelog/group_1.256.919868623 is missing
     --list failure all;
     advise failure; 
     --������
     repair failure;
     select status from v$instance;

/*
--һ��INACTIVE��־����־�ļ���ʧ
    select * from v$log;
    select lf.*,'rm '||member from v$logfile lf order by group#,member;
    su - grid
    asmcmd
    rm +DATA/orcl/onlinelog/group_1.261.926515539
    rm +FRA/orcl/onlinelog/group_1.257.926515555

    SQL> shutdown immediate;
    SQL> startup mount

    rm +DATA/orcl/onlinelog/group_1.261.926515539
    rm +FRA/orcl/onlinelog/group_1.257.926515555

    RMAN> list failure;
    RMAN> list failure all;
    RMAN> advise failure; 
        -- #   Strategy: The repair includes complete media recovery with no data loss
      Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_3106898201.hm
    [root@localhost ~]# cat /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_3106898201.hm
       # recover database until cancel and open resetlogs
       sql 'alter database recover database until cancel';
       alter database open resetlogs;
    RMAN> repair failure;
    */

--��ǰ���־����
alter system switch logfile;
RMAN> backup database plus archivelog ;
select * from v$log; 
    /*              #���ڵĻ��־����group2
    1    1    28    52428800    512    2    YES    ACTIVE    1389576    2016/11/12 13:50:24    1389652    2016/11/12 13:51:37
    2    1    29    52428800    512    2    NO    CURRENT    1389652    2016/11/12 13:51:37    281474976710655    
    3    1    27    52428800    512    2    YES    ACTIVE    1389451    2016/11/12 13:47:02    1389576    2016/11/12 13:50:24
    */
select * from v$logfile order by group#,member;
    /*
    2        ONLINE    +DATA/orcl/onlinelog/group_2.262.927713415    NO
    2        ONLINE    +FRA/orcl/onlinelog/group_2.258.927713421    YES
    */

SQL> shutdown immediate  
ASMCMD> rm +DATA/orcl/onlinelog/group_2.262.927713415
ASMCMD> rm +FRA/orcl/onlinelog/group_2.258.927713421
 /*
    SQL> startup
    ORACLE instance started.

    Total System Global Area 1787138048 bytes
    Fixed Size                  2254104 bytes
    Variable Size            1006635752 bytes
    Database Buffers          771751936 bytes
    Redo Buffers                6496256 bytes
    Database mounted.
    ORA-00313: open failed for members of log group 3 of thread 1
    ORA-00312: online log 3 thread 1: '+FRA/ocp/onlinelog/group_3.259.914844673'
    ORA-17503: ksfdopn:2 Failed to open file
    +FRA/ocp/onlinelog/group_3.259.914844673
    ORA-15012: ASM file '+FRA/ocp/onlinelog/group_3.259.914844673' does not exist
    ORA-00312: online log 3 thread 1: '+DATA/ocp/onlinelog/group_3.263.914844673'
    ORA-17503: ksfdopn:2 Failed to open file
    +DATA/ocp/onlinelog/group_3.263.914844673
    ORA-15012: ASM file '+DATA/ocp/onlinelog/group_3.263.914844673' does not exist
    ORA-00312: online log 3 thread 1:
    '/u01/app/oracle/fast_recovery_area/ocp/redo03.log'
    ORA-27037: unable to obtain file status
    Linux-x86_64 Error: 2: No such file or directory
    Additional information: 3


    SQL> select status from v$instance;

    STATUS
    ------------
    MOUNTED
    */
 3    1    30    52428800    512    3    NO    CURRENT    1958073    2016/6/18 14:25:51    281474976710655       
 list failure;
 advise failure;
 repair failure;
 select status from v$instance;
 
  restore database until scn 1958073;
   recover database until scn 1958073;
   alter database open resetlogs;
   select status from v$instance;
   
   restore database until sequence 30;
   recover database until sequence 1958073;
   alter database open resetlogs;
   restore database until time "to_date('2016/6/18 14:25:51', 'YYYY-MM-DD HH24:MI:SS')";
   recover database until time "to_date('2016/6/18 14:25:51', 'YYYY-MM-DD HH24:MI:SS')";
   alter database open resetlogs;
   
   
select 'rm '||MEMBER rm_CURRENT_log from v$logfile where group# in (select group# from v$log where status='CURRENT') order by group#,member;
  # database point-in-time recovery
   restore database until scn 1679746;
   recover database until scn 1679746;
   alter database open resetlogs;
   1386546
   sql 'alter database recover database until cancel';
   alter database open resetlogs;
list failure;
list failure all;
advise failure;
    Automated Repair Options
    ========================
    Option Repair Description
    ------ ------------------
    1      ִ�е� SCN 1582313 �Ĳ���ȫ���ݿ�ָ�  
      Strategy: �޸����������ᶪʧ�������ݵ�ʱ���ָ�
      Repair script: /u01/app/oracle/diag/rdbms/ocp/ocp/hm/reco_1639996943.hm
repair failure;
  rman target /
shutdown abort
startup mount
  restore database until scn 1582313;
   recover database until scn 1582313;
   alter database open resetlogs;


--�������ݿ�
--��ɾ���û�
Drop user hr cascade;
--����Ҫ�ָ�����Ҫ�ָ����������ļ�
�����ļ�   ����        ��                   �ɶ�ʧ,dataguard�ر�       sysԶ������
�����ļ�   ���ػ�asm   ��                   ���ɶ�ʧ                   ���ݿ�nomount
�����ļ�   asm         ��                   ���ɶ�ʧ                   mount
�����ļ�   asm         ��                   ���ɶ�ʧ                   open,�û�dml,ddl,dcl

--�и��򵥵ķ������������ݿ�
  �鿴alert��־����drop�Ĳ�����¼
--�ȿ���
    select name,current_scn,flashback_on ,DB_UNIQUE_NAME from v$database;
     select * from v$version;
    shutdown immediate
    startup mount ;
    --11.2.0.3.0 open��Ҳ����ֱ�Ӳ���    
    alter database flashback on;
    truncate table hr.JOB_HISTORY;
--����־�ھ�����ʱ���: 
    
    shutdown immediate
        startup mount
        set timing on;
    flashback database to scn 1382595;
    flashback database to timestamp to_timestamp('2016-11-12 11:15:00','yyyy-mm-dd hh24:mi:ss');
    alter database open read only;
    select * from hr.JOB_HISTORY;
        --select count(1) from hr.COUNTRIES_bak;
        --û�����
        shutdown immediate
        startup mount
        alter database open resetlogs;
        --���������ظ�����Ĺ���

    --�����ص�����ʱ��
    select * from v$flashback_database_log;


--7*24,���ֱ�������
    alter database flashback on;
    ORA-01153: �����˲����ݵĽ��ʻָ�
    alter database recover managed standby database cancel; --dba
    alter database flashback on;
    ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE disconnect;--sysdba

    show parameter db_flashback_retention_target;
    --db_flashback_retention_target 1440 minute=1day
    --modify to 3days
    alter system set db_flashback_retention_target=4320 scope=both sid='*';
    --�������ص��ĸ�ʱ���
    select * from v$flashback_database_log;
    select * from  v$database;

    ֱ�Ӷ����������ء�
    alter database recover managed standby database cancel;
    shutdown immediate
    startup nomount
    alter database mount standby database;
    flashback database to scn 35659021;
    alter database open ;--read 
     exp���ݵ�����,����û���ɾ��������
    ��ȡ������
    shutdown immediate
    startup nomount
    alter database mount standby database;
    alter database open read only;
    ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE disconnect;


--���ر�
    --ģ��������*
        delete from hr.JOB_HISTORY where EMPLOYEE_ID=200;
        commit;
    Insert into "HR"."JOB_HISTORY"
       (EMPLOYEE_ID, START_DATE, END_DATE, JOB_ID, DEPARTMENT_ID)
     Values
       (107, TO_DATE('07/01/2002 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('12/31/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), 'AC_ACCOUNT', 90);
    Insert into "HR"."JOB_HISTORY"
       (EMPLOYEE_ID, START_DATE, END_DATE, JOB_ID, DEPARTMENT_ID)
     Values
       (107, TO_DATE('09/17/1995 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('06/17/2001 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), 'AD_ASST', 90);
    COMMIT;

     commit;
    --��ʼ����
       select * from FLASHBACK_TRANSACTION_QUERY 
     where table_name in (upper('JOB_HISTORY')) order by START_SCN;
     /*
    0500170062040000    1419390    2016/11/12 16:10:25    1419476    2016/11/12 16:10:28    SYS    1    UNKNOWN    JOB_HISTORY
    0500170062040000    1419390    2016/11/12 16:10:25    1419476    2016/11/12 16:10:28    SYS    2    UNKNOWN    JOB_HISTORY
    0700020091030000    1419733    2016/11/12 16:11:04    1419737    2016/11/12 16:11:13    SYS    1    UNKNOWN    JOB_HISTORY
    0700020091030000    1419733    2016/11/12 16:11:04    1419737    2016/11/12 16:11:13    SYS    2    UNKNOWN    JOB_HISTORY                    
    */
    select * from hr.JOB_HISTORY as of scn 1419390 order by 1;
    --��200��¼,��107
    select * from hr.JOB_HISTORY order by 1;
    --��200��¼,��107
    flashback table hr.JOB_HISTORY to  scn 1419390;
        --ORA-08189: ��Ϊδ�������ƶ�����, �������ر�
    alter table    hr.JOB_HISTORY enable row movement;
    flashback table hr.JOB_HISTORY to  scn 1419390;
    select * from hr.JOB_HISTORY order by 1;
    --200������,����107��ɾ����

    select * from hr.JOB_HISTORY as of timestamp to_date(to_char(sysdate,'yyyy-mm-dd')||' 10:00','yyyy-mm-dd hh24:mi:ss');
    select * from hr.JOB_HISTORY where EMPLOYEE_ID=200;
    flashback table hr.JOB_HISTORY to  timestamp to_date(to_char(sysdate,'yyyy-mm-dd')||' 10:00','yyyy-mm-dd hh24:mi:ss');
        --ORA-08189: ��Ϊδ�������ƶ�����, �������ر�
    alter table    hr.JOB_HISTORY enable row movement;
    flashback table hr.JOB_HISTORY to  timestamp to_date(to_char(sysdate,'yyyy-mm-dd')||' 10:00','yyyy-mm-dd hh24:mi:ss');
--һ�����������һ�ű���������ݡ�����������֮�����кܶ���ȥ�޸����ű�
--��ô�����ر�֮��ֻ�ǻָ���֮ǰ���˵����������ô֮��ĺܶ��˵���ȷ���������ݾ�û���ˣ����Ҳ��ָܻ���
--��������������ȡ��,����ȡ������������޸�

--��������
--��־�ھ򣬱���������С������־ 
alter database add supplemental log data;
--ֱ��ִ��undo_sql���ð�����
RMAN> delete noprompt  archivelog until time "to_date('20161112 153000','yyyymmdd hh24miss')";

    DECLARE
       xids   SYS.xid_array;
    BEGIN
       xids := sys.xid_array ('03000E0059040000');
       DBMS_FLASHBACK.transaction_backout (1,--��һ��������ʾVARRAY������ŵ�������������ֻ��һ��������Ҫ���������Ե���1��
                                           xids,
                                           options   => DBMS_FLASHBACK.nocascade);
    END;
    /
    "HR"."JOB_HISTORY"
    --commit;
    --��飬������Ա��������Ա���û�����ûcommit���ǿ�����

    select * from "HR"."JOB_HISTORY" where EMPLOYEE_ID=200;
        --�����ɾ��200�������
    select * from "HR"."JOB_HISTORY" where EMPLOYEE_ID=107;
        --�����˵Ĳ�������
    commit;



--����
select supplemental_log_data_min,--logmnr or goldendate
supplemental_log_data_pk, --oem flashback tranction
supplemental_log_data_ui,
supplemental_log_data_fk,
supplemental_log_data_all,
FORCE_LOGGING, --datagard
LOG_MODE
from v$database;
--��־�ھ򣬱���������С������־ 
alter database add supplemental log data;
--�����oem����������������
alter database add supplemental log data (primary key) columns;
alter system switch logfile;


--���ر�ɾ��
drop table hr.JOB_HISTORY;
select * from hr.JOB_HISTORY;
    --ORA-00942: �����ͼ������
flashback table hr.JOB_HISTORY to before drop;
select * from hr.JOB_HISTORY;




--����redo size
 set pagesize 1000
    set linesize 2000
    SET TRIMSPOOL on
    col name for a30
    --redo��С
        --datagard
    select FORCE_LOGGING  from v$database;
    column redo_size new_val redo_size_begin
    select s.name, m.value redo_size from v$mystat m, v$statname s where s.statistic# = m.statistic# and s.name='redo size';
        create table hr.employees_dup nologging as select * from hr.employees;
    --redo��С,�õ�ǰֵ�Ϳ�ʼֵ�Ƚ�
    select s.name, m.value ,to_char(m.value-&redo_size_begin,'999,999,999,999') redo_size_diff from v$mystat m, v$statname s where s.statistic# = m.statistic# and s.name='redo size';

table���ʱnologging����ô����Ĳ������ͻ�������ٵ���־
insert /*+ append */ into scott.big_table_dup select * from scott.big_table nologging;






--�޷�Ǩ�ƣ�����ֻ��goldengate�ܹ�ʵ��
--�ڸ�����ͬ�����ݿ⣬��ͬ�����ݿ�汾��Ǩ������


--��־�ھ�




--job
--�ϵ�job�Ѿ���ʹ����
DECLARE
  X NUMBER;
  user_name varchar2(30);
BEGIN
  select user into user_name from dual;
  execute immediate 'alter session set current_schema = IBOXCLEAR';
  BEGIN
    SYS.DBMS_JOB.SUBMIT
    ( job       => X 
     ,what      => 'SpAddToMchofChannls(to_char(sysdate,''yyyymmdd''));'
     ,next_date => to_date('20/11/2016 05:00:00','dd/mm/yyyy hh24:mi:ss')
     ,interval  => 'trunc(sysdate)+1+5/24'
     ,no_parse  => FALSE
    );
    SYS.DBMS_OUTPUT.PUT_LINE('Job Number is: ' || to_char(x));
    execute immediate 'alter session set current_schema = ' || user_name ;
  EXCEPTION
    WHEN OTHERS THEN 
      execute immediate 'alter session set current_schema = ' || user_name ;
      RAISE;
  END;
  COMMIT;
END;
/

DECLARE
  X NUMBER;
BEGIN
  SYS.DBMS_JOB.SUBMIT
    (
      job        => X
     ,what       => 'HR.secure_dml;'
     ,next_date  => to_date('04/15/2015 14:28:40','mm/dd/yyyy hh24:mi:ss')
     ,interval   => 'SYSDATE+1/1440 '
     ,no_parse   => FALSE
     ,instance  => 0
     ,force     => TRUE
    );
END;
/

--��job
--schedule job
--job����
    --procedure
    --PLSQL_BLOCK
    --chain��ҵ��
        --chain��ҵ����һ��������ִ����һ�������۳ɹ�ʧ��(���ֲ�������
        --chain��ҵ����һ���ɹ���ִ����һ��
--����һ��ִ�е�job
--����һ����ִ��һ�ε�job
--�������ſ�ʼִ�е�job
--job�ֶ�ִ��
--jobֹͣ
--schedule job��־ ���7��
--Ŀǰ�������е�job��schedule job
--schedule job�б�
--job����

--PLSQL_BLOCK
BEGIN
    sys.dbms_scheduler.create_job( 
    job_name => 'job_GATHER_DATABASE_STATS',
    job_type => 'PLSQL_BLOCK',
    job_action => 'begin 
        DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC; 
          end;',
    repeat_interval => 'FREQ=DAILY;BYHOUR=5;BYMINUTE=00;BYSECOND=0',
    start_date => systimestamp at time zone 'Asia/Shanghai'+100,--100����ִ�е�job
    job_class =>'DEFAULT_JOB_CLASS',
    comments => 'sysdbaȫ��ɼ�ͳ����Ϣ����ֹ����',
    auto_drop => FALSE,
    enabled => false);--����Ч
END;




--ˢ���ڴ��,ģ���������ݿ�.
  --����,�ڶ���ˢ�¹����,������sharepool�Ĵ�������,Ҫ�ڷ�ҵ��߷�����(0���)
    alter system flush buffer_cache;
    alter system flush shared_pool; 
    alter system flush global CONTEXT;  



--���ʻ�
--�鿴���ݿ��ַ���
select 
(select value from nls_instance_parameters where parameter in ('NLS_LANGUAGE'))
||'_'||
(select value from nls_instance_parameters where parameter in ('NLS_TERRITORY')
)
||'.'||
(select value from v$nls_parameters where parameter in ('NLS_CHARACTERSET')
)
from dual;
AMERICAN_AMERICA.AL32UTF8
SIMPLIFIED CHINESE_CHINA.ZHS16GBK
--windows
--linux     
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8 
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8" 


create table scott.test_charset (name varchar2(10)); --byte
insert into scott.test_charset values('�й�');
commit;
select name,length(name),lengthb(name) from scott.test_charset;


create table scott.test_charset2 (name varchar2(10 char));
insert into scott.test_charset2 values('�й�');
commit;
select name,length(name),lengthb(name) from scott.test_charset2;


insert into scott.test_charset2 values('�л����񹲺͹�');
commit;
select name,length(name),lengthb(name) from scott.test_charset2;
commit;
select name,length(name),lengthb(name) from scott.test_charset;

insert into scott.test_charset2 values('�л����񹲺͹�');
commit;
select name,length(name),lengthb(name) from scott.test_charset2;


select * from nls_database_parameters;


--�ڵ��뵼����ʱ�������ַ���
--windows
 set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
--linux
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8" 















