#!/bin/bash
runner=`whoami`
[ $runner != 'oracle' ] && echo 'Pls run this scripts by user:oracle!' && exit;

. /home/oracle/.bash_profile
#tmp_scripts_dir=/tmp/.pre_check
host_name=`hostname`
output_dir=/tmp/pre_check_data_`date +%Y%m%d`
zip_file=/tmp/pre_check_data_${ORACLE_SID}_`date +%Y%m%d`.zip



#[ -z $DISPLAY ] && echo 'Pls set DISPLAY avariable!' && exit;

[ -d ${output_dir} ] && echo 'OUTPUT dir already exist,pls check!' && exit;

mkdir -p ${output_dir}
chmod -R 777 ${output_dir}

#[ -d ${tmp_scripts_dir} ] && rm -rf ${tmp_scripts_dir}


echo "###oracle_os_check"
#sh ${tmp_scripts_dir}/oracle_os_check.sh


output_file=${output_dir}/${host_name}_oracle_os_check.output


echo "========================================== ENV info ==============================================" > ${output_file}
hostname  >>${output_file}
whoami    >>${output_file}
cat /proc/meminfo >>${output_file}

#ip
echo "========================================== ip ==============================================" >>${output_file}
ifconfig -a >>${output_file}
cat /etc/hosts >>${output_file}

#env
echo "========================================== env parameter ==============================================" >>${output_file}
cat /home/oracle/.bash_profile | grep -v '^#' | grep -v '^$' >>${output_file}

#kenerl parameter
echo "========================================== kenerl parameter ==============================================" >>${output_file}
cat /etc/sysctl.conf | grep -v '^#' | grep -v '^$' >>${output_file}



#limits.conf
echo "========================================== limits.conf ==============================================" >>${output_file}
cat /etc/security/limits.conf | grep -v '^#' | grep -v '^$' >>${output_file}
ulimit -a >>${output_file}

#selinux
echo "========================================== selinux ==============================================" >>${output_file}
cat /etc/selinux/config | grep -v '^#' | grep -v '^$' >>${output_file}

#firewalld
echo "========================================== firewalld ==============================================" >>${output_file}
systemctl status firewalld >>${output_file}

#filesystem
echo "========================================== filesystem ==============================================" >>${output_file}
df -h  >>${output_file}

#oracle user
echo "========================================== user:oracle ==============================================" >>${output_file}
id oracle >>${output_file}


#crontab
echo "========================================== crontabl:oracle ==============================================" >>${output_file}
crontab -l >>${output_file}

#listener
echo "========================================== listener ==============================================" >>${output_file}
lsnrctl status   >>${output_file} 
echo " "         >>${output_file} 
lsnrctl service  >>${output_file} 

#tnsnames.ora
echo "========================================== tnsnames.ora ==============================================" >>${output_file}
cat $ORACLE_HOME/network/admin/tnsnames.ora  >>${output_file} 

#listener.ora
echo "========================================== listener.ora ==============================================" >>${output_file}
cat $ORACLE_HOME/network/admin/listener.ora  >>${output_file}

#sqlnet.ora
echo "========================================== sqlnet.ora ==============================================" >>${output_file}
cat $ORACLE_HOME/network/admin/sqlnet.ora    >>${output_file}

#scripts
echo "========================================== scripts ==============================================" >>${output_file}
ls -l ~/scripts         >>${output_file}
echo " "                >>${output_file}
#ls -l ~/scripts/v0.1    >>${output_file}

#VERSION
echo "========================================== ORACLE VERSION ==============================================" >>${output_file}
$ORACLE_HOME/OPatch/opatch lsinventory >>${output_file}


#alert log
#get alert log filename
sqlplus -S "/ as sysdba" >/dev/null  <<EOF
set pagesize
col VALUE format a80
spool /tmp/.AlertFileName.out
select value||'/alert_'||instance_name||'.log' from v\$diag_info,v\$instance where name= 'Diag Trace';
spool off
exit
EOF


if [ $? -ne 0 ]
        then
        echo "Spool alert log file name to tempfile failed!"
        exit
fi

ALERT_FILE=`grep alert /tmp/.AlertFileName.out`

if [ -z ${ALERT_FILE} ]
        then
        echo "The Alert log file name is null!"
  exit
fi

if [ ! -f ${ALERT_FILE} ]
        then
        echo "The Alert log file ${ALERT_FILE} not found!"
  exit
fi

cp ${ALERT_FILE} ${output_dir}/




echo "###oracle_db_check"
#sh ${tmp_scripts_dir}/oracle_db_check.sh

db_output_file=${output_dir}/${host_name}_${ORACLE_SID}_oracle_db_check.html
basedir=`dirname $0`

line_cnt=`ps -ef | grep pmon | grep -v grep | wc -l`

if [ ${line_cnt} -eq 0 ] 
then
    echo "The instance not running on this node!" >  ${output_file}
    exit
fi


sqlplus -M "html on" -S / as sysdba > ${db_output_file} <<eof
set line 500
set pages 9999
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
alter session set nls_timestamp_format='YYYY-MM-DD HH24:MI:SS';

