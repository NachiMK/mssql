USE $Database
GO
/*==========================================================================
Author:		$Author
Name:		KS.[$Table].Tests.sql
Purpose:	Script to test KS.$Table ETL changes
============================================================================
Date		User			Description
-----------	--------------	------------------------------------------------
$Date		$Author			Created
==========================================================================*/

-- First Stage Data OR USE SSIS to Stage Data

-- Truncate Switch in case we are using Switch schema
-- TRUNCATE TABLE KS.$Table
-- EXEC KS.ETL_$Table

-- Test

--Simple Counts
-- SELECT	$TableCnt = COUNT(*)
-- FROM	KS.$Table AS KS

--DATA EXISTS as in SOURCE
-- SELECT	KeyColumn_PK
-- FROM	SOURCE

-- EXCEPT

-- SELECT	KeyColumn_PK
-- FROM	KS.$Table
