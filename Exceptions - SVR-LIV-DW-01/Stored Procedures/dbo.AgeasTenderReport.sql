SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[AgeasTenderReport]
AS 

BEGIN 
SELECT master_client_code + '-' +master_matter_number AS [Client and matter ref]
,matter_owner_full_name AS[weightmans handler]
,matter_description AS[matter description]
,date_opened_case_management AS [date opened]
,date_closed_case_management AS [date closed]
,dim_detail_core_details.[incident_date] AS [incident date]
,hierarchylevel4hist AS team
,work_type_name AS [matter type]
,dim_detail_core_details.[suspicion_of_fraud] AS [suspicion of fraud]
,dim_detail_core_details.[track] AS track    
,dim_detail_core_details.[credit_hire] AS [credit hire]
,dim_detail_core_details.fixed_fee AS [fixed fee?]--  dim_detail_previous_details[fixed_fee]
,dim_detail_core_details.[proceedings_issued] AS [proceedings issued]
,dim_detail_court.[date_proceedings_issued]  AS [date proceedings issued]
,fact_finance_summary.[damages_reserve]  AS[damages reserve (flag for reserving accuracy)] --  fact_finance_summary[damages_reserve] and highlight red if lower than paid on concluded claims using date claim concluded
,fact_finance_summary.[damages_paid] AS [damages paid]-- fact_finance_summary[damages_paid]
,CASE WHEN date_claim_concluded IS NOT NULL THEN ISNULL(fact_finance_summary.[damages_reserve],0)-ISNULL(fact_finance_summary.[damages_paid],0) END AS [damages saving]-- (calc of paid less spend on claims where date claim concluded is completed)
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [TP costs reserve (flag for reserving accuracy against claimed)]  --fact_detail_reserve_detail[claimant_costs_reserve_current] - highlight red if lower than costs claimed
,fact_finance_summary.[tp_total_costs_claimed] AS [TP costs claimed]--  fact_finance_summary[tp_total_costs_claimed]
,fact_finance_summary.[claimants_costs_paid] AS [TP costs paid]--  fact_finance_summary[claimants_costs_paid]
,(CASE WHEN ISNULL(fact_finance_summary.[tp_total_costs_claimed],0)=0 
THEN ISNULL(fact_detail_reserve_detail.[claimant_costs_reserve_current],0) 
ELSE ISNULL(fact_finance_summary.[tp_total_costs_claimed],0) END) - ISNULL(fact_finance_summary.[claimants_costs_paid],0)  AS [TP costs (saving)]-- claimed less saved  - if claimed is blank use costs reserve. only to be completed on concluded claims
,ISNULL(fact_finance_summary.[damages_reserve],0) + ISNULL(fact_detail_reserve_detail.[claimant_costs_reserve_current],0) AS [Total reserve] -- (Damages and TP)
,ISNULL(fact_finance_summary.[damages_paid],0) + ISNULL(fact_finance_summary.[claimants_costs_paid] ,0)  AS [Total Paid]-- (Damages and TP)
--Total Saving (Damages and TP)
,ISNULL(curHireClaimed,hire_claimed) AS[Hire claimed]-- sorry unable to find the code, this will need adding to the DWH
,ISNULL(curHirePaid,amount_hire_paid) AS [Hire paid]--  - sorry unable to find the code, this will need adding to the DWH
,fact_finance_summary.[defence_costs_reserve] AS [Defence costs reserve (flag for reserving accuracy)] 
,total_amount_billed AS [Billed]
,wip AS WIP
,ISNULL(total_amount_billed,0) + ISNULL(wip,0) AS [Total billed + WIP]
,dim_detail_outcome.[date_claim_concluded] AS [date claim concluded]
,dim_detail_outcome.[outcome_of_case] AS [outcome]
,dim_detail_outcome.[are_we_pursuing_a_recovery] AS [pursuing a recovery]-- dim_detail_outcome[are_we_pursuing_a_recovery]
,[total recovery £]= (ISNULL(fact_detail_recovery_detail.[recovery_claimants_damages_claimant],0)
+ISNULL(fact_detail_recovery_detail.[recovery_damages_counterclaim_claimant],0)
+ISNULL(fact_detail_recovery_detail.[recovery_damages_counterclaim_third_party],0)
+ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)
+ISNULL(dim_detail_outcome.[recovery_claimants_our_client_damages],0)
+ISNULL(fact_detail_recovery_detail.[recovery_claimants_our_client_costs],0)
+ISNULL(fact_finance_summary.[recovery_defence_costs_from_claimant],0)
+ISNULL(fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution],0)
+ISNULL(fact_finance_summary.[recovery_defence_costs_via_third_party_contribution],0))
,elapsed_days_live_files AS [elapsed days live files]
,DATEDIFF(DAY,date_opened_case_management,dim_detail_core_details.date_proceedings_issued) AS [elapsed days to issues]
,DATEDIFF(DAY,incident_date,date_opened_case_management) AS [elapsed days incident date to date opened]
,DATEDIFF(DAY,incident_date,dim_detail_core_details.date_proceedings_issued) AS [elapsed days incident date to date proceedings issued]
,dim_detail_claim.[name_of_instructing_insurer] 
,dim_detail_core_details.referral_reason AS [Referral Reason]
,hierarchylevel3hist AS [Department]
,COALESCE(dim_detail_fraud.[fraud_type_motor], dim_detail_fraud.[fraud_type_casualty], dim_detail_fraud.[fraud_type_disease]) AS [Fraud type]
,defence_costs_billed AS [Revenue]
	   ,

