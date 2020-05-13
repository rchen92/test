#!/bin/sh
source /home/oracle/.bash_profile
#export ORACLE_SID=
sqlplus -S / as sysdba >> /tmp/snap_session_log <<EOF
insert into snap_session select sysdate,inst_id,sid,serial#,username,sql_id,event,program,module,machine ,osuser from gv\$session;
commit;
select sysdate from dual;
exit;
EOF