USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<SQL Server Instance Name>'
SELECT	@@SERVERNAME
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<SQL Server Version, Edition and Build>'
SELECT	@@VERSION
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<The server wide configuration>'
GO
sp_configure
	'show advanced options'
   ,1 
RECONFIGURE WITH OVERRIDE
GO
sp_configure 
GO
sp_configure
	'show advanced options'
   ,0 
RECONFIGURE WITH OVERRIDE
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of Attached Databases>'
SELECT	name AS Database_Name
	   ,dbid AS Database_ID
	   ,cmptlevel AS Database_Compatibility_Level
	   ,filename AS Database_MDF_Location
FROM	sys.sysdatabases
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Information for all the databases and their files>'
SET NOCOUNT ON
IF (OBJECT_ID('tempdb..#TMPFIXEDDRIVES') IS NOT NULL)
	DROP TABLE #TMPFIXEDDRIVES
IF (OBJECT_ID('tempdb..#TMPSPACEUSED') IS NOT NULL)
	DROP TABLE #TMPSPACEUSED
IF (OBJECT_ID('tempdb..#HDB') IS NOT NULL)
	DROP TABLE #HDB
CREATE TABLE #TMPFIXEDDRIVES (DRIVE CHAR(1), MBFREE INT) 
INSERT	INTO #TMPFIXEDDRIVES
		EXEC xp_fixeddrives 
CREATE TABLE #TMPSPACEUSED
(DBNAME VARCHAR(255)
,FILEID INT
,FILENME VARCHAR(255)
,SPACEUSED FLOAT
) 
CREATE TABLE #HDB
(name sysname NOT NULL
,db_size VARCHAR(25) NOT NULL
,owner VARCHAR(40) NOT NULL
,dbid INT NOT NULL
,created SMALLDATETIME NOT NULL
,status VARCHAR(500) NOT NULL
,compatibility_level INT NOT NULL
)
INSERT	INTO #HDB
		EXEC sp_helpdb;
INSERT	INTO #TMPSPACEUSED
		EXEC
		('sp_msforeachdb''use [?]; Select ''''?'''' DBName,fileid, Name FileNme, fileproperty(Name,''''SpaceUsed'''') SpaceUsed from sysfiles''') 
SELECT	@@servername AS SQLServerInstance
	   ,A.database_id AS Database_ID
	   ,A.name AS Database_Name
	   ,CASE D.FILEID
		  WHEN 1 THEN LTRIM(XX.db_size)
		  ELSE NULL
		END AS Database_Size
	   ,CASE D.FILEID
		  WHEN 1 THEN XX.owner
		  ELSE NULL
		END AS Database_Owner
	   ,CASE D.FILEID
		  WHEN 1 THEN XX.created
		  ELSE NULL
		END AS Database_Creation_Date
	   ,C.DRIVE
	   ,C.MBFREE AS Free_Space_of_the_Disk
	   ,D.FILEID AS Database_File_ID
	   ,B.name AS Database_Filename
	   ,CASE B.TYPE
		  WHEN 0 THEN 'DATA'
		  ELSE TYPE_DESC
		END AS FILETYPE
	   ,(B.SIZE * 8 / 1024) AS FILESIZE_MB
	   ,ROUND((B.SIZE * 8 / 1024) - (D.SPACEUSED / 128), 2) AS SPACEFREE_MB
	   ,ROUND(100 - ((((B.SIZE * 8 / 1024) - (D.SPACEUSED / 128)) * 100)
			  / CASE (B.SIZE * 8 / 1024)
				  WHEN 0 THEN 1
				  ELSE (B.SIZE * 8 / 1024)
				END), 2) AS [%USED]
	   ,B.size
	   ,B.max_size
	   ,B.growth
	   ,B.is_percent_growth
	   ,B.PHYSICAL_NAME
	   ,CASE B.TYPE
		  WHEN 0 THEN A.recovery_model_desc
		  ELSE NULL
		END AS [Recovery_Model]
	   ,CASE B.TYPE
		  WHEN 0 THEN A.compatibility_level
		  ELSE NULL
		END AS [Compatibility_Level]
	   ,CASE D.FILEID
		  WHEN 1 THEN BR.last_backup_finish_date
		  ELSE NULL
		END AS [Backup]
	   ,CASE D.FILEID
		  WHEN 1 THEN BR.last_TRLog_backup_finish_date
		  ELSE NULL
		END AS TRBackup
	   ,CASE D.FILEID
		  WHEN 1 THEN BR.last_restore_date
		  ELSE NULL
		END AS [Restore]
	   ,dm.mirroring_role_desc + '(' + dm.mirroring_state_desc + ')' AS DBMirror_Info