prompt ================= ENV info =======================
select a.inst_id,a.instance_name,a.status,logins,startup_time,a.host_name,b.dbid,b.name,b.database_role,b.open_mode from gv\$instance a, gv\$database b where a.inst_id = b.inst_id;

prompt ================= service_names =================
select inst_id,name,display_value from gv\$parameter where name ='service_names';

prompt ================= SUMMARY =================

col stat_name for a30
col value for 99999999999999999
select inst_id,stat_name,value from (
select inst_id,stat_name,value value 
from gv\$osstat where stat_name in ('NUM_CPUS','PHYSICAL_MEMORY_BYTES') order by 2,1);


select 'db_name: '||name from v\$database union all
select 'instance: '||instance_name from v\$instance   union all
select 'DBID: '||DBID from v\$database   union all
select 'version: '||version from v\$instance   union all
select 'tablespace_cnt: '||count(*) from dba_tablespaces   union all
select 'datafile_cnt: '||count(*) from
(
select file# from v\$datafile
union all
select file# from v\$tempfile)   union all
select 'datafiles_TotoalSize: '||trunc(sum(bytes)/1024/1024/1024)||'GB' from (
select bytes from v\$datafile
union all
select bytes from v\$tempfile)   union all
select 'controlfile: '||count(*) from v\$controlfile   union all
select distinct 'thread: '||thread#||','||'redo_size: '||bytes/1024/1024||'M' from v\$log   union all
select 'thread: '||thread#||','||'redo_gps: '||count(*) from v\$log group by thread#   union all
select distinct 'thread: '||thread#||','||'redo_members: '||members from v\$log   union all
select 'archivelog: '||decode(log_mode,'ARCHIVELOG','Y','N') from v\$database   union all
select 'flashback: '||FLASHBACK_ON from v\$database union all
select 'thread: '||thread#||','||'max_seq: '||max(sequence#) from v\$log group by thread#;



prompt ================= BLOCKSIZE =================
select inst_id,name,display_value from gv\$parameter where name='db_block_size';

prompt ================= DATABASE PROPERTIES =================
col PROPERTY_VALUE for a40
select property_name,property_value from database_properties a where a.property_name in (
'DEFAULT_TEMP_TABLESPACE',
'DEFAULT_PERMANENT_TABLESPACE',
'DBTIMEZONE',
'DEFAULT_TBS_TYPE',
'NLS_LANGUAGE',
'NLS_TERRITORY',
'NLS_CURRENCY',
'NLS_ISO_CURRENCY',
'NLS_NUMERIC_CHARACTERS',
'NLS_CHARACTERSET',
'NLS_CALENDAR',
'NLS_DATE_FORMAT',
'NLS_DATE_LANGUAGE',
'NLS_SORT',
'NLS_TIME_FORMAT',
'NLS_TIMESTAMP_FORMAT',
'NLS_TIME_TZ_FORMAT',
'NLS_TIMESTAMP_TZ_FORMAT',
'NLS_DUAL_CURRENCY',
'NLS_COMP',
'NLS_LENGTH_SEMANTICS',
'NLS_NCHAR_CONV_EXCP',
'NLS_NCHAR_CHARACTERSET',
'NLS_RDBMS_VERSION',
'GLOBAL_DB_NAME',
'EXPORT_VIEWS_VERSION'
) order by 1;


prompt ================= parameters =================
col name for a40
col display_value for a100
select inst_id,name,display_value from gv\$parameter where name = 'audit_sys_operations' union all 
select inst_id,name,display_value from gv\$parameter where name = 'audit_trail' union all
select inst_id,name,display_value from gv\$parameter where name = 'filesystemio_options' union all
select inst_id,name,display_value from gv\$parameter where name = 'db_files' union all
select inst_id,name,display_value from gv\$parameter where name = 'archive_lag_target' union all
select inst_id,name,display_value from gv\$parameter where name = 'db_block_checking' union all
select inst_id,name,display_value from gv\$parameter where name = 'control_file_record_keep_time' union all
select inst_id,name,display_value from gv\$parameter where name = 'db_writer_processes' union all
select inst_id,name,display_value from gv\$parameter where name = 'open_cursors' union all
select inst_id,name,display_value from gv\$parameter where name = 'session_cached_cursors' union all
select inst_id,name,display_value from gv\$parameter where name = 'deferred_segment_creation' union all
select inst_id,name,display_value from gv\$parameter where name = 'job_queue_processes' union all

select inst_id,name,display_value from gv\$parameter where name = 'parallel_max_servers' union all
select inst_id,name,display_value from gv\$parameter where name = '_optimizer_use_feedback' union all
select inst_id,name,display_value from gv\$parameter where name = '_optimizer_mjc_enabled' union all
select inst_id,name,display_value from gv\$parameter where name = '_datafile_write_errors_crash_instance' union all 
select inst_id,name,display_value from gv\$parameter where name = '_cleanup_rollback_entries' union all 
select inst_id,name,display_value from gv\$parameter where name = 'enable_ddl_logging' union all 
select inst_id,name,display_value from gv\$parameter where name = 'resource_limit' union all 
select inst_id,name,display_value from gv\$parameter where name = '_PX_use_large_pool' union all 
select inst_id,name,display_value from gv\$parameter where name = 'event' union all 

select inst_id,name,display_value from gv\$parameter where name = 'db_flashback_retention_target' union all 
select inst_id,name,display_value from gv\$parameter where name = 'db_recovery_file_dest' union all 
select inst_id,name,display_value from gv\$parameter where name = 'db_recovery_file_dest_size' union all 
select inst_id,name,display_value from gv\$parameter where name = 'resource_manager_plan' union all  
 
select inst_id,name,display_value from gv\$parameter where name = 'processes' union all 
select inst_id,name,display_value from gv\$parameter where name = 'recyclebin';

prompt =================rac parameters =================
select inst_id,name,display_value from gv\$parameter where name = '_cgs_health_check_in_reconfig' union all 
select inst_id,name,display_value from gv\$parameter where name = '_clusterwide_global_transactions' union all 
select inst_id,name,display_value from gv\$parameter where name = 'gcs_server_processes' union all 
select inst_id,name,display_value from gv\$parameter where name = '_gc_defer_time' union all 
select inst_id,name,display_value from gv\$parameter where name = '_gc_policy_time' union all 
select inst_id,name,display_value from gv\$parameter where name = '_gc_read_mostly_locking' union all 
select inst_id,name,display_value from gv\$parameter where name = '_gc_undo_affinity' union all 
select inst_id,name,display_value from gv\$parameter where name = 'parallel_force_local';

prompt ================= memory parameters =================
select inst_id,name,display_value from gv\$parameter where name = 'memory_max_target' union all 
select inst_id,name,display_value from gv\$parameter where name = 'memory_target' union all 
select inst_id,name,display_value from gv\$parameter where name = 'large_pool_size' union all 
select inst_id,name,display_value from gv\$parameter where name = 'shared_pool_size' union all 
select inst_id,name,display_value from gv\$parameter where name = '_disable_streams_pool_auto_tuning' union all 
select inst_id,name,display_value from gv\$parameter where name = 'streams_pool_size' union all 
select inst_id,name,display_value from gv\$parameter where name = 'db_cache_size' union all 
select inst_id,name,display_value from gv\$parameter where name = 'pga_aggregate_target' union all 
select inst_id,name,display_value from gv\$parameter where name = 'sga_target';



prompt ================= awr control =================
SELECT * FROM DBA_HIST_WR_CONTROL;

prompt ================= autotask window =================
select WINDOW_NAME,REPEAT_INTERVAL,DURATION,ENABLED from dba_scheduler_windows;



prompt ================= control file =================
select decode(status,null,'OK',status) status,name,trunc(block_size*file_size_blks/1024/1024) "SIZE(MB)" from v\$controlfile;

prompt ================= redolog file =================
col member for a60
select a.group#,thread#,sequence#,bytes/1024/1024 "SIZE(MB)",members,archived,a.status,type,member
from v\$log a,v\$logfile b where a.group# = b.group# order by thread#,group#;

prompt ================= data file =================
select tablespace_name,file_id,file_name,sizes "SIZE(MB)",status,autoextensible,max_size,increment_by
from (
select tablespace_name,file_id,file_name,bytes/1024/1024 sizes,status,autoextensible,maxbytes/1024/1024 max_size,increment_by from dba_data_files
UNION ALL
select tablespace_name,file_id,file_name,bytes/1024/1024,status,autoextensible,maxbytes/1024/1024,increment_by/1024 from dba_temp_files);



prompt ================= tablespace usage =================
col TOTAL_SPACE for 9999999999
col SPACE_USED for 9999999999
col space_used_pct for 9999999999
select a.TABLESPACE_NAME,b.extent_management,b.segment_space_management,TOTAL_SPACE "TOTAL_SPACE(MB)",SPACE_USED "SPACE_USED(MB)",FREE_SPACE "FREE_SPACE(MB)",SPACE_USED_PCT from  (
SELECT D.TABLESPACE_NAME TABLESPACE_NAME,
       SPACE  TOTAL_SPACE,
       SPACE - NVL(FREE_SPACE, 0) SPACE_USED,
       FREE_SPACE,
       ROUND((1 - NVL(FREE_SPACE, 0) / SPACE) * 100, 2) || '%' SPACE_USED_PCT
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
               SUM(BLOCKS) BLOCKS,
               round(sum(decode(maxbytes, 0, bytes, maxbytes) / 1024 / 1024),
                     2) max_space
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) FREE_SPACE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F
WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
UNION ALL
select a.tablespace_name,total_space,nvl(used_space,0) used_space,(total_space-nvl(used_space,0)) free_space,trunc((nvl(used_space,0)/total_space)*100,1)||'%' used_pct
from
(select tablespace_name,sum(bytes)/1024/1024 total_space from dba_temp_files  group by tablespace_name) a,
(select su.tablespace,sum(su.blocks*dt.block_size)/1024/1024 used_space from v\$sort_usage su,dba_tablespaces dt where su.tablespace = dt.tablespace_name group by tablespace) b
where a.tablespace_name = b.tablespace(+)
) a , dba_tablespaces b where a.TABLESPACE_NAME = b.tablespace_name;



