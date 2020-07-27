SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--=================================================
-- ES 2020-07-21 #64865 added historic fed codes
--=================================================

CREATE PROCEDURE [dbo].[FeeEarnerSearch] -- dbo.FeeEarnerSearch "EPI","EPI Birmingham"
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)

AS 

BEGIN

	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
		IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team

			SELECT ListValue COLLATE DATABASE_DEFAULT ListValue INTO #Team  FROM 	dbo.udt_TallySplit(',', @Team)  
				SELECT ListValue COLLATE DATABASE_DEFAULT  ListValue INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)

SELECT hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.name AS [Name]
,dim_fed_hierarchy_history.fed_code AS [PayrollID]
,STRING_AGG(HistFedCodes.fed_code,', ') AS [Historic Fed Codes]
,dim_employee.windowsusername AS [Username]
,dim_employee.jobtitle AS [JobTitle]
,locationidud AS [Office]
,dim_employee.workemail AS [WorkEmail]
,workphone AS [ContactNumber]
,worksforname AS [Worksor]
,workemail

,leftdate AS [DateLeft]
FROM red_dw.dbo.dim_fed_hierarchy_history
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
 LEFT OUTER JOIN (SELECT DISTINCT employeeid,name, fed_code
				FROM red_dw.dbo.dim_fed_hierarchy_history
				) AS [HistFedCodes] ON HistFedCodes.employeeid = dim_fed_hierarchy_history.employeeid
INNER JOIN #Department AS Department ON Department.ListValue  = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue  = hierarchylevel4hist COLLATE DATABASE_DEFAULT

WHERE dss_current_flag='Y'
AND activeud=1
AND dim_fed_hierarchy_history.name NOT IN ('Unknown','Budget Balance')
AND dim_fed_hierarchy_history.fed_code NOT IN ('Unknown')

GROUP BY hierarchylevel2hist,
         hierarchylevel3hist,
         hierarchylevel4hist,
         dim_fed_hierarchy_history.name,
         dim_fed_hierarchy_history.fed_code,
         dim_employee.windowsusername,
         dim_employee.jobtitle,
         locationidud,
         workemail,
         workphone,
         worksforname,
         workemail,
         leftdate

ORDER BY Division,Department,Team,name
END
GO
