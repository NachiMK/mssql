/*

	What is purpose?
		Find whether a table is being used or not?

	Final Output:
		Database, Table, Last Used, Row Count, Size, Used Flag

		To get to final output we need
		Database
		Tables
		Last Read Date
		Last Written to date
		Last Missing index reported date
		Last stats updated date
		Row count
		Table size (index + data + unused)
		Table created
		Table modified (schema modification)
		Table has Index

	Approach:
		1. Find all Tables, Row Count, Created Date, Modified Date, Size from all databases
		2. Find Table has index or not, # of indexes table has, Last Read, Last Written, Read count, Write counts
		3. Find last missing index reported (only for tables that doesn't have any indexes) - Time consuming
		4. Find the Last used date (Basically Max of Create date, modified date, last read date, last written date)
		5. If Last Used date < 6 months from today then mark as not used.
*/

USE [DBA];
GO

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#AllTables') IS NOT NULL
	DROP TABLE #AllTables
CREATE TABLE #AllTables
(
	 DatabaseId		BIGINT
	,SchemaName		SYSNAME
	,SchemaId		BIGINT
	,TableId		BIGINT
	,TableName		SYSNAME
)

IF OBJECT_ID('tempdb..#TableRowCount') IS NOT NULL
    DROP TABLE #TableRowCount
CREATE TABLE #TableRowCount
(	 DatabaseName   SYSNAME
	,DatabaseId		BIGINT
	,SchemaName		NVARCHAR(256)
	,SchemaId		BIGINT
	,TableName		NVARCHAR(256)
	,TableId		BIGINT
	,[RowCount]		BIGINT
	,TotalSizeInMB  DECIMAL
	,create_date	DATETIME2
	,modify_date	DATETIME2
)

IF OBJECT_ID('tempdb..#Stats') IS NOT NULL
    DROP TABLE #Stats
CREATE TABLE #Stats
(
	 DatabaseId			BIGINT
	,SchemaId			BIGINT
	,TableId			BIGINT
	,StatsUpdateDate	DATETIME2
	,HasStats			BIT
)

IF OBJECT_ID('tempdb..#index_usage') is not null
	DROP TABLE #index_usage
CREATE TABLE #index_usage
(
		 DatabaseId		BIGINT
		,SchemaId		BIGINT  DEFAULT -1
		,TableId		BIGINT
		,ReadCount		BIGINT
		,WriteCount		BIGINT
		,LastReadDate	DATETIME2
		,LastWriteDate	DATETIME2
       ,PRIMARY KEY CLUSTERED (DatabaseId, SchemaId, TableId)
)

IF OBJECT_ID('tempdb..#TablesMissingIndexes') IS NOT NULL
	DROP TABLE #TablesMissingIndexes
CREATE TABLE #TablesMissingIndexes
(
	 DatabaseId		BIGINT
	,SchemaId		BIGINT
	,TableId		BIGINT
	,LastSeekDate	DATETIME2
)

IF OBJECT_ID('tempdb..#dependencies') IS NOT NULL
	DROP TABLE #dependencies
CREATE TABLE #dependencies
(
	 Referencing_DatabaseId		BIGINT
	,Referencing_Object			SYSNAME
	,Referencing_Object_Id		BIGINT
	,Referencing_Object_Type	SYSNAME

	,Referenced_Database_Id		BIGINT
	,Referenced_Schema_Id		BIGINT
	,Referenced_TableId			BIGINT
	,Referenced_Object_Type		SYSNAME
	,Referenced_Table_name		SYSNAME
);

;WITH index_stats 
AS 
(
	SELECT	 DatabaseId		= database_id
			,SchemaId		= ISNULL(SCHEMA_ID(OBJECT_SCHEMA_NAME(OBJECT_ID, database_id)), -1)
			,TableId		= OBJECT_ID
			,ReadCount		= user_seeks + user_scans + user_lookups
			,WriteCount		= user_updates
			,LastReadDate	= (
									SELECT MAX(value)
									FROM (
											VALUES(last_user_seek),(last_user_scan),(last_user_lookup)
											)	AS v(value)
								)
			,LastWriteDate	= last_user_update
	FROM	sys.dm_db_index_usage_stats
	WHERE	database_id > 4
)
INSERT INTO 
		#index_usage
