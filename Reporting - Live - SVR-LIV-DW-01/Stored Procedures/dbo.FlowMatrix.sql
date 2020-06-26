SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[FlowMatrix]

AS 

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
	   MAX(DateScanned) AS NewestItem

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
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j
  JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 AND (activeud=1 OR windowsusername IN ('cwahle','awilli07'))
INNER JOIN   red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE completed = 0
  AND j.owner_type='user'
--SELECT job_id,
--       envelope_id,
--       scan_user,
--       process_id,
--       workflow_id,
--       queue_id,
--       PARSE(LEFT(scan_datetime,10) AS DATE USING 'en-gb') AS DateScanned,
--	   forename + ' ' + surname AS [Full Name]
--	   ,hierarchylevel4hist AS Team
--	   ,dim_employee.jobtitle AS [Role]
--	   ,locationidud AS [Office]	
--	   ,1 AS ItemsWaiting
--	   ,worksforname AS [Team Manager]
--	   ,worksforemail AS [TM Email]
--FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.RecentAuditlog
--INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
-- ON windowsusername=owner COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
-- AND (activeud=1 OR windowsusername='cwahle')
--INNER JOIN   red_dw.dbo.dim_employee
-- ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

--WHERE Process_Id = 'QuickDrop Workflow'
--      AND workflow_Id = 'QuickDrop Workflow'
	  
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
GO
