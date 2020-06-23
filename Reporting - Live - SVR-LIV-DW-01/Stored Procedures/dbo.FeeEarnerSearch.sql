SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[FeeEarnerSearch] -- dbo.FeeEarnerSearch "EPI","EPI Birmingham"
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)

AS 

BEGIN

	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
		IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team

			SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
				SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)

SELECT hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS Team
,name AS [Name]
,fed_code AS [PayrollID]
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
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

WHERE dss_current_flag='Y'
AND activeud=1
AND name NOT IN ('Unknown','Budget Balance')
AND fed_code NOT IN ('Unknown')
ORDER BY Division,Department,Team,name
END
GO