SELECT	 DatabaseId	
		,SchemaId	
		,TableId	
		,ReadCount		= SUM(ReadCount)
		,WriteCount		= SUM(WriteCount)
		,LastReadDate	= Max(LastReadDate)
		,LastWriteDate	= Max(LastWriteDate)
FROM	index_stats
GROUP BY
		 DatabaseId
		,SchemaId
		,TableId
ORDER BY
	DatabaseId, SchemaId, TableId

DECLARE @SqlCommand NVARCHAR(MAX)
SET     @SqlCommand =
'
USE ?

IF OBJECT_ID(''tempdb..#RowCntAllTables'') IS NOT NULL
    DROP TABLE #RowCntAllTables
CREATE TABLE #RowCntAllTables
(
     name		sysname
    ,rows		bigint
    ,reserved	sysname
    ,data		sysname
    ,index_size	sysname
    ,unused		sysname
)

IF OBJECT_ID(''tempdb..#Tables'') IS NOT NULL
    DROP TABLE #Tables

INSERT  INTO	#AllTables
SELECT	 DatabaseId		= DB_ID()
		,SchemaName		= SCHEMA_NAME(schema_id)
		,SchemaId		= schema_id
		,TableId		= object_id
		,TableName		= name
FROM	sys.tables
WHERE	name not like ''sys%''
AND		name not like ''MSpeer%''
AND		name not like ''MSpub%''
AND		type = ''U''

SELECT	name
INTO	#Tables
FROM	sys.tables
WHERE	name not like ''sys%''
AND		name not like ''MSpeer%''
AND		name not like ''MSpub%''
AND		type = ''U''

DECLARE @Tablename SYSNAME

WHILE EXISTS (SELECT 1 FROM #Tables)
BEGIN
    SET @TableName = (SELECT TOP 1 name FROM #Tables)

	BEGIN TRY
		INSERT INTO 
				#RowCntAllTables
		EXEC sp_spaceused @Tablename
	END TRY
	BEGIN CATCH
		PRINT ''-------Error in Getting spaceused for Table :'' + @Tablename
		PRINT ''Error Message: '' + ERROR_MESSAGE()
		PRINT ''Error #: ''		+ CONVERT(NVARCHAR, ERROR_NUMBER())
		PRINT ''Error Line: ''	+ CONVERT(NVARCHAR, ERROR_LINE())
		PRINT ''Error Proc: ''	+ ERROR_PROCEDURE()
		PRINT ''-------Error in Running sp_spacedused on DB:''
	END CATCH
    
	DELETE #Tables WHERE name = @Tablename
END

INSERT	INTO
		#TableRowCount
SELECT	 DatabaseName   = DB_NAME()
		,DatabaseId		= DB_ID()	
		,SchemaName		= T.Table_schema
		,SchemaId		= ST.SCHEMA_ID
		,TableName		= ST.name
		,TableId		= ST.OBJECT_ID
		,[RowCount]		= ISNULL(R.rows, -1)
		,TotalSizeInMB  = (ISNULL(CONVERT(DECIMAL, REPLACE(data, '' KB'', '''')), 0) 
							+ ISNULL(CONVERT(DECIMAL, REPLACE(index_size, '' KB'', '''')), 0) 
							+ ISNULL(CONVERT(DECIMAL, REPLACE(unused, '' KB'', '''')), 0)) / 1024.00
		,st.create_date
		,st.modify_date
FROM	SYS.TABLES					ST
JOIN	INFORMATION_SCHEMA.TABLES	T	ON	T.Table_name = ST.name
LEFT
JOIN	#RowCntAllTables			R	ON	R.name		 = ST.name
WHERE	ST.name not like ''sys%''
AND		ST.name not like ''MSpeer%''
AND		ST.name not like ''MSpub%''
AND		ST.type = ''U''

INSERT	INTO
		#Stats
SELECT	 DatabaseId			=	DB_ID()
		,SchemaId			=	ST.schema_id
		,TableId			=	S.object_id
		,StatsUpdateDate	=	max(P.last_updated)
		,HasStats			=	1
FROM	sys.Stats S
JOIN	sys.tables ST ON S.object_id = ST.object_id
CROSS   APPLY
		(
			SELECT *
			FROM   sys.dm_db_stats_properties (S.object_id, S.stats_id)
		) P
WHERE	NOT EXISTS (SELECT 1 FROM #index_usage IU WHERE IU.TableId = S.object_id)
AND		ST.name not like ''sys%''
AND		ST.name not like ''MSpeer%''
AND		ST.name not like ''MSpub%''
GROUP BY
		S.object_id, ST.schema_Id

INSERT INTO
		#TablesMissingIndexes
SELECT	 DatabaseId		=	dm_mid.database_id
		,SchemaId		=	ISNULL(SCHEMA_ID(OBJECT_SCHEMA_NAME(dm_mid.OBJECT_ID, DB_ID())), -1)
		,TableId		=	dm_mid.OBJECT_ID
		,LastSeekDate	=	MAX(dm_migs.last_user_seek)
FROM	sys.dm_db_missing_index_groups dm_mig
JOIN	sys.dm_db_missing_index_group_stats dm_migs	ON	dm_migs.group_handle	= dm_mig.index_group_handle
JOIN	sys.dm_db_missing_index_details dm_mid		ON	dm_mig.index_handle		= dm_mid.index_handle
WHERE	dm_mid.database_ID = DB_ID()
--AND		NOT EXISTS (SELECT 1 FROM #index_usage IU WHERE IU.TableId = dm_mid.OBJECT_ID)
GROUP   BY
		dm_mid.database_id, dm_mid.OBJECT_ID

INSERT INTO
	#dependencies
SELECT 
	 Referencing_DatabaseId		= DB_ID()
	,Referencing_Object			= OBJECT_NAME(referencing_id, DB_ID())
	,Referencing_Object_Id		= s.object_id
	,Referencing_Object_Type	= s.type_desc

	,Referenced_Database_Id		= CASE WHEN REFERENCED_SERVER_NAME IS NULL THEN DB_ID(ISNULL(referenced_database_name, DB_NAME())) ELSE -999 END
	,Referenced_Schema_Id		= SCHEMA_ID(ISNULL(NULLIF(referenced_schema_name, ''''), ''dbo''))
	,Referenced_TableId			= Referenced_id
	,Referenced_Object_Type		= T.type_desc
	,Referenced_Table_name		= Referenced_entity_name

FROM	sys.sql_expression_dependencies	seq
JOIN	sys.objects							T	ON	T.name = seq.referenced_entity_name
LEFT
JOIN	sys.objects							S	ON	S.object_id = referencing_id


INSERT INTO 
	#dependencies 
SELECT	 Referencing_DatabaseId		= DB_ID()
		,Referencing_Object			= TT.name
		,Referencing_Object_Id		= TT.object_id
		,Referencing_Object_Type	= TT.type_desc

		,Referenced_Database_Id		= DB_ID()
		,Referenced_Schema_Id		= ISNULL(st.Schema_id, SCHEMA_ID(''dbo''))
		,Referenced_TableId			= SR.rkeyid
		,Referenced_Object_Type		= ST.type_desc
		,Referenced_Table_name		= ST.name
FROM	sys.sysreferences	sr
JOIN	sys.tables			TT	ON	TT.object_id	= fkeyid
JOIN	sys.tables			st	ON	ST.object_id	= SR.rkeyid

INSERT INTO 
	#dependencies
SELECT	 Referencing_DatabaseId		= DB_ID()
		,Referencing_Object			= S.name
		,Referencing_Object_Id		= S.object_id
		,Referencing_Object_Type	= S.type_desc

		,Referenced_Database_Id		= COALESCE(DB_ID(PARSENAME(S.base_object_name,3)),DB_ID())
		,Referenced_Schema_Id		= COALESCE(SCHEMA_ID(PARSENAME(S.base_object_name,2)),SCHEMA_ID())
		,Referenced_TableId			= CASE WHEN PARSENAME(S.base_object_name,4) IS NULL 
										THEN OBJECT_ID(S.base_object_name) ELSE -1 * object_id(S.name)
									  END
		,Referenced_Object_Type		= CONVERT(NVARCHAR(256), OBJECTPROPERTYEX(OBJECT_ID(S.name), ''BaseType''))
		,Referenced_Table_name		= PARSENAME(S.base_object_name,1)
FROM	SYS.SYNONYMS	S
JOIN	SYS.OBJECTS		O	ON S.object_id = O.object_id
';

DECLARE
     @command				NVARCHAR(MAX)
    ,@replace_character		NCHAR(1) = N'?'
    ,@print_dbname			BIT = 0
    ,@print_command_only	BIT = 0
    ,@suppress_quotename	BIT = 0
    ,@system_only			BIT = NULL
    ,@user_only				BIT = 1
    ,@name_pattern			NVARCHAR(300) = N'%'
    ,@database_list			NVARCHAR(MAX) = NULL
    ,@recovery_model_desc	NVARCHAR(120) = NULL
    ,@compatibility_level	TINYINT = NULL
    ,@state_desc			NVARCHAR(120) = N'ONLINE'
    ,@is_read_only			BIT = 0
    ,@is_auto_close_on		BIT = NULL
    ,@is_auto_shrink_on		BIT = NULL
    ,@is_broker_enabled		BIT = NULL

SET	@command = @SqlCommand
--SET @database_list = 'Assets'

DECLARE
    @sql NVARCHAR(MAX),
    @dblist NVARCHAR(MAX),
    @db NVARCHAR(300),
    @i INT;

IF @database_list > N''
BEGIN
    ;WITH n(n) AS 
    (
        SELECT ROW_NUMBER() OVER (ORDER BY s1.name) - 1
        FROM sys.objects AS s1 
        CROSS JOIN sys.objects AS s2
    )
    SELECT @dblist = REPLACE(REPLACE(REPLACE(x,'</x><x>',','),
    '</x>',''),'<x>','')
    FROM 
    (
        SELECT DISTINCT x = 'N''' + LTRIM(RTRIM(SUBSTRING(
        @database_list, n,
        CHARINDEX(',', @database_list + ',', n) - n))) + ''''
        FROM n WHERE n <= LEN(@database_list)
        AND SUBSTRING(',' + @database_list, n, 1) = ','
        FOR XML PATH('')
    ) AS y(x);
END

IF OBJECT_ID('tempdb..#x') IS NOT NULL
	DROP TABLE #x
CREATE TABLE #x(db NVARCHAR(300));

SET @sql = N'SELECT name FROM sys.databases WHERE 1=1'
    + CASE WHEN @system_only = 1 THEN 
        ' AND database_id IN (1,2,3,4)' 
        ELSE '' END
    + CASE WHEN @user_only = 1 THEN 
        ' AND database_id NOT IN (1,2,3,4)' 
        ELSE '' END
    + CASE WHEN @name_pattern <> N'%' THEN 
        ' AND name LIKE N''%' + REPLACE(@name_pattern, '''', '''''') + '%''' 
        ELSE '' END
    + CASE WHEN @dblist IS NOT NULL THEN 
        ' AND name IN (' + @dblist + ')' 
        ELSE '' END
    + CASE WHEN @recovery_model_desc IS NOT NULL THEN
        ' AND recovery_model_desc = N''' + @recovery_model_desc + ''''
        ELSE '' END
    + CASE WHEN @compatibility_level IS NOT NULL THEN
        ' AND compatibility_level = ' + RTRIM(@compatibility_level)
        ELSE '' END
    + CASE WHEN @state_desc IS NOT NULL THEN
        ' AND state_desc = N''' + @state_desc + ''''
        ELSE '' END
    + CASE WHEN @is_read_only IS NOT NULL THEN
        ' AND is_read_only = ' + RTRIM(@is_read_only)
        ELSE '' END
    + CASE WHEN @is_auto_close_on IS NOT NULL THEN
        ' AND is_auto_close_on = ' + RTRIM(@is_auto_close_on)
        ELSE '' END
    + CASE WHEN @is_auto_shrink_on IS NOT NULL THEN
        ' AND is_auto_shrink_on = ' + RTRIM(@is_auto_shrink_on)
        ELSE '' END
    + CASE WHEN @is_broker_enabled IS NOT NULL THEN
        ' AND is_broker_enabled = ' + RTRIM(@is_broker_enabled)
    ELSE '' END;

    INSERT #x EXEC sp_executesql @sql;

    DECLARE c CURSOR 
        LOCAL FORWARD_ONLY STATIC READ_ONLY
        FOR SELECT CASE WHEN @suppress_quotename = 1 THEN 
                db
            ELSE
                QUOTENAME(db)
            END 
        FROM #x ORDER BY db;

    OPEN c;

    FETCH NEXT FROM c INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
		BEGIN TRY
			SET @sql = REPLACE(@command, @replace_character, @db);

			IF @print_command_only = 1
			BEGIN
				PRINT '/* For ' + @db + ': */'
				+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
				+ @sql 
				+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10);
			END
			ELSE
			BEGIN
				IF @print_dbname = 1
				BEGIN
					PRINT '/* ' + @db + ' */';
				END

				EXEC sp_executesql @sql;
			END
		END TRY
		BEGIN CATCH
			PRINT '-------Error in Running Query on DB:' + @db
			PRINT 'Error Message: ' + ERROR_MESSAGE()
			PRINT 'Error #: '		+ CONVERT(NVARCHAR, ERROR_NUMBER())
			PRINT 'Error Line: '	+ CONVERT(NVARCHAR, ERROR_LINE())
			PRINT 'Error Proc: '	+ ERROR_PROCEDURE()
			PRINT '-------Error in Running Query on DB:' + @db
		END CATCH
        FETCH NEXT FROM c INTO @db;
END

CLOSE c;
DEALLOCATE c;

IF OBJECT_ID('tempdb..#DependencyCount') IS NOT NULL
	DROP TABLE #DependencyCount
SELECT	 DatabaseId = D.Referenced_Database_Id
		,SchemaId   = D.Referenced_Schema_Id
		,TableId	= D.Referenced_TableId
		,TableReferenceCount	= SUM(CASE WHEN D.Referenced_Object_type IN ('USER_TABLE') THEN 1 ELSE 0 END)
		,ProReferenceCount		= SUM(CASE WHEN D.Referenced_Object_type IN ('SQL_STORED_PROCEDURE') THEN 1 ELSE 0 END)
		,OtherReferenceCount	= SUM(CASE WHEN D.Referenced_Object_type NOT IN ('SQL_STORED_PROCEDURE', 'USER_TABLE') THEN 1 ELSE 0 END)
INTO	#DependencyCount
FROM	#dependencies D
GROUP BY
	 D.Referenced_Database_Id
	,D.Referenced_Schema_Id
	,D.Referenced_TableId
ORDER BY
	 D.Referenced_Database_Id
	,D.Referenced_Schema_Id
	,D.Referenced_TableId

IF OBJECT_ID('tempdb..#ResultDetail') IS NOT NULL
	DROP TABLE #ResultDetail
SELECT	 DatabaseName   = DB_NAME(A.DatabaseId)
		,DatabaseId		= A.DatabaseId
		,SchemaName		= A.SchemaName
		,SchemaId		= A.SchemaId
		,TableName		= A.TableName
		,TableId		= A.TableId
		,[RowCount]		= R.[RowCount]
		,TotalSizeInMB  = R.TotalSizeInMB
		,R.create_date
		,R.modify_date
		,IU.ReadCount
		,IU.WriteCount
		,IU.LastReadDate
		,IU.LastWriteDate
		,HasStats		= ISNULL(S.HasStats, 0)
		,S.StatsUpdateDate
		,MI.LastSeekDate
		,TableReferenceCount	= ISNULL(D.TableReferenceCount, 0)
		,ProReferenceCount		= ISNULL(D.ProReferenceCount, 0)
		,OtherReferenceCount	= ISNULL(D.OtherReferenceCount, 0)
INTO	#ResultDetail
FROM	#AllTables A
LEFT
JOIN	#TableRowCount				R	ON	R.DatabaseId	= A.DatabaseId
										AND	R.SchemaId		= A.SchemaId
										AND	R.TableId		= A.TableId
LEFT
JOIN	#index_usage				IU	ON	IU.DatabaseId	= A.DatabaseId
										AND	IU.SchemaId		= A.SchemaId
										AND	IU.TableId		= A.TableId
LEFT
JOIN	#Stats						S	ON	S.DatabaseId	= A.DatabaseId
										AND	S.SchemaId		= A.SchemaId
										AND	S.TableId		= A.TableId
LEFT
JOIN	#TablesMissingIndexes		MI	ON	MI.DatabaseId	= A.DatabaseId
										AND	MI.SchemaId		= A.SchemaId
										AND	MI.TableId		= A.TableId
LEFT
JOIN	#DependencyCount			D	ON	D.DatabaseId	= A.DatabaseId
										AND	D.SchemaId		= A.SchemaId
										AND	D.TableId		= A.TableId
ORDER BY
		DatabaseName, SchemaName, TableName

IF OBJECT_ID('dbo.DataSeedTableUsage') IS NULL
BEGIN
	-- DROP TABLE dbo.DataSeedTableUsage
	CREATE TABLE dbo.DataSeedTableUsage
	(
		 DataSeedTableUsageID	BIGINT			NOT NULL IDENTITY(1, 1)
		,DatabaseName			NVARCHAR(256)	NOT NULL
		,DatabaseId				BIGINT			NOT NULL
		,SchemaName				NVARCHAR(256)	NOT NULL
		,SchemaId				BIGINT			NOT NULL
		,TableName				NVARCHAR(256)	NOT NULL
		,TableId				BIGINT			NOT NULL
		,[RowCount]				BIGINT			NOT NULL
		,TotalSizeInMB			DECIMAL			NULL
		,create_date			DATETIME2		NOT NULL
		,modify_date			DATETIME2		NOT NULL
		,ReadCount				BIGINT			NULL
		,WriteCount				BIGINT			NULL
		,LastReadDate			DATETIME2		NULL
		,LastWriteDate			DATETIME2		NULL
		,HasStats				BIT				NULL
		,StatsUpdateDate		DATETIME2		NULL
		,LastSeekDate			DATETIME2		NULL
		,TableReferenceCount	INT				NULL
		,ProReferenceCount		INT				NULL
		,OtherReferenceCount	INT				NULL
		,ServerRestartDtTm		DATETIME2		NOT NULL
		,RecordCreatedDtTm		DATETIME2		NOT NULL CONSTRAINT DF_DataSeedTableUsage_CreatedDtTm DEFAULT GETDATE()
		,BatchSeqNumber			BIGINT			NOT NULL
	)
	CREATE NONCLUSTERED INDEX [IDX_DB_Schema_Table] ON dbo.DataSeedTableUsage(DatabaseName, SchemaName, TableName)

	CREATE SEQUENCE [dbo].[SQ_DataSeedTableUsage_Batch]  START WITH 10 INCREMENT BY 10
END


DECLARE @ServerStartDtTm DATETIME2
SELECT	@ServerStartDtTm = sqlserver_start_Time FROM sys.dm_os_sys_info;

DECLARE @BatchSeqNum BIGINT
SET @BatchSeqNum = NEXT VALUE FOR [dbo].[SQ_DataSeedTableUsage_Batch]

INSERT INTO
		dbo.DataSeedTableUsage
		(
		 DatabaseName			
		,DatabaseId				
		,SchemaName				
		,SchemaId				
		,TableName				
		,TableId				
		,[RowCount]				
		,TotalSizeInMB			
		,create_date			
		,modify_date			
		,ReadCount				
		,WriteCount				
		,LastReadDate			
		,LastWriteDate			
		,HasStats				
		,StatsUpdateDate		
		,LastSeekDate			
		,TableReferenceCount	
		,ProReferenceCount		
		,OtherReferenceCount	
		,ServerRestartDtTm		
		,BatchSeqNumber
		)
SELECT	 DatabaseName			
		,DatabaseId				
		,SchemaName				
		,SchemaId				
		,TableName				
		,TableId				
		,[RowCount]				
		,TotalSizeInMB			
		,create_date			
		,modify_date			
		,ReadCount				
		,WriteCount				
		,LastReadDate			
		,LastWriteDate			
		,HasStats				
		,StatsUpdateDate		
		,LastSeekDate			
		,TableReferenceCount	
		,ProReferenceCount		
		,OtherReferenceCount	
		,ServerRestartDtTm		=	@ServerStartDtTm
		,BatchSeqNumber			=	@BatchSeqNum
FROM	#ResultDetail		R

SELECT	sqlserver_start_Time, BatchSeqNum = @BatchSeqNum
FROM	sys.dm_os_sys_info;

SELECT	 [DB Name]				= R.DatabaseName   
		,[Schema Name]			= R.SchemaName
		,[Table Name]			= R.SchemaName + '.' + R.TableName
		,[Row Count]			= R.[RowCount]
		,[Table Size (MB)]		= R.TotalSizeInMB
		,[Table Created On**]	= CONVERT(DATE, R.create_date, 101)
		,[Table Modified On**]	= CONVERT(DATE, R.modify_date, 101)
		,[Total Reads*]			= R.ReadCount
		,[Total Writes*]		= R.WriteCount
		,[Last Read Date*]		= CONVERT(DATE, R.LastReadDate, 101)
		,[Last Write Date*]		= CONVERT(DATE, R.LastWriteDate, 101)
		,HasStats				= CASE WHEN R.HasStats = 1 THEN 'Yes' ELSE 'No' END
		,[Stats Updated*]		= CONVERT(DATE, R.StatsUpdateDate, 101)
		,[Missing Index*]		= CONVERT(DATE, R.LastSeekDate, 101)
		,[# of Table References]= TableReferenceCount
		,[# of Proc References] = ProReferenceCount
		,[# of other References]= OtherReferenceCount
FROM	DataSeedTableUsage R
WHERE	BatchSeqNumber			=	@BatchSeqNum
ORDER BY
		R.DatabaseName, R.SchemaName, R.TableName


SELECT	 [DB Name]	=	DatabaseName
		,[SchemaId] =	SchemaName
		,[TableId]	=	SchemaName + '.' + TableName
		,[Used Since 10/01/2017]	= CASE WHEN (LastestDate > DATEADD(mm, -6, GETDATE())) THEN 'Yes' ELSE 'No' END
		,[Last Used Date]		= CONVERT(DATE, LastestDate, 101)
		,[Row Count]			= [RowCount]
		,[Table Size (MB)]		= TotalSizeInMB
		,[# Of References]		= TableReferenceCount + ProReferenceCount + OtherReferenceCount
FROM	#ResultDetail R
CROSS	APPLY
		(
		SELECT LastestDate = MAX(value)
		FROM (
				VALUES(create_date),(modify_date),(LastReadDate),(LastWriteDate),(StatsUpdateDate),(LastSeekDate)
			 )	AS v(value)
		)	MD
ORDER BY
	R.DatabaseName, R.SchemaName, R.TableName

-- Unique list of DBs
SELECT	DISTINCT [DB Name]				= R.DatabaseName   
FROM	#ResultDetail R
ORDER BY
		R.DatabaseName

-- Unique list of DBs NOT used Since last 6 months.
SELECT	DISTINCT [DB Name]				= R.DatabaseName   
FROM	#ResultDetail R
WHERE	R.DatabaseName NOT IN
(
SELECT	DISTINCT DatabaseName
FROM	#ResultDetail
WHERE 
	ISNULL(create_date, '1/1/2000')		> '5/1/2017'
OR ISNULL(modify_date, '1/1/2000')		> '5/1/2017'
OR ISNULL(LastReadDate, '1/1/2000')		> '5/1/2017'
OR ISNULL(LastWriteDate, '1/1/2000')	> '5/1/2017'
OR ISNULL(StatsUpdateDate, '1/1/2000')	> '5/1/2017'
OR ISNULL(LastSeekDate, '1/1/2000')		> '5/1/2017'
)
ORDER BY
		R.DatabaseName

SELECT	*
FROM	#ResultDetail
WHERE	DatabaseName IN (
SELECT	DISTINCT [DB Name]				= R.DatabaseName   
FROM	#ResultDetail R
WHERE	R.DatabaseName NOT IN
(
SELECT	DISTINCT DatabaseName
FROM	#ResultDetail
WHERE 
	ISNULL(create_date, '1/1/2000')		> '5/1/2017'
OR ISNULL(modify_date, '1/1/2000')		> '5/1/2017'
OR ISNULL(LastReadDate, '1/1/2000')		> '5/1/2017'
OR ISNULL(LastWriteDate, '1/1/2000')	> '5/1/2017'
OR ISNULL(StatsUpdateDate, '1/1/2000')	> '5/1/2017'
OR ISNULL(LastSeekDate, '1/1/2000')		> '5/1/2017'
)
)

/*
-- Sanity Checks
SELECT	*
FROM	#AllTables A
WHERE	NOT EXISTS (SELECT 1 FROM #ResultDetail R WHERE R.DatabaseId = A.DatabaseId AND R.SchemaId = A.SchemaId AND R.TableId = A.TableId)

-- Sanity Checks
SELECT	*
FROM	#AllTables A
WHERE	NOT EXISTS (SELECT 1 FROM #TableRowCount R WHERE R.DatabaseId = A.DatabaseId AND R.SchemaId = A.SchemaId AND R.TableId = A.TableId)

SELECT (SELECT count(*) FROM #AllTables) - (SELECT count(*) FROM #TableRowCount )

SELECT SUM(Cnt)
FROM (
	SELECT DatabaseId, Cnt = count(*) FROM #AllTables group by DatabaseId 
	EXCEPT
	SELECT DatabaseId, Cnt = count(*) FROM #TableRowCount group by DatabaseId 
	) F

SELECT	 DB_NAME(DatabaseId)
		,DatabaseId
		,CntAllTables = COUNT(*)
		,CntInTmpTable = SUM(C.Cnt)
		,Delta		  = COUNT(*) - SUM(C.Cnt)
FROM	#AllTables	A
CROSS
APPLY	(
			SELECT	Cnt = count(*)
			FROM	#TableRowCount T
			WHERE	T.DatabaseId	=	A.DatabaseId
			AND		T.SchemaId		=	A.SchemaId
			AND		T.TableId		=	A.TableId
			GROUP BY
					T.DatabaseId 
		) C
GROUP BY
		DatabaseId 

SELECT	*
FROM	#AllTables A
WHERE	DatabaseId = DB_ID('Private')
AND		TableID  = 725577623

SELECT * 
FROM   #TableRowCount
WHERE	TableID  = 725577623

SELECT	*
FROM	#dependencies
WHERE	Referenced_TableId = 62735732

SELECT	*
FROM	#dependencies
WHERE	Referencing_object = 'spDailySalesRepository_CreateDailySalesProductsData'

SELECT	*, DB_NAME(DatabaseId)
FROM	#DependencyCount
WHERE	TableId = 725577623


*/