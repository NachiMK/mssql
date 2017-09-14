USE DBATools
GO
IF OBJECT_ID('dbo.usp_ShrinkDatabase') IS NOT NULL
	DROP PROCEDURE dbo.usp_ShrinkDatabase
GO
CREATE PROCEDURE dbo.usp_ShrinkDatabase
(
	  @DBName	SYSNAME
	 ,@Debug	BIT	=	NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE
	--	 @DBName			SYSNAME = 'CartEasy'

	SET @DBName	= ISNULL(@DBName, '')
	SET @Debug	= Isnull(@Debug, 0)

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
	SET @SqlCmd = REPLACE(@SqlCmd, '?', @DBName)

	DECLARE @ShrinkDBScript NVARCHAR(MAX)
	EXEC sp_executesql @SqlCmd, N'@ShrinkDBScript NVARCHAR(MAX) OUT', @ShrinkDBScript = @ShrinkDBScript OUT

	IF @Debug = 1
	BEGIN
		PRINT '----- Command to Shrink DB ------------'
		PRINT @ShrinkDBScript
		PRINT '----- Command to Shrink DB ------------'
	END
	ELSE
		EXEC (@ShrinkDBScript)
END
GO
/*
	-- Testing
	DECLARE
		 @DBName			SYSNAME = 'Products'

	EXEC dbo.usp_ShrinkDatabase  @DBName	= @DBName
								,@Debug		= 1
*/