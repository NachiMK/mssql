USE Master
GO
DECLARE @SqlCmd NVARCHAR(MAX)

SET @SqlCmd = 
N'
USE ?

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

PRINT ''
USE ?
''
PRINT ''ALTER DATABASE ? SET RECOVERY SIMPLE;''
PRINT @SqlShrinkFiles
PRINT @SqlShrinkLogFiles
PRINT @SqlShrinkDB
PRINT ''ALTER DATABASE ? SET RECOVERY FULL;''

-- EXEC(@SqlShrinkFiles)

'

EXEC dbo.sp_foreachdb @command = @sqlCmd, @print_command_only = 0, @user_only = 1--, @database_list = ''
