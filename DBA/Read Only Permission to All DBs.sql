SET NOCOUNT ON;

DECLARE @user_name    SYSNAME = 'SPARKMT\SQLReadOnly'
        , @login_name SYSNAME = 'SPARKMT\SQLReadOnly';

SELECT '
    USE ' + QUOTENAME(NAME) + ';

    CREATE USER ' + QUOTENAME(@user_name)
       + ' FOR LOGIN ' + QUOTENAME(@login_name)
       + ' WITH DEFAULT_SCHEMA=[dbo];

    EXEC sys.sp_addrolemember
      ''db_datareader'',
      ''' + @user_name + ''';

    EXEC sys.sp_addrolemember
      ''db_denydatawriter'',
      '''
       + @user_name + '''; 

GO
'
FROM   sys.databases
WHERE  database_id > 4
       AND state_desc = 'ONLINE' 