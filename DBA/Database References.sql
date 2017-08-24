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
CREATE TABLE #databases(
    database_id int, 
    database_name sysname
);

-- ignore systems databases
INSERT INTO #databases(database_id, database_name)
SELECT database_id, name FROM sys.databases
WHERE database_id > 4
and   name NOT LIKE 'ASPState%'
and   name NOT LIKE 'CommonDB%'
and   name NOT LIKE 'CustomerGUID_Archive%'
and   name NOT LIKE 'DBA%'
and   name NOT LIKE 'IISLogs%'
and   name NOT LIKE 'Private%'
and   name NOT LIKE 'TCS_%'
;

DECLARE 
    @database_id int, 
    @database_name sysname, 
    @sql varchar(max);

IF OBJECT_ID('tempdb..#dependencies') IS NOT NULL
	DROP TABLE #dependencies
CREATE TABLE #dependencies(
    referencing_database varchar(max),
    referencing_schema varchar(max),
    referencing_object_name varchar(max),
    referenced_server varchar(max),
    referenced_database varchar(max),
    referenced_schema varchar(max),
    referenced_object_name varchar(max)
);

WHILE (SELECT COUNT(*) FROM #databases) > 0 BEGIN
    SELECT TOP 1 @database_id = database_id, 
                 @database_name = database_name 
    FROM #databases;

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

    DELETE FROM #databases WHERE database_id = @database_id;
END;

SELECT * FROM #dependencies;

-- DB Dependencies
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

-- DBs in use
SELECT DISTINCT [Database Name] =  referencing_database FROM #dependencies
UNION 
SELECT DISTINCT [Database Name] =  referenced_database FROM #dependencies;
