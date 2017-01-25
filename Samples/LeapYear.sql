--select 2012.0/4.0, 2012 % 4, 2012 % 100, 2012 % 400

DECLARE @Year INT = 9996
IF (
		(((@Year % 4) = 0) AND ((@Year % 100) != 0))
	OR (((@Year % 4) = 0)  AND ((@Year  % 100) = 0)  AND ((@Year % 400) = 0))
	)
	PRINT 'Leap'
ELSE 
	PRINT 'NO'