SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[FlowMatrixQuickDropAnalysis]
(
@Email AS NVARCHAR(MAX)
)
AS 

IF @Email='All'
BEGIN


SELECT ROW_NUMBER() OVER (PARTITION BY 1
ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
GroupedData.[Full Name],
GroupedData.[Business Line],
GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email] ,
	   SUM(ItemsWaiting) AS NoItemsWaiting,
	   MIN(DateScanned) AS OldestItem,
	   MAX(DateScanned) AS NewestItem,
	   SUM(Over5Days) AS NoOver5Days
FROM 
(
SELECT j.[job_id] AS job_id,
       NULL AS envelope_id,
       owner AS scan_user,
       NULL process_id,
       NULL workflow_id,
       j.queue_id,
       created AS DateScanned,
	   forename + ' ' + surname AS [Full Name]
	   ,hierarchylevel2hist AS [Business Line]
	   ,hierarchylevel3hist AS [Practice Area]
	   ,hierarchylevel4hist AS Team
	   ,dim_employee.jobtitle AS [Role]
	   ,locationidud AS [Office]	
	   ,1 AS ItemsWaiting
	   ,worksforname AS [Team Manager]
	   ,worksforemail AS [TM Email]
	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j
 
JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
 OR windowsusername IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 0 AND dss_current_flag = 'Y'
AND windowsusername IS NOT NULL 
AND windowsusername NOT IN (SELECT DISTINCT ISNULL(windowsusername,'')
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 1 AND dss_current_flag = 'Y')))
INNER JOIN   red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE completed = 0
  AND j.owner_type='user'
	  
) AS GroupedData
GROUP BY GroupedData.[Full Name],
GroupedData.[Business Line],GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email]
	   ORDER BY SUM(GroupedData.ItemsWaiting) DESC

END

ELSE 

BEGIN


SELECT ROW_NUMBER() OVER (PARTITION BY 1
ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
GroupedData.[Full Name],
GroupedData.[Business Line],
GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email] ,
	   SUM(ItemsWaiting) AS NoItemsWaiting,
	   MIN(DateScanned) AS OldestItem,
	   MAX(DateScanned) AS NewestItem,
	   SUM(Over5Days) AS NoOver5Days
FROM 
(
SELECT j.[job_id] AS job_id,
       NULL AS envelope_id,
       owner AS scan_user,
       NULL process_id,
       NULL workflow_id,
       j.queue_id,
       created AS DateScanned,
	   forename + ' ' + surname AS [Full Name]
	   ,hierarchylevel2hist AS [Business Line]
	   ,hierarchylevel3hist AS [Practice Area]
	   ,hierarchylevel4hist AS Team
	   ,dim_employee.jobtitle AS [Role]
	   ,locationidud AS [Office]	
	   ,1 AS ItemsWaiting
	   ,worksforname AS [Team Manager]
	   ,worksforemail AS [TM Email]
	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j

JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'

 AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
  OR windowsusername IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 0 AND dss_current_flag = 'Y'
AND windowsusername IS NOT NULL 
AND windowsusername NOT IN (SELECT DISTINCT ISNULL(windowsusername,'')
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 1 AND dss_current_flag = 'Y')))

INNER JOIN   red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE completed = 0
  AND j.owner_type='user'
	  
) AS GroupedData
WHERE GroupedData.[TM Email]=@Email
GROUP BY GroupedData.[Full Name],
GroupedData.[Business Line],GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email]
	   ORDER BY SUM(GroupedData.ItemsWaiting) DESC

END


GO