FROM	sys.databases A
INNER JOIN sys.master_files B ON A.database_id = B.database_id
INNER JOIN #TMPFIXEDDRIVES C ON LEFT(B.PHYSICAL_NAME, 1) = C.DRIVE
INNER JOIN #TMPSPACEUSED D ON A.name = D.DBNAME
							  AND B.name = D.FILENME
INNER JOIN #HDB XX ON XX.dbid = A.database_id
INNER JOIN (SELECT	D.database_id
				   ,B.last_backup_finish_date
				   ,TR.last_TRLog_backup_finish_date
				   ,R.last_restore_date
			FROM	sys.databases D
			LEFT JOIN (SELECT	BS.database_name
							   ,MAX(BS.backup_finish_date) AS last_backup_finish_date
					   FROM		msdb.dbo.backupset BS (NOLOCK)
					   INNER JOIN msdb.dbo.backupmediafamily MF (NOLOCK) ON BS.media_set_id = MF.media_set_id
					   WHERE	BS.backup_start_date >= CAST(CONVERT(VARCHAR(10), DATEADD(mm,
															  -3, GETDATE()), 120) AS DATETIME)
								AND BS.server_name = @@servername
								AND BS.type = 'D'
					   GROUP BY	BS.database_name
					  ) B ON D.name = B.database_name
			LEFT JOIN (SELECT	BS.database_name
							   ,MAX(BS.backup_finish_date) AS last_TRLog_backup_finish_date
					   FROM		msdb.dbo.backupset BS (NOLOCK)
					   INNER JOIN msdb.dbo.backupmediafamily MF (NOLOCK) ON BS.media_set_id = MF.media_set_id
					   WHERE	BS.backup_start_date >= CAST(CONVERT(VARCHAR(10), DATEADD(mm,
															  -1, GETDATE()), 120) AS DATETIME)
								AND BS.server_name = @@servername
								AND BS.type = 'L'
					   GROUP BY	BS.database_name
					  ) TR ON D.name = TR.database_name
			LEFT JOIN (SELECT	rh.destination_database_name
							   ,MAX(rh.restore_date) AS last_restore_date
					   FROM		msdb.dbo.restorehistory rh (NOLOCK)
					   INNER JOIN msdb.dbo.backupset BS (NOLOCK) ON rh.backup_set_id = BS.backup_set_id
					   WHERE	BS.type = 'D'
								AND rh.restore_date >= CAST(CONVERT(VARCHAR(10), DATEADD(mm,
															  -3, GETDATE()), 120) AS DATETIME)
					   GROUP BY	rh.destination_database_name
					  ) R ON D.name = R.destination_database_name
		   ) BR ON A.database_id = BR.database_id
LEFT JOIN msdb.sys.database_mirroring dm (NOLOCK) ON A.database_id = dm.database_id
ORDER BY database_name
IF (OBJECT_ID('tempdb..#TMPFIXEDDRIVES') IS NOT NULL)
	DROP TABLE #TMPFIXEDDRIVES
IF (OBJECT_ID('tempdb..#TMPSPACEUSED') IS NOT NULL)
	DROP TABLE #TMPSPACEUSED
IF (OBJECT_ID('tempdb..#HDB') IS NOT NULL)
	DROP TABLE #HDB
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Information for all the server logins>'
EXEC sp_helplogins
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<The permissions of the users for each database>'
DECLARE	@DB_USers TABLE
(DBName sysname
,UserName sysname
,LoginType sysname
,AssociatedRole VARCHAR(MAX)
,create_date DATETIME
,modify_date DATETIME
)
INSERT	@DB_USers
		EXEC sp_MSforeachdb '
use [?]
SELECT ''?'' AS DB_Name,
case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''
SELECT	DBName
	   ,UserName
	   ,LoginType
	   ,create_date
	   ,modify_date
	   ,STUFF((SELECT	',' + CONVERT(VARCHAR(500), AssociatedRole)
			   FROM		@DB_USers user2
			   WHERE	user1.DBName = user2.DBName
						AND user1.UserName = user2.UserName
			  FOR
			   XML PATH('')
			  ), 1, 1, '') AS Permissions_user
FROM	@DB_USers user1
GROUP BY DBName
	   ,UserName
	   ,LoginType
	   ,create_date
	   ,modify_date
ORDER BY DBName
	   ,UserName
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Script out any Credentials under Security>'
SELECT	'CREATE CREDENTIAL ' + name + ' WITH IDENTITY = '''
		+ credential_identity + ''', SECRET = ''<Put Password Here>'';'
FROM	sys.credentials
ORDER BY name;
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all Server Backup Devices>'
SELECT	'Server[@Name='
		+ QUOTENAME(CAST(SERVERPROPERTY(N'Servername') AS sysname), '''')
		+ ']' + '/BackupDevice[@Name=' + QUOTENAME(o.name, '''') + ']' AS [Urn]
	   ,o.name AS [Name]
	   ,CASE WHEN 1 = msdb.dbo.fn_syspolicy_is_automation_enabled()
				  AND EXISTS ( SELECT	*
							   FROM		msdb.dbo.syspolicy_system_health_state
							   WHERE	target_query_expression_with_id LIKE 'Server/BackupDevice\[@Name='
										+ QUOTENAME(o.name, '''') + '\]%'
										ESCAPE '\' ) THEN 1
			 ELSE 0
		END AS [PolicyHealthState]
