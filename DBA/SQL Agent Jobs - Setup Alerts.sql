USE [msdb]
GO

/****** Object:  Operator [A3 Notify - SQL Agent]    Script Date: 12/17/2014 1:08:44 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'A3 Notify - SQL Agent')
EXEC msdb.dbo.sp_add_operator @name=N'A3 Notify - SQL Agent', 
		@enabled=1, 
		@weekday_pager_start_time=0, 
		@weekday_pager_end_time=235959, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=160000, 
		@sunday_pager_end_time=235959, 
		@pager_days=63, 
		@email_address=N'a3notify.sqlagent@asmnet.com', 
		@category_name=N'[Uncategorized]'
GO

DECLARE @Category VARCHAR(100) = 'ASM A3 BI ETL'
DECLARE @Operator NVARCHAR(100) = N'A3 Notify - SQL Agent'

-- Find jobs & operators
SELECT 
	 J.[name] AS [JobName]
	,job_id
	,J.notify_level_email
	,notify_email_operator_id
	,O.email_address
	,O.enabled
	,SC.name	AS Category
	,HasOperator	=	CASE WHEN O.id IS NOT NULL THEN 'Yes' ELSE 'No' END
FROM	[dbo].[sysjobs] j
JOIN	dbo.syscategories AS SC	ON	SC.category_id = J.category_id
LEFT JOIN [dbo].[sysoperators] o ON (J.[notify_email_operator_id] = o.[id])
WHERE	J.[enabled] = 1
AND		SC.name LIKE @Category
ORDER BY	SC.name, J.name

DECLARE  @job_id UNIQUEIDENTIFIER
		,@JobName VARCHAR(256)
		,@HasOperator VARCHAR(10)
		,@Email_Address VARCHAR(100)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT 
	 J.[name] AS [JobName]
	,job_id
	,HasOperator	=	CASE WHEN O.id IS NOT NULL THEN 'Yes' ELSE 'No' END
	,O.email_address
FROM	[dbo].[sysjobs] j
JOIN	dbo.syscategories AS SC	ON	SC.category_id = J.category_id
LEFT JOIN [dbo].[sysoperators] o ON (J.[notify_email_operator_id] = o.[id])
WHERE	J.[enabled] = 1
AND		SC.name LIKE @Category
ORDER BY	SC.name, J.name

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @JobName, @Job_id, @HasOperator, @Email_Address

WHILE (@@FETCH_STATUS = 0)
BEGIN

	IF (@HasOperator = 'No') OR ((@HasOperator = 'Yes') AND (@Email_Address != @Operator))
	BEGIN
		EXEC msdb.dbo.sp_update_job @job_id=@job_id, 
				@notify_level_email=2, 
				@notify_email_operator_name=@Operator

		PRINT  'Job Name: ' + @JobName + ' with Job ID: ' + CONVERT(VARCHAR(256), @job_id) + ' didnt have A3 notifier as operator. So it was setup.'
	END
	ELSE
		PRINT  'Job Name: ' + @JobName + ' with Job ID: ' + CONVERT(VARCHAR(256), @job_id) + ' already has an operator. NO IT WAS NOT SETUP'

	-- To remove operator from notification   
   	--	EXEC msdb.dbo.sp_update_job @job_id=@job_id, 
				--@notify_email_operator_name=''

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @JobName, @Job_id, @HasOperator, @Email_Address
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR

-- AFTER UPDATE RESULTS
SELECT 
	 J.[name] AS [JobName]
	,job_id
	,J.notify_level_email
	,notify_email_operator_id
	,O.email_address
	,O.enabled
	,SC.name	AS Category
	,HasOperator	=	CASE WHEN O.id IS NOT NULL THEN 'Yes' ELSE 'No' END
FROM	[dbo].[sysjobs] j
JOIN	dbo.syscategories AS SC	ON	SC.category_id = J.category_id
LEFT JOIN [dbo].[sysoperators] o ON (J.[notify_email_operator_id] = o.[id])
WHERE	J.[enabled] = 1
AND		SC.name LIKE @Category
ORDER BY	SC.name, J.name

GO
