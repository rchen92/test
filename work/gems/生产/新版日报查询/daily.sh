#!/bin/bash
source ~/.bash_profile
sqlplus query/yyhis1000\!@sgehis << EOF 
@/home/oracle/daily/HIS.sql;
exit;
EOF

mv /tmp/zb_daily_data/daily.data /tmp/zb_daily_data/his.daily.$(date +%Y%m%d).data

#sleep 60

#/home/nuggets/scp.exp scp nuggets@12.1.103.10:/home/nuggets/daily/log/his.daily.$(date +%Y%m%d).data /tmp/sh_daily_data/
