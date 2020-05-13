#!/bin/bash
. /home/grid/.bash_profile
host_name=`hostname`
output_dir=/tmp/pre_check_data_`date +%Y%m%d`
output_file=${output_dir}/${host_name}_grid_os_check.output

mkdir -p ${output_dir}

echo "========================================== ENV info ==============================================" > ${output_file}
hostname  >>${output_file}

#env parameter
echo "========================================== env parameter ==============================================" >>${output_file}
cat /home/grid/.bash_profile | grep -v '^#' | grep -v '^$' >>${output_file}


#storage
echo "========================================== 12-dm-permissions.rules ==============================================" >>${output_file}
cat /etc/udev/rules.d/12-dm-permissions.rules >>${output_file}

echo "========================================== disk list ==============================================" >>${output_file}
ls /dev/mapper/* -l                >>${output_file}
ls /dev/dm* -l                           >>${output_file}


#grid user
echo "========================================== user:grid ==============================================" >>${output_file}
id grid >>${output_file}




#crontab
echo "========================================== crontabl:grid ==============================================" >>${output_file}
#crontab -l >>${output_file}


#listener
echo "========================================== listener ==============================================" >>${output_file}
lsnrctl status LISTENER   >>${output_file} 
echo " "                  >>${output_file} 
lsnrctl service LISTENER  >>${output_file} 

#listener
echo "========================================== scan listener ==============================================" >>${output_file}
lsnrctl status  LISTENER_SCAN1 >>${output_file} 
echo " "                       >>${output_file} 
lsnrctl service LISTENER_SCAN1 >>${output_file}

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
ls -l /home/grid/scripts         >>${output_file}
echo " "                >>${output_file}
#ls -l /home/grid/scripts/v0.1    >>${output_file}

#CLUSTER
echo "========================================== CLUSTER ==============================================" >>${output_file}

echo "###resource status###"       >>${output_file}
crsctl stat res -t                 >>${output_file}
crsctl stat res -t -init           >>${output_file}
                                   
echo "###olsnodes###"              >>${output_file}
olsnodes                           >>${output_file}
                                   
echo "###ocrcheck###"              >>${output_file}
ocrcheck                           >>${output_file}

echo "###ocrcheck -local###"       >>${output_file}
ocrcheck -local                    >>${output_file}

echo "###ocrconfig -showbackup###" >>${output_file}
ocrconfig -showbackup              >>${output_file}

echo "###ocrconfig -local -showbackup###" >>${output_file}
ocrconfig -local -showbackup              >>${output_file}

echo "###crsctl check crs status###"      >>${output_file}
crsctl check crs                         >>${output_file}

echo "###crsctl query css votedisk### "  >>${output_file}
crsctl query css votedisk                >>${output_file}

echo "###oifcfg getif### "               >>${output_file}
oifcfg getif                             >>${output_file}


#SERVER CONFIG
echo "=======================================SERVER CONFIG ==============================================" >>${output_file}
db_u_name=$(srvctl config database)
echo "###config database### "              >>${output_file}
srvctl config database -d ${db_u_name}     >>${output_file}

echo "###config service### "               >>${output_file}
srvctl config service -d ${db_u_name}      >>${output_file}

echo "###config nodeapps### "               >>${output_file}
srvctl config nodeapps                     >>${output_file}

echo "###config listener### "               >>${output_file}
srvctl config listener                     >>${output_file}

echo "###config asm### "               >>${output_file}
srvctl config asm                          >>${output_file}

echo "###config scan### "               >>${output_file}
srvctl config scan                         >>${output_file}

echo "###config scan_listener### "               >>${output_file}
srvctl config scan_listener                >>${output_file}

#VERSION
echo "========================================== GRID VERSION ==============================================" >>${output_file}
$ORACLE_HOME/OPatch/opatch lsinventory >>${output_file}

##asm alert log
#get alert log filename
sqlplus -S "/ as sysdba" >/dev/null  <<EOF
set pagesize
col VALUE format a80
spool /tmp/.AlertFileName_ASM.out
select value||'/alert_'||instance_name||'.log' from v\$diag_info,v\$instance where name= 'Diag Trace';
spool off
exit
EOF


if [ $? -ne 0 ]
        then
        echo "Spool alert log file name to tempfile failed!"
        exit
fi

ALERT_FILE=`grep alert /tmp/.AlertFileName_ASM.out`

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



##cluster alert log
cp $ORACLE_HOME/log/`hostname`/alert* ${output_dir}/

asm_output_file=${output_dir}/${host_name}_${ORACLE_SID}_grid_asm_check.html
basedir=`dirname $0`

sqlplus -M "html on" -S / as sysdba >>${asm_output_file} <<eof
set line 500
set pages 999
prompt ================= ENV info============================
select instance_name,status,sys_context('userenv','host') host_name from v\$instance;

prompt ================= asm parameters =================
select name,display_value from v\$parameter where name = 'memory_target';
select name,display_value from v\$parameter where name = 'asm_power_limit';

prompt ================= ASM DISKGROUPS =================
select GROUP_NUMBER,NAME,BLOCK_SIZE,ALLOCATION_UNIT_SIZE,STATE,TYPE,trunc(TOTAL_MB/1024) "TOTAL_GB",trunc(USABLE_FILE_MB/1024) "USABLE_FILE_GB",OFFLINE_DISKS,COMPATIBILITY,DATABASE_COMPATIBILITY,VOTING_FILES from  v\$asm_diskgroup;

prompt ================= ASM DISKS =================
select GROUP_NUMBER,DISK_NUMBER,MOUNT_STATUS,HEADER_STATUS,STATE,trunc(TOTAL_MB/1024) "TOTAL_GB",trunc(FREE_MB/1024) "FREE_GB",NAME,PATH,CREATE_DATE from  v\$asm_disk order by 1,2;
exit
eof

