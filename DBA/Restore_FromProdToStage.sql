--ALTER DATABASE InexScoreCard
--SET SINGLE_USER WITH
--ROLLBACK AFTER 60 --this will give your current connections 60 seconds to complete

--/*If there is no error in statement before database will be in multiuser
--mode.  If error occurs please execute following command it will convert
--database in multi user.*/
--ALTER DATABASE InexScoreCard SET MULTI_USER


-- RESTORE PTS FROM PROD
-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\PTS_backup_2014_11_05_220019_7649116.bak' WITH FILE = 1
RESTORE DATABASE PTS
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\PTS_backup_2014_11_05_220019_7649116.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'PTS' TO 'G:\Data\PTS.mdf',
move 'PTS_DS01' to 'G:\Data\PTS_DS01.ndf',
move 'PTS_DS02' to 'G:\Data\PTS_DS02.ndf',
move 'PTS_DSBlob' to 'G:\Data\PTS_DSBlob.ndf',
MOVE 'PTS_log' TO 'H:\Log\PTS_log.LDF'

-- TAKE SNAPSHOT
CREATE DATABASE SS_PTS ON ( NAME = PTS, FILENAME = N'G:\Data\SS_PTS.ss' ),
( NAME = PTS_DS01, FILENAME = N'G:\Data\SS_PTS_DS01.ss' ),
( NAME = PTS_DS02, FILENAME = N'G:\Data\SS_PTS_DS02.ss' )
 AS SNAPSHOT OF PTS;


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\QnA_backup_2014_11_12_220012_7288647.bak' WITH FILE = 1
-- RESTORE QnA FROM PROD
RESTORE DATABASE QnA
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\QnA_backup_2014_11_12_220012_7288647.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'QnA' TO 'G:\Data\QnA.mdf',
MOVE 'QnA_log' TO 'H:\Log\QnA_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_QnA ON ( NAME = QnA, FILENAME = N'G:\Data\SS_QnA.ss')
AS SNAPSHOT OF QnA;
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\CRM_backup_2014_09_13_210006_2882427.bak' WITH FILE = 1
-- RESTORE CRM FROM PROD
RESTORE DATABASE CRM
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\CRM_backup_2014_09_13_210006_2882427.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'CRM' TO 'G:\Data\CRM.mdf',
MOVE 'CRM_log' TO 'H:\Log\CRM_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_CRM ON ( NAME = CRM, FILENAME = N'G:\Data\SS_CRM.ss')
AS SNAPSHOT OF CRM;
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_REPL_backup_2014_11_05_220018_6728696.bak' WITH FILE = 1
-- RESTORE CARDIFF_REPL FROM PROD
RESTORE DATABASE Cardiff_REPL
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_REPL_backup_2014_11_05_220018_6728696.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Cardiff' TO 'G:\Data\Cardiff_REPL.mdf',
MOVE 'Cardiff_log' TO 'H:\Log\Cardiff_REPL_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_backup_2014_11_05_220018_6728696.bak' WITH FILE = 1
-- RESTORE CARDIFF FROM PROD
RESTORE DATABASE Cardiff
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_backup_2014_11_05_220018_6728696.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Cardiff' TO 'G:\Data\Cardiff.mdf',
MOVE 'Cardiff_log' TO 'H:\Log\Cardiff_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_Cardiff ON ( NAME = Cardiff, FILENAME = N'G:\Data\SS_Cardiff.ss')
AS SNAPSHOT OF Cardiff;
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Billing_backup_2014_11_05_220018_6260678.bak' WITH FILE = 1
-- RESTORE BIlling FROM PROD
RESTORE DATABASE Billing
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Billing_backup_2014_11_05_220018_6260678.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Billing' TO 'G:\Data\Billing.mdf',
MOVE 'Billing_log' TO 'H:\Log\Billing_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_Billing ON ( NAME = Billing, FILENAME = N'G:\Data\SS_Billing.ss')
AS SNAPSHOT OF Billing;
GO

--ALTER DATABASE Billing
--SET SINGLE_USER WITH
--ROLLBACK AFTER 60 --this will give your current connections 60 seconds to complete

--/*If there is no error in statement before database will be in multiuser
--mode.  If error occurs please execute following command it will convert
--database in multi user.*/
--ALTER DATABASE Billing SET MULTI_USER

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\AMS_backup_2014_11_05_220018_4076594.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
--DROP DATABASE AMS
RESTORE DATABASE AMS
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\AMS_backup_2014_11_05_220018_4076594.bak' 
WITH FILE = 1, REPLACE, STATS = 10,
MOVE 'AMS' TO 'G:\Data\AMS.mdf'
,MOVE 'AMS_log' TO 'H:\Log\AMS_log.LDF'
GO

RESTORE DATABASE AMS
FROM DISK = N'G:\Data\AMS_Stage_11172014_NM.bak' 
WITH FILE = 1, REPLACE, STATS = 10,
MOVE 'AMS' TO 'G:\Data\AMS.mdf'
,MOVE 'AMS_log' TO 'H:\Log\AMS_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\TD_backup_2014_10_22_220028_4003447.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE TD
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\TD_backup_2014_10_22_220028_4003447.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'TD' TO 'G:\Data\TD.mdf',
MOVE 'TD_log' TO 'H:\Log\TD_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Origami_backup_2014_11_12_220012_6508617.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Origami
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Origami_backup_2014_11_12_220012_6508617.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Origami' TO 'G:\Data\Origami.mdf',
MOVE 'Origami_log' TO 'H:\Log\Origami_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kenexa_backup_2014_11_12_220012_4324533.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Kenexa
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kenexa_backup_2014_11_12_220012_4324533.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Kenexa' TO 'G:\Data\Kenexa.mdf',
MOVE 'Kenexa_log' TO 'H:\Log\Kenexa_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\InexScoreCard_backup_2014_11_12_220012_3700509.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE InexScoreCard
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\InexScoreCard_backup_2014_11_12_220012_3700509.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'InexScoreCard' TO 'G:\Data\InexScoreCard.mdf',
MOVE 'InexScoreCard_log' TO 'H:\Log\InexScoreCard_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_InexScoreCard ON ( NAME = InexScoreCard, FILENAME = N'G:\Data\SS_InexScoreCard.ss')
AS SNAPSHOT OF InexScoreCard;
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\EmployeeRelation_backup_2014_11_12_220012_1204413.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE EmployeeRelation
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\EmployeeRelation_backup_2014_11_12_220012_1204413.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'EmployeeRelation' TO 'G:\Data\EmployeeRelation.mdf',
MOVE 'EmployeeRelation_log' TO 'H:\Log\EmployeeRelation_Log.LDF'
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Encompass_backup_2014_11_12_220012_1516425.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Encompass
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Encompass_backup_2014_11_12_220012_1516425.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Encompass' TO 'G:\Data\Encompass.mdf',
MOVE 'Encompass_log' TO 'H:\Log\Encompass_Log.LDF'
GO

