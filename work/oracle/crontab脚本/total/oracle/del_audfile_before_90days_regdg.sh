#!/bin/bash
# 
# Name         : del_audfile_before_90days_regdg.sh
# Used  For    : clean history audit file.
# Created By   : shsnc
# Created Time : 20170406
###############################################

. ~/.bash_profile

export ORACLE_SID=sgeregdg

PMON_FLAG=`ps -ef | grep -w ora_pmon_${ORACLE_SID} | grep -v grep`

if [ -z "${PMON_FLAG}" ]
        then
        echo "Instance ${ORACLE_SID} is not running!"
        exit
fi

AUDIT_DEST=`sqlplus -S / as sysdba <<EOF
set line 200 pages 0 feedback off heading off 
select value from v\\$parameter where name = 'audit_file_dest';
exit
EOF`

if [ $? -ne 0 ]
        then
        echo "Get audit_dest failed!"
        exit
fi

if [ -z ${AUDIT_DEST} ]
        then
        echo "The audit direcotry is null!"
  exit
fi

if [ ! -d "${AUDIT_DEST}" ]
        then
        echo "The direcotry ${AUDIT_DEST} is not exist!"
        exit
fi

find ${AUDIT_DEST} -type f -name '*.xml' -mtime +90 | xargs -i rm -vf {};
find ${AUDIT_DEST} -type f -name '*.aud' -mtime +90 | xargs -i rm -vf {};

exit