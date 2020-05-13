#!/bin/bash
# 
# Name         : alert_arc.sh
# Used  For    : auto archive alert log.
# Created By   : shsnc
# Created Time : 20170406
###############################################

. ~/.bash_profile


CDATE=`date "+%Y%m%d"`
ARC_DIR=/home/oracle/alert_archive
LOCK_FILE=/tmp/.alert_arc.lock
RUN_FLAG_FILE=/tmp/.alert_arc.run

RUN_FLAG=`grep "Start" ${RUN_FLAG_FILE} 2>/dev/null`

if [ "$RUN_FLAG" = "Start" ]
        then
        echo "The script is running"
  exit
fi

# running flag file
echo "Start" > ${RUN_FLAG_FILE}


FLAG=`find ${LOCK_FILE} -mtime -27 2>/dev/null | wc -l`
if [ $FLAG -eq 1 ]
        then
        echo "The scripts has been runned within 28 days!"
        echo "End" > ${RUN_FLAG_FILE}
  exit
fi

PMON_FLAG=`ps -ef | grep -w ora_pmon_${ORACLE_SID} | grep -v grep`

if [ -z "${PMON_FLAG}" ]
        then
        echo "Instance ${ORACLE_SID} is not running!"
        echo "End" > ${RUN_FLAG_FILE}
        exit
fi

if [ ! -d $ARC_DIR ]
        then
        mkdir ${ARC_DIR}
fi



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
        echo "End" > ${RUN_FLAG_FILE}
        exit
fi

ALERT_FILE=`grep alert /tmp/.AlertFileName.out`

if [ -z ${ALERT_FILE} ]
        then
        echo "The Alert log file name is null!"
        echo "End" > ${RUN_FLAG_FILE}
  exit
fi

if [ ! -f ${ALERT_FILE} ]
        then
        echo "The Alert log file name ${ALERT_FILE} not found!"
        echo "End" > ${RUN_FLAG_FILE}
  exit
fi

#archive alert log 
ARC_ALERT_FILE=`echo ${ALERT_FILE} | tr -s ' '`_${CDATE}

if [ ! -f ${ARC_ALERT_FILE} ]
        then
  mv -v ${ALERT_FILE}  ${ARC_ALERT_FILE}
fi

# move the archive alert log to archive diretory
mv -v -S _`date '+%Y%m%d%H%M%S'` ${ARC_ALERT_FILE} ${ARC_DIR}/


# lockfile
if [ $? -eq 0 ]
        then
        echo "`date '+%Y%m%d%H%M%S'`" > ${LOCK_FILE}
fi

echo "End" > ${RUN_FLAG_FILE}
exit