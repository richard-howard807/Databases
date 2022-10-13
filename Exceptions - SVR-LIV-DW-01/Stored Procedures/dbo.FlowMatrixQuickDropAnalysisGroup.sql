SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[FlowMatrixQuickDropAnalysisGroup]  
 
(  
@Email AS NVARCHAR(MAX)  
)  
AS   
  
--Test -- DECLARE @Email AS NVARCHAR(20) = 'All'
DROP TABLE IF EXISTS #TeamLeaders

SELECT DISTINCT 

   ROW_NUMBER() OVER (PARTITION BY a.hierarchylevel4hist, a.hierarchylevel3hist, a.hierarchylevel2hist  ORDER BY a.dss_version DESC) RN
    ,a.hierarchylevel2hist  AS [Business Line]  
    ,a.hierarchylevel3hist  AS [Practice Area]  
    ,a.hierarchylevel4hist  AS Team  
	,a.worksforname         AS TeamLeader
	,a.dss_version
	,dim_employee.workemail AS TeamLeaderEmail
	,dim_employee.jobtitle  AS [Role]  
    ,locationidud           AS [Office]   
	INTO #TeamLeaders
	from
red_dw.dbo.dim_fed_hierarchy_history  a
LEFT JOIN   red_dw.dbo.dim_employee  
 ON a.worksforname = forename +' ' +surname
WHERE a.dss_current_flag='Y'  AND a.activeud= 1 
AND a.worksforname IS NOT NULL 
AND a.hierarchylevel4hist IS NOT NULL 
 
IF @Email='All'  

BEGIN   
  
SELECT 
ROW_NUMBER() OVER (ORDER BY x.NumberPending DESC) AS [Leaderboard Place], 
x.[Full Name],                                                                                                 
x.[Business Line],
x.[Practice Area],
x.Team,
x.Role,
x.Office,
x.[Team Manager],
x.[TM Email],
x.NoItemsCompleted,
x.OldestItem,
x.NewestItem,
x.NoOver5Days,
x.NumberCompleted,
x.NumberPending,
CASE WHEN [x].[Business Line] = 'Team QuickDrop Queues' THEN 1 ELSE 0 END AS SortOrder


 
 FROM 
 (
--SELECT ROW_NUMBER() OVER (PARTITION BY 1  ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],  
SELECT 
GroupedData.[Full Name],  
GroupedData.[Business Line],  
GroupedData.[Practice Area],  
       GroupedData.Team,  
       GroupedData.Role,  
       GroupedData.Office,  
       GroupedData.[Team Manager],  
       GroupedData.[TM Email] ,  
    SUM(ItemsCompleted) AS NoItemsCompleted,  
    MIN(DateScanned) AS OldestItem,  
    MAX(DateScanned) AS NewestItem,  
    SUM(Over5Days) AS NoOver5Days  ,
	SUM(CASE WHEN GroupedData.completed = 1 THEN 1 END) AS NumberCompleted,
	SUM(CASE WHEN GroupedData.completed = 0 THEN 1 END) AS NumberPending
FROM   
(  
SELECT j.[job_id] AS job_id,  
       NULL AS envelope_id,  
       owner AS scan_user,  
       NULL process_id,  
       NULL workflow_id,  
       j.queue_id,  
       created AS DateScanned  
    ,COALESCE(Team,[owner] COLLATE DATABASE_DEFAULT,'Unknown') AS [Full Name]  --Added owner 20210209 - MT
    ,'Team QuickDrop Queues' AS [Business Line]  --[Business Line] 
    ,COALESCE(Team,[owner] COLLATE DATABASE_DEFAULT,'Unknown') AS [Practice Area] -- [Practice Area] --Added owner 20210209 - MT
    ,COALESCE(Team, [owner] COLLATE DATABASE_DEFAULT)  AS Team  --Added owner 20210209 - MT
    ,COALESCE([Role], 'Unknown') AS [Role]  
    ,COALESCE([Office], 'Unknown') AS [Office]   
    ,1 AS ItemsCompleted
    ,COALESCE(TeamLeader,'Unknown') AS [Team Manager]  
    ,COALESCE(TeamLeaderEmail,'Unknown') AS [TM Email]  
    ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days  
	,j.completed
	
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j  
   
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id  
 
LEFT JOIN  #TeamLeaders 
 ON Team=[owner] COLLATE DATABASE_DEFAULT AND RN = 1 


WHERE 1 = 1
  AND completed = 0
  AND (j.owner_type='group')
  
     
) AS GroupedData  

WHERE GroupedData.[Full Name] <> 'Unknown'

GROUP BY 
GroupedData.[Full Name],  
GroupedData.[Business Line],GroupedData.[Practice Area],  
       GroupedData.Team,  
       GroupedData.Role,  
       GroupedData.Office,  
       GroupedData.[Team Manager] 
      ,GroupedData.[TM Email]  
 --   ORDER BY SUM(GroupedData.ItemsWaiting) DESC  

UNION 
SELECT
--SELECT ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
GroupedData.[Full Name],
GroupedData.[Business Line],
GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email] ,
	   SUM(ItemsCompleted) AS NoItemsCompleted,
	   MIN(DateScanned) AS OldestItem,
	   MAX(DateScanned) AS NewestItem,
	   SUM(Over5Days) AS NoOver5Days,
	   SUM(CASE WHEN GroupedData.completed = 1 THEN 1 END) AS NumberCompleted,
	   SUM(CASE WHEN GroupedData.completed = 0 THEN 1 END) AS NumberPending
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
	   ,1 AS ItemsCompleted
	   ,worksforname AS [Team Manager]
	   ,worksforemail AS [TM Email]
	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
	   ,j.completed
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j
 
JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
 OR windowsusername IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 0 AND dss_current_flag = 'Y'
AND windowsusername IS NOT NULL 
AND windowsusername NOT IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 1 AND dss_current_flag = 'Y' AND windowsusername IS NOT null)))
INNER JOIN   red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
 --LEFT JOIN  #TeamLeaders 
 --ON TeamLeader=[owner] COLLATE DATABASE_DEFAULT AND RN = 1 

WHERE 1 = 1

  AND completed = 0
  AND j.owner_type='user'
  --AND forename + ' ' + surname = worksforname
	  
) AS GroupedData

--WHERE GroupedData.[Full Name] IN (SELECT DISTINCT TeamLeader FROM #TeamLeaders)

GROUP BY 

GroupedData.[Full Name],
GroupedData.[Business Line],GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email]

) x
ORDER BY x.NoItemsCompleted DESC

END

ELSE   
  
BEGIN    

  
  
SELECT 
ROW_NUMBER() OVER (ORDER BY x.NumberPending DESC) AS [Leaderboard Place], 
x.[Full Name],                                                                                                 
x.[Business Line],
x.[Practice Area],
x.Team,
x.Role,
x.Office,
x.[Team Manager],
x.[TM Email],
x.NoItemsCompleted,
x.OldestItem,
x.NewestItem,
x.NoOver5Days,
x.NumberCompleted, 
x.NumberPending,
CASE WHEN [x].[Business Line] = 'Team QuickDrop Queues' THEN 1 ELSE 0 END AS SortOrder
 FROM 
 (
--SELECT ROW_NUMBER() OVER (PARTITION BY 1  ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],  
SELECT 
GroupedData.[Full Name],  
GroupedData.[Business Line],  
GroupedData.[Practice Area],  
       GroupedData.Team,  
       GroupedData.Role,  
       GroupedData.Office,  
       GroupedData.[Team Manager],  
       GroupedData.[TM Email] ,  
    SUM(ItemsCompleted) AS NoItemsCompleted,  
    MIN(DateScanned) AS OldestItem,  
    MAX(DateScanned) AS NewestItem,  
    SUM(Over5Days) AS NoOver5Days  ,
	SUM(CASE WHEN GroupedData.completed = 1 THEN 1 END) AS NumberCompleted, 
	 SUM(CASE WHEN GroupedData.completed = 0 THEN 1 END) AS NumberPending
FROM   
(  
SELECT j.[job_id] AS job_id,  
       NULL AS envelope_id,  
       owner AS scan_user,  
       NULL process_id,  
       NULL workflow_id,  
       j.queue_id,  
       created AS DateScanned  
    ,COALESCE(Team,[owner] COLLATE DATABASE_DEFAULT,'Unknown') AS [Full Name]  --Added owner 20210209 - MT
    ,'Team QuickDrop Queues' AS [Business Line]  --[Business Line] 
    ,COALESCE(Team,[owner] COLLATE DATABASE_DEFAULT,'Unknown') AS [Practice Area] -- [Practice Area] --Added owner 20210209 - MT
    ,COALESCE(Team, [owner] COLLATE DATABASE_DEFAULT)  AS Team  --Added owner 20210209 - MT
    ,COALESCE([Role], 'Unknown') AS [Role]  
    ,COALESCE([Office], 'Unknown') AS [Office]   
    ,1 AS ItemsCompleted
    ,COALESCE(TeamLeader,'Unknown') AS [Team Manager]  
    ,COALESCE(TeamLeaderEmail,'Unknown') AS [TM Email]  
    ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days  
	,j.completed
	
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j  
   
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id  
 
LEFT JOIN  #TeamLeaders 
 ON Team=[owner] COLLATE DATABASE_DEFAULT AND RN = 1 


WHERE 1 = 1
  AND completed = 0 
  AND (j.owner_type='group')
  
     
) AS GroupedData  

WHERE GroupedData.[Full Name] <> 'Unknown'

GROUP BY 
GroupedData.[Full Name],  
GroupedData.[Business Line],GroupedData.[Practice Area],  
       GroupedData.Team,  
       GroupedData.Role,  
       GroupedData.Office,  
       GroupedData.[Team Manager] 
      ,GroupedData.[TM Email]  
 --   ORDER BY SUM(GroupedData.ItemsWaiting) DESC  

UNION 
SELECT
--SELECT ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
GroupedData.[Full Name],
GroupedData.[Business Line],
GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email] ,
	   SUM(ItemsCompleted) AS NoItemsCompleted,
	   MIN(DateScanned) AS OldestItem,
	   MAX(DateScanned) AS NewestItem,
	   SUM(Over5Days) AS NoOver5Days,
	   SUM(CASE WHEN GroupedData.completed = 1 THEN 1 END) AS NumberCompleted, 
	   SUM(CASE WHEN GroupedData.completed = 0 THEN 1 END) AS NumberPending
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
	   ,1 AS ItemsCompleted
	   ,worksforname AS [Team Manager]
	   ,worksforemail AS [TM Email]
	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
	   ,j.completed
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j
 
JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
 OR windowsusername IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 0 AND dss_current_flag = 'Y'
AND windowsusername IS NOT NULL 
AND windowsusername NOT IN (SELECT DISTINCT windowsusername
FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE activeud = 1 AND dss_current_flag = 'Y' AND windowsusername IS NOT null)))
INNER JOIN   red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
 --LEFT JOIN  #TeamLeaders 
 --ON TeamLeader=[owner] COLLATE DATABASE_DEFAULT AND RN = 1 

WHERE 1 = 1

  AND completed = 0
  AND j.owner_type='user'
  --AND forename + ' ' + surname = worksforname
	  
) AS GroupedData

--WHERE GroupedData.[Full Name] IN (SELECT DISTINCT TeamLeader FROM #TeamLeaders)

GROUP BY 

GroupedData.[Full Name],
GroupedData.[Business Line],GroupedData.[Practice Area],
       GroupedData.Team,
       GroupedData.Role,
       GroupedData.Office,
       GroupedData.[Team Manager],
       GroupedData.[TM Email]

) x

WHERE x.[TM Email]=@Email 
ORDER BY x.NoItemsCompleted DESC

END

  

  

  
  
  /*Previous version pre 18/12/2020*/
--  ALTER PROCEDURE [dbo].[FlowMatrixQuickDropAnalysis]
--(
--@Email AS NVARCHAR(MAX)
--)
--AS 

--IF @Email='All'
--BEGIN


