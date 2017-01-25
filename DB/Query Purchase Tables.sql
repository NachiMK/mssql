-- UPDATED
--1146247353 <-- 3 bought 6
--1146257805 <-- 6 bought 3

-- 1146253701 <-- 6 bought 3
-- 1150287281 <-- 6 bought 3

-- NOT UPDATED YET
-- 1146241077 <-- 3 bought 6
-- 1164874810 <-- 6 bought 3

DECLARE @OrderID INT = 1146264297
--1165031962 --1146361182

SELECT	O.OrderID, O.TotalAmount, O.UpdateDate, OD.OrderDetailID, OD.PackageID, OD.Duration, OD.Amount, OD.UpdateDate, O.CustomerID
		--O.*, OD.*
FROM	epOrder..[Order]		AS O		WITH (READUNCOMMITTED)
JOIN	epOrder..OrderDetail	AS OD	WITH (READUNCOMMITTED)	ON	OD.OrderID = O.OrderID
WHERE	O.OrderID IN (@OrderID)

--SELECT	O.*--, OD.*
--FROM	epOrder..[Order]		AS O		WITH (READUNCOMMITTED)
--WHERE	O.CustomerID = 113898159
--ORDER BY O.InsertDate desc

SELECT	AT.OrderID, AT.AccessTransactionID, AT.UpdateDate, AD.EndDate, AD.Duration
FROM	epAccess..AccessTransaction			AS	AT	WITH (READUNCOMMITTED)
JOIN	epAccess..AccessTransactionDetail	AS	AD	WITH (READUNCOMMITTED)	ON	AD.AccessTransactionID = AT.AccessTransactionID
WHERE	AT.OrderID IN (@OrderID)

-- Fix End Date for Access Transaction for Order ID 1146247353, should be -3 months.

-- Fix End Date for Access Customer Priv for Order ID 1146247353, should be -3 months.
SELECT	O.OrderID, AP.CustomerID, AP.AccessCustomerPrivilegeID, AP.UpdateDate, AP.EndDate
FROM	epOrder..[Order]					AS O	WITH (READUNCOMMITTED)
JOIN	epAccess..AccessCustomerPrivilege	AS	AP	WITH (READUNCOMMITTED)	ON	AP.CustomerID = O.CustomerID
WHERE	O.OrderID IN (@OrderID)
AND		AP.ArchiveFlag			=	0
AND		AP.UnifiedPrivilegeTypeID = 1
AND		AP.CallingSystemID		=	103


SELECT	
		--O.OrderID, RS.RenewalSubscriptionID, RS.RenewalDate, RS.UpdateDate, RT.RenewalTransactionID, RT.RenewalEndDateUTC, RT.UpdateDate, RTD.PackageID, RS.PrimaryPackageID
		--, RSD.PackageID, RSD.UpdateDate, RSD.RenewalSubscriptionID
		RS.*
		,RT.*
		--,RTD.*
		,RSD.*
FROM	epOrder..[Order]		AS O		WITH (READUNCOMMITTED)
JOIN	epRenewal.dbo.RenewalSubscription		AS	RS		WITH (READUNCOMMITTED)	ON	O.CustomerID	=	RS.CustomerID
																					AND	RS.IsArchived = 0
JOIN	epRenewal.dbo.RenewalSubscriptionDetail	AS	RSD		WITH (READUNCOMMITTED)	ON	RSD.RenewalSubscriptionID	= RS.RenewalSubscriptionID
LEFT JOIN	epRenewal.dbo.RenewalTransaction		AS	RT		WITH (READUNCOMMITTED)	ON	RS.RenewalSubscriptionID	= RT.RenewalSubscriptionID
																					AND	RT.ExternalTransactionID    = O.OrderID
LEFT JOIN	epRenewal.dbo.RenewalTransactionDetail	AS	RTD		WITH (READUNCOMMITTED)	ON	RTD.RenewalTransactionID	= RT.RenewalTransactionID
WHERE	O.OrderID IN (@OrderID)
AND		RSD.IsArchived = 0

SELECT * FROM epRenewal..RenewalSubscription WHERE CustomerID  = (SELECT CustomerID FROM epOrder..[Order] WHERE OrderID = 1146264297)
SELECT * FROM epRenewal..RenewalTransaction WHERE ExternalTransactionID = 1146264297


-- SELECT * FROM epProductService.dbo.PackageItem WHERE PackageID IN (33041, 33053)
