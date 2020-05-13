oracle����ṹ
1.oracle ���
 cat /home/grid/.bash_profile
 cat /home/oracle/.bash_profile
     ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE  
    ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME  
    ORACLE_SID=ocp; export ORACLE_SID 
    
    --chown -Rf /u01 oracle.oinstall
    su - root
    mkdir /oracleback
    chown -Rf /u01 oracle.oinstall
    cp -Rf /u01 /oracleback
    ���ش��� 
2.oracle database
����      �洢·��     Ĭ���Ƿ���           �ɷ�ʧ                   ʲôʱ����
�����ļ�   ����        ��                   �ɶ�ʧ,dataguard�ر�       sysԶ������
�����ļ�   ���ػ�asm   ��                   ���ɶ�ʧ                   ���ݿ�nomount
�����ļ�   asm         ��                   ���ɶ�ʧ                   mount
�����ļ�   asm         ��                   ���ɶ�ʧ                   open,�û�dml,ddl,dcl
������־   asm         ��                   ��־�鲻�ɶ�,�ɶ�һ����Ա  dml,ddl,dcl,logminer,ʵ���ָ�
�鵵��־   asm         ��(�����鵵ģʽ)     ���Զ�                     ���ʹ���,�ָ��� ,logminer 
������־   asm         ��(�������ݿ�)       ���Զ�                     �û������
������ļ� asm         ��(rman����,dba����) ���Զ�                     �ӿ�rmanÿ���������ݵ��ٶ� 

�����ļ� +data
�����ļ� +data +fra
�����ļ� +data
������־ +data +fra
�鵵��־ +data +fra
�����ļ�       +fra 


[root@oracle ~]# mkdir -p /oraclemgr/db_bak
[root@oracle ~]# chown -R oracle:oinstall /oraclemgr/db_bak/
[grid@oracle68 ~]$ asmcmd
ASMCMD> pwd
+
ASMCMD> ls
DATA/
FRA/
ASMCMD> cd +FRA
ASMCMD> mkdir db_bak
[oracle@oracle68 ~]$ rman target /
RMAN> show all;
using target database control file instead of recovery catalog
RMAN configuration parameters for database with db_unique_name ORCL are:
CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
CONFIGURE BACKUP OPTIMIZATION OFF; # default
CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
CONFIGURE CONTROLFILE AUTOBACKUP OFF; # default
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE MAXSETSIZE TO UNLIMITED; # default
CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/u01/app/oracle/product/11.1.0/dbhome_1/dbs/snapcf_orcl.f'; # default

RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 8 DAYS;
RMAN> CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET PARALLELISM 1;


[oracle@oracle68 ~]$ cd /oraclemgr/db_bak/
[oracle@oracle68 db_bak]$ vim rmanbaklevel0.sql
run {
BACKUP
    incremental level=0
    SKIP INACCESSIBLE
    FILESPERSET 10
    # recommended format
    FORMAT '+fra/db_bak/diskdb0_T.%T_s.%s_d.%d'
    DATABASE;
#sql 'alter system archive log current';
BACKUP
  incremental level=0
   filesperset 200
   FORMAT '+fra/db_bak/diskar0_T.%T_s.%s_d.%d'
   ARCHIVELOG ALL  not backed up;
delete noprompt  archivelog until time 'sysdate-3';
BACKUP
    # recommended format
    FORMAT '+fra/db_bak/diskctl0_T.%T_s.%s_d.%d'
    CURRENT CONTROLFILE;
sql "create pfile=''?/dbs/initocp.ora.bak'' from spfile";
crosscheck backup;
delete noprompt expired backup;
delete noprompt obsolete;
restore database validate;
restore controlfile validate;
restore archivelog from time  'sysdate-1'  until time 'sysdate' validate;
}
[oracle@oracle68 db_bak]$ vim rmanbaklevel0.sh
source /home/oracle/.bash_profile
$ORACLE_HOME/bin/rman target / nocatalog cmdfile=/oraclemgr/db_bak/rmanbaklevel0.sql log=/oraclemgr/db_bak/rmanbaklevel0.log append
[oracle@oracle68 db_bak]$ chmod +x rmanbaklevel0.sh
[oracle@oracle68 db_bak]$ ./rmanbaklevel0.sh

[oracle@oracle68 ~]$ crontab -e
30 5 * * 6 /oraclemgr/db_bak/rmanbaklevel0.sh               #��������5��룬��ȫ��
30 5 * * 0,1,2,3,4,5 /oraclemgr/db_bak/rmanbaklevel1.sh     #����ÿ������5��룬����������

[oracle@oracle68 db_bak]$ vim rmanbaklevel1.sql
run {
BACKUP
    incremental level=1
    SKIP INACCESSIBLE
    FILESPERSET 10
    # recommended format
    FORMAT '+fra/db_bak/diskdb1_T.%T_s.%s_d.%d'
    DATABASE;
#sql 'alter system archive log current';
BACKUP
  incremental level=1
   filesperset 200
   FORMAT '+fra/db_bak/diskar1_T.%T_s.%s_d.%d'
   ARCHIVELOG ALL  not backed up;
delete noprompt  archivelog until time 'sysdate-3';
BACKUP
    # recommended format
    FORMAT '+fra/db_bak/diskctl1_T.%T_s.%s_d.%d'
    CURRENT CONTROLFILE;
sql "create pfile=''?/dbs/initkhb.ora.bak'' from spfile";
crosscheck backup;
delete noprompt expired backup;
delete noprompt obsolete;
restore database validate;
restore controlfile validate;
restore archivelog from time  'sysdate-1'  until time 'sysdate' validate;
}
[oracle@oracle68 db_bak]$ vim rmanbaklevel1.sh
source /home/oracle/.bash_profile
$ORACLE_HOME/bin/rman target / nocatalog cmdfile=/oraclemgr/db_bak/rmanbaklevel1.sql log=/oraclemgr/db_bak/rmanbaklevel1.log append
[oracle@oracle68 db_bak]$ chmod +x rmanbaklevel1.sh
[oracle@oracle68 db_bak]$ vim arch.sql
run {
BACKUP
  incremental level=1
   filesperset 200
   FORMAT '+fra/db_bak/diskar1_T.%T_s.%s_d.%d'
   ARCHIVELOG ALL  not backed up;
   }
[oracle@oracle68 db_bak]$ vim arch.sh
source /home/oracle/.bash_profile
$ORACLE_HOME/bin/rman target / nocatalog cmdfile=/oraclemgr/db_bak/arch.sql log=/oraclemgr/db_bak/arch.log append
[oracle@oracle68 db_bak]$ chmod +x arch.sh
[oracle@oracle68 ~]$ crontab -e
*/10 * * * * /oraclemgr/db_bak/arch.sh














