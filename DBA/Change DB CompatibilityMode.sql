USE master
go

DECLARE @SQLCmd NVARCHAR(4000)
DECLARE @DBName VARCHAR(100)
DECLARE @compatibility_level INT

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT	DBName	=	name, compatibility_level
FROM	SYS.databases AS D
WHERE	is_read_committed_snapshot_on = 0
AND		is_read_only = 0
AND		collation_name = 'SQL_Latin1_General_CP1_CI_AS'
AND		owner_sid != 0x01
ORDER BY database_id

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @DBName, @compatibility_level

WHILE (@@FETCH_STATUS = 0)
BEGIN

	IF (@compatibility_level != 120)
	BEGIN
		SET	@SQLCmd  = 'ALTER DATABASE ' + @DBname + ' SET COMPATIBILITY_LEVEL = 120' + CHAR(13)
		PRINT @SQLCmd
		EXEC sp_executeSQL @Statement = @SQlCmd
    END

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @DBName, @compatibility_level
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR

GO
