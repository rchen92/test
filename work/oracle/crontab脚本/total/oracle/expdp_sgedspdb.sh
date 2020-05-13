#!/bin/bash
source /home/oracle/.bash_profile
BACK_DIR=/backup/dmp
CTIME=`date +%Y%m%d%H%M%S`
FILE_MD5=`hostname`${CTIME}.md5

if [ ! -d ${BACK_DIR} ]
        then
        echo "The directory ${BACK_DIR} does not exist!"
  exit
fi

find ${BACK_DIR}/*.dmp -exec rm -vf {} \;
find ${BACK_DIR}/*.log -exec rm -vf {} \;
find ${BACK_DIR}/*.md5 -exec rm -vf {} \;

expdp \"/as sysdba\" directory=dmp_dir dumpfile=dsp${CTIME}_%U.dmp schemas=dexchange,dsp_rpt,report parallel=4 cluster=n compression=all logfile=expdp_dsp${CTIME}.log

echo "md5sum ${BACK_DIR}/*.dmp to ${FILE_MD5}:"
md5sum ${BACK_DIR}/*.dmp |tee ${BACK_DIR}/${FILE_MD5}

chmod o+r ${BACK_DIR}/*
ls -lh ${BACK_DIR}/*