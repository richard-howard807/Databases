SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[MilestoneProjectWixardCompliance]

AS 

BEGIN

SELECT hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS [Fee Earner]
,fed_code AS [FedCode]
,1 AS [Number Live Matters]
,CASE WHEN Milestones.Completed>=1 THEN 1 ELSE 0 END  AS [WizardCompleted]
,CASE WHEN Milestones.Completed=0 THEN 1 ELSE 0 END  AS [WizardIncomplete]
,Milestones.DateLastCompleted AS [LastTimeRan]
,DATEDIFF(DAY,Milestones.DateLastCompleted,GETDATE()) AS [DaysSinceWizardLastCompleted]
,client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS [MatterDescription]
,name AS [MatterOwner]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(tskCompleted) AS [DateLastCompleted]
FROM [SVR-LIV-MSP-01].MS_TEST.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Stage%' AND tskDesc LIKE '%Wizard%'
AND tskactive=1
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND dss_current_flag='Y' AND activeud=1
AND date_closed_case_management IS NULL


END
GO