FROM	sys.backup_devices o
ORDER BY [name] ASC
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all System and Mirroring endpoints>'
SELECT	*
FROM	sys.endpoints 
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all Linked Servers and their associated login>'
SELECT	ss.server_id
	   ,ss.name
	   ,'Server ' = CASE ss.server_id
					  WHEN 0 THEN 'Current Server'
					  ELSE 'Remote Server'
					END
	   ,ss.product
	   ,ss.provider
	   ,ss.catalog
	   ,'Local Login ' = CASE sl.uses_self_credential
						   WHEN 1 THEN 'Uses Self Credentials'
						   ELSE ssp.name
						 END
	   ,'Remote Login Name' = sl.remote_name
	   ,'RPC Out Enabled' = CASE ss.is_rpc_out_enabled
							  WHEN 1 THEN 'True'
							  ELSE 'False'
							END
	   ,'Data Access Enabled' = CASE ss.is_data_access_enabled
								  WHEN 1 THEN 'True'
								  ELSE 'False'
								END
	   ,ss.modify_date
FROM	sys.servers ss
LEFT JOIN sys.linked_logins sl ON ss.server_id = sl.server_id
LEFT JOIN sys.server_principals ssp ON ssp.principal_id = sl.local_principal_id
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Script out the Logon Triggers of the server, if any exist>'
SELECT	SSM.definition
FROM	sys.server_triggers AS ST
JOIN	sys.server_sql_modules AS SSM ON ST.object_id = SSM.object_id
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<REPLICATION - List Publication or Subscription articles>'
IF EXISTS ( SELECT	1
			FROM	INFORMATION_SCHEMA.TABLES
			WHERE	TABLE_TYPE = 'BASE TABLE'
					AND TABLE_NAME = 'sysextendedarticlesview' )
	(SELECT	sub.srvname
		   ,pub.name
		   ,art.name
		   ,art.dest_table
		   ,art.dest_owner
	 FROM	sysextendedarticlesview art
	 INNER JOIN syspublications pub ON (art.pubid = pub.pubid)
	 INNER JOIN syssubscriptions sub ON (sub.artid = art.artid)
	)
ELSE
	SELECT	'No Publication or Subcsription articles were found'
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all SQL Server Agent jobs>'
USE msdb
GO
SELECT	srv.srvname
	   ,sj.name
	   ,COALESCE(sj.description, '')
	   ,ss.name
	   ,ss.schedule_id
	   ,sc.name
	   ,ss.freq_type
	   ,ss.freq_interval
	   ,ss.freq_subday_type
	   ,ss.freq_subday_interval
	   ,ss.freq_relative_interval
	   ,ss.freq_recurrence_factor
	   ,COALESCE(STR(ss.active_start_date, 8),
				 CONVERT(CHAR(8), GETDATE(), 112))
	   ,STUFF(STUFF(REPLACE(STR(ss.active_start_time, 6), ' ', '0'), 3, 0, ':'),
			  6, 0, ':')
	   ,STR(ss.active_end_date, 8)
	   ,STUFF(STUFF(REPLACE(STR(ss.active_end_time, 6), ' ', '0'), 3, 0, ':'),
			  6, 0, ':')
	   ,sj.enabled
	   ,ss.enabled
FROM	msdb..sysschedules AS ss
INNER JOIN msdb..sysjobschedules AS sjs ON sjs.schedule_id = ss.schedule_id
INNER JOIN msdb..sysjobs AS sj ON sj.job_id = sjs.job_id
INNER JOIN sys.sysservers AS srv ON srv.srvid = sj.originating_server_id
INNER JOIN msdb..syscategories AS sc ON sc.category_id = sj.category_id
WHERE	ss.freq_type IN (1, 4, 8, 16, 32)
ORDER BY srv.srvname
	   ,sj.name
	   ,ss.name
GO
USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SQL Server Agent - Alerts>'
SELECT	*
FROM	msdb.dbo.sysalerts 
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SQL Server Agent - Operators>'
SELECT	name
	   ,email_address
	   ,enabled
FROM	msdb.dbo.sysoperators
ORDER BY name
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SSIS packages in MSDB>'
USE msdb
GO
SELECT	name
	   ,description
	   ,createdate
FROM	sysssispackages
WHERE	description NOT LIKE 'System Data Collector Package'
USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'