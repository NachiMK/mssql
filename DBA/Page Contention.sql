/*
	Purpose of query is to find page contention and sessions
	linked to those contentions

	It is right now limited to just TEMPDB, change the DB_ID for other databases
*/

SELECT  session_id ,
        wait_type ,
        wait_duration_ms ,
        blocking_session_id ,
        resource_description ,
        ResourceType = CASE WHEN CAST(RIGHT(resource_description,
                                            LEN(resource_description)
                                            - CHARINDEX(':',
                                                        resource_description,
                                                        3)) AS INT) - 1 % 8088 = 0
                            THEN 'Is PFS Page'
                            WHEN CAST(RIGHT(resource_description,
                                            LEN(resource_description)
                                            - CHARINDEX(':',
                                                        resource_description,
                                                        3)) AS INT) - 2
                                 % 511232 = 0 THEN 'Is GAM Page'
                            WHEN CAST(RIGHT(resource_description,
                                            LEN(resource_description)
                                            - CHARINDEX(':',
                                                        resource_description,
                                                        3)) AS INT) - 3
                                 % 511232 = 0 THEN 'Is SGAM Page'
                            ELSE 'Is Not PFS, GAM, or SGAM page'
                       END
FROM    sys.dm_os_waiting_tasks
WHERE   wait_type LIKE 'PAGE%LATCH_%'
        AND resource_description LIKE '2:%'



SELECT  session_id ,
        wait_type ,
        wait_duration_ms ,
        blocking_session_id ,
        resource_description ,
        Descr.*
FROM    sys.dm_os_waiting_tasks AS waits
        INNER JOIN sys.dm_os_buffer_descriptors AS Descr ON LEFT(waits.resource_description,
                                                              CHARINDEX(':',
                                                              waits.resource_description,
                                                              0) - 1) = Descr.database_id
                                                            AND SUBSTRING(waits.resource_description,
                                                              CHARINDEX(':',
                                                              waits.resource_description)
                                                              + 1,
                                                              CHARINDEX(':',
                                                              waits.resource_description,
                                                              CHARINDEX(':',
                                                              resource_description)
                                                              + 1)
                                                              - ( CHARINDEX(':',
                                                              resource_description)
                                                              + 1 )) = Descr.[file_id]
                                                            AND RIGHT(waits.resource_description,
                                                              LEN(waits.resource_description)
                                                              - CHARINDEX(':',
                                                              waits.resource_description,
                                                              3)) = Descr.[page_id]
WHERE   wait_type LIKE 'PAGE%LATCH_%'