CASE WHEN (outcome_of_case LIKE 'Discontinued%') OR (outcome_of_case IN
(
'Rejected (MIB untraced only)                                ',
'struck out                                                  ',
'won at trial                                                ',
'Struck Out                                                  ',
'Struck out                                                  ',
'Won At Trial                                                ',
'Won at Trial                                                ',
'Won at trial                                                '
, 'Withdrawn'
)) THEN 'Repudiated'


WHEN
((LOWER(outcome_of_case) LIKE 'settled%' ) OR (outcome_of_case IN
(
'Assessment of damages',
'Assessment of damages (damages exceed claimant''s P36 offer) ',
'Lost at Trial                                               ',
'Lost at trial                                               ',
'Lost at trial (damages exceed claimant''s P36 offer)         ',
'Settled',
'Settled  - claimant accepts P36 offer out of time',
'Settled - Infant Approval                                   ',
'Settled - Infant approval                                   ',
'Settled - JSM',
'Settled - Mediation                                         ',
'Settled - mediation                                         '
))) THEN 'Paid'
 

 WHEN 
 outcome_of_case 
 IN
(
'Appeal',
'Assessment of damages (claimant fails to beat P36 offer)    ',
'Exclude from reports                                        ',
'Returned to Client', 'Other', 'Exclude from Reports   ', 'Other'
) THEN 'Other' END AS [Repudiated/Paid]

,DueDate AS [Ddefence due key date]
,[Interim damages paid] =fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction]
,[date instructions received] =  dim_detail_core_details.[date_instructions_received]
,[Fixed fee]= dim_detail_core_details.[fixed_fee]
,[Fixed fee amount]= fact_finance_summary.[fixed_fee_amount]

FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
 ON dim_detail_fraud.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim WITH(NOLOCK)
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail WITH(NOLOCK)
 ON   fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days WITH(NOLOCK)
 ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail WITH(NOLOCK)
 ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details WITH(NOLOCK)
ON dim_detail_hire_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK)
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court WITH(NOLOCK)
ON  dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN ms_prod.dbo.udMIHire
 ON ms_fileid=fileID
LEFT OUTER JOIN (SELECT fileID,MIN(tskDue) AS DueDate FROM ms_prod.dbo.dbTasks
WHERE tskDesc LIKE '%Defence due - today%'
AND tskActive=1 GROUP BY fileID) AS Defendue
 ON Defendue.fileID = ms_fileid
WHERE master_client_code='A3003'
AND date_opened_case_management>='2018-01-01'
AND ISNULL(name_of_instructing_insurer,'') <>'Tesco Underwriting (TU)'
AND reporting_exclusions=0
AND ISNULL(outcome_of_case,'')<>'Returned to Client'

END 
GO
