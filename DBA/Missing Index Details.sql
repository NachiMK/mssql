USE mnRegFlow
GO
SELECT OBJECT_NAME(object_id), * 
FROM	sys.dm_db_missing_index_details MI 
WHERE	DB_NAME(MI.database_id) = 'mnIMail6' 

SELECT OBJECT_NAME(MI.object_id), DB_NAME(MI.database_id), * 
FROM	sys.dm_db_missing_index_details MI 
JOIN	sys.objects			SO	ON	SO.object_id = MI.object_id
WHERE	DB_NAME(MI.database_id) = 'mnRegFlow' 
AND		SO.Name = 'MessageList'

SELECT * FROM sys.dm_db_missing_index_details WHERE DB_NAME(database_id) = 'mnRegFlow' 

SELECT * FROM sys.dm_db_missing_index_details WHERE DB_NAME(database_id) = 'epOrder' AND OBJECT_NAME(object_id) = 'RenewalTransaction'

SELECT * FROM sys.dm_db_missing_index_details WHERE OBJECT_NAME(object_id) = 'RegTrackingHeader'