select 'TOTAL_USED(exclude undo,temp): '||sum(space_used) ||' MB' from (
SELECT D.TABLESPACE_NAME TABLESPACE_NAME,
       SPACE  TOTAL_SPACE,
       SPACE - NVL(FREE_SPACE, 0) SPACE_USED,
       FREE_SPACE
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
               SUM(BLOCKS) BLOCKS,
               round(sum(decode(maxbytes, 0, bytes, maxbytes) / 1024 / 1024),
                     2) max_space
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) FREE_SPACE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F,
         DBA_TABLESPACES G
WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+) and d.tablespace_name = g.tablespace_name and g.contents <> 'UNDO'
);


SELECT 'TOTAL_USED FOR APPLICATION: '||round(SUM(USED_SPACE)/1024/1024) ||' MB' from (
      SELECT D.TABLESPACE_NAME TABLESPACE_NAME,
             SPACE ,
             NVL(FREE_SPACE,0) FREE_SPACE,
             SPACE - NVL(FREE_SPACE, 0) USED_SPACE
        FROM (SELECT TABLESPACE_NAME,
                     SUM(BYTES) SPACE
                FROM DBA_DATA_FILES WHERE tablespace_name like '%/_TBS' escape '/'
               GROUP BY TABLESPACE_NAME) D,
             (SELECT TABLESPACE_NAME,
                     SUM(BYTES) FREE_SPACE
                FROM DBA_FREE_SPACE WHERE tablespace_name like '%/_TBS' escape '/'
               GROUP BY TABLESPACE_NAME
             ) F
       WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
      );


