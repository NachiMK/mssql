/*
	Find Cross database dependencies.

	- Get List of databases from a server
	- For each database
		- Generate Scripts for All Views/Functions/Procs/Synonyms
			- See if the script has dependency to any of other databases in our list
			- If so document the dependency and move to next DB.
			- Can we get Count & Type of Objects that are dependent on other databases.
*/

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#databases') IS NOT NULL
	DROP TABLE #databases
CREATE TABLE #databases
(
     database_id	INT
    ,database_name	SYSNAME
);

-- ignore systems databases
INSERT INTO 
		#databases(database_id, database_name)
SELECT	database_id, name
FROM	sys.databases
WHERE	database_id > 4
;

DECLARE 
	 @database_id	INT 
    ,@database_name	SYSNAME 
    ,@sql			VARCHAR(MAX);

IF OBJECT_ID('tempdb..#dependencies') IS NOT NULL
	DROP TABLE #dependencies
CREATE TABLE #dependencies
(
	 DatabaseName				SYSNAME
	,SchemaName					SYSNAME
	,ObjectName					SYSNAME
	,ObjectType					SYSNAME
	,ObjectId					BIGINT
	,Referenced_ServerName		SYSNAME
	,Referenced_DatabaseName	SYSNAME
	,Referenced_SchemaName		SYSNAME
	,Referenced_ObjectName		SYSNAME
	,Referenced_ObjectType		SYSNAME
	,Referenced_ObjectId		BIGINT
);

WHILE (SELECT COUNT(*) FROM #databases) > 0
BEGIN

	SELECT	TOP 1
			 @database_id	= database_id
			,@database_name	= database_name 
	FROM	#databases;

	BEGIN TRY

		SET @sql = '
					USE [' + @database_name + ']

					INSERT INTO 
						#dependencies 
					SELECT 
						 DatabaseName				= DB_NAME()
						,SchemaName					= OBJECT_SCHEMA_NAME(referencing_id,' + convert(varchar,@database_id) +')
						,ObjectName					= OBJECT_NAME(referencing_id,' + convert(varchar,@database_id) + ') 
						,ObjectType					= s.type_desc
						,ObjectId					= referencing_id
						,Referenced_ServerName		= ISNULL(referenced_server_name, '''')
						,Referenced_DatabaseName	= ISNULL(referenced_database_name, db_name('+ convert(varchar,@database_id) + '))
						,Referenced_SchemaName		= referenced_Schema_name
						,Referenced_ObjectName		= referenced_entity_name
						,Referenced_ObjectType		= referenced_class_desc
						,Referenced_ObjectId		= referenced_id

					FROM	sys.sql_expression_dependencies	D
					JOIN	sys.objects						S	ON	S.object_Id = D.referencing_id
					WHERE	1 = 1
					AND		(
								(
									D.referenced_database_name IN (SELECT	name FROM sys.databases)
								AND	D.referenced_server_name IS NULL
								)
								OR    
								(D.referenced_server_name IS NOT NULL)
							)';

		EXEC(@sql);
	END TRY
	BEGIN CATCH
		PRINT '------'
		PRINT 'Error finding references in DB:' + @database_name
		PRINT 'Error Message :' + ERROR_MESSAGE()
		PRINT 'Error Number  :' + CONVERT(NVARCHAR, ERROR_NUMBER())
		PRINT 'Error Line    :' + CONVERT(NVARCHAR, ERROR_LINE())
		PRINT 'Error Severity:' + CONVERT(NVARCHAR, ERROR_SEVERITY())
		PRINT '------'
	END CATCH
	
	DELETE FROM #databases WHERE database_id = @database_id;
END;

USE [master]
GO

SELECT	*
FROM	#dependencies;

-- Distinct List of Databases, dependent databases, and count of referenced objects
SELECT	 [Database Name]			= DatabaseName
		,[Referenced Server]		= ISNULL(Referenced_ServerName, '')
		,[Referenced Database]		= Referenced_DatabaseName
		,[# of Referenced Objects]	= COUNT(DISTINCT Referenced_ObjectName)
FROM	#dependencies 
WHERE	DatabaseName != Referenced_DatabaseName
GROUP BY
		 DatabaseName
		,ISNULL(Referenced_ServerName, '')
		,Referenced_DatabaseName
ORDER BY
		 DatabaseName
		,[Referenced Server]
		,[Referenced Database]
;

-- Distinct list of DBs in use
SELECT DISTINCT [Database Name] =  DatabaseName FROM #dependencies
UNION 
SELECT DISTINCT [Database Name] =  Referenced_DatabaseName FROM #dependencies;
