#!/bin/bash
#
# Name         : expdp.sh
# Used  For    : call shell scripts and log to /home/oracle/logs.
# Created By   : shsnc
# Created Time : 20170405
. ~/.bash_profile
LOGDIR=/home/oracle/logs
LOGPREFIX=expdp_schema.sh
LOGFILE=${LOGDIR}/${LOGPREFIX}.log
SCRIPT=/home/oracle/scripts/expdp_${ORACLE_UNQNAME}.sh
RUN_FLAG_FILE=/tmp/.expdp.sh.run

RUN_FLAG=`grep "Start" ${RUN_FLAG_FILE} 2>/dev/null`

if [ "$RUN_FLAG" = "Start" ]
        then
        echo "The script is running"
  exit
fi

# running flag file
echo "Start" > ${RUN_FLAG_FILE}

## create log directory
if [ ! -d ${LOGDIR} ]
   then
   mkdir -p ${LOGDIR}
fi

if [ $? -ne 0 ]
   then
   echo "Create directory [${LOGDIR}] failed!"
   echo "End" > ${RUN_FLAG_FILE}
   exit
fi


## verify the directory name
if [ ! -f ${SCRIPT} ]
   then 
   echo " Script [${SCRIPT}] is not exists!"
   echo "End" > ${RUN_FLAG_FILE}
   exit
fi

## call the script and write log
echo "==============================Start: `date '+%Y%m%d %H:%M:%S'`============================" >> ${LOGFILE}
echo "Script ${SCRIPT}" >> ${LOGFILE}

sh ${SCRIPT} 2>&1 |tee >> ${LOGFILE}

echo -e "End:   `date '+%Y%m%d %H:%M:%S'`\n" >> ${LOGFILE}

echo "End" > ${RUN_FLAG_FILE}
exit