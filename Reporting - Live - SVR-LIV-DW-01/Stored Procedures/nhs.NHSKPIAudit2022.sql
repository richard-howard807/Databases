SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- LD 20190809 Amended to wrap the audit date with the [datetimelocal] function
--				Amended so that only the last audit date is shown

CREATE PROCEDURE [nhs].[NHSKPIAudit2022] --EXEC [nhs].[NHSKPIAudit2022] '2022-03-01','2022-03-22'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS

-- for testing purposes
--DECLARE @StartDate AS DATE = '20220601'
--, @EndDate AS DATE = '20220722'

-- used to set fin year headings for NHSR MI Dashboard report
DECLARE @current_fin_year AS INT = (SELECT DISTINCT dim_date.fin_year FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = @EndDate)
DECLARE @previous_fin_year AS INT = @current_fin_year - 1

BEGIN
SELECT dim_detail_health.[nhs_type_of_instruction_billing] AS [Worktype]
,CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END  AS [NHSR Ref]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number)  AS [Weightmans reference AS [Panel Ref]
,[name] AS [Panel fee earner]
,dim_detail_health.[nhs_scheme] AS [Scheme]
,hierarchylevel4hist [Team]
--,dim_detail_health.nhs_damages_tranche AS [Damages Tranche]
,
CASE 
WHEN 
dim_detail_health.[nhs_is_this_a_ppo_matter] = 'Yes' THEN '£500,001 and above'

WHEN
 LOWER(dim_detail_outcome.outcome_of_case) LIKE '%discontinued%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%won%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%struck%' THEN '£0 to £25,000'



WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

  BETWEEN' 0'AND '25000' THEN '£0 to £25,000'
 
WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

  BETWEEN '25001'AND '50000' THEN '£25,001 to £50,000'
 
WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

BETWEEN   '50001' AND '100000' THEN '£50,001 to £100,000'


 
WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

 BETWEEN '100001' AND '500000' THEN '£100,001 to £500,000'

 WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

>= '500001' THEN '£500,001 and above'


WHEN 
(dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN' 0'AND '25000' THEN '£0 to £25,000'

 WHEN 
(dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN '25001'AND '50000' THEN '£25,001 to £50,000'

 WHEN 
 (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN '50001' AND '100000' THEN '£50,001 to £100,000'

 WHEN 
  (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN '100001' AND '500000' THEN '£100,001 to £500,000'

 WHEN 
   (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )>= '500001' THEN '£500,001 and above'
  

WHEN 
(dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) BETWEEN' 0'AND '25000' THEN '£0 to £25,000'

 WHEN 
(dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) BETWEEN '25001'AND '50000' THEN '£25,001 to £50,000'

 WHEN 
 (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) BETWEEN '50001' AND '100000' THEN '£50,001 to £100,000'

 WHEN 
  (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0)  ) BETWEEN '100001' AND '500000' THEN '£100,001 to £500,000'

 WHEN 
   (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) >= '500001' THEN '£500,001 and above'


ELSE '-' END AS [Damages Tranche]
,dim_detail_core_details.[date_instructions_received] AS [Instruction date]




,[red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) AS [Audit Date]
,AuditComments.nhs_audit_date
,AuditComments.nhs_auditor_comments
, 'Q' + TRIM(STR(dim_date.fin_quarter_no))		AS fin_quarter_formatted
, CASE
	WHEN dim_date.current_fin_year = 'Current' THEN
		'Q' + TRIM(STR(dim_date.fin_quarter_no)) + ' ' + TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2)))	
	ELSE
		'Q' + TRIM(STR(dim_date.fin_quarter_no)) + ' ' + TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))
  END				AS quarter_headings
, TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2)))		AS current_fin_year_formatted
, TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))	AS previous_fin_year_formatted
, dim_date.current_fin_year

