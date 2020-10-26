SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- FW Deeds
CREATE PROCEDURE [dbo].[LeedsDeeds]
(
@Search AS NVARCHAR(MAX)
) 
AS 

IF @Search='All'

BEGIN


SELECT ddocod AS [Outlet No]
,ddname AS [Outlet Name]
,ddadd1 AS Address1
,ddadd2 AS Address2
,ddadd3 AS Address3
,ddadd4 AS Address4
,ddpost AS Postcode
,dparea AS [Area]
,ddpack AS [Number of Packets]
,ddfile.ddrequ AS [Requested]
,drfile.drdesc AS [Reason for Request]
,dsdesc AS [Current Status]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[ddfile]
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[dsfile]
 ON dsidno = ddstat
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[drfile]
 ON ddreas = dridno
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[dpfile]
 ON ddarea=dpidno


END 

ELSE 

BEGIN

SELECT ddocod AS [Outlet No]
,ddname AS [Outlet Name]
,ddadd1 AS Address1
,ddadd2 AS Address2
,ddadd3 AS Address3
,ddadd4 AS Address4
,ddpost AS Postcode
,dparea AS [Area]
,ddpack AS [Number of Packets]
,ddfile.ddrequ AS [Requested]
,drfile.drdesc AS [Reason for Request]
,dsdesc AS [Current Status]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[ddfile]
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[dsfile]
 ON dsidno = ddstat
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[drfile]
 ON ddreas = dridno
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[deeds].[dbo].[dpfile]
 ON ddarea=dpidno
WHERE ddname LIKE '%' + @Search + '%'

END 
GO