prompt ================= log_history =================
col 00 for '999'
col 01 for '999'
col 02 for '999'
col 03 for '999'
col 04 for '999'
col 05 for '999'
col 06 for '999'
col 07 for '999'
col 08 for '999'
col 09 for '999'
col 10 for '999'
col 11 for '999'
col 12 for '999'
col 13 for '999'
col 14 for '999'
col 15 for '999'
col 16 for '999'
col 17 for '999'
col 18 for '999'
col 19 for '999'
col 20 for '999'
col 21 for '999'
col 22 for '999'
col 23 for '999'
select * from (SELECT   thread#, a.ttime, SUM (c0) "00", SUM (c1) "01", SUM (c2) "02", SUM (c3) "03",
                   SUM (c4) "04", SUM (c5) "05", SUM (c6) "06", SUM (c7) "07",SUM (c8) "08", SUM (c9) "09", SUM (c10) "10",
                   SUM (c11) "11", SUM (c12) "12", SUM (c13) "13", SUM (c14) "14",
                   SUM (c15) "15", SUM (c16) "16", SUM (c17) "17", SUM (c18) "18",
                                   SUM (c19) "19", SUM (c20) "20", SUM (c21) "21", SUM (c22) "22",
                   SUM (c23) "23"
              FROM (SELECT thread#, ttime, DECODE (tthour, '00', 1, 0) c0,
                           DECODE (tthour, '01', 1, 0) c1,
                           DECODE (tthour, '02', 1, 0) c2,
                           DECODE (tthour, '03', 1, 0) c3,
                           DECODE (tthour, '04', 1, 0) c4,
                           DECODE (tthour, '05', 1, 0) c5,
                           DECODE (tthour, '06', 1, 0) c6,
                           DECODE (tthour, '07', 1, 0) c7,
                           DECODE (tthour, '08', 1, 0) c8,
                           DECODE (tthour, '09', 1, 0) c9,
                           DECODE (tthour, '10', 1, 0) c10,
                           DECODE (tthour, '11', 1, 0) c11,
                           DECODE (tthour, '12', 1, 0) c12,
                           DECODE (tthour, '13', 1, 0) c13,
                           DECODE (tthour, '14', 1, 0) c14,
                           DECODE (tthour, '15', 1, 0) c15,
                           DECODE (tthour, '16', 1, 0) c16,
                           DECODE (tthour, '17', 1, 0) c17,
                           DECODE (tthour, '18', 1, 0) c18,
                           DECODE (tthour, '19', 1, 0) c19,
                           DECODE (tthour, '20', 1, 0) c20,
                           DECODE (tthour, '21', 1, 0) c21,
                           DECODE (tthour, '22', 1, 0) c22,
                           DECODE (tthour, '23', 1, 0) c23
                      FROM (SELECT thread#, TO_CHAR (first_time, 'yyyy-mm-dd') ttime,
                                   TO_CHAR (first_time, 'hh24') tthour
                              FROM v\$log_history
                             WHERE (SYSDATE - first_time < 30))) a
        group by thread#, a.ttime)
        order BY thread#, ttime;


prompt ================= Use default password =========================
col username for a20
set linesize 100
select username from dba_users_with_defpwd where username in ('SYS','SYSTEM');

prompt ================= dba/sysdba privs =========================
col sysdba for a10
col sysoper for a10
select a.grantee,a.granted_role from dba_role_privs a where a.granted_role = 'DBA';
select a.username,a.sysdba,a.sysoper from v\$pwfile_users a;

prompt ================= users =========================
select username,default_tablespace,role_privs,c.profile,
max(decode(d.resource_name,'FAILED_LOGIN_ATTEMPTS',d.limit,'')) "F_L_A",
max(decode(d.resource_name,'PASSWORD_LIFE_TIME',d.limit,'')) "P_L_T",
max(decode(d.resource_name,'PASSWORD_LOCK_TIME',d.limit,'')) "P_K_T",
max(decode(d.resource_name,'PASSWORD_VERIFY_FUNCTION',d.limit,'')) "P_V_F",
max(decode(d.resource_name,'SESSIONS_PER_USER',d.limit,'')) "S_P_U",
max(decode(d.resource_name,'PASSWORD_REUSE_MAX',d.limit,'')) "P_R_M",
max(decode(d.resource_name,'IDLE_TIME',d.limit,'')) "I_T"
 from (
select username,default_tablespace,profile,listagg(role_privs,',') within group (order by role_privs) over(partition by username ) role_privs
from dba_users a,(select grantee,granted_role role_privs from dba_role_privs union all select grantee,privilege from dba_sys_privs) b 
where b.grantee = a.username and a.username not in ('SYSTEM','SYS','SYSMAN','DBSNMP','MGMT_VIEW','DBMON','DSG')/* and a.account_status='OPEN'*/ ) c ,dba_profiles d
where c.profile=d.profile group by username,default_tablespace,role_privs,c.profile  order by default_tablespace,username;

prompt ================= RESOURCE LIMIT =================
select * from gv\$resource_limit order by 1,2;

prompt ================= DBA_RECYCLEBIN =================
SELECT COUNT(*) RECYCLEBIN_OBJECTS FROM DBA_RECYCLEBIN;


prompt ================= current_object_id =================
SELECT dataobj# FROM sys.obj$ where name='_NEXT_OBJECT';

prompt ================= grows valule_detal of object_id for every day in last 30 days =================
select date_day,begin_oid,end_oid,GROW
from (select to_char(created, 'yyyy-mm-dd') Date_day,
LAG(max(object_id), 1, '0') OVER(ORDER BY to_char(created, 'yyyy-mm-dd')) "BEGIN_OID",
max(object_id) "END_OID",
(max(object_id) - LAG(max(object_id), 1, '0') OVER(ORDER BY to_char(created, 'yyyy-mm-dd'))) as "GROW"
from dba_objects
where created > sysdate - 30
group by to_char(created, 'yyyy-mm-dd')) 
where begin_oid >0;


prompt ================= OBJECTS =================
select owner,object_type,status,count(*) from dba_objects  group by owner,object_type,status order by 1,2,3;

prompt ================= INVALID OBJECTS =================
select owner,object_type,status,count(*) from dba_objects where status <> 'VALID' group by owner,object_type,status order by 1,2,3;

prompt ================= Invalid objects_detail =================
col owner for a20
col object_name for a30
select a.owner,a.object_type,a.object_name,a.status from dba_objects a where 
a.status = 'INVALID' order by 1,2,3;

prompt ================= sequences cache size < 100 =================
select sequence_owner,sequence_name,min_value,max_value,increment_by,cache_size,last_number 
from dba_sequences where cache_size < 100 and sequence_owner not in ('APPQOSSYS','DBSNMP','DIP','ORACLE_OCM','OUTLN','SYSTEM','SYS','WMSYS','SYSMAN') order by 1,2;


col SEGMENT_NAME for a40
prompt ================= big tables =================
select owner,segment_name,t_size from (
select a.owner,a.segment_name,round((sum(a.bytes)/1024/1024/1024),2) t_size from dba_segments a
where a.segment_type='TABLE' group by a.owner,a.segment_name order by 3 desc)
where rownum <=10;

--big indexes
prompt ================= big indexes =================
select owner,segment_name,t_size from (
select a.owner,a.segment_name,round((sum(a.bytes)/1024/1024/1024),2) t_size from dba_segments a
where a.segment_type='INDEX' group by a.owner,a.segment_name order by 3 desc)
where rownum <=10;


prompt ================= index blevel > 3] =================
select owner,index_name,index_type,num_rows,last_analyzed,blevel,leaf_blocks from dba_indexes where blevel > 3;

