/*
	Find Queries that use a specific Index
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
DECLARE @IndexName AS NVARCHAR(128) = 'ix_BulkMailSchedule_NextAttemptDate_LastLogonDate_SelectID_incl';

-- Make sure the name passed is appropriately quoted 
IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']') SET @IndexName = QUOTENAME(@IndexName); 
--Handle the case where the left or right was quoted manually but not the opposite side 
IF LEFT(@IndexName, 1) <> '[' SET @IndexName = '['+@IndexName; 
IF RIGHT(@IndexName, 1) <> ']' SET @IndexName = @IndexName + ']';

--Dig into the plan cache and find all plans using this index 
;WITH XMLNAMESPACES 
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')    
SELECT 
stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text, 
obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName, 
obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName, 
obj.value('(@Table)[1]', 'varchar(128)') AS TableName, 
obj.value('(@Index)[1]', 'varchar(128)') AS IndexName, 
obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind, 
cp.plan_handle, 
query_plan 
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj) 
--WHERE obj.value('(@Database)[1]', 'varchar(128)') = 'mnAlert'
OPTION(MAXDOP 1, RECOMPILE);
