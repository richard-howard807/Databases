SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[TechnicalChecklistMotor]

AS 

BEGIN
SELECT dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
,matter_description 
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS matter_owner_full_name
,fed_code
,red_dw.dbo.datetimelocal(tskDue) AS tskDue
,red_dw.dbo.datetimelocal(tskCompleted) AS tskCompleted
,tskActive
,tskDesc
,CASE WHEN tskCompleted IS NULL AND tskActive=1 THEN 1 ELSE 0 END AS [ProcessDue]
,CASE WHEN tskCompleted IS NOT NULL AND tskActive=1 THEN 1 ELSE 0 END AS [ProcessCompleted]
,1 AS [Number]
,CASE WHEN cboCLNotInd='Y' THEN 'Yes' WHEN cboCLNotInd='N' THEN 'No' ELSE cboCLNotInd END AS [Has the insurer client told us they are not providing an indemnity e.g. said they are RTA or Article 75 insurer?]
,CASE WHEN cboIssDrCov='Y' THEN 'Yes' WHEN cboIssDrCov='N' THEN 'No' ELSE cboIssDrCov END AS [Is there and issue over the driver being covered by the client’s policy e.g. driver is not a named driver on the policy?]
,CASE WHEN cboIssVehCov='Y' THEN 'Yes' WHEN cboIssVehCov='N' THEN 'No' ELSE cboIssVehCov END AS [Is there an issue over the vehicle being covered by the client’s policy]
,CASE WHEN cboIssInsVeh='Y' THEN 'Yes' WHEN cboIssInsVeh='N' THEN 'No' ELSE cboIssInsVeh END  AS [Is there an issue over the use of the insured vehicle being covered by the terms of the policy]
,CASE WHEN cboSugBrePol='Y' THEN 'Yes' WHEN cboSugBrePol='N' THEN 'No' ELSE cboSugBrePol END  AS [Is there a suggested breach of policy terms and conditions e.g. late reporting of accident?]
,CASE WHEN cboAccPrivLand='Y' THEN 'Yes' WHEN cboAccPrivLand='N' THEN 'No' ELSE cboAccPrivLand END  AS [Was the accident arguably on private land e.g. in a private car park, or on business premises?]
,CASE WHEN cboAnOthIns='Y' THEN 'Yes' WHEN cboAnOthIns='N' THEN 'No' ELSE cboAnOthIns END  AS [Is there another insurer (in addition to the client) for the at-fault vehicle]
,CASE WHEN cboAnoInsParty='Y' THEN 'Yes' WHEN cboAnoInsParty='N' THEN 'No' ELSE cboAnoInsParty END  AS [Is there another insured party who might be partially or wholly to blame?]
,CASE WHEN cboEleSubLoss='Y' THEN 'Yes' WHEN cboEleSubLoss='N' THEN 'No' ELSE cboEleSubLoss END  AS [Is there an element of subrogated losses or losses that could have been claimed from the claimant’s own insurer]
,CASE WHEN cboInsSpecAdvDi='Y' THEN 'Yes' WHEN cboInsSpecAdvDi='N' THEN 'No' ELSE cboInsSpecAdvDi END  AS [Have we been instructed specifically to advise in relation to a dispute or potential dispute between the client and MIB?]
,CASE WHEN cboInsSpecAdvIn='Y' THEN 'Yes' WHEN cboInsSpecAdvIn='N' THEN 'No' ELSE cboInsSpecAdvIn END  AS [Have we been instructed specifically to advise on the insurer status and the implications?]
,CASE WHEN cboInsRelTech='Y' THEN 'Yes' WHEN cboInsRelTech='N' THEN 'No' ELSE cboInsRelTech END  AS [Have we been instructed in relation to a Technical Committee / arbitration dispute?]
,CASE WHEN cboPolCanAv='Y' THEN 'Yes' WHEN cboPolCanAv='N' THEN 'No' ELSE cboPolCanAv END  AS [Has the policy been cancelled or avoided, or has the vehicle been sold prior to the accident?]
,curTotalTech AS [Total Score]
,work_type_group
,CASE WHEN cboCLNotInd IS NULL  AND cboIssDrCov IS NULL AND cboIssVehCov IS NULL
AND cboIssInsVeh IS NULL AND cboSugBrePol IS NULL AND cboAccPrivLand IS NULL
AND cboAnOthIns IS NULL AND cboAnoInsParty IS NULL AND cboEleSubLoss IS NULL
AND cboInsSpecAdvDi IS NULL AND cboInsSpecAdvIn IS NULL AND cboInsRelTech IS NULL
AND cboPolCanAv IS NULL THEN 1 ELSE 0 END  AS ScoreISBlank
,CASE WHEN cboInsSpecAdvDi ='Y' OR cboInsSpecAdvIn ='Y' OR cboInsRelTech ='Y' OR cboPolCanAv=  'Y' THEN 1  
WHEN (CASE WHEN cboCLNotInd='Y' THEN 1 ELSE 0 END  + 
CASE WHEN cboIssDrCov='Y' THEN 1 ELSE 0 END + 
CASE WHEN cboIssVehCov='Y' THEN 1 ELSE 0 END +
CASE WHEN cboIssInsVeh='Y' THEN 1 ELSE 0 END +
CASE WHEN cboSugBrePol='Y' THEN 1 ELSE 0 END)>=1 AND 
(CASE WHEN cboAccPrivLand='Y' THEN 1 ELSE 0 END  + 
 CASE WHEN cboAnOthIns='Y' THEN 1 ELSE 0 END  + 
  CASE WHEN cboAnoInsParty='Y' THEN 1 ELSE 0 END  + 
   CASE WHEN cboEleSubLoss='Y' THEN 1 ELSE 0 END)>=1 THEN 1 
