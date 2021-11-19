SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[GoAheadClientDashboard]

AS 

BEGIN

SELECT master_client_code + '-' + master_matter_number AS [master_client_matter_combined]            
,dim_client_involvement.[insurerclient_reference] AS [GAG Op.Company Ref]
,dim_client_involvement.[insuredclient_reference]
,dim_client_involvement.[insuredclient_name]
,dim_matter_header_current.[client_code]
,dim_matter_header_current.[matter_number]
,dim_detail_core_details.[incident_date] AS [Date Of Accident]
,date_opened_case_management AS [Date Case Opened] 
,dim_detail_outcome.[date_claim_concluded] AS [Date Case Concluded]
,dim_detail_core_details.[date_instructions_received]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings issued]
,dim_detail_core_details.[track] AS [Track]
,dim_detail_core_details.[referral_reason] AS [Referral Reason]
,dim_detail_core_details.[is_there_an_issue_on_liability] AS [Is there an issue on liability]
, dim_detail_outcome.[outcome_of_case] AS Outcome
,dim_detail_court.[date_of_trial] AS [Date of Trial]
,fact_finance_summary.[damages_paid] AS [Damages Paid]
,fact_finance_summary.[claimants_costs_paid]
,fact_finance_summary.[claimants_solicitors_disbursements_paid]
,defence_costs_billed AS [Own Solicitors Fees]
,date_closed_case_management AS [Date Closed]
,dim_detail_core_details.[grpageas_motor_moj_stage]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursements_billed]
,fact_finance_summary.[recovery_defence_costs_from_claimant]
,fact_finance_summary.[recovery_defence_costs_via_third_party_contribution]
,fact_detail_paid_detail.[vat_amount]
,dim_experts_involvement.[counsel_name]
,fact_detail_recovery_detail.[costs_recovered]
,fact_finance_summary.[total_costs_paid]
,fact_finance_summary.[total_costs_recovery] AS [Costs Recovered]
,fact_detail_paid_detail.[total_damages_paid] AS [Cost of TP Indemnity]
,fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Cost of TP Legal Costs]
,defence_costs_billed AS [Total (Net of VAT)]
,[Chambers & Barrister Fees]
,(ISNULL(defence_costs_billed,0) + ISNULL(disbursements_billed,0) ) - ISNULL(ChamberFees.[Chambers & Barrister Fees],0) AS [Own Solicitors Fees (excl VAT and Chambers & Barrister Fees)]
,[Settled Pre Trail]= CASE WHEN outcome_of_case IN ('Won at trial','Lost at trial','Struck out') THEN 'N'ELSE  'Y' END

,[Categories]= CASE WHEN dim_detail_core_details.[track] = 'Small Claims' THEN 'Small Claims'
WHEN dim_detail_core_details.[track] = 'Multi Track' THEN 'Multi Track'
WHEN dim_detail_core_details.[track] = 'Fast Track' THEN 'Fast Track'
WHEN dim_detail_core_details.[grpageas_motor_moj_stage] IS NULL THEN 'MOJ'
WHEN dim_detail_core_details.[referral_reason] IN ('Infant Approval', 'Inquest Criminal Hearing') OR dim_detail_core_details.[track] ='Pre-Action Disclosure' THEN 'OTHER' END 


