#!/bin/bash
# 
# Name         : lsnrlog_arc.sh
# Used  For    : auto archive listener log.
# Created By   : shsnc
# Created Time : 20170406
###############################################

. ~/.bash_profile

HOST_NAME=`hostname`
CDATE=`date "+%Y%m%d"`
ARC_DIR=/home/oracle/lsnrlog_archive
LOCK_FILE=/tmp/.lsnrlog_arc.lock
RUN_FLAG_FILE=/tmp/.lsnrlog_arc.run
LSNRLOG_FILE=${ORACLE_BASE}/tnslsnr/${HOST_NAME}/listener/trace/listener.log
#archive listener log 
ARC_LSNRLOG_FILE=${LSNRLOG_FILE}_${CDATE}.tar.gz

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


if [ ! -d $ARC_DIR ]
        then
        mkdir ${ARC_DIR}
fi



if [ ! -f ${LSNRLOG_FILE} ]
        then
        echo "The listener log file name ${LSNRLOG_FILE} not found!"
        echo "End" > ${RUN_FLAG_FILE}
  exit
fi


if [ ! -f ${ARC_LSNRLOG_FILE} ]
        then
  tar -czvf  ${ARC_LSNRLOG_FILE} ${LSNRLOG_FILE}
  cat /dev/null > ${LSNRLOG_FILE}
fi

# move the archive listener log to archive diretory
mv -v -S _`date '+%Y%m%d%H%M%S'` ${ARC_LSNRLOG_FILE} ${ARC_DIR}/


# lockfile
if [ $? -eq 0 ]
        then
        echo "`date '+%Y%m%d%H%M%S'`" > ${LOCK_FILE}
fi

echo "End" > ${RUN_FLAG_FILE}
exit