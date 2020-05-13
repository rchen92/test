#!/bin/bash
# 
# Name         : vcs_filesync.sh
# Used  For    : remote sync to vcs node2.
# Created By   : shsnc
# Created Time : 20170414
###############################################

. ~/.bash_profile

ORAPWF=$ORACLE_HOME/dbs/orapwsgedspdb
ORASPF=$ORACLE_HOME/dbs/spfilesgedspdb.ora
ORATNS=$ORACLE_HOME/network/admin/tnsnames.ora
ORANET=$ORACLE_HOME/network/admin/sqlnet.ora
RHOST=rmdb2

for i in ${ORAPWF} ${ORASPF} ${ORATNS} ${ORANET}
do
  if [ -f $i ]
        then
        rsync -av $i ${RHOST}:$i
        echo "rsync -av $i ${RHOST}:$i"
  fi
done