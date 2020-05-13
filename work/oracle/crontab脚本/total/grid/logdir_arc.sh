#!/bin/bash
#
# Name         : logdir_arc.sh
# Used  For    : archive logfile directory.
# Created By   : shsnc
# Created Time : 20170411
. ~/.bash_profile

CDATE=`date +%Y%m%d`
LOGDIR=~/logs
ARC_LOGDIR=~/logs.gz.tar_${CDATE}

[ -d ${LOGDIR} ] && tar -czvf ${ARC_LOGDIR} ${LOGDIR} --remove-files

## create log directory
mkdir -p ${LOGDIR}