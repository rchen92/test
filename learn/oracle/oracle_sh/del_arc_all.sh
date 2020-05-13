#!/bin/bash
source /home/oracle/.bash_profile
rman target / <<EOF
delete noprompt archivelog all;
exit;
EOF
