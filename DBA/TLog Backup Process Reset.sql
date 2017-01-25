/*
	Backup Process re-setup
*/

USE mnDBA
GO

/*

	1. Disable the JOb or update the job to stop taking TLog backups for Maropost in sparkMT
	2. Disable the job that restores TLogs in UTMT
	3. Take a Full Backup in SPARKMT (Script below)
	4. Take a TLog backup in SPARKMT (Script below)
	5. Wait for Full backup to be copied over from sparkMT to UTMT
	6. WAit for the TLog to be copied over. 
	7. Restore header only of the full back up on UTMT (remote into UT jump box and do this) - This is to ensure the backup got copied over without issues (Script below)
	8. If Headers restore without errors. restore the full backup in UTMT server (DB mode should be in NORECOVERY) - (Script below)
	9. Clear all previous TLog non applied entries from Backup control tables in UTMT mnDBA_UTMT database (on whatever server you working on)
	10. Mark the TLog that you just created as 3 hours older so that automated process takes it over
	11. Restore the TLog in UTMT - (Script below)
	12. Enable Job in UTMT for restoration (Use SSMS UI)
	13. Enable TLog job in SparkMT. (Use SSMS UI)
	14. Wait for 3 hours and verify whether TLogs are catching up properly. (Check the BackupFileList table in UTMT for logs that weren't applied for more than 3 hours)
*/

-- STEP 3
EXEC mnDBA.dbo.usp_Backup_call @path = '\\lalogship01\Logshipping\Tlog\LASQL09\', @localpath = 'G:\SQL_BACKUP\full\', @backup_databases = 'epProductService', @bkpType = 'Full', @retention = 8, @liteSpeed = 'N' , @freespaceMBrequired = 6000
GO
-- STEP 4
EXEC mnDBA.dbo.usp_Backup_call @path = '\\lalogship01\Logshipping\Tlog\LASQL09\', @localpath = 'G:\SQL_BACKUP\Tlog\', @backup_databases = 'epProductService', @bkpType = 'Tlog', @retention = 3, @liteSpeed = 'N' , @freespaceMBrequired = 16000 
GO

-- SET @dbType = 'epAccess,epAuthorization,epOrder,epProductService,epRenewal,epValidation,mnDBA,mnKey3,mnPremiumServices,mnRegion,mnSystem,mnSubscription,msdb,mnRegFlow'
-- TEMP CHANGE TO --SET @dbType = 'epAccess,epAuthorization,epRenewal,epValidation,mnDBA,mnKey3,mnPremiumServices,mnRegion,mnSystem,mnSubscription,msdb,mnRegFlow'


use mnDBA_UTMT -- ONLY AFTER REMOTING INTO UTMT JUMP BOX AND CONNECTING TO SERVER YOU WANT TO RESTORE
GO

-- STEP 5 & 6: Verify file got copied over to Location \\172.20.101.51\utsqlshare\Tlog\<ServerName>\

-- STEP 7: REmote into UTMT jumpbox, connect to Server and run on it once you find the file name from Step 5 & 6 above 
RESTORE FILELISTONLY FROM DISK ='\\172.20.101.51\utsqlshare\Tlog\LASQL09\LASQL09_epProductService_20151021141709_1.BAK'

-- STEP 8: Restore backup, again find proper file name, change database name, change path if needed, USE THE PROPER BAK file, don't restore TRN file.
RESTORE DATABASE epProductService FROM DISK ='\\172.20.101.51\utsqlshare\Tlog\LASQL09\LASQL09_epProductService_20151021141709_1.BAK'
WITH  NORECOVERY, FILE = 1
,  MOVE N'epProductService' TO N'G:\SQL_DATA\epProductService.mdf',
--MOVE N'epProductService1' TO N'G:\SQL_DATA\epProductService_1.mdf',
--MOVE N'Maropost_Index' TO N'G:\SQL_DATA\Maropost_Index_Data.ndf',   
MOVE N'epProductService_Log' TO N'G:\SQL_LOG\epProductService_Log.ldf',  NOUNLOAD,  STATS = 10


-- Step 9: REstore TLOg, before restoring TLog make sure all other OLD TLogs are cleared from queue by updating the Applied time for older entries except the latest TRN file we have.
UPDATE dbo.BackupFileList 
SET Applied_Time = '1/1/1900'
WHERE backupDB = 'epProductService' and Applied_Time is null
AND BackupFile != 'LASQL09_epProductService_20151021141756.TRN'

-- Step 10: Find the Max verified time and subtract 180 minutes from it. We need this value to update the queue entry so that the automated TLog restoration process can pick up our latest file instead of waiting for 3 hours.
DECLARE @maxVerifiedTime datetime
SELECT @maxVerifiedTime = MAX(Verified_Time) FROM BackupFileList
SELECT maxVerifiedTime = @maxVerifiedTime, LogTimeMx = DATEADD(mi,-180,@maxVerifiedTime)

UPDATE dbo.BackupFileList 
SET LogTime = DATEADD(mi, -1, @maxVerifiedTime)
WHERE backupDB = 'epProductService'  -- <-- Dont forget to change the database name -->
AND Applied_Time is null

-- Once above ist done, run the following to verify this query is returning the latest TRN file that you manually backedup, if it doesn't show up in this
-- query the automated process won't pickup the log and restore it.
SELECT	 backuppath
		,backupDB
		,BackupFile
		,logtime 
FROM	BackupFileList   
WHERE	Applied_Time is null   
AND		Logtime < DATEADD(mi,-180,@maxVerifiedTime)   
AND		Backupdb='epProductService'  
ORDER BY LogTime   DESC

-- STEP 11: Restore the TRN File
EXEC usp_restore_tranlogs @backupdbname = 'epProductService', @debug = 1

