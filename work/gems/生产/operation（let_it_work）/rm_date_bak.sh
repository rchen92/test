#!/bin/bash

week=`date | cut -f1 -d ' '`

if [ "$week" = "Mon" ];then
  find /data/datadump/cln_bak/ -type f -mtime +4 -exec rm {} \;
  find /data/datadump/his_incr_bak/ -type f -mtime +4 -exec rm {} \;
  find /data/datadump/int_bak/ -type f -mtime +4 -exec rm {} \;
  find /data/datadump/reg_bak/ -type f -mtime +4 -exec rm {} \;
  find /data/datadump/rmdb_bak/ -type f -mtime +4 -exec rm {} \;
  find /data/datadump/tra_bak/ -type f -mtime +4 -exec rm {} \;
elif [ "$week" = "Tue" ];then
  find /data/datadump/cln_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/his_bak/ -type f -mtime +3 -exec rm {} \;		###周2删除his_bak里面4天前的文件，上个星期5及之前的文件
  find /data/datadump/his_incr_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/int_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/reg_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/rmdb_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/tra_bak/ -type f -mtime +2 -exec rm {} \;
elif [ "$week" = "Sat" ];then
  find /data/datadump/his_bak/ -type f -mtime 1 -exec rm {} \;		###周6删除his_bak里面前1天的文件
elif [ "$week" = "Sun" ];then
  find /data/datadump/dsp_bak/ -type f -mtime +7 -exec rm {} \;		###星期7删除dsp_bak里面8天前的文件
else
  find /data/datadump/cln_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/his_bak/ -type f -mtime 1 -exec rm {} \;		###3  4  5删除his_bak里面前1天的文件
  find /data/datadump/his_incr_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/int_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/reg_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/rmdb_bak/ -type f -mtime +2 -exec rm {} \;
  find /data/datadump/tra_bak/ -type f -mtime +2 -exec rm {} \;
fi
