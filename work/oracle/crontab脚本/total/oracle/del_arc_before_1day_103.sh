#!/bin/bash
source /home/oracle/.bash_profile
export ORACLE_SID=sgetradg
rman target / <<EOF
delete noprompt archivelog all completed before 'sysdate -1';
exit;
EOF

export ORACLE_SID=sgeregdg
rman target / <<EOF
delete noprompt archivelog all completed before 'sysdate -1';
exit;
EOF