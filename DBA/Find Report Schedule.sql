USE ReportServer
GO


SELECT	'EXEC ReportServer.dbo.AddEvent @EventType=''TimedSubscription'', @EventData='''
		+ CAST(a.SubscriptionID AS VARCHAR(40)) + '''' AS ReportCommand
	   ,b.name AS JobName
	   ,a.SubscriptionID
	   ,a.ReportAction
	   ,e.Name
	   ,e.Path
	   ,d.Description
	   ,LastStatus
	   ,EventType
	   ,LastRunTime
	   ,date_created
	   ,date_modified
FROM	ReportServer.dbo.ReportSchedule a
INNER
JOIN	msdb.dbo.sysjobs b ON a.ScheduleID = b.name
INNER
JOIN	ReportServer.dbo.ReportSchedule c ON b.name = c.ScheduleID
INNER
JOIN	ReportServer.dbo.Subscriptions d ON c.SubscriptionID = d.SubscriptionID
INNER
JOIN	ReportServer.dbo.Catalog e ON d.Report_OID = e.ItemID
WHERE	1 = 1
AND		b.name != 'syspolicy_purge_history'
		AND		(
						ExtensionSettings LIKE '%Admin Suspensions%'
				OR		ExtensionSettings LIKE '%Closed Sub Fraud Records Unupdated in BH Production%'
				OR		ExtensionSettings LIKE '%Missing CRX ResponseID%'
				)

