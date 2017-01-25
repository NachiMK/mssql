/*
	Purpose: Find all tables that have change tracking enabled and internal table name
	that has the changes for the source table
*/
SELECT	SchemaName = SS.name, TableName = ST.name, SIT.name
FROM	sys.tables ST 
JOIN	sys.schemas	SS			ON	SS.schema_id = ST.schema_id
JOIN	sys.internal_tables	SIT ON	SIT.[internal_type_desc] = 'CHANGE_TRACKING'
								AND	REPLACE(SIT.[name], 'change_tracking_', '')  = ST.object_id

SELECT * FROM sys.change_tracking_tables


SELECT SCHEMA_NAME(itab.schema_id) AS schema_name
    ,itab.name AS internal_table_name
    ,typ.name AS column_data_type 
    ,col.*
FROM sys.internal_tables AS itab
JOIN sys.columns AS col ON itab.object_id = col.object_id
JOIN sys.types AS typ ON typ.user_type_id = col.user_type_id
ORDER BY itab.name, col.column_id

