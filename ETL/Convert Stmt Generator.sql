-- CONVERT SCRIPT
SELECT	c.name + CHAR(9) + CHAR(9) + CHAR(9) + '= CONVERT(' + UPPER(T.name) + CASE WHEN T.name IN ('VARCHAR', 'CHAR', 'NVARCHAR', 'VARBINARY') THEN '(' + CONVERT(VARCHAR(5), C.max_length) + ')' ELSE '' END + ', ' + c.name + ')'
FROM	sys.columns AS C
JOIN	sys.types AS T ON T.system_type_id = C.system_type_id
WHERE	C.object_id = object_id('ARCH.RW5_Employee')
ORDER BY	C.column_id
