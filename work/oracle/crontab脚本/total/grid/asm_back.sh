#!/bin/bash
# 
# Name         : asm_back.sh
# Used  For    : auto backup asm disk header .
# Created By   : shsnc
# Created Time : 20161120
# Modified Time: 20170405
. ~/.bash_profile

CDATE=`date "+%y%m%d%H%M%S"`
BASE_HOME=/backup
BAKDIR=${BASE_HOME}/asm_backup

if [ ! -d ${BAKDIR} ]; then
   echo "BAKDIR directory not found!"
   exit;
fi

# output  to logfile
LOGFILE=${BAKDIR}/asmbackup.log

exec >> ${LOGFILE}  2>&1
echo  "Asm Backup Begin :"`date "+%y-%m-%d:%H:%M:%S"` ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

# md_backup  For Backup all asm diskgroups
asmcmd <<EOF
md_backup ${BAKDIR}/asmdg.md.${CDATE}
exit;
EOF

#   dd backup For asm disks
TEMPFILE=/tmp/asm.dd.${CDATE}
sqlplus -S '/ as sysdba' <<EOD
SET PAGES 0 lines 200 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
spool ${BAKDIR}/dd_bak.sh
SELECT 'dd if='||path||' of=${BAKDIR}/'||substr(path,instr(path,'/',-1)+1)||'.dd.${CDATE} bs=40960 count=1' FROM v\$asm_disk WHERE GROUP_NUMBER != 0 ;
spool off
exit;
EOD

if [ -s ${BAKDIR}/dd_bak.sh ]; then
chmod 755 ${BAKDIR}/dd_bak.sh
/bin/sh ${BAKDIR}/dd_bak.sh
fi

# Rm old backup files
find ${BAKDIR} -type f -name "asmdg.md.*" -mtime +30 |xargs rm -f 
find ${BAKDIR} -type f -name "*.dd.*" -mtime +30 |xargs rm -f 


echo  "Asm Backup END :"`date "+%y-%m-%d:%H:%M:%S"` "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"