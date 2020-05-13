oracle物理结构
1.oracle 软件
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
    本地磁盘 
2.oracle database
类型      存储路径     默认是否有           可否丢失                   什么时候用
口令文件   本地        有                   可丢失,dataguard必备       sys远程连接
参数文件   本地或asm   有                   不可丢失                   数据库nomount
控制文件   asm         有                   不可丢失                   mount
数据文件   asm         有                   不可丢失                   open,用户dml,ddl,dcl
在线日志   asm         有                   日志组不可丢,可丢一个成员  dml,ddl,dcl,logminer,实例恢复
归档日志   asm         无(开启归档模式)     可以丢                     介质故障,恢复用 ,logminer 
闪回日志   asm         无(闪回数据库)       可以丢                     用户误操作
块跟踪文件 asm         无(rman增量,dba配置) 可以丢                     加快rman每天增量备份的速度 

参数文件 +data
控制文件 +data +fra
数据文件 +data
在线日志 +data +fra
归档日志 +data +fra
备份文件       +fra 


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
30 5 * * 6 /oraclemgr/db_bak/rmanbaklevel0.sh               #周六下午5点半，做全备
30 5 * * 0,1,2,3,4,5 /oraclemgr/db_bak/rmanbaklevel1.sh     #其他每天下午5点半，做增量备份

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