ELSE 0 

END AS Indemnity 
,CASE WHEN cboInsSpecAdvDi ='Y' OR cboInsSpecAdvIn ='Y' OR cboInsRelTech ='Y' OR cboPolCanAv=  'Y' THEN 0  
WHEN (CASE WHEN cboCLNotInd='Y' THEN 1 ELSE 0 END  + 
CASE WHEN cboIssDrCov='Y' THEN 1 ELSE 0 END + 
CASE WHEN cboIssVehCov='Y' THEN 1 ELSE 0 END +
CASE WHEN cboIssInsVeh='Y' THEN 1 ELSE 0 END +
CASE WHEN cboSugBrePol='Y' THEN 1 ELSE 0 END)>=1 AND 
(CASE WHEN cboAccPrivLand='Y' THEN 1 ELSE 0 END  + 
 CASE WHEN cboAnOthIns='Y' THEN 1 ELSE 0 END  + 
  CASE WHEN cboAnoInsParty='Y' THEN 1 ELSE 0 END  + 
   CASE WHEN cboEleSubLoss='Y' THEN 1 ELSE 0 END)>=1 THEN 0
ELSE 1

END AS Nonindemnity 
,CASE WHEN cboCLNotInd='Y' THEN 1 ELSE 0 END  + 
CASE WHEN cboIssDrCov='Y' THEN 1 ELSE 0 END + 
CASE WHEN cboIssVehCov='Y' THEN 1 ELSE 0 END +
CASE WHEN cboIssInsVeh='Y' THEN 1 ELSE 0 END +
CASE WHEN cboSugBrePol='Y' THEN 1 ELSE 0 END  AS Section1

, CASE WHEN cboAccPrivLand='Y' THEN 1 ELSE 0 END  + 
 CASE WHEN cboAnOthIns='Y' THEN 1 ELSE 0 END  + 
  CASE WHEN cboAnoInsParty='Y' THEN 1 ELSE 0 END  + 
   CASE WHEN cboEleSubLoss='Y' THEN 1 ELSE 0 END   AS Section2

 ,referral_reason

 ,DATEDIFF(DAY,date_opened_case_management,GETDATE()) AS DateOpenedRange







FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT JOIN ms_prod.dbo.dbTasks 
 ON  ms_fileid=dbTasks.fileid AND tskFilter='tsk_01_02_010_TechCheckMot '
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number

 LEFT OUTER JOIN ms_prod.dbo.udTechMotor ON ms_fileid=udTechMotor.fileID

WHERE 
(work_type_group='Motor'
AND date_opened_case_management>='2021-03-01'
) 
AND reporting_exclusions=0
AND referral_reason LIKE 'Dispute%'
AND DATEDIFF(DAY,date_opened_case_management,GETDATE())>14


END
GO
