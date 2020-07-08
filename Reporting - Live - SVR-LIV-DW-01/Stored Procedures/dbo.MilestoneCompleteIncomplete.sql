SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MilestoneCompleteIncomplete]
(@FedCode AS NVARCHAR(20))
AS 

BEGIN


SELECT client_code AS Client
,matter_number AS Matter
,matter_description AS MatterDescription
,name AS FeeEarner
,tskdesc AS TaskDescription
,CASE WHEN tskComplete=0  THEN 'Incomplete' ELSE 'Complete' END AS MilestoneStatus
,tskcompleted AS DateCompleted
,tskdue AS DueDate
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_TEST.dbo.dbTasks
 ON ms_fileid=fileid
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND dss_current_flag='Y' AND activeud=1
AND date_closed_case_management IS NULL	
AND tskType='MILESTONE'
AND tskDesc LIKE '%Stage%' AND tskDesc LIKE '%Wizard%'
AND tskactive=1	
AND fee_earner_code=@FedCode

END

GO
