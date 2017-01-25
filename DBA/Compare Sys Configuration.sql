/*
	Get Cnofiguration from OLD server
*/
IF OBJECT_ID('tempdb..#OLD') IS NOT NULL
	DROP TABLE #OLD
SELECT * INTO #OLD FROM sys.configurations ORDER BY name

IF OBJECT_ID('tempdb..#New') IS NOT NULL
	DROP TABLE #New
SELECT * INTO #New FROM CLSQL43New.msdb.sys.configurations ORDER BY Name

-- Config in both servers but different Values
SELECT Comment = 'Different Config Value', O.name, O.Configuration_id, OLDValue = O.value, NewValue = N.value
FROM	#OLD	AS O
JOIN #New	AS N ON N.name = O.name
				AND N.value != O.value
UNION

-- ONLY IN OLD SERVER
SELECT Comment = 'Missing in New Server ', O.name, O.Configuration_id, OLDValue = O.value, NewValue = NULL
FROM	#OLD	AS O
WHERE NOT EXISTS (SELECT * FROM #New	AS N WHERE N.name = O.name)

UNION

-- ONLY IN NEW SERVER
SELECT Comment = 'Missing in OLD Server ', N.name, N.Configuration_id, OLDValue = NULL, NewValue = N.value
FROM	#New	AS N
WHERE NOT EXISTS (SELECT * FROM #OLD	AS O WHERE N.name = O.name)


--SELECT * FROM sys.servers
--SELECT * FROM sys.linked_logins
--SELECT * FROM sys.assemblies
--SELECT * FROM sys.assembly_files
--SELECT * FROM sys.server_permissions

