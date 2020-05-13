#!/bin/bash
#
# Name         : run.sh
# Used  For    : call the script and write log in /home/oracle/logs.
# Created By   : shsnc
# Created Time : 20170405
. ~/.bash_profile

prompt()
{
  cat << eof
   Usage:
         <PATH>/run.sh <PATH>/script.sh
   Example:
         /home/oracle/scripts/run.sh /home/oracle/scripts/script.sh
eof
}

LOGDIR=/home/grid/logs
LOGPREFIX=`basename $1`
LOGFILE=${LOGDIR}/${LOGPREFIX}.log

## create log directory
if [ ! -d ${LOGDIR} ]
   then
   mkdir -p ${LOGDIR}
fi

if [ $? -ne 0 ]
   then
   echo "Create directory [${LOGDIR}] failed!" 
   exit
fi

## verify the script 
if [ -z $1 ]
        then prompt
        exit 
fi

## verify the directory name
if [ ! -f $1 ]
        then 
        echo " Script [$1] is not exists!" >> ${LOGFILE}
        exit
fi


## call the script and write log
echo "Start: `date '+%Y%m%d %H:%M:%S'`" >> ${LOGFILE}
sh $1 2>&1 |tee >> ${LOGFILE}
echo -e "End:   `date '+%Y%m%d %H:%M:%S'`\n" >> ${LOGFILE}