prompt ================= Unusable indexes =================
col owner for a12
col table_owner for a12
SELECT OWNER,INDEX_NAME,INDEX_TYPE,STATUS,TABLE_OWNER,TABLE_NAME,TABLESPACE_NAME FROM DBA_INDEXES WHERE STATUS='UNUSABLE' order by 1,2;

prompt ================= index_degree > 1 =================
select owner,index_name,degree from dba_indexes where decode(degree,'DEFAULT',1,nvl(degree,1)) > 1 order by 1;

prompt ================= table_degree > 1 =================
select owner,table_name,degree from dba_tables where  decode(degree,'DEFAULT',1,nvl(degree,1)) > 1 order by 1;

prompt ================= Segments In SYSTEM/SYSAUX =================
col segment_name for a30
set linesize 200
col owner for a20
select owner,segment_name,segment_type,tablespace_name from dba_segments
where tablespace_name in ('SYSTEM','SYSAUX')
and owner not in ('SYS','SYSTEM','OUTLN','APEX_030200','SYSMAN','MDSYS','OLAPSYS','ORDDATA','ORDSYS','EXFSYS','XDB','CTXSYS','EXFSYS','WMSYS','DBSNMP');


prompt ================= Table Fragment =================
col table_name for a30
select table_name,round(BLOCKS*8192/1024/1024,2) total_size_MB,
round(num_rows*AVG_ROW_LEN/1024/1024,2) used_size_MB,
round(((BLOCKS*8192/1024/1024)-(num_rows*AVG_ROW_LEN/1024/1024)),2)  wasted_size_MB,
round(round(((BLOCKS*8192/1024/1024)-(num_rows*AVG_ROW_LEN/1024/1024)),2)/
round(BLOCKS*8192/1024/1024,2),2)*100||'%' wasted_percent
from dba_tables where owner not in ('SYS','SYSTEM','OUTLN')
 and round(BLOCKS*8192/1024/1024,2) <>0
 and round(((BLOCKS*8192/1024/1024)-(num_rows*AVG_ROW_LEN/1024/1024)),2)>100
