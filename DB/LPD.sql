/*
	Purpose: To Find the Logical Physical Database mapping and what servers the databases are on.
*/
SELECT	LD.LogicalDatabaseName
		,PD.ServerName
		,PD.PhysicalDatabaseName
		,PD.ActiveFlag
		,PD.MaintenanceTypeMask
		,HM.HydraModeID
		,LD.HydraThreads
		,LD.HydraFailureThreshold
		,LPD.Offset
		,LD.LogicalDatabaseID
		,PD.PhysicalDatabaseID
		,LPD.LogicalPhysicalDatabaseID
FROM	mnSystem.dbo.LogicalDatabase			AS LD	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.HydraMode					AS HM	WITH (READUNCOMMITTED)	ON	HM.HydraModeID = LD.HydraModeID
JOIN	mnSystem.dbo.LogicalPhysicalDatabase	AS LPD	WITH (READUNCOMMITTED)	ON	LPD.LogicalDatabaseID = LD.LogicalDatabaseID
JOIN	mnSystem.dbo.PhysicalDatabase			AS PD	WITH (READUNCOMMITTED)	ON	PD.PhysicalDatabaseID = LPD.PhysicalDatabaseID
WHERE	1 = 1
--AND		LD.LogicalDatabaseName LIKE '%mnMember%'
--AND		LD.LogicalDatabaseName LIKE 'mnMember'
--AND		ActiveFlag = 1
--AND PD.ServerName = 'LASQL03'
AND		PD.PhysicalDatabaseName = 'mnLookup'
ORDER BY	LD.LogicalDatabaseID, LPD.PhysicalDatabaseID



;WITH cteLPD
AS
(
SELECT
	ld.LogicalDatabaseName,
	pd.ServerName,
	pd.PhysicalDatabaseName,
	pd.ActiveFlag,
	ServerID = ROW_NUMBER() OVER (PARTITION BY pd.PhysicalDatabaseName ORDER BY pd.ServerName)
from
	LogicalDatabase ld (nolock)
	join LogicalPhysicalDatabase lpd (nolock) on ld.LogicalDatabaseID = lpd.LogicalDatabaseID
	join PhysicalDatabase pd (nolock) on lpd.PhysicalDatabaseID = pd.PhysicalDatabaseID
GROUP BY
	ld.LogicalDatabaseName,
	pd.ServerName,
	pd.PhysicalDatabaseName,
	pd.ActiveFlag
)
SELECT	
		S1.PhysicalDatabaseName
		,S1.LogicalDatabaseName
		,Server1	=	S1.ServerName
		,Server2	=	S2.ServerName
		,Server1Active	=	S1.ActiveFlag
		,Server2Active	=	S2.ActiveFlag
FROM	cteLPD	S1
LEFT 
JOIN	cteLPD	S2	ON S2.PhysicalDatabaseName = S1.PhysicalDatabaseName
					AND S2.ServerID = 2
WHERE	S1.ServerID = 1
ORDER by
	Server1, LogicalDatabaseName, S1.PhysicalDatabaseName