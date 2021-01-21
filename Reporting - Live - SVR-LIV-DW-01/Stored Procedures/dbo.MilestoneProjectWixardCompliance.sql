SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




--JL 06-10-2020 - I have excluded "In House" as per Bob's request 
--JL 19-01-2021 - Excluded client 30645 as per ticket #85254
--JL 20-01-2021 - #85340 - excluded clients as per ticket 




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
,CONVERT(DATE,Milestones.DateLastCompleted,103) AS [LastTimeRan]
,DATEDIFF(DAY,CONVERT(DATE,Milestones.DateLastCompleted,103),GETDATE()) AS [DaysSinceWizardLastCompleted]
,CONVERT(DATE,GETDATE(),103) AS TodaysDate
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,matter_description AS [MatterDescription]
,name AS [MatterOwner]
,dim_matter_header_current.present_position
,DATEDIFF(Day,'2020-09-28',CONVERT(DATE,GETDATE()-1,103)) AS LiveDays
,DATEDIFF(Day,'2020-09-28','2021-01-31') AS Day1
,DATEDIFF(Day,'2020-09-28','2021-04-30') AS Day2
,DATEDIFF(Day,'2020-09-28','2021-07-31') AS Day3

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(tskCompleted) AS [DateLastCompleted]
FROM MS_Prod.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Milestone Wizard%' 
AND tskactive=1
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND dss_current_flag='Y' AND activeud=1
AND date_closed_case_management IS NULL
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND leaver =0
AND master_client_code <> '30645'
AND   RTRIM(dim_matter_header_current.client_code)+'/'+dim_matter_header_current.matter_number NOT IN  ('00015526/00000275',
'125409T/00001126',
'125409T/00000047',
'125409T/00001259',
'00707938/00001497',
'00707938/00001131',
'00707938/00001436',
'00707938/00001444',
'51130A/00001024',
'CNST/00000001',
'DHCLIN/00000001',
'DHLIAB/00000001',
'ELS/00000001',
'INQCOST/00000001',
'N00002/00000999',
'N00007/PPD001',
'N00007/VOL001',
'N00009/00000001',
'N00003/VOL001',
'N00004/VOL001',
'N00005/VOL001',
'N00006/PPD001',
'N00001/00000999',
'N00002/VOL001',
'N00005/PPD001',
'N00006/VOL001',
'N00033/00000999',
'N00034/00000999',
'N00003/00000999',
'N00004/00000999',
'N00004/PPD001',
'N00031/00000999',
'N00035/00000999',
'RPST/00000001',
'W16179/00000012',
'W16179/00000007',
'W16179/00000008',
'W16179/00000009',
'W16179/00000010',
'W16179/00000003',
'W16179/00000005',
'W16179/00000006',
'W16179/00000011',
'W16179/00000013',
'W16179/00000001',
'W16179/00000002',
'W16179/00000014',
'W15526/00000275'
) 
--AND fed_code='5900'

END


GO
