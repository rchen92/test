#!/bin/bash
source /home/oracle/.bash_profile

SQLPLUS_CMD='/ as sysdba'   
MAXLOG=$(sqlplus -s "$SQLPLUS_CMD" <<EOF
set heading off
set trimout on;
set pagesize 0 ;
select to_char(max(sequence#)) from v\$archived_log;
exit
EOF
)
MINLOG=$(sqlplus -s "$SQLPLUS_CMD" <<EOF
set heading off
set trimout on;
set pagesize 0 ;
select to_char(min(sequence#)) from v\$archived_log;
exit
EOF
)
BEFORE30=`expr $MAXLOG - 10`

$ORACLE_HOME/bin/rman log=~/rman.log <<EOF     
connect target /  
run
{ 
crosscheck archivelog all;  
delete noprompt expired archivelog all;
delete noprompt archivelog from sequence ${MINLOG} until sequence ${BEFORE30};
}  
exit;  
EOF