order by 2;

PROMPT ================= TABLESPACE FRAGMENT =================
set linesize 150
        column tablespace_name format a20 heading 'Tablespace'
     column sumb format 999,999,999
     column extents format 9999
     column bytes format 999,999,999,999
     column largest format 999,999,999,999
     column Tot_Size format 999,999 Heading 'Total| Size(Mb)'
     column Tot_Free format 999,999,999 heading 'Total Free(MB)'
     column Pct_Free format 999.99 heading '% Free'
     column Chunks_Free format 9999 heading 'No Of Ext.'
     column Max_Free format 999,999,999 heading 'Max Free(Kb)'
     set echo off
     PROMPT  FREE SPACE AVAILABLE IN TABLESPACES
     select a.tablespace_name,sum(a.tots/1048576) Tot_Size,
     sum(a.sumb/1048576) Tot_Free,
     sum(a.sumb)*100/sum(a.tots) Pct_Free,
     sum(a.largest/1024) Max_Free,sum(a.chunks) Chunks_Free
     from
     (
     select tablespace_name,0 tots,sum(bytes) sumb,
     max(bytes) largest,count(*) chunks
     from dba_free_space a
     group by tablespace_name
     union
     select tablespace_name,sum(bytes) tots,0,0,0 from
      dba_data_files
     group by tablespace_name) a
     group by a.tablespace_name
order by pct_free;

prompt ================= db time =================
WITH A AS
(SELECT b.INSTANCE_NUMBER,B.SNAP_ID, SUM(VALUE)/1000000/60 VALUE
    FROM dba_hist_sys_time_model B
   WHERE B.DBID = (SELECT DBID FROM v\$DATABASE)
     AND B.STAT_NAME IN ('DB time')
   GROUP BY b.INSTANCE_NUMBER, B.SNAP_ID
   ORDER BY b.INSTANCE_NUMBER,b.SNAP_ID)
SELECT A.INSTANCE_NUMBER,A.SNAP_ID,
       LAG(VALUE, 1, '0') OVER(partition by A.INSTANCE_NUMBER ORDER BY A.SNAP_ID) "START_VALUE(M)",
       VALUE "END_VALUE(M)",
       TO_CHAR(BEGIN_INTERVAL_TIME,'YYYY-MM-DD HH24:MI:SS')"START_TIME",
       TRUNC(VALUE - LAG(VALUE, 1, '0') OVER(partition by A.INSTANCE_NUMBER ORDER BY A.SNAP_ID),1) "D-VALUE(M)"
  FROM A,(SELECT instance_number,BEGIN_INTERVAL_TIME,SNAP_ID
    FROM DBA_HIST_SNAPSHOT
   WHERE  DBID = (SELECT dbid FROM v\$database)) B
     WHERE A.SNAP_ID=B.snap_id
     AND A.INSTANCE_NUMBER = B.instance_number
     AND B.BEGIN_INTERVAL_TIME>=SYSDATE-30;

prompt ================= No bound variables are used for SQL =================
set numw 20
select FORCE_MATCHING_SIGNATURE, count(1)
  from v\$sql
 where FORCE_MATCHING_SIGNATURE > 0
   and FORCE_MATCHING_SIGNATURE != EXACT_MATCHING_SIGNATURE
 group by FORCE_MATCHING_SIGNATURE
