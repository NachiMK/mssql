-- INDEX USAGE
SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail1.sys.dm_db_index_usage_stats IU
JOIN	mnImail1.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail1.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail1%' 
AND		SO.Name = 'MessageList'

UNION ALL

SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail2.sys.dm_db_index_usage_stats IU
JOIN	mnImail2.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail2.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail2%' 
AND		SO.Name = 'MessageList'

UNION ALL

SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail3.sys.dm_db_index_usage_stats IU
JOIN	mnImail3.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail3.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail3%' 
AND		SO.Name = 'MessageList'
-- ORDER BY i.name, IU.database_id

UNION ALL

SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail4.sys.dm_db_index_usage_stats IU
JOIN	mnImail4.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail4.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail4%' 
AND		SO.Name = 'MessageList'
-- ORDER BY i.name, IU.database_id
UNION ALL

SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail5.sys.dm_db_index_usage_stats IU
JOIN	mnImail5.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail5.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail5%' 
AND		SO.Name = 'MessageList'
--ORDER BY i.name, IU.database_id

UNION ALL

SELECT DB_NAME(database_id), I.Name, *
FROM	mnImail6.sys.dm_db_index_usage_stats IU
JOIN	mnImail6.sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	mnImail6.sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnIMail6%' 
AND		SO.Name = 'MessageList'
ORDER BY i.name, IU.database_id

SELECT DB_NAME(database_id), I.Name, *
FROM	sys.dm_db_index_usage_stats IU
JOIN	sys.objects			SO	ON	SO.object_id = IU.object_id
JOIN	sys.indexes			I	ON	I.index_id = IU.index_id AND I.object_id = IU.object_id
WHERE	DB_NAME(database_id) like 'mnSubscription%' 
AND		SO.Name = 'Promo'
ORDER BY i.name, IU.database_id


SELECT	ST.name, ID.*, IG.*, IGS1.*
FROM	sys.dm_db_missing_index_details			ID
JOIN	sys.dm_db_missing_index_groups			IG	ON	IG.index_handle = ID.index_handle
CROSS	APPLY
		(
			SELECT	TOP 1 IGS.*
			FROM	sys.dm_db_missing_index_group_stats		IGS	
			WHERE	IG.index_group_handle	= IG.index_group_handle
			ORDER BY IGS.avg_user_impact DESC
		) IGS1
JOIN	sys.tables								ST	ON	ST.object_id = ID.object_id
WHERE	1 = 1
AND		DB_NAME(ID.database_id) LIKE 'mnSubscription%'
AND		ST.name	LIKE '%Promo%'


