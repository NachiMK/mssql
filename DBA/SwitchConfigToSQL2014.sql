USE InData_Config
GO

SELECT  *
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVA3DB-D1'
AND		PackagePath NOT LIKE '%Config%'

UPDATE	SSIS.Configuration
SET		ConfiguredValue = 'NVBIDBD5'
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVA3DB-D1'
AND		PackagePath NOT LIKE '%Config%'


SELECT  *
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVA3DB-D1'
AND		PackagePath NOT LIKE '%Config%'

UPDATE	SSIS.Configuration
SET		ConfiguredValue = 'NVA3DB-D1'
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVBIDBD5'
AND		PackagePath NOT LIKE '%Config%'
