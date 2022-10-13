SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[FlowMatrixUsers]
(
@Target  AS NVARCHAR(100)
)

AS
BEGIN

IF @Target='All'

BEGIN
SELECT ac.[context6] AS target_user,
 TargetUser.FullName AS TargetFullName,
 TargetUser.Team AS TargetTeam,
 TargetUser.Department AS TargetDepartment,
 TargetUser.Office AS TargetOffice

, u.username AS  delegated_user, u.fullname AS  delegated_name,
 DelegateUser.FullName,
 DelegateUser.Team,
 DelegateUser.Department,
 DelegateUser.Office
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclContexts] ac

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclUserMembership] am ON am.acl_id = ac.id

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Users] u ON am.user_id = u.user_id
LEFT OUTER JOIN 
(
SELECT dim_employee.windowsusername
,name AS FullName
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,locationidud AS [Office]
FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y' AND activeud=1
) AS TargetUser
 ON ac.[context6] =TargetUser.windowsusername COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT dim_employee.windowsusername
,name AS FullName
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,locationidud AS [Office]
FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y' AND activeud=1
) AS DelegateUser
 ON u.username=DelegateUser.windowsusername COLLATE DATABASE_DEFAULT

WHERE context3 = 'Worklist'

AND context4 = 'QD_Validation_Work_List'

AND context5 = 'User'


ORDER BY target_user,  delegated_user
END

ELSE


BEGIN
   SELECT ac.[context6] AS target_user,
 TargetUser.FullName AS TargetFullName,
 TargetUser.Team AS TargetTeam,
 TargetUser.Department AS TargetDepartment,
 TargetUser.Office AS TargetOffice

, u.username AS  delegated_user, u.fullname AS  delegated_name,
 DelegateUser.FullName,
 DelegateUser.Team,
 DelegateUser.Department,
 DelegateUser.Office
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclContexts] ac

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[AclUserMembership] am ON am.acl_id = ac.id

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Users] u ON am.user_id = u.user_id
LEFT OUTER JOIN 
(
SELECT dim_employee.windowsusername
,name AS FullName
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,locationidud AS [Office]
FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y' AND activeud=1
) AS TargetUser
 ON ac.[context6] =TargetUser.windowsusername COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT dim_employee.windowsusername
,name AS FullName
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,locationidud AS [Office]
FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y' AND activeud=1
) AS DelegateUser
 ON u.username=DelegateUser.windowsusername COLLATE DATABASE_DEFAULT

WHERE context3 = 'Worklist'

AND context4 = 'QD_Validation_Work_List'

AND context5 = 'User'
AND TargetUser.FullName=@Target

ORDER BY target_user,  delegated_user
END

END



GO
