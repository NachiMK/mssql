--EXEC dbo.up_LPD_List @LogicalDatabaseName = 'mnIMailNew'

--sqlcmd -S LASQL01 -i "C:\Deployments\09222015\TEST.sql" -o "C:\Deployments\09222015\TestOutput.txt"
DECLARE @SQLProcPath VARCHAR(1000)		=	'N:\Users\nmuthukumar.MATCHNET\Documents\Projects\Deployment\02-03-2016\DATA-699\'
DECLARE @SQLOutputFilePath VARCHAR(500)	=	'N:\Users\nmuthukumar.MATCHNET\Documents\Projects\Deployment\02-03-2016\DATA-699\Output.txt'
-- DECLARE @SQLProcToApply VARCHAR(200)	=	'dbo.up_Mail_Conversation_Inbox_Member_List.proc.sql'
-- DECLARE @SQLProcToApply VARCHAR(200)	=	'dbo.up_Mail_Conversation_Inbox_Message_List.sql'
DECLARE @SQLProcToApply VARCHAR(200)	=	'up_List_Save.sql'

DECLARE @SPName VARCHAR(100) = 'up_List_Save'

-- up_Mail_Conversation_Draft_Member_List
--up_Mail_Conversation_Inbox_Member_List
--up_Mail_Conversation_Sent_Member_List
--up_Mail_Conversation_Trash_Member_List


--DECLARE @SQLStoredProcFolder VARCHAR(1000)	=	'C:\Deployments\09222015\DATA-288'
/*
	Purpose: To Find the Logical Physical Database mapping and what servers the databases are on.
*/
SELECT	LD.LogicalDatabaseName
		,PD.ServerName
		,PD.PhysicalDatabaseName
		--,SQLCmdUtility = 'for %%a in ("' + @SQLStoredProcFolder + '\*.sql") do SQLCMD -S ' + PD.ServerName + ' -d ' + PD.PhysicalDatabaseName + ' -E -i "%%a" >> "' + @SQLStoredProcFolder + '\output.txt"'
		,TestDeploy = 'SELECT * FROM ' + PD.ServerName + '.' + PD.PhysicalDatabaseName + '.sys.procedures WHERE name IN ('''+ @SPName + ''')'
		,SQLCmdUtility = 'sqlcmd -S ' + PD.ServerName + + ' -d ' + PD.PhysicalDatabaseName + ' -E -i "' + @SQLProcPath + @SQLProcToApply + '" >> "' + @SQLOutputFilePath + '"'
FROM	mnSystem.dbo.LogicalDatabase			AS LD	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.HydraMode					AS HM	WITH (READUNCOMMITTED)	ON	HM.HydraModeID = LD.HydraModeID
JOIN	mnSystem.dbo.LogicalPhysicalDatabase	AS LPD	WITH (READUNCOMMITTED)	ON	LPD.LogicalDatabaseID = LD.LogicalDatabaseID
JOIN	mnSystem.dbo.PhysicalDatabase			AS PD	WITH (READUNCOMMITTED)	ON	PD.PhysicalDatabaseID = LPD.PhysicalDatabaseID
WHERE	1 = 1
AND		LD.LogicalDatabaseName LIKE 'mnMember'
--AND		LD.LogicalDatabaseName LIKE 'mnMember'
--AND		ActiveFlag = 1
ORDER BY	LD.LogicalDatabaseID, PD.ServerName, LPD.PhysicalDatabaseID


