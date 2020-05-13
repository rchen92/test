#!/bin/bash
source /home/oracle/.bash_profile
rman target / <<EOF
delete noprompt archivelog all completed before 'sysdate -3';
exit;
EOF