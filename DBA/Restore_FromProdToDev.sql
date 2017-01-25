--ALTER DATABASE InexScoreCard
--SET SINGLE_USER WITH
--ROLLBACK AFTER 60 --this will give your current connections 60 seconds to complete

--/*If there is no error in statement before database will be in multiuser
--mode.  If error occurs please execute following command it will convert
--database in multi user.*/
--ALTER DATABASE InexScoreCard SET MULTI_USER


-- RESTORE PTS FROM PROD
-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\PTS_backup_2014_11_12_220012_6508617' WITH FILE = 1
RESTORE DATABASE PTS
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\PTS_backup_2014_11_12_220012_6508617' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'PTS' TO 'E:\Data\PTS.mdf',
move 'PTS_DS01' to 'E:\Data\PTS_DS01.ndf',
move 'PTS_DS02' to 'E:\Data\PTS_DS02.ndf',
move 'PTS_DSBlob' to 'E:\Data\PTS_DSBlob.ndf',
MOVE 'PTS_log' TO 'E:\Log\PTS_log.LDF'

-- TAKE SNAPSHOT
CREATE DATABASE SS_PTS ON ( NAME = PTS, FILENAME = N'E:\Data\SS_PTS.ss' ),
( NAME = PTS_DS01, FILENAME = N'E:\Data\SS_PTS_DS01.ss' ),
( NAME = PTS_DS02, FILENAME = N'E:\Data\SS_PTS_DS02.ss' )
 AS SNAPSHOT OF PTS;


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\QnA_backup_2014_11_12_220012_7288647.bak' WITH FILE = 1
-- RESTORE QnA FROM PROD
RESTORE DATABASE QnA
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\QnA_backup_2014_11_12_220012_7288647.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'QnA' TO 'E:\Data\QnA.mdf',
MOVE 'QnA_log' TO 'E:\Log\QnA_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_QnA ON ( NAME = QnA, FILENAME = N'E:\Data\SS_QnA.ss')
AS SNAPSHOT OF QnA;
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\CRM_backup_2014_11_12_220012_0112371.bak' WITH FILE = 1
-- RESTORE CRM FROM PROD
RESTORE DATABASE CRM
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\CRM_backup_2014_11_12_220012_0112371.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'CRM' TO 'E:\Data\CRM.mdf',
MOVE 'CRM_log' TO 'E:\Log\CRM_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_CRM ON ( NAME = CRM, FILENAME = N'E:\Data\SS_CRM.ss')
AS SNAPSHOT OF CRM;
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_REPL_backup_2014_11_12_220012_0112371.bak' WITH FILE = 1
-- RESTORE CARDIFF_REPL FROM PROD
RESTORE DATABASE Cardiff_REPL
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_REPL_backup_2014_11_12_220012_0112371.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Cardiff' TO 'E:\Data\Cardiff_REPL.mdf',
MOVE 'Cardiff_log' TO 'E:\Log\Cardiff_REPL_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_backup_2014_11_12_220011_9956365.bak' WITH FILE = 1
-- RESTORE CARDIFF FROM PROD
RESTORE DATABASE Cardiff
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Cardiff_backup_2014_11_12_220011_9956365.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Cardiff' TO 'E:\Data\Cardiff.mdf',
MOVE 'Cardiff_log' TO 'E:\Log\Cardiff_log.LDF'
GO

USE [Cardiff]
GO
-- DROP KEY CardNos_Key_01
IF EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'CardNos_Key_01')
	DROP SYMMETRIC KEY [CardNos_Key_01]
GO
-- DROP CERTIFICATE ASM_IT_CustomDev_Cardiff_001
IF EXISTS (SELECT * FROM sys.certificates AS C WHERE name = 'ASM_IT_CustomDev_Cardiff_001')
	DROP CERTIFICATE [ASM_IT_CustomDev_Cardiff_001]
