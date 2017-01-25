IF OBJECT_ID('tempdb..#ServersInQuestion') IS NOT NULL
	DROP TABLE #ServersInQuestion
CREATE TABLE #ServersInQuestion
(
	ServerName VARCHAR(100)
)
INSERT INTO #ServersInQuestion(ServerName)
SELECT ServerName = 'CLSQL76'
UNION ALL SELECT ServerName = 'LAANALYTICS01'
UNION ALL SELECT ServerName = 'LACCDB01'
UNION ALL SELECT ServerName = 'LACCDB02'
UNION ALL SELECT ServerName = 'LACCDB03'
UNION ALL SELECT ServerName = 'LACORPDIST02'
UNION ALL SELECT ServerName = 'LACORPSQL01'
UNION ALL SELECT ServerName = 'LACUBEDATA01'
UNION ALL SELECT ServerName = 'LAFINANCE01'
UNION ALL SELECT ServerName = 'LARESEARCHDB01'
UNION ALL SELECT ServerName = 'LASEARCHDB01'
UNION ALL SELECT ServerName = 'LASQLPRODFLAT01'
UNION ALL SELECT ServerName = 'LASQLPRODFLAT02'
UNION ALL SELECT ServerName = 'LADATAMART01'
UNION ALL SELECT ServerName = 'OCETLPRODSQL01'


--SELECT	*
--FROM	sys.dm_exec_connections SC 
--WHERE	SC.client_net_address != '<local machine>'

SELECT * FROM
(
SELECT	ServerName	= @@SERVERNAME
		,[User/Device] = 'Device'
		,[User Name] = remote_name
		,Device		= name
FROM	sys.linked_logins	sl
JOIN	sys.servers			s	ON s.server_id = sl.server_id
WHERE	S.name IN (SELECT ServerName FROM #ServersInQuestion)
AND		name != @@SERVERNAME

UNION

SELECT DISTINCT 
		 ServerName	= @@SERVERNAME
		,[User/Device] = 'User'
		,[User Name] = login_name
		,Device		= ''
FROM	sys.dm_exec_sessions  SS
WHERE	login_name NOT IN ('sql_replication')
AND		SS.login_name != @@SERVERNAME + '\' + 'sql_replication'

UNION

SELECT DISTINCT 
		 ServerName	= @@SERVERNAME
		,[User/Device] = 'User'
		,[User Name] =	loginname
		,Device		= ''
FROM	sys.syslogins
WHERE	denylogin = 0
AND		hasaccess = 1
AND		name NOT LIKE '%#%'
AND		name NOT LIKE '%NT SERVICE%'
AND		NAME NOT LIKE '%NT AUTHORITY%'
AND		NAME NOT LIKE  '%' + @@SERVERNAME + '%'
) AS L
