system/B0x_sYsteM27@aix
spool .\result\daycheck.log
SET ECHO ON
set head off
SELECT UTL_INADDR.GET_HOST_ADDRESS, 
SYS_CONTEXT('userenv', 'ip_address')
FROM DUAL;
--验证同步
select   current_scn from v$database@dgp
union all
select   current_scn from v$database@dgs;
select sequence#,applied from v$archived_log@dgs order by 1 desc; 
spool off
set echo off
set head off
set sqlblanklines on
--set wrap off
--set linesize 1500
set feedback off 
spool .\result\list.txt
select 'select count(1) from  ' ||owner||'.'||TABLE_NAME||'@dgp'||chr(10)||
 ' union all '||chr(10)||
  'select count(1) from  ' ||owner||'.'||TABLE_NAME||'@dgs;' countsql
  from dba_tables
  where owner not in ('SYS','SYSTEM', 'DBSNMP', 'SYSMAN','APEX_030200','APPQOSSYS',
  'CTXSYS','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORDDATA','ORDSYS','OUTLN','OWBSYS','SCOTT','WMSYS','XDB','HR','IX','OE','PM','SH')
  order by owner;
spool off
set echo on
set head on
set feedback on
spool .\result\logverify.log
@result\list.txt
spool off
exit


APEX_030200
APPQOSSYS
CTXSYS
DBSNMP
EXFSYS
FLOWS_FILES
HR
IX
MDSYS
OE
OLAPSYS
ORDDATA
ORDSYS
OUTLN
OWBSYS
PM
SCOTT
SH
SYS
SYSMAN
SYSTEM
TXY
WMSYS
XDB