GO
-- DROP MASTER
DROP MASTER KEY
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_Cardiff ON ( NAME = Cardiff, FILENAME = N'E:\Data\SS_Cardiff.ss')
AS SNAPSHOT OF Cardiff;
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Billing_backup_2014_11_12_220011_9800359.bak' WITH FILE = 1
-- RESTORE BIlling FROM PROD
RESTORE DATABASE Billing
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Billing_backup_2014_11_12_220011_9800359.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Billing' TO 'E:\Data\Billing.mdf',
MOVE 'Billing_log' TO 'E:\Log\Billing_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_Billing ON ( NAME = Billing, FILENAME = N'E:\Data\SS_Billing.ss')
AS SNAPSHOT OF Billing;
GO

--ALTER DATABASE Billing
--SET SINGLE_USER WITH
--ROLLBACK AFTER 60 --this will give your current connections 60 seconds to complete

--/*If there is no error in statement before database will be in multiuser
--mode.  If error occurs please execute following command it will convert
--database in multi user.*/
--ALTER DATABASE Billing SET MULTI_USER

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\AMS_backup_2014_11_12_220011_8864323.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE AMS
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\AMS_backup_2014_11_12_220011_8864323.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'AMS' TO 'E:\Data\AMS.mdf',
MOVE 'AMS_log' TO 'E:\Log\AMS_log.LDF'
GO



-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\TD_backup_2014_10_22_220028_4003447.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE TD
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\TD_backup_2014_10_22_220028_4003447.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'TD' TO 'E:\Data\TD.mdf',
MOVE 'TD_log' TO 'E:\Log\TD_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Origami_backup_2014_11_12_220012_6508617.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Origami
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Origami_backup_2014_11_12_220012_6508617.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Origami' TO 'E:\Data\Origami.mdf',
MOVE 'Origami_log' TO 'E:\Log\Origami_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kenexa_backup_2014_11_12_220012_4324533.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Kenexa
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kenexa_backup_2014_11_12_220012_4324533.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Kenexa' TO 'E:\Data\Kenexa.mdf',
MOVE 'Kenexa_log' TO 'E:\Log\Kenexa_log.LDF'
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\InexScoreCard_backup_2014_11_12_220012_3700509.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE InexScoreCard
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\InexScoreCard_backup_2014_11_12_220012_3700509.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'InexScoreCard' TO 'E:\Data\InexScoreCard.mdf',
MOVE 'InexScoreCard_log' TO 'E:\Log\InexScoreCard_log.LDF'
GO

-- TAKE SNAPSHOT
CREATE DATABASE SS_InexScoreCard ON ( NAME = InexScoreCard, FILENAME = N'E:\Data\SS_InexScoreCard.ss')
AS SNAPSHOT OF InexScoreCard;
GO

-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\EmployeeRelation_backup_2014_11_12_220012_1204413.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE EmployeeRelation
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\EmployeeRelation_backup_2014_11_12_220012_1204413.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'EmployeeRelation' TO 'E:\Data\EmployeeRelation.mdf',
MOVE 'EmployeeRelation_log' TO 'E:\Log\EmployeeRelation_Log.LDF'
GO


-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Encompass_backup_2014_11_12_220012_1516425.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Encompass
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Encompass_backup_2014_11_12_220012_1516425.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Encompass' TO 'E:\Data\Encompass.mdf',
MOVE 'Encompass_log' TO 'E:\Log\Encompass_Log.LDF'
GO


-- Kroger
-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kroger_backup_2014_11_19_220018_8902194.bak' WITH FILE = 1
-- RESTORE AMS FROM PROD
RESTORE DATABASE Kroger
FROM DISK = N'\\asm.lan\dcshare\Backup\CA\SQL\Prod\CABIPV1\Kroger_backup_2014_11_19_220018_8902194.bak' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'Kroger' TO 'E:\Data\Kroger.mdf',
MOVE 'Kroger_log' TO 'E:\Log\Kroger_Log.LDF'
GO
