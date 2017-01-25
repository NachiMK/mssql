DECLARE @EndTime DATETIME = DATEADD(hh, 3, GETDATE())
PRINT @EndTime
WHILE (@EndTime > GETDATE())
BEGIN
	IF EXISTS (SELECT * FROM mnTransactionsDW..CubeProcessing_QueryControl WHERE Is_ProcessRequired = 1 AND ISNULL(Process_Status, '') = 'Completed' AND StepDesc = 'Process Measure - Registrations')
	BEGIN
		PRINT 'Sending Email'
		DECLARE @body NVARCHAR(1200) = N'Process Measure - Registrations completed for 02/12/2016 @ ' + CONVERT(VARCHAR, GETDATE(), 101) + ' ' + CONVERT(VARCHAR, GETDATE(), 114)
		EXEC msdb.dbo.sp_send_dbmail
		@recipients =N'nmuthukumar@spark.net,dmartin@spark.net'
		,@body = @body,@body_format ='HTML',@subject = 'Process Measure - Registrations completed by Nachi BOT',@profile_name ='Admin'
		BREAK
	END

	IF @EndTime > '02/12/2016 19:35'
	BEGIN
		PRINT 'Sending Email'
		DECLARE @body1 NVARCHAR(1200) = N'Process Measure - Registrations DID NOT COMPLETE Time @ ' + CONVERT(VARCHAR, GETDATE(), 101) + ' ' + CONVERT(VARCHAR, GETDATE(), 114)
		EXEC msdb.dbo.sp_send_dbmail
		@recipients =N'nmuthukumar@spark.net'
		,@body = @body1,@body_format ='HTML',@subject = 'Process Measure - Registrations DID NOT COMPLETE by Nachi BOT',@profile_name ='Admin'
		BREAK
	END
	ELSE
	BEGIN
		WAITFOR DELAY '00:05:00'

		PRINT '--- IN LOOP --'
		PRINT CONVERT(VARCHAR, GETDATE(), 114)
		PRINT '--- IN LOOP --'
	END

END
PRINT 'ENDED'
PRINT GETDATE()
PRINT @EndTime
