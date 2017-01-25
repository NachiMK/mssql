USE epRenewal
GO

IF OBJECT_ID('tempdb..#TableRowCount') IS NOT NULL
	DROP TABLE #TableRowCount
CREATE TABLE #TableRowCount
(
	TableName	VARCHAR(100)
	,LASQL09Cnt	INT
	,LASQL10Cnt	INT
)

DECLARE @TableName VARCHAR(100)
DECLARE @SQL VARCHAR(4000)

IF OBJECT_ID('tempdb..#Tables') IS NOT NULL
	DROP TABLE #Tables
SELECT	TableName = SS.name + '.[' + ST.name + ']'
INTO	#Tables
FROM	sys.tables	ST
JOIN	sys.schemas	SS	ON	SS.schema_id = ST.schema_id
WHERE	SS.name = 'dbo'
AND		NOT EXISTS (SELECT * FROM sys.columns SC WHERE SC.object_id = ST.object_id AND SC.system_type_id = 241)
AND		EXISTS	(SELECT * FROM LASQL10.epRenewal.sys.tables	TST	WHERE	TST.name	=	ST.name)
--AND		ST.name IN (
--'FrozenRenewalSubscription'
--,'FrozenRenewalSubscriptionDetail'
--,'RenewalSubscription'
--,'RenewalSubscriptionDetail'
--,'RenewalTransaction'
--,'RenewalTransactionDetail')


DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		TableName
FROM		#Tables

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @TableName

WHILE (@@FETCH_STATUS = 0)
BEGIN


	SET @SQL = ''
	SET @SQL = @SQL + 'INSERT INTO #TableRowCount( TableName, LASQL09Cnt, LASQL10Cnt )'
	SET @SQL = @SQL + ' SELECT	TableName	=	''' + @TableName + ''''
	SET @SQL = @SQL + ',LASQL09Cnt	=	(SELECT COUNT(1) FROM ' + @TableName + ' WITH (NOLOCK))'
	SET @SQL = @SQL + ',LASQL10Cnt	=	(SELECT COUNT(1) FROM LASQL10.epRenewal.' + @TableName + ')'
	
	PRINT @SQL
	EXEC(@SQL)

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @TableName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR

IF 1 = 0
-- Only for epRenewal comparison
INSERT INTO #TableRowCount
        ( TableName, LASQL09Cnt, LASQL10Cnt )
VALUES  ( 'dbo.OrderAttributeValue',
          8242275, -- LASQL09Cnt - int
          8242436  -- LASQL10Cnt - int
          )

SELECT *, Delta = ABS(LASQL09Cnt - LASQL10Cnt) FROM #TableRowCount WHERE LASQL09Cnt != LASQL10Cnt

-- 09Cnt = 8242275
-- 10Cnt = 8242436
-- SELECT COUNT(*) FROM dbo.OrderAttributeValue WITH (NOLOCK)

--tablediff -sourceserver LASQL10 -sourcedatabase epRenewal -sourceschema dbo -sourcetable RenewalTransaction -destinationserver LASQL09 -destinationdatabase epRenewal -destinationschema dbo -destinationtable RenewalTransaction -o c:\datafiles\epRenewal\tablediff\RenewalTransactionresults.txt -f c:\datafiles\epRenewal\tablediff\RenewalTransactionscript.sql