,[Small Claims]= CASE WHEN dim_detail_core_details.[track] = 'Small Claims' THEN  'Y' ELSE  '-' END
,[Multi Track]= CASE WHEN dim_detail_core_details.[track] = 'Multi Track' THEN 'Y' ELSE '-' END
,[Fast Track]= CASE WHEN dim_detail_core_details.[track] = 'Fast Track' THEN 'Y'ELSE '-' END
,[Infant Approval]= CASE WHEN dim_detail_core_details.[referral_reason]='Infant Approval' THEN 'Y' ELSE '-' END
,[Inquest]= CASE WHEN dim_detail_core_details.[referral_reason]='Inquest Criminal Hearing' THEN 'Y' ELSE '-' END
,[Pre- Disclousre Action]= CASE WHEN dim_detail_core_details.[track] = 'Pre-Action Disclosure' THEN 'Y' ELSE '-'END
,[If Y Then on small track Cases which stage settled]= CASE WHEN dim_detail_core_details.[track] = 'Small Claims' THEN dim_detail_core_details.[grpageas_motor_moj_stage] END
,[If Y Then on Fast Track  Cases which stage settled]=CASE WHEN dim_detail_core_details.[track] = 'Fast Track' THEN dim_detail_core_details.[grpageas_motor_moj_stage]END
,[Trail won]= CASE WHEN dim_detail_outcome.[outcome_of_case] = 'Won at trial' THEN 'Yes'
WHEN dim_detail_outcome.[outcome_of_case] = 'Lost at trial' THEN 'No' ELSE  '-' END
,[Claim Discontinued Struck Out]= CASE WHEN dim_detail_outcome.[outcome_of_case] IN ('Discontinued - post-lit with costs order','Discontinued','Discontinued - pre-lit','Struck out') THEN 'Y' ELSE 'No' END 
,[Third Party Legal Costs & Disbursements paid]= ISNULL(fact_finance_summary.[claimants_costs_paid],0) + ISNULL(fact_finance_summary.[claimants_solicitors_disbursements_paid],0)
,[Comments]= CASE WHEN date_closed_case_management IS NOT NULL THEN 'Concluded'   END
,[Status] = CASE WHEN date_closed_practice_management IS NULL THEN 'Live' ELSE 'Closed' END 
,[MOJ] =CASE WHEN dim_detail_core_details.[grpageas_motor_moj_stage] IS NULL THEN 'N' ELSE  dim_detail_core_details.[grpageas_motor_moj_stage] END
,[Life Span]= DATEDIFF(DAY,ISNULL(date_instructions_received,date_opened_case_management),date_claim_concluded)
,[Solicitor Reference]= RTRIM(dim_matter_header_current.client_code) +'/'+ RTRIM(dim_matter_header_current.[matter_number])
,[REF]= UPPER(LEFT(dim_client_involvement.[insuredclient_reference], 3))
,[Postcode] 
,ISNULL([Depot],'Other') AS Depot
,[Operating Company]
,Maps.Longitude
,Maps.Latitude
,damages_reserve_initial AS [Damages Reserve Initial]
,defence_costs_reserve_initial AS [Defence Cost Reserve Initial]
,tp_costs_reserve_initial AS [Claimants Cost Reseve Initial]
,brief_description_of_injury AS injury_type
,((ISNULL(defence_costs_billed,0) + ISNULL(disbursements_billed,0) ) - ISNULL(ChamberFees.[Chambers & Barrister Fees],0)
) + ISNULL(ChamberFees.[Chambers & Barrister Fees],0) 
+ ISNULL(fact_finance_summary.[total_costs_recovery],0)
+ISNULL(fact_finance_summary.damages_paid,0) 
+(ISNULL(fact_finance_summary.[claimants_costs_paid],0) + ISNULL(fact_finance_summary.[claimants_solicitors_disbursements_paid],0))
AS [Total Cost]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
 ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement 
 ON dim_experts_involvement.client_code = dim_matter_header_current.client_code
 AND dim_experts_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.dim_matter_header_curr_key,SUM(bill_total_excl_vat) AS [Chambers & Barrister Fees]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_cost_type
 ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
WHERE cost_type_description='Counsel'
AND client_group_code='00000126'
AND charge_type='disbursements'
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS ChamberFees
 ON ChamberFees.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN Reporting.dbo.GoAheadDepots  ON GoAheadDepots.Ref=UPPER(LEFT(dim_client_involvement.[insuredclient_reference], 3)) COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT Ref,Longitude,Latitude FROM red_dw.dbo.Doogal
INNER JOIN Reporting.dbo.GoAheadDepots
 ON GoAheadDepots.Postcode = Doogal.Postcode COLLATE DATABASE_DEFAULT
 ) AS Maps
  ON Maps.Ref=UPPER(LEFT(dim_client_involvement.[insuredclient_reference], 3)) COLLATE DATABASE_DEFAULT
 WHERE client_group_code = '00000126'
AND ISNULL(outcome_of_case,'')<> 'Exclude from reports'
AND ISNULL(dim_client_involvement.[insuredclient_name],'') <> 'Avis Budget UK'
AND dim_matter_header_current.matter_number <>'ML'
AND incident_date>='2012-06-30'
AND master_client_code + '-' + master_matter_number <>'W15492-1455'
--AND RTRIM(dim_matter_header_current.client_code) +'/'+ RTRIM(dim_matter_header_current.[matter_number])='00065232/00001259'

END
GO
