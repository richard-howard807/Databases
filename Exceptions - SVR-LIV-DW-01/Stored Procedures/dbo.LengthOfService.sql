SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-05-11
-- Description:	#145774, Length of Service Report
-- =============================================
CREATE PROCEDURE [dbo].[LengthOfService]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT load_cascade_employee.displayemployeeid AS [Employee Number]
	, load_cascade_employee.windowsusername AS [Username]
	, load_cascade_employee.knownas AS [Known As]
	, load_cascade_employee.surname AS [Surname]
	, load_cascade_employee.workemail AS [Email]
	, load_cascade_employee_jobs.locationidud AS [Office]
	, linemanager.forename + ' ' + linemanager.surname AS [Line Manager]
	, dbo.FindDateDiff(load_cascade_employee.contservicedate, GETDATE(),1) AS [Length of Service]

	FROM red_dw.dbo.load_cascade_employee
	INNER JOIN red_dw.dbo.load_cascade_employee_jobs ON load_cascade_employee.employeeid =  load_cascade_employee_jobs.employeeid AND sys_activejob = 1 
	LEFT OUTER JOIN red_dw.dbo.load_cascade_employee linemanager ON linemanager.employeeid = load_cascade_employee_jobs.worksforemployeeid

	WHERE load_cascade_employee.leftdate IS NULL
	AND load_cascade_employee.employeestartdate <= GETDATE() 
	AND linemanager.forename + ' ' + linemanager.surname IS NOT NULL 
	AND NOT load_cascade_employee.surname LIKE 'Automation%'
	AND NOT load_cascade_employee.workemail LIKE 'Test.Test%'

	ORDER BY Surname, [Known As]

END
GO
