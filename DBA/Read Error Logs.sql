EXEC xp_ReadErrorLog 1
--Reads SQL Server error log from ERRORLOG.1 file
 
EXEC xp_ReadErrorLog 0, 1
--Reads current SQL Server error log
 
EXEC xp_ReadErrorLog 0, 2
--Reads current SQL Server Agent error log

EXEC xp_ReadErrorLog 0, 1, N'Error' 
EXEC xp_ReadErrorLog 0, 1, N'Failed'
--Reads current SQL Server error log with text 'Failed'
 
EXEC xp_ReadErrorLog 0, 1, 'Failed', 'Login'
--Reads current SQL Server error log with text ‘Failed’ AND 'Login'
 
EXEC xp_ReadErrorLog 0, 1, 'Failed', 'Login', '20151021', NULL
--Reads current SQL Server error log with text ‘Failed’ AND ‘Login’ from 01-Nov-2012
 
EXEC xp_ReadErrorLog 0, 1, 'Failed', 'Login', '20151021', '20151022'
--Reads current SQL Server error log with text ‘Failed’ AND ‘Login’ between 01-Nov-2012 and 30-Nov-2012
 
EXEC xp_ReadErrorLog 0, 1, NULL, NULL, '20151021', '20151022'
--Reads current SQL Server error between 01-Nov-2012 and 30-Nov-2012
 
EXEC xp_ReadErrorLog 0, 1, NULL, NULL, '20151116', '20151117', 'DESC'
--Reads current SQL Server error log between 01-Nov-2012 and 30-Nov-2012 and sorts in descending order