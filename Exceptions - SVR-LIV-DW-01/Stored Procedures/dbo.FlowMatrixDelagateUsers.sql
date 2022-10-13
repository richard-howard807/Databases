SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[FlowMatrixDelagateUsers]

AS 

BEGIN

SELECT DISTINCT 
ac.[context6] AS target_user
,dim_employee.forename + ' ' + dim_employee.surname AS [Full Name]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS Team
,dim_employee.jobtitle AS [Role]
,dim_employee.locationidud AS [Office]	
,u.username AS delegated_user
,u.fullname AS delegated_name



FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclContexts] ac
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclUserMembership] am ON am.acl_id = ac.id
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Users] u ON am.user_id = u.user_id
LEFT OUTER JOIN red_dw.dbo.dim_employee
ON RTRIM(ac.[context6])=RTRIM(windowsusername) COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key 
 AND
 (dss_current_flag='Y' AND activeud=1
 OR dim_employee.windowsusername IN ('ccorey','jwrigh','kfrost','nellab','stempe','awilli07')
 )
WHERE context3 = 'Worklist'
AND context4 = 'QD_Validation_Work_List'
AND context5 = 'User'
AND hierarchylevel2hist <>'Public Sector'
--AND dim_employee.forename + ' ' + dim_employee.surname='Ambre Cross'
ORDER BY target_user, delegated_user

END
GO