,nhs_correct_costs_scheme AS [Correct costs scheme?]
,nhs_proactivity_on_file AS [Proactivity on File?]
,CASE WHEN nhs_damages_reserve_accurate = 'Not applicable' THEN 'N/A' ELSE nhs_damages_reserve_accurate END AS [Damages reserve accurate?]
,CASE WHEN nhs_c_costs_reserve_accurate  = 'Not applicable' THEN 'N/A' ELSE nhs_c_costs_reserve_accurate END AS [C Costs reserve accurate?]
,CASE WHEN nhs_d_costs_reserve_accurate = 'Not applicable' THEN 'N/A' ELSE nhs_d_costs_reserve_accurate END AS [D Costs reserve accurate?]
,CASE WHEN nhs_probabilty_reserve_accurate = 'Not applicable' THEN 'N/A' ELSE nhs_probabilty_reserve_accurate END  AS [Probabilty reserve accurate?]
,CASE WHEN nhs_esd_reserve_accurate = 'Not applicable' THEN 'N/A' ELSE nhs_esd_reserve_accurate END AS [ESD reserve accurate?]
,CASE WHEN nhs_breach_of_duty_decision_correct  = 'Not applicable' THEN 'N/A' ELSE nhs_breach_of_duty_decision_correct END AS [Breach of duty decision correct?]
,CASE WHEN nhs_causation_decision_correct = 'Not applicable' THEN 'N/A' ELSE nhs_causation_decision_correct END AS [Causation decision correct?]
,CASE WHEN nhs_correct_choice_of_expert = 'Not applicable' THEN 'N/A' ELSE nhs_correct_choice_of_expert END AS [Correct choice of expert?]
,CASE WHEN nhs_supervisory_process_followed = 'Not applicable' THEN 'N/A' ELSE nhs_supervisory_process_followed END AS [Supervisory process followed?]
,CASE WHEN nhs_sla_instructions_ack_in_48_hours = 'Not applicable' THEN 'N/A' ELSE nhs_sla_instructions_ack_in_48_hours END  AS [SLA: Instructions ack in 48 hours?]
,CASE WHEN nhs_sla_first_report_deadline_met = 'Not applicable' THEN 'N/A' ELSE nhs_sla_first_report_deadline_met END  AS [SLA: First report deadline met?]
,CASE WHEN nhs_sla_follow_up_report_deadlines_met = 'Not applicable' THEN 'N/A' ELSE nhs_sla_follow_up_report_deadlines_met END AS [SLA: Follow up report deadlines met?]
,CASE WHEN nhs_sla_pre_trial_report_deadline_met = 'Not applicable' THEN 'N/A' ELSE nhs_sla_pre_trial_report_deadline_met END  AS [SLA: Pre-trial report deadline met?]
,CASE WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met = 'Not applicable' THEN 'N/A' ELSE nhs_sla_advice_on_claimant_p36_offer_deadline_met END AS [SLA: Advice on claimant P36 offer deadline met?]
,CASE WHEN nhs_advice_contains_all_required_fields_quality = 'Not applicable' THEN 'N/A' ELSE nhs_advice_contains_all_required_fields_quality END AS [Advice contains all required fields/quality?]
,CASE WHEN nhs_court_deadlines_met = 'Not applicable' THEN 'N/A' ELSE nhs_court_deadlines_met END  AS [Court deadlines met?]
,CASE WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate  = 'Not applicable' THEN 'N/A' ELSE nhs_internal_and_nhsr_cms_consistent_and_accurate END AS [Internal and NHSR CMS consistent and accurate?]
,fact_child_detail.nhs_hard_leakage_quantified_at AS [Hard Leakage quantified at £]
,nhs_soft_leakage_difficult_unable_to_quantify AS [Soft Leakage -difficult/unable to quantify]
,nhs_reasons_for_leakage AS [Reasons for leakage]

---------------SCORING ---------------------------------



,CASE WHEN nhs_correct_costs_scheme='Not applicable' THEN 0 ELSE 1 END 
+ CASE WHEN nhs_proactivity_on_file ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_damages_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_c_costs_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_d_costs_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_probabilty_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_esd_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_breach_of_duty_decision_correct ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_causation_decision_correct ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_correct_choice_of_expert ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_supervisory_process_followed ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_sla_instructions_ack_in_48_hours ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_sla_first_report_deadline_met ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_sla_follow_up_report_deadlines_met ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_sla_pre_trial_report_deadline_met ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_advice_contains_all_required_fields_quality ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_court_deadlines_met ='Not applicable' THEN 0 ELSE 1 END
+ CASE WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate ='Not applicable' THEN 0 ELSE 1 END
+ 1 -- Hard Leakage
+ CASE WHEN nhs_soft_leakage_difficult_unable_to_quantify ='Not applicable' THEN 0 ELSE 1 END 

/* Added 20220707 - MT*/
+ CASE WHEN nhsr_steps_to_avoid_litigation  ='Not applicable' THEN 0 ELSE 1 END 
+ CASE WHEN panel_steps_to_avoid_litigation ='Not applicable' THEN 0 ELSE 1 END  
+ CASE WHEN adr_considered ='Not applicable' THEN 0 ELSE 1 END  
+ CASE WHEN adr_appropriate_time ='Not applicable' THEN 0 ELSE 1 END  


AS [Possible Points]

