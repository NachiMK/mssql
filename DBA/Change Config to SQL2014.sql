SELECT  *
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVBIDBD5'
and		PackagePath NOT LIKE '%Config%'
and		ConfigurationFilter like 'PTS%'

UPDATE	SSIS.Configuration
SET		ConfiguredValue = 'NVA3DB-D1'
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVBIDBD5'
and		PackagePath NOT LIKE '%Config%'
--and		ConfigurationFilter like 'PTS%'

UPDATE  SSIS.Configuration
SET		ConfiguredValue = 'NVA3DB-D1'
FROM    SSIS.Configuration
WHERE	ConfiguredValue = 'NVBIDBD5'
and		PackagePath LIKE '%Log%'
and		ConfigurationFilter like 'PTS%'
