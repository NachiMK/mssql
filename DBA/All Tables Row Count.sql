

IF OBJECT_ID('tempdb..#RowCntAllTables') IS NOT NULL
    DROP TABLE #RowCntAllTables
CREATE TABLE #RowCntAllTables
(
    name sysname
    ,rows bigint
    ,reserved sysname
    ,data sysname
    ,index_size sysname
    ,unused sysname
)

IF OBJECT_ID('tempdb..#Tables') IS NOT NULL
    DROP TABLE #Tables
SELECT name into #Tables FROM sys.tables
DECLARE @Tablename SYSNAME

WHILE EXISTS (SELECT 1 FROM #Tables)
BEGIN
    SET @TableName = (SELECT TOP 1 name FROM #Tables)
    INSERT INTO #RowCntAllTables
    EXEC sp_spaceused @Tablename

    DELETE #Tables WHERE name = @Tablename
END

SELECT * FROM #RowCntAllTables 
--where rows != 0 
order by name
