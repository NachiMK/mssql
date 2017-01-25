/*
	Script used to Generated SELECT script based on source table.
*/
USE RW5
GO
DECLARE @TabSpace	REAL		= 4.0
DECLARE @Tab		CHAR	= CHAR(9)
DECLARE @MaxColLength REAL

DECLARE @SrcTable VARCHAR(50)	= 'dbo.Address'
DECLARE @CTSql VARCHAR(MAX) = ''
DECLARE @ColSql VARCHAR(MAX) = ''
SET @CTSql = 'SELECT ' + CHAR(13)

SELECT @MaxColLength = MAX(LEN(c.name))
FROM	sys.columns AS C
WHERE	C.object_id = object_id(@SrcTable)


--SELECT	c.NAME, REPLICATE(@Tab, ((@MaxColLength - LEN(c.name))/@TabSpace)), @MaxColLength, LEN(c.name), (@MaxColLength - LEN(c.name)), (@MaxColLength - LEN(c.name))/@TabSpace
--, [Ceiling] = CEILING(ISNULL(NULLIF(((@MaxColLength - LEN(c.name))/@TabSpace), 0), 1))
--FROM	sys.columns AS C
--WHERE	C.object_id = object_id(@SrcTable)
--ORDER BY	C.column_id


SELECT	@ColSql = @ColSql + ',' + c.name + REPLICATE(@Tab, (CEILING(((@MaxColLength - LEN(c.name))/@TabSpace)) + 1) ) + '=' + ' ' + c.name + CHAR(13)
FROM	sys.columns AS C
WHERE	C.object_id = object_id(@SrcTable)
ORDER BY	C.column_id

SET @ColSql = STUFF(@ColSql, 1, 1, ' ')
SET @CTSql = @CTSql + @ColSql + ';' + CHAR(13)


PRINT @CTSql

