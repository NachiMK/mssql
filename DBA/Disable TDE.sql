/*
	Disable encryption
*/
DECLARE @DBName					SYSNAME = 'Amazon'	-- SET THIS TO DATABASE YOU WANT TO DISABLE ENCRYPTION
DECLARE @print_commands_only	BIT = 1				-- SET THIS TO 0 to actually run the script, setting to 1 will just print the actual commands
DECLARE @BackupDirectory		NVARCHAR(400) = 'C:\SQL\SQL_BACKUP\'	-- Localtion were backup should be kept. If null or empty it will be set to default backup location

SET @DBName = ISNULL(@DBName, '')
SET @print_commands_only = ISNULL(@print_commands_only, 1)
SET @BackupDirectory = ISNULL(@BackupDirectory, '')

DECLARE @SqlDecryptCmd NVARCHAR(MAX)
DECLARE @SqlShrinkCmd NVARCHAR(MAX)
DECLARE @SqlCmd NVARCHAR(MAX)

SET @SqlDecryptCmd = 
N'

EXEC DBAUtil.dbo.DatabaseBackup @DAtabases = ''?'', @Directory = ''<@BackupDirectory>'', @BackupType = ''FULL''

USE MASTER
ALTER DATABASE [?]
SET ENCRYPTION OFF

DECLARE @State INT = 0
DECLARE @DBToChange SYSNAME = ''?''

WHILE @State != 1
BEGIN

	SELECT	@State = encryption_state
	FROM	sys.dm_database_encryption_keys DEK
	JOIN	sys.databases D ON D.database_id = DEK.database_id
	WHERE	D.name = @DBToChange

	PRINT ''State Last Checked: '' + CONVERT(VARCHAR, GETDATE())
	PRINT ''State Value: '' + CONVERT(VARCHAR, @State)

	IF @State != 1
		WAITFOR DELAY ''00:00:30''
END

USE [?]
DROP DATABASE ENCRYPTION KEY

IF EXISTS (SELECT * FROM sys.databases WHERE name = ''?'' AND recovery_model = 1)
	BACKUP LOG [?] TO DISK = ''NUL''
'

SET @SqlShrinkCmd = 
N'
USE [?]

DECLARE @SqlShrinkLogFiles NVARCHAR(1000) = ''''
DECLARE @SqlShrinkFiles NVARCHAR(1000) = ''''

SELECT @SqlShrinkFiles = @SqlShrinkFiles + ''
DBCC SHRINKFILE (N'''''' + name + '''''') --, 0, TRUNCATEONLY)
''
FROM	sys.database_files	SF
WHERE type = 0

SELECT @SqlShrinkLogFiles = @SqlShrinkLogFiles + ''
DBCC SHRINKFILE (N'''''' + name + '''''') --, 0, TRUNCATEONLY)

''
FROM	sys.database_files	SF
WHERE type = 1

DECLARE @SqlShrinkDB NVARCHAR(1000) = ''''
SET @SqlShrinkDB = ''DBCC SHRINKDATABASE(N'''''' + DB_NAME() + '''''')
''

SET @ShrinkDBScript = 
''
USE ?
'' 
 + ''ALTER DATABASE ? SET RECOVERY SIMPLE;''
 + @SqlShrinkFiles
 + @SqlShrinkLogFiles
 + @SqlShrinkDB
 + ''ALTER DATABASE ? SET RECOVERY FULL;''

'
SET @SqlShrinkCmd = REPLACE(@SqlShrinkCmd, '?', @DBName)
DECLARE @ShrinkDBScript NVARCHAR(MAX)
EXEC sp_executesql @SqlShrinkCmd, N'@ShrinkDBScript NVARCHAR(MAX) OUT', @ShrinkDBScript = @ShrinkDBScript OUT

SET @SqlCmd = @SqlDecryptCmd + @ShrinkDBScript
SET @SqlCmd = REPLACE(@SqlCmd, '?', @DBName)
SET @SqlCmd = REPLACE(@SqlCmd, '<@BackupDirectory>', @BackupDirectory)

PRINT '----- Command to Unencrypt DB ------------'
PRINT @SqlCmd
PRINT '----- Command to Shrink DB ------------'

IF @print_commands_only = 0
	EXEC (@SqlCmd)
