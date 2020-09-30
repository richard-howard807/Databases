SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[MilestoneCompleteIncomplete]
(@FedCode AS NVARCHAR(20))
AS 

BEGIN


SELECT dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,matter_description AS MatterDescription
,name AS FeeEarner
,tskdesc AS TaskDescription
,CASE WHEN tskComplete=0  THEN 'Incomplete' ELSE 'Complete' END AS MilestoneStatus
,tskcompleted AS DateCompleted
,tskdue AS DueDate
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  MS_Prod.dbo.dbTasks
 ON ms_fileid=fileid
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND dss_current_flag='Y' AND activeud=1
AND date_closed_case_management IS NULL	
AND tskType='MILESTONE'
AND tskDesc LIKE '%Milestone Wizard%' 
AND tskactive=1	
AND fee_earner_code=@FedCode
AND ISNULL(dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
END

GO
