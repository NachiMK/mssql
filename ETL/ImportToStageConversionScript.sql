-- Conversion Script
IF OBJECT_ID('tempdb..#TblConvertLookup') IS NOT NULL 
	DROP TABLE #TblConvertLookup
CREATE TABLE #TblConvertLookup
(
	DataType		VARCHAR(100)	NOT NULL
,	ConvertFuncName	VARCHAR(200)	NOT NULL
)
INSERT INTO #TblConvertLookup(DataType,ConvertFuncName)
SELECT	 DataType = T.name
		,ConvertFuncName = CASE 
								WHEN T.name LIKE '%char%' THEN 'DS.ConvertToString'
								ELSE 'DS.ConvertTo' + UPPER(LEFT(T.name, 1)) + RIGHT(T.NAME, LEN(T.NAME) - 1)
							END
FROM	sys.types AS T 
WHERE	NAME NOT IN ('IMAGE', 'SQL_VARIANT', 'TIMESTAMP', 'BINARY', 'XML', 'SYSNAME', 'GEOMETRY', 'GEOGRAPHY', 'VARBINARY', 'HIREARCHYID', 'NTEXT', 'UNIQUEIDENTIFIER', 'DATETIMEOFFSET')
AND		is_assembly_type = 0
AND		EXISTS (SELECT * FROM sys.objects SO WHERE SO.type = 'FN' AND ((SO.name LIKE '%' + T.name + '%') OR (SO.name LIKE '%String%' AND T.name LIKE '%CHAR%')))

SELECT * FROM #TblConvertLookup AS TCL
