/*
	Script used to Generated Create Table script based on source table.
*/
USE tempdb
GO
DECLARE	@Author VARCHAR(20)		=	'Nachi'
-- CREATE TABLE SCRIPT
DECLARE @TGTTableSchema VARCHAR(50)	= 'dbo'
DECLARE @TGTTable VARCHAR(50)	= 'StageMaropostUserInfoExport'
DECLARE @TGTTableAndSchema VARCHAR(50)	= @TGTTableSchema + '.' + @TGTTable
DECLARE @SrcTable VARCHAR(50)	= 'dbo.StageMaropostUserInfoExport'
DECLARE @CTSql VARCHAR(MAX) = ''
DECLARE @ColSql VARCHAR(MAX) = ''

DECLARE @TabSpace	REAL		= 4.0
DECLARE @Tab		CHAR	= CHAR(9)
DECLARE @MaxColLength REAL
SELECT @MaxColLength = MAX(LEN(c.name))
FROM	sys.columns AS C
WHERE	C.object_id = object_id(@SrcTable)

SET @CTSql = 'CREATE TABLE ' + @TGTTableAndSchema + '(' + CHAR(13)

SELECT	@ColSql = @ColSql + ',' + c.name + REPLICATE(@Tab, (CEILING(((@MaxColLength - LEN(c.name))/@TabSpace)) + 1) ) + UPPER(CASE WHEN T.name = 'Timestamp' THEN 'VARBINARY(8)' ELSE T.NAME END) 
	+ CASE WHEN T.name IN ('VARCHAR', 'CHAR') THEN '(' + ISNULL(CONVERT(VARCHAR(5), NULLIF(C.max_length, -1)), 'MAX') + ')' 
	WHEN T.name IN ('NVARCHAR') THEN '(' + ISNULL(CONVERT(VARCHAR(5), (NULLIF(C.max_length, -1)/2)), 'MAX') + ')' 
	ELSE '' END
	+ CHAR(9)
	+ CHAR(9)
	+ CASE WHEN C.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END
	+ CHAR(13)
FROM	sys.columns AS C
JOIN	sys.types AS T ON T.system_type_id = C.system_type_id
WHERE	C.object_id = object_id(@SrcTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate', 'RowVersion')
ORDER BY	C.column_id

SET @ColSql = STUFF(@ColSql, 1, 1, ' ')
SET @CTSql = @CTSql + @ColSql + ');' + CHAR(13)
SET @CTSql = @CTSql + 'GO' + CHAR(13)

PRINT '/*==========================================================================
Author:		' + @Author + '
Name:		' + @TGTTableAndSchema + '.table.sql
============================================================================
Date		User			Description
-----------	--------------	------------------------------------------------
' + CONVERT(VARCHAR(15), GETDATE(), 110) + '	' + @Author + '			Created
==========================================================================*/

'
PRINT @CTSql

DECLARE @Col1 VARCHAR(256)
SELECT @Col1 = c.name
FROM	sys.columns AS C
JOIN	sys.types AS T ON T.system_type_id = C.system_type_id
WHERE	C.object_id = object_id(@SrcTable)
AND		c.column_id = 1
ORDER BY	C.column_id


PRINT 'CREATE CLUSTERED INDEX IX_' + REPLACE(@TGTTableAndSchema, '.', '_') + '_' + @Col1 + ' ON ' + @TGTTableAndSchema + '(' + @Col1 + ');'
PRINT 'GO'

PRINT 
'
/*============================================================
TABLE-LEVEL EXTENDED PROPERTIES
============================================================*/'

PRINT
'EXEC sys.sp_addextendedproperty 
@name		= N''ASM360_Description'', 
@value		= N''' + @SrcTable + N' data from PTS'', 
@level0type = N''SCHEMA'', @level0name = '''+@TGTTableSchema+''',
@level1type = N''TABLE'',  @level1name = '''+@TGTTable+''';
GO'

PRINT
'EXEC sys.sp_addextendedproperty 
@name		= N''ASM360_Definition'', 
@value		= N''' + @SrcTable + N' data from PTS, This is RAW unprocessed data and data could be deleted any time'', 
@level0type = N''SCHEMA'', @level0name = '''+@TGTTableSchema+''',
@level1type = N''TABLE'',  @level1name = '''+@TGTTable+''';
GO
'

/*
-- CREATE TABLE SCRIPT
SELECT	c.name 
	, UPPER(T.name)  + CASE WHEN T.name IN ('VARCHAR', 'CHAR', 'NVARCHAR') THEN '(' + CONVERT(VARCHAR(5), C.max_length) + ')' ELSE '' END
	, CASE WHEN C.is_nullable = 1 THEN 'Yes' ELSE 'No' END
FROM	sys.columns AS C
JOIN	sys.types AS T ON T.system_type_id = C.system_type_id
WHERE	C.object_id = object_id('DS.Transcript')
ORDER BY	C.column_id
*/
