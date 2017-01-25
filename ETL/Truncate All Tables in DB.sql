/*
	Loop through tables and truncate
*/
SELECT	'TRUNCATE TABLE '+ S.name + '.' + T.name
FROM	sys.tables AS T
JOIN	sys.schemas AS S ON S.schema_id = T.schema_id
WHERE	s.name != 'A3'
ORDER BY s.name, t.name