having count(1) > 100
 order by 2;

prompt +------------------+
prompt |   DG CONFIG      |
prompt +------------------+

prompt [dg parameters]
select inst_id,name,display_value from gv\$parameter where name = 'remote_login_passwordfile' union all 
select inst_id,name,display_value from gv\$parameter where name = 'standby_file_management' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_config' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_1' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_state_1' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_2' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_state_2' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_3' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_archive_dest_state_3' union all 
select inst_id,name,display_value from gv\$parameter where name = 'fal_client' union all 
select inst_id,name,display_value from gv\$parameter where name = 'fal_server' union all 
select inst_id,name,display_value from gv\$parameter where name = 'db_file_name_convert' union all 
select inst_id,name,display_value from gv\$parameter where name = 'log_file_name_convert';

prompt [database]

column force_logging format a13
column remote_archive format a14
column supplemental_log_data_pk format a24
column supplemental_log_data_ui format a24
column dataguard_broker format a16
SELECT force_logging, remote_archive, supplemental_log_data_pk, supplemental_log_data_ui, switchover_status, dataguard_broker FROM v\$database;  

prompt [standby_log]
SELECT thread#, group#, sequence#, bytes, archived, status FROM v\$standby_log order by thread#, group#;

prompt [ARCHIVE_DEST_STATUS]
col dest_name for a30
col destination for a30
col gap_status for a10
col error for a20
select dest_id,dest_name,status,type,database_mode,recovery_mode,protection_mode,destination,gap_status,error from v\$archive_dest_status where dest_id < 5;

