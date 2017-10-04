--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_ReSyncDBUser_Login') IS NOT NULL
--	DROP PROCEDURE dbo.usp_ReSyncDBUser_Login
--GO
CREATE PROCEDURE dbo.usp_ReSyncDBUser_Login
(
	  @DBName	SYSNAME
	 ,@UserName	SYSNAME
	 ,@print_command_only BIT = NULL
	 ,@Debug	BIT	=	NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE
	--	 @DBName		SYSNAME = 'CartEasy'
	--	 @UserName		SYSNAME = 'lpsqlrw'

	SET @DBName		= ISNULL(@DBName, '')
	SET @UserName	= ISNULL(@UserName, 'ALL_SQL_USERS')
	SET @print_command_only = ISNULL(@print_command_only, 0)
	SET @Debug		= Isnull(@Debug, 0)

DECLARE @SqlPermissions NVARCHAR(MAX)
DECLARE @SqlScriptToUpdateUser NVARCHAR(MAX) =
N'
USE [?]

SET @SqlPermissions = ''''

DECLARE @sql  VARCHAR(2048), 
        @sort INT 

IF OBJECT_ID(''tempdb..#UsersToSetup_1003'') IS NOT NULL
	DROP TABLE #UsersToSetup_1003
CREATE TABLE #UsersToSetup_1003
(
	UserName SYSNAME
)

IF OBJECT_ID(''tempdb..#DBUserPermissions_1003'') IS NOT NULL
	DROP TABLE #DBUserPermissions_1003

INSERT INTO
		#UsersToSetup_1003
SELECT	DISTINCT name
FROM   sys.database_principals AS rm 
WHERE  1 = 1
AND		rm.name NOT IN (''guest'', ''INFORMATION_SCHEMA'', ''sys'', ''NT AUTHORITY\SYSTEM'')
AND		(
			((@UserToScript IN (N''ALL'', N''ALL_USERS'')) AND rm.[type] IN ( ''U'', ''S'', ''G'' ) )
		OR	((@UserToScript IN (N''SQL_USERS'', N''ALL_SQL_Users'')) AND rm.[type] IN ( ''S'' ) )
		OR	((rm.name IN (@UserToScript)) AND rm.[type] IN ( ''S'' ) AND (LEN(@UserToScript) > 0) )
		)

IF @Debug = 1
	SELECT sComments = ''Users to script'', * FROM #UsersToSetup_1003

/*********************************************/ 
/*********   DB CONTEXT STATEMENT    *********/ 
  /*********************************************/ 
  SELECT ''-- [-- DB CONTEXT --] --'' AS [-- SQL STATEMENTS --], 
         1                          AS [-- RESULT ORDER HOLDER --] 
  INTO
		#DBUserPermissions_1003
  UNION 
  SELECT ''USE'' + Space(1) + Quotename(Db_name()) AS [-- SQL STATEMENTS --], 
         1.1                                     AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT '''' AS [-- SQL STATEMENTS --], 
         2  AS [-- RESULT ORDER HOLDER --] 
  UNION 
  /*********************************************/ 
  /*********     DB USER CREATION      *********/ 
  /*********************************************/ 
  SELECT ''-- [-- DB USERS --] --'' AS [-- SQL STATEMENTS --], 
         3                        AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT CASE 
           WHEN rm.authentication_type IN ( 2, 0 ) 
         /* 2=contained database user with password, 0 =user without login; create users without logins*/ THEN (
  ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' 
  + Space(1) + '''''''' + [name] + '''''''' 
  + '') BEGIN CREATE USER '' + Space(1) 
  + Quotename([name]) 
  + '' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '' 
  + Quotename([default_schema_name]) + Space(1) 
  + '', SID = '' + CONVERT(VARCHAR(1000), sid) 
  + Space(1) + '' END; '' ) 
  ELSE ( 
  ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' 
  + Space(1) + '''''''' + [name] + '''''''' 
  + '') BEGIN CREATE USER '' + Space(1) 
  + Quotename([name]) + '' FOR LOGIN '' 
  + Quotename(Suser_sname([sid])) 
  + '' WITH DEFAULT_SCHEMA = '' 
  + Quotename(Isnull([default_schema_name], ''dbo'')) 
  + Space(1) + ''END; '' ) 
  END AS [-- SQL STATEMENTS --], 
  3.1 AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_principals AS rm 
  WHERE  NAME IN (SELECT UserName FROM #UsersToSetup_1003)
  UNION 
  /*********************************************/ 
  /*********    MAP ORPHANED USERS     *********/ 
  /*********************************************/ 
  SELECT ''-- [-- ORPHANED USERS --] --'' AS [-- SQL STATEMENTS --], 
         4                              AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT ''ALTER USER ['' + rm.NAME + ''] WITH LOGIN = ['' 
         + rm.NAME + '']'', 
         4.1 AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_principals AS rm 
         INNER JOIN sys.server_principals AS sp 
                 ON rm.NAME = sp.NAME 
                    AND rm.sid <> sp.sid 
  -- windows users, sql users, windows groups 
  WHERE  rm.NAME NOT IN ( ''dbo'', ''MS_DataCollectorInternalUser'' ) 
		 AND rm.NAME IN (SELECT UserName FROM #UsersToSetup_1003)
  UNION 
  /*********************************************/ 
  /*********    DB ROLE PERMISSIONS    *********/ 
  /*********************************************/ 
  SELECT ''-- [-- DB ROLES --] --'' AS [-- SQL STATEMENTS --], 
         5                        AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT ''EXEC sp_addrolemember @rolename ='' 
         + Space(1) 
         + Quotename(User_name(rm.role_principal_id), '''''''') 
         + '', @membername ='' + Space(1) 
         + Quotename(User_name(rm.member_principal_id), '''''''') AS 
         [-- SQL STATEMENTS --], 
         5.1                                                  AS 
         [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_role_members AS rm 
  WHERE  User_name(rm.member_principal_id) IN ( 
                                              --get user names on the database 
                                              SELECT [name] 
                                               FROM   sys.database_principals 
                                               WHERE  [principal_id] > 4 
                                                      -- 0 to 4 are system users/schemas 
                                                      AND NAME IN (SELECT UserName FROM #UsersToSetup_1003)
													  ) 
  --ORDER BY rm.role_principal_id ASC 
  UNION 
  SELECT '''' AS [-- SQL STATEMENTS --], 
         7  AS [-- RESULT ORDER HOLDER --] 
  UNION 
  /*********************************************/ 
  /*********  OBJECT LEVEL PERMISSIONS *********/ 
  /*********************************************/ 
  SELECT ''-- [-- OBJECT LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --], 
         7.1                                      AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END + 
         Space 
         (1) + 
         perm.permission_name + Space(1) 
         + ''ON '' 
         + Quotename(Schema_name(obj.schema_id)) + ''.'' 
         + Quotename(obj.NAME) --select, execute, etc on specific objects 
         + CASE WHEN cl.column_id IS NULL THEN Space(0) ELSE ''('' + 
         Quotename(cl.NAME) + 
         '')'' END + Space(1) + ''TO'' 
         + Space(1) 
         + Quotename(User_name(usr.principal_id)) COLLATE database_default + 
         CASE 
                WHEN perm.state <> ''W'' THEN Space(0) 
                ELSE Space(1) + ''WITH GRANT OPTION'' 
                                                                             END 
         AS 
         [-- SQL STATEMENTS --], 
         7.2 
         AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_permissions AS perm 
         INNER JOIN sys.objects AS obj 
                 ON perm.major_id = obj.[object_id] 
         INNER JOIN sys.database_principals AS usr 
                 ON perm.grantee_principal_id = usr.principal_id 
		 INNER JOIN #UsersToSetup_1003 TU
				 ON TU.UserName = usr.Name
         LEFT JOIN sys.columns AS cl 
                ON cl.column_id = perm.minor_id 
                   AND cl.[object_id] = perm.major_id 
  --WHERE usr.name = @OldUser 
  --ORDER BY perm.permission_name ASC, perm.state_desc ASC 
  UNION 
  /*********************************************/ 
  /*********  TYPE LEVEL PERMISSIONS *********/ 
  /*********************************************/ 
  SELECT ''-- [-- TYPE LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --], 
         8                                      AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END + 
         Space 
         (1) + 
         perm.permission_name + Space(1) 
         + ''ON '' 
         + Quotename(Schema_name(tp.schema_id)) + ''.'' 
         + Quotename(tp.NAME) --select, execute, etc on specific objects 
         + Space(1) + ''TO'' + Space(1) 
         + Quotename(User_name(usr.principal_id)) COLLATE database_default + 
         CASE 
                WHEN perm.state <> ''W'' THEN Space(0) 
                ELSE Space(1) + ''WITH GRANT OPTION'' 
                                                                             END 
         AS 
         [-- SQL STATEMENTS --], 
         8.1 
         AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_permissions AS perm 
         INNER JOIN sys.types AS tp 
                 ON perm.major_id = tp.user_type_id 
         INNER JOIN sys.database_principals AS usr 
                 ON perm.grantee_principal_id = usr.principal_id 
                    AND usr.NAME IN (SELECT UserName FROM #UsersToSetup_1003)
  UNION 
  SELECT '''' AS [-- SQL STATEMENTS --], 
         9  AS [-- RESULT ORDER HOLDER --] 
  UNION 
  /*********************************************/ 
  /*********    DB LEVEL PERMISSIONS   *********/ 
  /*********************************************/ 
  SELECT ''-- [--DB LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --], 
         10                                  AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT CASE WHEN perm.state <> ''W'' THEN perm.state_desc 
         --W=Grant With Grant Option 
         ELSE ''GRANT'' END + Space(1) + perm.permission_name --CONNECT, etc 
         + Space(1) 
         + ''TO'' + Space(1) + ''['' 
         + User_name(usr.principal_id) + '']'' COLLATE database_default 
         --TO  
         + CASE 
             WHEN perm.state <> ''W'' THEN Space(0) 
             ELSE Space(1) + ''WITH GRANT OPTION'' 
           END AS [-- SQL STATEMENTS --], 
         10.1  AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_permissions AS perm 
         INNER JOIN sys.database_principals AS usr 
                 ON perm.grantee_principal_id = usr.principal_id 
  --WHERE usr.name = @OldUser 
  WHERE  [perm].[major_id] = 0 
         AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas 
         AND [usr].[type] IN ( ''G'', ''S'', ''U'' ) 
         -- S = SQL user, U = Windows user, G = Windows group 
         AND usr.NAME IN (SELECT UserName FROM #UsersToSetup_1003)
  UNION 
  SELECT '''' AS [-- SQL STATEMENTS --], 
         11 AS [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT ''-- [--DB LEVEL SCHEMA PERMISSIONS --] --'' AS [-- SQL STATEMENTS --], 
         12                                         AS 
         [-- RESULT ORDER HOLDER --] 
  UNION 
  SELECT CASE WHEN perm.state <> ''W'' THEN perm.state_desc 
         --W=Grant With Grant Option 
         ELSE ''GRANT'' END + Space(1) + perm.permission_name --CONNECT, etc 
         + Space(1) 
         + ''ON'' + Space(1) + class_desc + ''::'' COLLATE database_default 
         --TO  
         + Quotename(Schema_name(major_id)) + Space(1) + ''TO'' + Space(1) + 
                Quotename(User_name(grantee_principal_id)) COLLATE 
         database_default + 
                CASE 
                WHEN perm.state <> ''W'' THEN Space(0) 
                ELSE Space(1) + ''WITH GRANT OPTION'' 
                END 
              AS [-- SQL STATEMENTS --], 
         12.1 AS [-- RESULT ORDER HOLDER --] 
  FROM   sys.database_permissions AS perm 
         INNER JOIN sys.schemas s 
                 ON perm.major_id = s.schema_id 
         INNER JOIN sys.database_principals dbprin 
                 ON perm.grantee_principal_id = dbprin.principal_id 
  WHERE  class = 3 --class 3 = schema 
         AND dbprin.NAME IN (SELECT UserName FROM #UsersToSetup_1003)
  ORDER  BY [-- result order holder --] 

DECLARE tmp CURSOR FOR 

SELECT	 [-- SQL STATEMENTS --]
		,[-- result order holder --]
FROM	#DBUserPermissions_1003
WHERE	[-- SQL STATEMENTS --] IS NOT NULL
ORDER BY
		[-- result order holder --]

OPEN tmp 

FETCH next FROM tmp INTO @sql, @sort 

WHILE @@FETCH_STATUS = 0 
  BEGIN 
      SET @SqlPermissions += @Sql + CHAR(13)

      FETCH next FROM tmp INTO @sql, @sort 
  END 

CLOSE tmp 

DEALLOCATE tmp 
'

SET @SqlScriptToUpdateUser = REPLACE(@SqlScriptToUpdateUser, '?', @DBName)
SET @SqlScriptToUpdateUser = REPLACE(@SqlScriptToUpdateUser, '@Debug', @Debug)

EXEC sp_executesql @SqlScriptToUpdateUser , N'@UserToScript SYSNAME,@SqlPermissions NVARCHAR(MAX) OUT', @UserToScript = @UserName, @SqlPermissions=@SqlPermissions OUT

	IF @Debug = 1
	BEGIN
		PRINT '----- Command to Find & Update User in DB ------------'
		PRINT @SqlScriptToUpdateUser
		PRINT '----- Command to Find & Update User in DB ------------'
	END

	PRINT '------- Permission Script -------'
	PRINT @SqlPermissions
	PRINT '------- Permission Script -------'

	IF @print_command_only = 0
		EXEC (@SqlPermissions)
END

/*
	-- Testing code
	EXEC dbo.usp_ReSyncDBUser_Login
			 @DBName			 = N'CartEasy'
			,@UserName			 = N'ALL'
			,@print_command_only = 1
			,@Debug				 = 1

*/