,CASE WHEN nhs_correct_costs_scheme IN ('Not applicable','No') THEN 0 
WHEN nhs_correct_costs_scheme ='Partial' THEN 0.5
ELSE 1 END 
+ CASE WHEN nhs_proactivity_on_file IN ('Not applicable','No') THEN 0 
WHEN nhs_proactivity_on_file ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_damages_reserve_accurate IN ('Not applicable','No') THEN 0 
WHEN nhs_damages_reserve_accurate ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_c_costs_reserve_accurate IN ('Not applicable','No') THEN 0 
WHEN nhs_c_costs_reserve_accurate ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_d_costs_reserve_accurate IN ('Not applicable','No') THEN 0 
WHEN nhs_d_costs_reserve_accurate ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_probabilty_reserve_accurate IN ('Not applicable','No') THEN 0 
WHEN nhs_probabilty_reserve_accurate='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_esd_reserve_accurate IN ('Not applicable','No') THEN 0 
WHEN nhs_esd_reserve_accurate ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_breach_of_duty_decision_correct IN ('Not applicable','No') THEN 0 
WHEN nhs_breach_of_duty_decision_correct ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_causation_decision_correct IN ('Not applicable','No') THEN 0 
WHEN nhs_causation_decision_correct ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_correct_choice_of_expert IN ('Not applicable','No') THEN 0 
WHEN nhs_correct_choice_of_expert ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_supervisory_process_followed IN ('Not applicable','No') THEN 0 
WHEN nhs_supervisory_process_followed ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_sla_instructions_ack_in_48_hours IN ('Not applicable','No') THEN 0 
WHEN nhs_sla_instructions_ack_in_48_hours  ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_sla_first_report_deadline_met IN ('Not applicable','No') THEN 0 
WHEN nhs_sla_first_report_deadline_met ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_sla_follow_up_report_deadlines_met IN ('Not applicable','No') THEN 0 
WHEN nhs_sla_follow_up_report_deadlines_met ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_sla_pre_trial_report_deadline_met IN ('Not applicable','No') THEN 0 
 WHEN nhs_sla_pre_trial_report_deadline_met ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met IN ('Not applicable','No') THEN 0 
WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_advice_contains_all_required_fields_quality IN ('Not applicable','No') THEN 0 
WHEN nhs_advice_contains_all_required_fields_quality ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_court_deadlines_met IN ('Not applicable','No') THEN 0 
WHEN nhs_court_deadlines_met ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate IN ('Not applicable','No') THEN 0 
 WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN fact_child_detail.nhs_hard_leakage_quantified_at <>0 THEN 0 ELSE 1 END 
+ CASE WHEN nhs_soft_leakage_difficult_unable_to_quantify  IN ('Not applicable','No') THEN 1 
WHEN nhs_soft_leakage_difficult_unable_to_quantify ='Partial' THEN 0.5 ELSE 0 END

/* Added 20220707 - MT*/
+CASE WHEN nhsr_steps_to_avoid_litigation IN ('Not applicable','No') THEN 0 
 WHEN nhsr_steps_to_avoid_litigation ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN panel_steps_to_avoid_litigation IN ('Not applicable','No') THEN 0 
 WHEN panel_steps_to_avoid_litigation ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN adr_considered IN ('Not applicable','No') THEN 0 
 WHEN adr_considered ='Partial' THEN 0.5
ELSE 1 END
+ CASE WHEN adr_appropriate_time IN ('Not applicable','No') THEN 0 
 WHEN adr_appropriate_time ='Partial' THEN 0.5
ELSE 1 END

 AS [Total Points]


,[Auditee 1] = dim_child_detail.[nhs_auditee_1]
,[Auditee 2] = dim_child_detail.[nhs_auditee_2]
,[Auditor Comments] = dim_detail_compliance.[auditcomments]

, CASE WHEN nhsr_steps_to_avoid_litigation = 'Not applicable' THEN 'N/A' ELSE nhsr_steps_to_avoid_litigation END AS [Did NHSR take steps to avoid Litigation?]
, CASE WHEN panel_steps_to_avoid_litigation = 'Not applicable' THEN 'N/A' ELSE panel_steps_to_avoid_litigation END AS [Did Panel take steps to avoid Litigation?]
, CASE WHEN who_was_responsible_for_delays = 'Not applicable' THEN 'N/A' ELSE who_was_responsible_for_delays END AS [Who was responsible for the delays?]
, CASE WHEN covid_direct_reported = 'Not applicable' THEN 'N/A' ELSE covid_direct_reported END AS [Is the case a covid direct case and reported as such?]
, CASE WHEN covid_indirect_reported = 'Not applicable' THEN 'N/A' ELSE covid_indirect_reported END AS [Does the case have covid indirect elements and reported as such?]
, CASE WHEN adr_considered = 'Not applicable' THEN 'N/A' ELSE adr_considered END AS [ADR: Has it been considered?]
, CASE WHEN adr_appropriate_time = 'Not applicable' THEN 'N/A' ELSE adr_appropriate_time END AS [ADR: was it considered at appropriate time?]

