SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*  
=============================================  
Author:   Julie Loughlin  
Create date: 2022-03-30  
Description: Catalina report to drive SSIS report as per ticket #140825
=============================================  
*/

CREATE PROCEDURE  [dbo].[CatalinaComingHearing] --EXEC [dbo].[CatalinaComingHearing] '2022-01-01','2022-12-31'
(
@StartDate AS DATE
,@EndDate AS DATE

)
AS
BEGIN

--DECLARE @StartDate AS DATE 
--DECLARE @EndDate AS DATE
--SET @StartDate='2022-01-01'
--SET @EndDate='2022-03-29'



SELECT
--CASE WHEN insurerclient_reference IS NULL THEN red_dw.dbo.dim_detail_client.zurich_insurer_ref ELSE insurerclient_reference END AS [Zurich Claim Number]
---IIF( dim_client_involvement.client_name LIKE '%Catalina%' AND insuredclient_reference IS NULL ,client_reference, insuredclient_reference)  AS test
CASE WHEN insurerclient_reference IS NOT NULL AND insurerclient_reference NOT LIKE '%Please Notify%'  THEN insurerclient_reference
	  WHEN insurerclient_reference IS NULL THEN red_dw.dbo.dim_detail_client.zurich_insurer_ref
	  WHEN dim_client_involvement.client_name LIKE '%Catalina%' THEN client_reference
	  END AS [Zurich Claim Number]
,CASE WHEN dim_claimant_thirdparty_involvement.claimant_name IS NULL THEN red_dw.dbo.dim_detail_claim.zurich_claimants_name ELSE dim_claimant_thirdparty_involvement.claimant_name END  AS [Claimant]
,zurich_policy_holdername_of_insured AS [Policy Holder]
,branch_name AS [Weightmans Office]
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,master_client_code + ' ' + master_matter_number AS [3E Reference] 
,name AS [Case Handler]
,matter_description AS [Matter Description]
,outcome_of_case AS [Outcome]
,date_of_trial AS [Trial Date]
,trial_window AS [Trial Window]
,CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) AS [Key Date]
,tskDesc AS [Key Date Narrative]
, CASE WHEN CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) >= GETDATE() AND tskComplete=0  AND tskActive=1 THEN 'Live'
ELSE  'Deleted/Completed' END AS [Tab Filter]
,zurich_data_admin_closure_date
,zurich_data_admin_exclude_from_reports
,injury_type_code
, CASE 
	WHEN dim_matter_header_current.date_closed_practice_management IS NULL AND dim_detail_client.zurich_data_admin_closure_date IS NULL THEN
		'Open'
	ELSE
		'Closed'
  END					AS [Status]
,catalinaClaim.is_this_a_catalina_claim_no
,is_there_a_catalina_claim_number_on_this_claim
,insuredclient_reference
,dim_detail_client.zurich_insurer_ref
,insurerclient_reference
,client_reference
,dim_client_involvement.client_name

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.dbo.dbTasks WITH (NOLOCK) ON ms_fileid=dbTasks.fileID
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number 

			 LEFT OUTER JOIN(

							SELECT DISTINCT
							  dim_child_detail.client_code
							, dim_child_detail.matter_number
							, dim_child_detail.is_this_a_catalina_claim_no

						    FROM red_dw.dbo.dim_parent_detail
							INNER JOIN red_dw.dbo.dim_child_detail
							ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key

						    WHERE
							dim_child_detail.is_this_a_catalina_claim_no = 'Yes'
							AND dim_parent_detail.client_code = 'Z1001'
					) AS catalinaClaim
		   ON catalinaClaim.client_code = dim_matter_header_current.client_code
			AND catalinaClaim.matter_number = dim_matter_header_current.matter_number


WHERE 
 
(red_dw.dbo.dim_matter_header_current.client_code = 'W25984')
OR (dim_matter_header_current.client_code = 'Z1001'
AND	is_there_a_catalina_claim_number_on_this_claim = 'Yes')

  
--is_this_a_catalina_claim_no = 'Yes') 





--AND RTRIM(tskDesc) IN 
--(
--'REM: Appeal hearing today [CASE MAN]'
--,'REM: Application hearing date today [CASE MAN]'
--,'REM: CMC today - [CASE MAN]'
--,'REM: Court hearing today [CASE MAN]'
--,'REM: Date of Inquest due today [CASE MAN]'
--,'REM: Detailed assessment hearing today - [CASE MAN]'
--,'REM: Disposal hearing due today [CASE MAN]'
--,'REM: Hearing date today [CASE MAN]'
--,'REM: Infant approval due today [CASE MAN]'
--,'REM: Inquest today [CASE MAN]'
--,'REM: Interlocutory hearing today -?? [CASE MAN]'
--,'REM: Joint settlement meeting due today (CM)'
--,'REM: Preliminary hearing due today - [CASE MAN]'
--,'REM: Small claim track hearing due today - [CM]'
--,'REM: Stage 3 infant approval hearing due today [CM]'
--,'REM: Stage 3 oral hearing due today [CM]'
--,'REM: Trial due today - [CASE MAN]'
--,'Appeal hearing - today'
--,'Application hearing - today'
--,'CMC due - today'
--,'Court hearing due - today'
--,'Inquest date - today'
--,'Detailed assessment hearing due - today'
--,'Disposal hearing due - today'
--,'Hearing ??? today'
--,'Infant approval - today'
--,'Interlocutory hearing - today'
--,'Joint settlement meeting - today'
--,'Preliminary hearing - today'
--,'Small Claim Track hearing due - today'
--,'Stage 3 infant approval hearing - today'
--,'Stage 3 oral hearing - today'
--,'Trial date - today'
--)

AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) BETWEEN @StartDate AND @EndDate
--AND ISNULL(zurich_data_admin_exclude_from_reports,'No')='No'
--AND zurich_data_admin_closure_date IS NULL

 

 END 


		 
GO
