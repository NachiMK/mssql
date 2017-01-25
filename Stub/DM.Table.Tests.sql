USE $Database
GO
/*==========================================================================
Author:		$Author
Name:		DM.[$Table].Tests.sql
Purpose:	Script to test DM.$Table ETL changes
============================================================================
Date		User			Description
-----------	--------------	------------------------------------------------
$Date		$Author		Created
==========================================================================*/
-- First Stage Data OR USE SSIS to Stage Data

-- Truncate Switch in case we are using Switch schema
-- TRUNCATE TABLE Switch.$Table
-- TRUNCATE TABLE DM.$Table
-- EXEC DM.ETL_$Table

-- Test

--Simple Counts
-- SELECT	$TableCnt = COUNT(*)
-- FROM	DM.$Table AS DM

--DATA EXISTS as in SOURCE
-- SELECT	*
-- FROM	SOURCE

-- EXCEPT

-- SELECT	*
-- FROM	DM.$Table
