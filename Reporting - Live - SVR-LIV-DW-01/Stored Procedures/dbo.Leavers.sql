SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-06-22
-- Description:	61937 New leavers report for Office Managers
-- =============================================

CREATE PROCEDURE [dbo].[Leavers]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT forename+' '+surname AS [Name]
	, payrollid AS [Payroll ID]
	, hierarchylevel2hist AS [Division]
	, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, HSD.HSD AS [HSD]
	, worksforname AS [Team Manager]
	, leaverlastworkdate AS [Leaver Last Work Date]
	, DATEDIFF(DAY, GETDATE(), leaverlastworkdate) AS [Days until leaving]
	--, * 
FROM red_dw.dbo.dim_employee
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.employeeid = dim_employee.employeeid
AND GETDATE() BETWEEN dss_start_date AND dss_end_date
AND dss_current_flag='Y'
AND activeud=1

LEFT OUTER JOIN (SELECT hierarchylevel3hist
						   , dim_fed_hierarchy_history.name AS [HSD]
					FROM red_dw.dbo.dim_fed_hierarchy_history
					WHERE dim_fed_hierarchy_history.windowsusername IS NOT NULL
						   AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
						   AND dim_fed_hierarchy_history.activeud = 1
						   AND dim_fed_hierarchy_history.management_role_one = 'HoSD') AS [HSD] 
ON HSD.hierarchylevel3hist=dim_fed_hierarchy_history.hierarchylevel3hist


WHERE leaverlastworkdate>GETDATE()
AND DATEDIFF(DAY, GETDATE(), leaverlastworkdate)<=14


ORDER BY leaverlastworkdate

END
GO
