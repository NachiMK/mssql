DECLARE @Sql NVARCHAR(MAX)
SET @Sql = N'
USE ?;
IF NOT EXISTS (SELECT * FROM sys.sysusers where name = ''db_executor'' and issqlrole = 1)
BEGIN
    CREATE ROLE [db_executor] AUTHORIZATION [dbo]
    GRANT EXECUTE ON SCHEMA::[dbo] TO [db_executor]
    GRANT SELECT ON SCHEMA::[dbo] TO [db_executor]
    GRANT VIEW CHANGE TRACKING ON SCHEMA::[dbo] TO [db_executor]
    GRANT VIEW DEFINITION ON SCHEMA::[dbo] TO [db_executor]
END
'

EXEC DBAUTil.dbo.sp_foreachdb @command = @Sql, @print_dbname = 1, @database_list = N'DBAUtil', @print_command_only = 0
GO

