DECLARE @transactionsbegin DECIMAL
DECLARE @transactionsend DECIMAL

DECLARE @AtStart BIGINT
DECLARE @AtEnd BIGINT

SET @transactionsbegin= (select cntr_value  FROM sys.dm_os_performance_counters
where counter_name ='Write Transactions/sec' and instance_name ='_Total')

--PRINT 'START DATE TIME:'
--SELECT GETDATE()

SELECT @AtStart = ms_ticks FROM sys.dm_os_sys_info

--Print @timetowait
WAITFOR delay '00:00:02'

SELECT @AtEnd = ms_ticks FROM sys.dm_os_sys_info

--PRINT 'END DATE TIME:'
--SELECT GETDATE()

set @transactionsend= (select cntr_value  FROM sys.dm_os_performance_counters where counter_name ='Write Transactions/sec' and instance_name ='_Total')

--SELECT transactionbegin = @transactionsbegin, transactionend = @transactionsend, AtStart = @AtStart, AtEnd = @AtEnd

SELECT	 TransPerSec		= (@transactionsend - @transactionsbegin) / ((@AtEnd - @AtStart) / 1000.0)
		,StartDate			= (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)
		,DaysUp				= DATEDIFF(dd, (SELECT sqlserver_start_time FROM sys.dm_os_sys_info), GETDATE())
		,TransPer5Sec		= (@transactionsend - @transactionsbegin) / 5.0
		,TimeElapsed		= ((@AtEnd - @AtStart) / 1000.0)
		,TransactionsEnd	= @transactionsend
		,TransactionsBegin	= @transactionsbegin
		,AtStart			= @AtStart
		,AtEnd				= @AtEnd