prompt [ARCHIVED_LOG APPLY]
select * from (select sequence#,first_time,applied from v\$archived_log where standby_dest='YES' order by 1 desc) where rownum <= 10;

prompt [dataguard_status]
set line 300
col facility for a25
col message for a75
select * from (
select FACILITY,SEVERITY,DEST_ID,MESSAGE_NUM,ERROR_CODE,to_char(TIMESTAMP,'yyyy/mm/dd hh24:mi:ss'),MESSAGE from v\$dataguard_status order by message_num desc) where rownum < 20;

prompt [archive_gap]
select *  from v\$archive_gap;

prompt [dataguard_stats]
select * from v\$dataguard_stats;

prompt [managed_standby]
select * from v\$managed_standby;

prompt +----------------------------+
prompt |        checkBitAttack      |
prompt +----------------------------+

prompt [attack object]

COL OWNER FOR A20
COL OBJECT_NAME FOR A80
COL OBJECT_TYPE FOR A10
COL SQL_STATMENT FOR A180
set line 200 pages 99
SELECT OWNER
     , '"'||OBJECT_NAME||'"' OBJECT_NAME
     ,OBJECT_TYPE
     ,TO_CHAR(CREATED, 'YYYY-MM-DD HH24:MI:SS') CREATED
  FROM DBA_OBJECTS
 WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';


SELECT '    DROP '||OBJECT_TYPE||' "'||OWNER||'"."'||OBJECT_NAME||'";' SQL_STATMENT
  FROM DBA_OBJECTS
 WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';
 
prompt [attack job]

COL LOG_USER FOR A20
COL WHAT FOR A120
SELECT JOB, LOG_USER, WHAT
  FROM DBA_JOBS
 WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;


SELECT '    -- Logon with '||LOG_USER||CHR(10)||'    EXEC DBMS_JOB.BROKEN ('||JOB||', ''TRUE'')'||CHR(10)||'    EXEC DBMS_JOB.REMOVE('||JOB||')' SQL_STATMENT
  FROM DBA_JOBS
 WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;


prompt [object_stats]
col owner for a25;
col object_name for a45;
col object_type for a20;
col status for a15;
col create_date for a25;
select owner,object_name,object_type,status,to_char(created,'yyyy-mm-dd hh24:mi:ss') create_date from dba_objects
where object_type in('PROCEDURE','TRIGGER','FUNCTION','PACKAGE','PACKAGE BODY','LOB','SYNONYM')
and owner in (select username from dba_users where default_tablespace not in ('SYSTEM','SYSAUX','USERS'))
order by 1,3;

prompt [dblink_stats]
col owner for a20;
col db_link for a30;
col username for a20;
col host for a30;
col create_date for a30;
select owner,db_link,username,host,to_char(created,'yyyy-mm-dd hh24:mi:ss') create_date from dba_db_links;

prompt =======================================+----------------------------+====================================
prompt =======================================|      NEW SECURITY CHECK    |====================================
prompt =======================================+----------------------------+====================================

prompt ================= parameters =================
col name for a40
col display_value for a100
select inst_id,name,display_value from gv\$parameter where name = 'audit_trail' union all 
select inst_id,name,display_value from gv\$parameter where name = 'remote_login_passwordfile' union all
select inst_id,name,display_value from gv\$parameter where name = 'audit_sys_operations' union all
select inst_id,name,display_value from gv\$parameter where name = 'O7_DICTIONARY_ACCESSIBILITY' union all
select inst_id,name,display_value from gv\$parameter where name = 'sec_case_sensitive_logon' union all
select inst_id,name,display_value from gv\$parameter where name = 'global_names' union all
select inst_id,name,display_value from gv\$parameter where name = 'utl_file_dir' union all
select inst_id,name,display_value from gv\$parameter where name = 'remote_os_authent';

prompt ================= PASSWORD PROFILE =================
col limit for a20
col profile for a20
Select username,profile from dba_users where account_status='OPEN';
select * from dba_profiles where profile in (Select profile from dba_users where account_status='OPEN')  order by profile,RESOURCE_TYPE,resource_name;

prompt ================= users check =================	
col USERNAME for a20
col ACCOUNT_STATUS  for a20	  
SELECT DU.username, DU.account_status, DU.created, DU.expiry_date
   FROM DBA_USERS DU
  WHERE DU.account_status = 'OPEN';

  
prompt ================= users priv ================= 
col username for a20
col role for a20
col priv for a50    
SELECT DECODE(SA1.GRANTEE#, 1, 'PUBLIC', U1.NAME) username,
       SUBSTR(U2.NAME, 1, 20) role,
       SUBSTR(SPM.NAME, 1, 40) priv
  FROM SYS.SYSAUTH$             SA1,
       SYS.SYSAUTH$             SA2,
       SYS.USER$                U1,
       SYS.USER$                U2,
       SYS.SYSTEM_PRIVILEGE_MAP SPM,
       DBA_USERS                DU
 WHERE SA1.GRANTEE# = U1.USER#
   AND SA1.PRIVILEGE# = U2.USER#
   AND U2.USER# = SA2.GRANTEE#
   AND SA2.PRIVILEGE# = SPM.PRIVILEGE
   AND DU.username = U1.NAME
   AND DU.account_status = 'OPEN'
   AND DU.username NOT IN ('SYS', 'SYSTEM')
UNION
SELECT U.NAME, NULL, SUBSTR(SPM.NAME, 1, 40)
  FROM SYS.SYSTEM_PRIVILEGE_MAP SPM,
       SYS.SYSAUTH$             SA,
       SYS.USER$                U,
       DBA_USERS                DU
 WHERE SA.GRANTEE# = U.USER#
   AND SA.PRIVILEGE# = SPM.PRIVILEGE
   AND DU.username = U.NAME
   AND DU.account_status = 'OPEN'
   AND DU.username NOT IN ('SYS', 'SYSTEM');
   
prompt ================= objects priv =================  
col owner for a20
col grantee for a20  
col privilege for a30
col table_ame for a30
SELECT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE
  FROM DBA_TAB_PRIVS A, DBA_USERS B
 WHERE b.username = a.grantee
   and b.account_status = 'OPEN'
   AND B.username NOT IN ('SYS', 'SYSTEM');
   
prompt ================= object public priv =================  
col TABLE_NAME for a20
col GRANTEE for a20
col PRIVILEGE for a20
col OWNER for a20
SELECT TABLE_NAME,GRANTEE,PRIVILEGE,OWNER
  FROM DBA_TAB_PRIVS
 WHERE PRIVILEGE = 'EXECUTE'
   AND TABLE_NAME IN ('UTL_FILE',
                      'UTL_TCP',
                      'UTL_HTTP',
                      'UTL_SMTP',
                      'DBMS_LOB',
                      'DBMS_SYS_SQL',
                      'DBMS_JOB',
                      'DBMS_SCHEDULER');






prompt ================= "###check_bitcoin"  =================

prompt ================= 'select statement for check attack dba_objects view'  
SELECT OWNER, '"'||OBJECT_NAME||'"' OBJECT_NAME,OBJECT_TYPE,TO_CHAR(CREATED, 'YYYY-MM-DD HH24:MI:SS') CREATED
    FROM DBA_OBJECTS
    WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';
    
prompt ================= 'select statement for check attack dba_objects view' 
SELECT '    DROP '||OBJECT_TYPE||' "'||OWNER||'"."'||OBJECT_NAME||'";' SQL_STATMENT
    FROM DBA_OBJECTS
    WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';

prompt ================='select statement for check attack dba_jobs view'
COL LOG_USER FOR A20
COL WHAT FOR A120
SELECT JOB, LOG_USER, WHAT 
    FROM DBA_JOBS
    WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;
    
prompt =================':select statement for check attack dba_jobs view'
SELECT '    -- Logon with '||LOG_USER||CHR(10)||'    EXEC DBMS_JOB.BROKEN ('||JOB||', ''TRUE'')'||CHR(10)||'    EXEC DBMS_JOB.REMOVE('||JOB||')' SQL_STATMENT
  FROM DBA_JOBS
  WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;
exit
eof



SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)
GRID_CHECK_SCRIPT=${SHELL_FOLDER}/grid_check.sh

id grid


if [ $? -eq 0 ]
   then
   echo "###grid check"
   su - grid -c "sh ${GRID_CHECK_SCRIPT}"
fi


zip -r ${zip_file} ${output_dir}  && rm -rf ${output_dir}

