/*
	CREDIT:
	https://dba.stackexchange.com/questions/40844/after-moving-database-backup-restore-i-have-to-re-add-user

	After Database restore a User is not linked to login
	This query will find such users and give you a list
	of SQL scripts that you can take and apply.
*/

-- FIND ORPHANED USERS
SELECT	 [User_name]	= dp.name
		,[User_type]	= dp.type_desc
		,[login_name]	= ISNULL(sp.name,'Orhphaned!')
		,[Login_type]	= sp.type_desc
		,[Script]		= CASE WHEN SP.name IS NOT NULL THEN
									'USE ' + QUOTENAME(DB_NAME()) + CHAR(13) + 
									'ALTER USER [' + dp.name + '] WITH LOGIN=[' + sp.name + ']'
							ELSE
									'USE ' + QUOTENAME(DB_NAME()) + CHAR(13) + 
									'DROP USER [' + dp.name + ']'
							END
FROM	sys.database_principals	dp
LEFT
JOIN	sys.server_principals	sp	ON	dp.sid	=	sp.sid
WHERE	dp.type IN ('S')
AND		dp.principal_id >4
ORDER BY
		sp.name

