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
     referencing_database		VARCHAR(MAX)
    ,referencing_schema			VARCHAR(MAX)
    ,referencing_object_name	VARCHAR(MAX)
    ,referenced_server			VARCHAR(MAX)
    ,referenced_database		VARCHAR(MAX)
    ,referenced_schema			VARCHAR(MAX)
    ,referenced_object_name		VARCHAR(MAX)
);

WHILE (SELECT COUNT(*) FROM #databases) > 0
BEGIN

	SELECT	TOP 1
			 @database_id	= database_id
			,@database_name	= database_name 
	FROM	#databases;

	BEGIN TRY

		SET @sql = 'INSERT INTO #dependencies select 
			DB_NAME(' + convert(varchar,@database_id) + '), 
			OBJECT_SCHEMA_NAME(referencing_id,' 
				+ convert(varchar,@database_id) +'), 
			OBJECT_NAME(referencing_id,' + convert(varchar,@database_id) + '), 
			referenced_server_name,
			ISNULL(referenced_database_name, db_name(' 
				 + convert(varchar,@database_id) + ')),
			referenced_schema_name,
			referenced_entity_name
		FROM ' + quotename(@database_name) + '.sys.sql_expression_dependencies';

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

SELECT	*
FROM	#dependencies;

-- Distinct List of Databases, dependent databases, and count of referenced objects
SELECT	 [Database Name]			= referencing_database
		,[Referenced Database]		= referenced_database
		,[# of Referenced Objects]	= COUNT(DISTINCT referenced_object_name)
FROM	#dependencies 
WHERE	referencing_database != referenced_database
GROUP BY
		 referencing_database
		,referenced_database
ORDER BY
		 referencing_database
		,referenced_database
;

-- Distinct list of DBs in use
SELECT DISTINCT [Database Name] =  referencing_database FROM #dependencies
UNION 
SELECT DISTINCT [Database Name] =  referenced_database FROM #dependencies;
