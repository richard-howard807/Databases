SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [onetoone].[users]

AS

SELECT emp.windowsusername employee_username, 
	emp.fed_code,
	emp.hierarchylevel1,
	emp.hierarchylevel2, 
	emp.hierarchylevel3,
	emp.hierarchylevel4,
	emp.name employee_name, 
	emp.leaver,
	emp.jobtitle,
	dim_employee.workemail,
	ISNULL(mgr.windowsusername, '') mgr_username,
	ISNULL(mgr.name, '') mgr_name,
	hsd.windowsusername hds_username,
	hsd.name hsd_name,
	dbo.dim_employee.employeestartdate
-- select *
FROM dbo.dim_fed_hierarchy_current emp
INNER JOIN dbo.dim_employee ON dim_employee.employeeid = emp.employeeid
LEFT OUTER JOIN dim_fed_hierarchy_current mgr ON mgr.employeeid = emp.worksforemployeeid AND mgr.activeud = 1
LEFT OUTER JOIN dim_fed_hierarchy_current hsd ON mgr.worksforemployeeid = hsd.employeeid AND hsd.activeud = 1
WHERE emp.activeud = 1
AND emp.windowsusername IS NOT NULL
AND ISNULL(dim_employee.deleted_from_cascade,0) <> 1


GO
GRANT SELECT ON  [onetoone].[users] TO [SBC\People - Team - Development]
GO