--SELECT ROW_NUMBER() OVER (PARTITION BY 1
--ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
--GroupedData.[Full Name],
--GroupedData.[Business Line],
--GroupedData.[Practice Area],
--       GroupedData.Team,
--       GroupedData.Role,
--       GroupedData.Office,
--       GroupedData.[Team Manager],
--       GroupedData.[TM Email] ,
--	   SUM(ItemsWaiting) AS NoItemsWaiting,
--	   MIN(DateScanned) AS OldestItem,
--	   MAX(DateScanned) AS NewestItem,
--	   SUM(Over5Days) AS NoOver5Days
--FROM 
--(
--SELECT j.[job_id] AS job_id,
--       NULL AS envelope_id,
--       owner AS scan_user,
--       NULL process_id,
--       NULL workflow_id,
--       j.queue_id,
--       created AS DateScanned,
--	   forename + ' ' + surname AS [Full Name]
--	   ,hierarchylevel2hist AS [Business Line]
--	   ,hierarchylevel3hist AS [Practice Area]
--	   ,hierarchylevel4hist AS Team
--	   ,dim_employee.jobtitle AS [Role]
--	   ,locationidud AS [Office]	
--	   ,1 AS ItemsWaiting
--	   ,worksforname AS [Team Manager]
--	   ,worksforemail AS [TM Email]
--	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
--FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j
 
--JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

--INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
-- ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
-- AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
-- OR windowsusername IN (SELECT DISTINCT windowsusername
--FROM red_dw.dbo.dim_fed_hierarchy_history
--WHERE activeud = 0 AND dss_current_flag = 'Y'
--AND windowsusername IS NOT NULL 
--AND windowsusername NOT IN (SELECT DISTINCT windowsusername
--FROM red_dw.dbo.dim_fed_hierarchy_history
--WHERE activeud = 1 AND dss_current_flag = 'Y' AND windowsusername IS NOT null)))
--INNER JOIN   red_dw.dbo.dim_employee
-- ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
--WHERE completed = 0
--  AND j.owner_type='user'
	  
--) AS GroupedData
--GROUP BY GroupedData.[Full Name],
--GroupedData.[Business Line],GroupedData.[Practice Area],
--       GroupedData.Team,
--       GroupedData.Role,
--       GroupedData.Office,
--       GroupedData.[Team Manager],
--       GroupedData.[TM Email]
--	   ORDER BY SUM(GroupedData.ItemsWaiting) DESC

--END

--ELSE 

--BEGIN


--SELECT ROW_NUMBER() OVER (PARTITION BY 1
--ORDER BY SUM(GroupedData.ItemsWaiting) DESC) AS [Leaderboard Place],
--GroupedData.[Full Name],
--GroupedData.[Business Line],
--GroupedData.[Practice Area],
--       GroupedData.Team,
--       GroupedData.Role,
--       GroupedData.Office,
--       GroupedData.[Team Manager],
--       GroupedData.[TM Email] ,
--	   SUM(ItemsWaiting) AS NoItemsWaiting,
--	   MIN(DateScanned) AS OldestItem,
--	   MAX(DateScanned) AS NewestItem,
--	   SUM(Over5Days) AS NoOver5Days
--FROM 
--(
--SELECT j.[job_id] AS job_id,
--       NULL AS envelope_id,
--       owner AS scan_user,
--       NULL process_id,
--       NULL workflow_id,
--       j.queue_id,
--       created AS DateScanned,
--	   forename + ' ' + surname AS [Full Name]
--	   ,hierarchylevel2hist AS [Business Line]
--	   ,hierarchylevel3hist AS [Practice Area]
--	   ,hierarchylevel4hist AS Team
--	   ,dim_employee.jobtitle AS [Role]
--	   ,locationidud AS [Office]	
--	   ,1 AS ItemsWaiting
--	   ,worksforname AS [Team Manager]
--	   ,worksforemail AS [TM Email]
--	   ,CASE WHEN DATEDIFF(DAY,created,GETDATE())>=5 THEN 1 ELSE 0 END AS Over5Days
--FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] j

--JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Queues] q ON j.queue_id = q.queue_id

--INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
-- ON windowsusername=[owner] COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'

-- AND (activeud= 1 OR windowsusername IN ('cwahle','awilli07')  
--  OR windowsusername IN (SELECT DISTINCT windowsusername
--FROM red_dw.dbo.dim_fed_hierarchy_history
--WHERE activeud = 0 AND dss_current_flag = 'Y'
--AND windowsusername IS NOT NULL 
--AND windowsusername NOT IN (SELECT DISTINCT windowsusername
--FROM red_dw.dbo.dim_fed_hierarchy_history
--WHERE activeud = 1 AND dss_current_flag = 'Y' AND windowsusername IS NOT null)))

--INNER JOIN   red_dw.dbo.dim_employee
-- ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
--WHERE completed = 0
--  AND j.owner_type='user'
	  
--) AS GroupedData
--WHERE GroupedData.[TM Email]=@Email
--GROUP BY GroupedData.[Full Name],
--GroupedData.[Business Line],GroupedData.[Practice Area],
--       GroupedData.Team,
--       GroupedData.Role,
--       GroupedData.Office,
--       GroupedData.[Team Manager],
--       GroupedData.[TM Email]
--	   ORDER BY SUM(GroupedData.ItemsWaiting) DESC

--END
GO
