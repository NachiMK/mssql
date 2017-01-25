SELECT		SchemaName = S.name, TableName = T2.name, ColumnName = c.name, DataType = T.name, ColumnLength = c.max_length, C.is_nullable, c.is_identity, DefaultConstName = DC.name, DC.definition
FROM		sys.columns AS C
JOIN		sys.tables AS T2				ON T2.object_id = C.object_id
JOIN		sys.schemas AS S				ON S.schema_id = T2.schema_id
JOIN		sys.types AS T					ON T.user_type_id = C.user_type_id
LEFT JOIN	sys.default_constraints AS DC	ON DC.parent_object_id = c.object_id	AND DC.parent_column_id = C.column_id
WHERE		1 = 1
--AND			T2.name LIKE '%Quest%'
AND			T2.name LIKE 'Question'
AND			S.name = 'DS'
--AND		C.name = 'Question'
ORDER BY	T2.name, C.column_id

