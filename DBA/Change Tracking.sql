/*
	Find out about Change Tracking

	URL where code was taken from: http://www.brentozar.com/archive/2014/06/performance-tuning-sql-server-change-tracking/
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

-- CHECK IF Change Tracking is Enabled
SELECT	db.name AS change_tracking_db
	   ,is_auto_cleanup_on
	   ,retention_period
	   ,retention_period_units_desc
FROM	sys.change_tracking_databases	ct
JOIN	sys.databases					db	ON ct.database_id = db.database_id;


-- Find Tables that have Change Tracking enabled
SELECT	sc.name AS tracked_schema_name
	   ,so.name AS tracked_table_name
	   ,ctt.is_track_columns_updated_on
	   ,ctt.begin_version /*when CT was enabled, or table was truncated */
	   ,ctt.min_valid_version /*syncing applications should only expect data on or after this version */
	   ,ctt.cleanup_version /*cleanup may have removed data up to this version */
FROM	sys.change_tracking_tables		ctt
JOIN	sys.objects						so	ON	ctt.[object_id]	= so.[object_id]
JOIN	sys.schemas						sc	ON	so.schema_id	= sc.schema_id;

-- Find Size of change tracking tales
-- This query will show you all the internal tables with their size and rowcount:
SELECT	sct1.name AS CT_schema
	   ,sot1.name AS CT_table
	   ,ps1.row_count AS CT_rows
	   ,ps1.reserved_page_count * 8. / 1024. AS CT_reserved_MB
	   ,sct2.name AS tracked_schema
	   ,sot2.name AS tracked_name
	   ,ps2.row_count AS tracked_rows
	   ,ps2.reserved_page_count * 8. / 1024. AS tracked_base_table_MB
	   ,change_tracking_min_valid_version(sot2.object_id) AS min_valid_version
FROM	sys.internal_tables			it
JOIN	sys.objects					sot1	ON	it.object_id		= sot1.object_id
JOIN	sys.schemas					sct1	ON	sot1.schema_id		= sct1.schema_id
JOIN	sys.dm_db_partition_stats	ps1		ON	it.object_id		= ps1.object_id
											AND	ps1.index_id IN (0, 1)
LEFT JOIN sys.objects				sot2	ON	it.parent_object_id	= sot2.object_id
LEFT JOIN sys.schemas				sct2	ON	sot2.schema_id		= sct2.schema_id
LEFT JOIN sys.dm_db_partition_stats	ps2		ON	sot2.object_id		= ps2.object_id
										   AND	ps2.index_id IN (0, 1)
WHERE	it.internal_type IN (209, 210);


/*

-- undocumented SP to cleanup change tracking. It is undocumented so test carefully and use it at your own risk. 

exec sp_helptext 'sys.sp_flush_commit_table_on_demand';

-- Querying Change Tracking tables for changes

SELECT	p.FirstName
	   ,p.MiddleName
	   ,p.LastName
	   ,c.SYS_CHANGE_VERSION
	   ,CHANGE_TRACKING_CURRENT_VERSION() AS current_version
FROM	Person.Person AS p
JOIN	CHANGETABLE(CHANGES Person.Person, 2) AS c ON p.BusinessEntityID = c.BusinessEntityID;
GO

*/