, CASE WHEN appropriate_delegation = 'Not applicable' THEN 'N/A' ELSE appropriate_delegation END AS [Appropriate delegation?]
, CASE WHEN magic_phone_call = 'Not applicable' THEN 'N/A' ELSE magic_phone_call END AS [Was there a magic phone call?]
, CASE WHEN proactive_approval_np_sca = 'Not applicable' THEN 'N/A' ELSE proactive_approval_np_sca END AS [Proactive approval by NP / SCA?]
,[Naming conventions used?] = cboNameConvUsed.cdDesc	
,[Misfiled / inappropriate content?] = cboMisfiledInap.cdDesc


FROM red_dw.dbo.dim_parent_detail
INNER JOIN red_dw.dbo.dim_child_detail ON dim_child_detail.case_id = dim_parent_detail.case_id
AND dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
LEFT OUTER JOIN red_dw.dbo.fact_child_detail ON fact_child_detail.case_id = dim_child_detail.case_id
AND fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key

INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_parent_detail.client_code
 AND dim_matter_header_current.matter_number = dim_parent_detail.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_core_details 
 ON dim_detail_core_details.client_code = dim_parent_detail.client_code
 AND dim_detail_core_details.matter_number = dim_parent_detail.matter_number 
INNER JOIN red_dw.dbo.dim_detail_health 
 ON dim_detail_health.client_code = dim_parent_detail.client_code
 AND dim_detail_health.matter_number = dim_parent_detail.matter_number 
INNER JOIN red_dw.dbo. fact_detail_client
 ON fact_detail_client.client_code = dim_parent_detail.client_code
 AND fact_detail_client.matter_number = dim_parent_detail.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_parent_detail.client_code
 AND dim_client_involvement.matter_number = dim_parent_detail.matter_number

 LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_parent_detail.client_code
 AND dim_detail_outcome.matter_number = dim_parent_detail.matter_number

  LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_parent_detail.client_code
 AND fact_detail_paid_detail.matter_number = dim_parent_detail.matter_number
 
   LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_parent_detail.client_code
 AND fact_detail_reserve_detail.matter_number = dim_parent_detail.matter_number
 
    LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_parent_detail.client_code
 AND fact_finance_summary.matter_number = dim_parent_detail.matter_number
 
 INNER JOIN ( SELECT client_code,matter_number,MAX(nhs_audit_date) nhs_audit_date 
				FROM red_dw.dbo.dim_parent_detail 
				WHERE [red_dw].[dbo].[datetimelocal](nhs_audit_date) BETWEEN @StartDate AND @EndDate

				GROUP BY client_code,matter_number ) max_date ON max_date.client_code = dim_parent_detail.client_code
				AND max_date.matter_number = dim_parent_detail.matter_number
				AND max_date.nhs_audit_date = dim_parent_detail.nhs_audit_date
LEFT OUTER JOIN red_dw.dbo.dim_date
	ON CAST([red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) AS DATE) = dim_date.calendar_date
LEFT OUTER JOIN (
SELECT dim_parent_detail.client_code,dim_parent_detail.matter_number
,nhs_auditor_comments,nhs_audit_date 
,ROW_NUMBER() OVER (PARTITION BY dim_parent_detail.client_code,dim_parent_detail.matter_number ORDER BY nhs_audit_date) AS xOrder
FROM red_dw.dbo.dim_parent_detail 
LEFT OUTER JOIN red_dw.dbo.dim_child_detail 
 ON dim_child_detail.client_code = dim_parent_detail.client_code
 AND dim_child_detail.matter_number = dim_parent_detail.matter_number
 AND dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
				WHERE [red_dw].[dbo].[datetimelocal](nhs_audit_date) BETWEEN @StartDate AND @EndDate) AS AuditComments
				 ON AuditComments.client_code = dim_matter_header_current.client_code
				 AND AuditComments.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.dim_detail_compliance
ON dim_detail_compliance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

LEFT JOIN [MS_PROD].[dbo].[udMIAuditNHSSearchList] 
	ON ms_fileid = fileID
  
/*cboNameConvUsed - Naming Convention Used*/
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboNameConvUsed' AND txtMSTable = 'udMIAuditNHSSearchList') cboNameConvUsed ON cboNameConvUsed.cdCode = [udMIAuditNHSSearchList].cboNameConvUsed

/*cboMisfiledInap Misfiled / inappropriate content? */
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboMisfiledInap' AND txtMSTable = 'udMIAuditNHSSearchList') cboMisfiledInap ON cboMisfiledInap.cdCode = [udMIAuditNHSSearchList].cboMisfiledInap


WHERE master_client_code='N1001'
AND reporting_exclusions=0
AND [red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date)>='2022-03-01'
AND [red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) BETWEEN @StartDate AND @EndDate



END
GO
