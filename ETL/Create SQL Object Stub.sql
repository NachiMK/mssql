IF OBJECT_ID('tempdb..#Tables') IS NOT NULL 
	DROP TABLE #Tables
CREATE TABLE #Tables
(
	TableName VARCHAR(200) NOT NULL PRIMARY KEY
)
INSERT INTO #Tables(TableName) SELECT 'AnswerOption' 
INSERT INTO #Tables(TableName) SELECT 'Assignment' 
INSERT INTO #Tables(TableName) SELECT 'AssignmentStatus' 
INSERT INTO #Tables(TableName) SELECT 'Category' 
INSERT INTO #Tables(TableName) SELECT 'ComplianceCategory' 
INSERT INTO #Tables(TableName) SELECT 'District' 
INSERT INTO #Tables(TableName) SELECT 'Employee' 
INSERT INTO #Tables(TableName) SELECT 'GridRow' 
INSERT INTO #Tables(TableName) SELECT 'JOB' 
INSERT INTO #Tables(TableName) SELECT 'JobQuestion' 
INSERT INTO #Tables(TableName) SELECT 'KeyMetric' 
INSERT INTO #Tables(TableName) SELECT 'KeyMetricRule' 
INSERT INTO #Tables(TableName) SELECT 'KeyMetricValue' 
INSERT INTO #Tables(TableName) SELECT 'Location' 
INSERT INTO #Tables(TableName) SELECT 'Material' 
INSERT INTO #Tables(TableName) SELECT 'Product' 
INSERT INTO #Tables(TableName) SELECT 'Question' 
INSERT INTO #Tables(TableName) SELECT 'QuestionType' 
INSERT INTO #Tables(TableName) SELECT 'StoreJobStatus' 

-- SCHEMAS/Scripts for each schemas
IF OBJECT_ID('tempdb..#SchemaScript') IS NOT NULL 
	DROP TABLE #SchemaScript
CREATE TABLE #SchemaScript
(
	 SchemaName		VARCHAR(100)	NOT NULL
	,FileType		VARCHAR(100)	NOT NULL
	,TemplateName	VARCHAR(500)	NOT NULL
	,TargetFolder	VARCHAR(100)	NOT NULL
)

INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'DM', 'table.sql', 'DM.Table.table.sql', 'DM'
INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'DM', 'Tests.sql', 'DM.Table.Tests.sql', 'Tests'
INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'KS', 'table.sql', 'KS.Table.table.sql', 'KS'
INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'KS', 'Tests.sql', 'KS.Table.Tests.sql', 'Tests'
INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'Stage', 'table.sql', 'Stage.Table.table.sql', 'Stage'
INSERT INTO #SchemaScript(SchemaName,FileType,TemplateName, TargetFolder) SELECT 'Stage', 'Tests.sql', 'Stage.Table.Tests.sql', 'Tests'


DECLARE	@TemplatePath	VARCHAR(100)	=	'"C:\Users\nachi.muthukumar\Documents\SQL Server Management Studio\Projects\Generic-Useful\Stub\"'
DECLARE	@TargetPath		VARCHAR(100)	=	'C:\Users\nachi.muthukumar\Projects\A3 Solutions\Dev\A3 SQL14 Database\Epson\Temp\'

;WITH CTE_CmdLineInput
AS
(
	SELECT	TableName, SqlObjecFileName = SchemaName + '.' + TableName + '.' + FileType, TemplateName, TargetFolder
	FROM	#Tables AS T
	CROSS JOIN #SchemaScript AS SS
)
SELECT	TableName
		,SqlObjecFileName
		,TemplateName
		,CmdLine			=	'COPY ' + @TemplatePath + TemplateName + ' "' + @TargetPath + TargetFolder + '\' + SqlObjecFileName +  '"'
FROM	CTE_CmdLineInput
