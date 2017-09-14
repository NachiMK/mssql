USE DBATools
GO
IF OBJECT_ID('dbo.sp_TruncateParentAndChild') IS NOT NULL
	DROP PROCEDURE dbo.sp_TruncateParentAndChild
GO
CREATE PROCEDURE dbo.sp_TruncateParentAndChild
(
	 @DBName			SYSNAME
	,@ParentTableName	SYSNAME
	,@ChildTableList	NVARCHAR(2000)
	,@KeepParentData	BIT		= 0
	,@PrintOnly			BIT		= 1
	,@Debug				BIT		= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE
	--	 @DBName			SYSNAME = 'CartEasy'
	--	,@ParentTableName	SYSNAME	= 'TblAbandonedCart'
	--	,@ChildTableList	SYSNAME	= 'TblAbandonedCartDetails,Tbl1'
	--	,@@KeepParentData	BIT		= 0
	--	,@PrintOnly			BIT		= 1
	--	,@Debug				BIT		= 1


	SET @DBName				= ISNULL(@DBName, '')
	SET @ParentTableName	= ISNULL(@ParentTableName, '')
	SET @ChildTableList		= ISNULL(@ChildTableList, '')
	SET @KeepParentData		= ISNULL(@KeepParentData, 0)

	SET @PrintOnly			= ISNULL(@PrintOnly, 1)
	SET @Debug				= ISNULL(@Debug, 0)

	DECLARE @SQLOutput NVARCHAR(MAX)

	IF @Debug = 1
		SELECT	 DBName				= @DBName
				,ParentTableName	= @ParentTableName
				,ChildTableName		= @ChildTableList
				,KeepParentData		= @KeepParentData
				,PrintOnly			= @PrintOnly
				,Debug				= @Debug

	IF OBJECT_ID('tempdb..#ChildTables') IS NOT NULL
		DROP TABLE #ChildTables
	CREATE TABLE #ChildTables
	(
		ChildTableName	SYSNAME
	)

	DECLARE @SQL NVARCHAR(MAX)
	SELECT @SQL = 'INSERT INTO #ChildTables SELECT ''' + REPLACE(@ChildTableList, ',', ''' INSERT INTO #ChildTables SELECT ''') + ''''

	IF @Debug = 1
	BEGIN
		PRINT '----- Child Table Query ----- '
		PRINT @SQL
		PRINT '----- Child Table Query ----- '
	END
	EXEC(@SQL)
	
	IF @Debug = 1
		SELECT * FROM #ChildTables

	
	DECLARE @SqlCommand	NVARCHAR(MAX) = ''


	SET @SqlCommand = N'
	USE [<@DBName>];

	DECLARE @CreateConstraint NVARCHAR(MAX) = ''''
	SELECT @CreateConstraint += N'' ALTER TABLE '' + QUOTENAME(cs.name) + ''.'' + QUOTENAME(ct.name) 
							+ '' ADD CONSTRAINT '' + QUOTENAME(fk.name) 
							+ '' FOREIGN KEY ('' + STUFF((SELECT '','' + QUOTENAME(c.name)
														-- get all the columns in the constraint table
														FROM	sys.columns				AS	C 
														JOIN	sys.foreign_key_columns	AS	FKC	ON	FKC.parent_column_id = C.column_id
																								AND	FKC.parent_object_id = C.[object_id]
													    WHERE	FKC.constraint_object_id	= fk.[object_id]
														ORDER BY
																FKC.constraint_column_id 
														FOR XML PATH(N''''), TYPE).value(N''.[1]'', N''nvarchar(max)''), 1, 1, N''''
														)
							+ '') REFERENCES '' + QUOTENAME(rs.name) + ''.'' + QUOTENAME(rt.name)
							+ ''('' + STUFF((SELECT '','' + QUOTENAME(c.name)
										   -- get all the referenced columns
											FROM	sys.columns				AS	C 
											JOIN	SYS.FOREIGN_KEY_COLUMNS	AS	FKC	ON	FKC.referenced_column_id = C.column_id
																					AND	FKC.referenced_object_id = C.[object_id]
											WHERE	FKC.constraint_object_id = fk.[object_id]
											ORDER BY
													FKC.constraint_column_id 
											FOR XML PATH(N''''), TYPE).value(N''.[1]'', N''nvarchar(max)''), 1, 1, N''''
										  ) 
							+ '');'' + CHAR(13)
	FROM	sys.foreign_keys		AS FK
	JOIN	sys.tables				AS rt	ON	fk.referenced_object_id	= rt.[object_id]
	JOIN	sys.schemas				AS rs	ON	rt.[schema_id]			= rs.[schema_id]
	JOIN	sys.tables				AS ct	ON	fk.parent_object_id		= ct.[object_id]
	JOIN	sys.schemas				AS cs	ON	ct.[schema_id]			= cs.[schema_id]
	WHERE	rt.is_ms_shipped	= 0
	AND		ct.is_ms_shipped	= 0
	AND		RT.name				= @ParentTableName
	AND		CT.name				IN (SELECT ChildTableName FROM #ChildTables);
	

	IF @Debug = 1
		SELECT	SR.constid, SR.fkeyid, SR.rkeyid, ParentTable = Parent.name, ChildTable = Child.name, ConstraintName = KeyN.name
		FROM	sys.sysreferences	SR
		JOIN	sys.tables			Parent	ON	Parent.object_Id	= SR.rkeyid
		JOIN	sys.tables			Child	ON	Child.Object_Id		= SR.fkeyid
		JOIN	sys.objects			KeyN	ON	KeyN.object_id		= SR.constid
		WHERE	Parent.name	= @ParentTableName
		AND		Child.name	IN (SELECT ChildTableName FROM #ChildTables)

	DECLARE @SqlScript NVARCHAR(MAX) = ''USE [<@DBName>];'' + CHAR(13)
	SELECT	@SqlScript	+= '' TRUNCATE TABLE '' + QUOTENAME(Child.name)  + '';'' + CHAR(13) + 
						   CASE WHEN @KeepParentData = 0 THEN 
								 '' ALTER TABLE '' + QUOTENAME(Child.name) + '' DROP CONSTRAINT '' + QUOTENAME(KeyN.Name) + '';'' + CHAR(13)
						   ELSE 
								'''' 
						   END

	FROM	sys.sysreferences	SR
	JOIN	sys.tables			Parent	ON	Parent.object_Id	= SR.rkeyid
	JOIN	sys.tables			Child	ON	Child.Object_Id		= SR.fkeyid
	JOIN	sys.objects			KeyN	ON	KeyN.object_id		= SR.constid
	WHERE	Parent.name	= @ParentTableName
	AND		Child.name	IN (SELECT ChildTableName FROM #ChildTables)


	IF @KeepParentData = 0
		SET @SqlScript = @SqlScript
					+ '' TRUNCATE TABLE '' + QUOTENAME(@ParentTableName)  + '';'' + CHAR(13)
					+ @CreateConstraint + CHAR(13)



	SET @SQLOutput = @SqlScript
	'

	SET @SqlCommand = REPLACE(@SqlCommand, '<@DBName>', @DBName)
	SET @SqlCommand = REPLACE(@SqlCommand, '@Debug', @Debug)

	IF @Debug = 1
	BEGIN
		PRINT '----- Dynamic TSQL ------------'
		PRINT @SqlCommand
		PRINT '----- Dynamic TSQL  ------------'
	END

	EXEC sp_executesql @sqlCommand, N'@ParentTableName SYSNAME, @KeepParentData BIT, @SQLOutput NVARCHAR(MAX) OUT'
	, @ParentTableName = @ParentTableName
	, @KeepParentData = @KeepParentData
	, @SQLOutput = @SQLOutput OUT

	IF @PrintOnly = 1
	BEGIN
		PRINT '----- Command to Truncate ------------'
		PRINT @SqlOutput
		PRINT '----- Command to Truncate ------------'
	END
	ELSE
		EXEC(@SqlOutput)
	
	IF @Debug = 1 AND (@PrintOnly = 1)
		PRINT 'Command was not Executed because @PrintOnly is set to 1'
END
GO
/*
	-- Testing
	DECLARE
		 @DBName			SYSNAME = 'Products'
		,@ParentTableName	SYSNAME	= 'tblFlashSaleProducts'
		,@ChildTableList	SYSNAME	= 'tblFlashSaleCollectionProductMap,tblFlashSaleProductBulletPoints,tblFlashSaleProductQuantity,tblFlashSaleQuantitySold'

	EXEC dbo.sp_TruncateParentAndChild  @DBName			= @DBName
									   ,@ParentTableName= @ParentTableName
									   ,@ChildTableList	= @ChildTableList
									   ,@KeepParentData	= 0
									   ,@PrintOnly		= 1
									   ,@Debug			= 0
*/

