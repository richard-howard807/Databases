SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[MilestoneProjectWixardCompliance_for_HSD_Summary]

AS 

BEGIN

SELECT 
hierarchylevel2hist AS Division
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
,DATEDIFF(DAY,'2020-09-28',CONVERT(DATE,GETDATE()-1,103)) AS LiveDays
,DATEDIFF(DAY,'2020-09-28','2021-01-31') AS Day1
,DATEDIFF(DAY,'2020-09-28','2021-04-30') AS Day2
,DATEDIFF(DAY,'2020-09-28','2021-07-31') AS Day3

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON  dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
	(SELECT dim_tasks.client_code, dim_tasks.matter_number
       , SUM(CASE WHEN task_status='C' THEN 1 ELSE 0 END) AS Completed
       , SUM(CASE WHEN task_status='N' THEN 1 ELSE 0 END) AS Incompleted
       ,MAX(red_dw.dbo.datetimelocal(completed)) AS [DateLastCompleted]
FROM red_dw.dbo.dim_tasks
WHERE dim_tasks.task_type_description ='Milestone Task'
AND dim_tasks.task_desccription LIKE '%Milestone Wizard%' 
AND tskactive=1
GROUP BY dim_tasks.client_code,
         dim_tasks.matter_number
) AS Milestones
 ON dim_detail_core_details.client_code=Milestones.client_code AND dim_detail_core_details.matter_number=Milestones.matter_number

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
'W15526/00000275', 
'POW025/00000423'
) 
--AND fed_code='5900'
AND  ms_fileid NOT IN 
(5090820,5090832,5090835,5090842,5090848,5090853,5091073,5091288,5091677
,5096365,5097171,5097193,5097355,5097677,5097684,5097751,5098182,5098201
,5098209,5098213,5098214,5098218,5098222,5098226,5098228,5098515,5098518
,5098521,5098530,5098898,5099062,5099250,
5097691,5097677,5098182,5098222,5098228) --Old Remedy Cases to exclude per request from Bob H
AND CASE WHEN work_type_name='PL - Pol - CHIS'  AND dim_detail_core_details.is_this_the_lead_file='No' THEN 1 ELSE 0 END=0 -- Filter per #87593
AND ISNULL(dim_detail_core_details.trust_type_of_instruction,'') NOT IN
('In-house: CN','In-house: COP','In-house: EL/PL','In-house: General','In-house: INQ','In-house: Secondment') -- Per #87516
AND ISNULL(fee_arrangement,'') NOT IN ('Internal / No charge','Secondment') --Request 88266

END


GO
