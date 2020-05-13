#!/bin/bash
###########################################################
#This script will be executed by crontab at 16:15 everyday#
###########################################################
. ~/.bash_profile
sqlplus -S / as sysdba > /tmp/tbs_size.txt <<EOF
set feedback off
col FREE_PCT for a8
col DB_NAME for a8
col USED_SIZE for a15
SELECT to_char(sysdate,'yyyy/mm/dd hh24:mi:ss') TIME,
       sys_context('userenv','db_name') DB_NAME,
       round(SUM(USED_SPACE)/1024/1024/1024,2)||'G' USED_SIZE,
       round(SUM(FREE_SPACE)/SUM(SPACE),4)*100||'%' FREE_PCT
from (
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
EOF