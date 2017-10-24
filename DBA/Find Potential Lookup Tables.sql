USE DBATools
GO

IF OBJECT_ID('tempdb..#PotentialLookupTables') IS NOT NULL
	DROP TABLE #PotentialLookupTables
CREATE TABLE #PotentialLookupTables
(
	  DatabaseName	SYSNAME
	 ,SchemaName	SYSNAME
	 ,TableName		SYSNAME	
	 ,ColumnName	SYSNAME
	 ,FKColName		SYSNAME
)

IF OBJECT_ID('tempdb..#PotentialLookupMatches') IS NOT NULL
	DROP TABLE #PotentialLookupMatches
CREATE TABLE #PotentialLookupMatches
(
	  DatabaseName	SYSNAME
	 ,SchemaName	SYSNAME
	 ,TableName		SYSNAME	
	 ,ColumnName	SYSNAME
	 ,LookupTable	SYSNAME	
	 ,FKColName		SYSNAME
	 ,LookupCol		SYSNAME
)



DECLARE @LookupTblSQL NVARCHAR(MAX)
SET @LookupTblSQL = 
N'
USE ?

INSERT INTO
		#PotentialLookupTables
SELECT	 DatabaseName = DB_NAME()
		,SchemaName	=	SCHEMA_NAME(T.schema_id)
		,TableName	=	OBJECT_NAME(ic.OBJECT_ID)
        ,ColumnName	=	COL_NAME(ic.OBJECT_ID,ic.column_id)
		,FKColName	=	REPLACE(OBJECT_NAME(ic.OBJECT_ID), ''tbl'', '''') + COL_NAME(ic.OBJECT_ID,ic.column_id)
FROM    sys.indexes			AS	i
JOIN	sys.index_columns	AS	ic	ON	i.OBJECT_ID = ic.OBJECT_ID
									AND	i.index_id	= ic.index_id
JOIN	sys.tables			AS	T	ON	T.object_id	= i.object_id
WHERE   i.is_primary_key = 1
AND		COL_NAME(ic.OBJECT_ID,ic.column_id) = ''Id''

INSERT INTO
	#PotentialLookupMatches
SELECT	 DatabaseName
		,SchemaName		= L.SchemaName
		,TableName		= T.name
		,ColName		= C.Name
		,LookupTable	=	L.TableName
		,L.FKColName
		,LookupCol		=	L.ColumnName
FROM	sys.tables	T
JOIN	sys.columns	C	ON	C.object_id = T.object_id
JOIN	#PotentialLookupTables L	ON	L.TableName != T.Name
								AND		L.SchemaName = SCHEMA_NAME(T.Schema_Id)
								AND		L.FKColName	= C.name
ORDER	BY
		DatabaseName, LookupTable, FKColName, TableName, ColName
'

EXEC master..sp_foreachdb @command = @LookupTblSQL, @user_only = 1


SELECT	*
FROM	#PotentialLookupMatches
Order	BY
		DatabaseName, LookupTable, FKColName, TableName, ColumnName
