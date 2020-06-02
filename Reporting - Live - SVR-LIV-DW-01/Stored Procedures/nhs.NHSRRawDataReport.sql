SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [nhs].[NHSRRawDataReport]--EXEC [nhs].[NHSRRawDataReport] '1009','Dispute on liability and quantum',NULL,NULL
(
@FeeEarner AS NVARCHAR(MAX)
,@Referralreason AS NVARCHAR(MAX)
,@StartDate AS DATE NULL
,@EndDate AS DATE NULL
)
AS
BEGIN

SELECT ListValue  INTO #FeeEarner FROM Reporting.dbo.[udt_TallySplit]('|', @FeeEarner)
SELECT ListValue  INTO #Referralreason  FROM Reporting.dbo.[udt_TallySplit]('|', @Referralreason)

DECLARE @GraphStart AS DATE
DECLARE @GraphEnd AS DATE

SET @GraphStart='2020-04-01'
SET @GraphEnd='2021-04-30'



SELECT DISTINCT 
CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END  AS [NHSR Ref]
,name AS [Case manager]
,matter_description AS [Matter Description]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number)  AS [Panel Ref]
,dim_detail_health.[nhs_instruction_type] AS [Instruction type (Weightmans)]
,dim_detail_health.[nhs_type_of_instruction_billing] AS [Instruction type]
,dim_detail_health.[nhs_scheme] [Scheme ]
,dim_matter_header_current.date_opened_case_management [Date Case Opened]
,dim_detail_core_details.[date_instructions_received] AS [Date of receipt of instruction]
,dim_detail_health.[nhs_date_of_instruction_of_expert_for_schedule_1_and_2] AS [Date of instruction of expert for schedule 1 & 2]
,dim_detail_court.[date_proceedings_issued] AS [Date of litigation]
,dim_detail_health.[nhs_damages_tranche] AS [Case value]
,dim_detail_health.[nhs_expected_settlement_date] AS [Expected settlement date]
,dim_detail_health.[nhs_probability] AS [Prospects of success/probability]
,dim_detail_health.[nhs_share] AS [Potential share with co defendant?]
,fact_detail_reserve_detail.[nhs_gd_reserve] AS [GD reserve]
,fact_detail_reserve_detail.[nhs_sd_reserve] AS [SD reserve]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant Costs reserve]
,fact_finance_summary.[defence_costs_reserve] AS [Defendant costs reserve]
,(ISNULL(fact_finance_summary.[defence_costs_reserve],0) 
- ( ISNULL(total_amount_bill_non_comp,0)  - ISNULL(vat_non_comp,0))) --amended to 
[DEFENDANTS COST RESERVE NEW]
,fee_arrangement [Fee Arrangment]
,dim_matter_worktype.work_type_name[Worktype ]
,proceedings_issued [Proceedings Issued]

--, NULL AS [Overall reserve]
,fact_detail_reserve_detail.[nhs_initial_meaningful_gd_reserve] AS [Initial meaningful GD reserve]
,fact_detail_reserve_detail.[nhs_initial_meaningful_sd_reserve] AS [Initial meaningful SD reserve]
,fact_finance_summary.[tp_costs_reserve_initial] AS [Initial meaningful Claimant Costs reserve]
,fact_finance_summary.[defence_costs_reserve_initial] AS [Initial meaningful Defendant costs reserve]
,ISNULL(fact_detail_reserve_detail.[nhs_initial_meaningful_gd_reserve],0) +
ISNULL(fact_detail_reserve_detail.[nhs_initial_meaningful_sd_reserve],0) +  
ISNULL(fact_finance_summary.[tp_costs_reserve_initial],0) +
ISNULL(fact_finance_summary.[defence_costs_reserve_initial],0)  AS [Overall reserve]
,fact_detail_paid_detail.[gd_paid_nhs] AS [GD Settlement amount (non PPO)]



,ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)AS [SD Settlement amount (non PPO)]
,CASE WHEN fact_detail_paid_detail.[gd_paid_nhs] IS NULL AND fact_detail_paid_detail.[sd_paid_nhs] IS NULL THEN NULL ELSE 
ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0)
-(ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0) 
+ISNULL(fact_finance_summary.[recovery_defence_costs_from_claimant],0) 
+ISNULL(fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution],0) 
+ ISNULL(fact_finance_summary.[recovery_defence_costs_via_third_party_contribution],0))  END   AS [Overall Settlement amount]







,fact_finance_summary.[damages_paid] AS [Total Damages paid by client]
,dim_detail_health.[nhs_is_this_a_ppo_matter] AS [Is this a PPO matter?]
,CASE WHEN dim_detail_health.[nhs_is_this_a_ppo_matter] = 'Yes' THEN 
ISNULL(fact_detail_client.[nhs_retained_lump_sum_amount_ppo],0) -  ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0) ELSE ISNULL(fact_detail_client.[nhs_retained_lump_sum_amount_ppo],0) END AS [Retained Lump sum amount (PPO)]
--,fact_detail_client.[nhs_retained_lump_sum_amount_ppo] AS [Retained Lump sum amount (PPO)]
,fact_detail_client.[nhs_annual_pp_ppo] AS [Annual PP (PPO)]
,CASE WHEN dim_detail_court.[date_of_trial] > dim_detail_outcome.[date_claim_concluded] THEN NULL ELSE dim_detail_court.[date_of_trial] END AS [Trial Date New]

,dim_detail_outcome.[date_claim_concluded] AS [Date of settlement - Concluded]
,dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] AS [Date of closure of file]
,dim_detail_health.[nhs_recommended_to_proceed_to_trial] AS [Recommended to proceed to trial]
,dim_detail_health.[nhs_reason_for_trial] AS [Reason for trIal]


,dim_detail_court.[date_of_trial] AS [Trial date]
,CASE WHEN UPPER(dim_detail_outcome.[outcome_of_case]) LIKE '%LOST%' THEN 'No'
WHEN UPPER(dim_detail_outcome.[outcome_of_case]) LIKE '%WON%' THEN 'Yes'

ELSE NULL END AS [Trial success]
,DATEDIFF(DAY,dim_detail_core_details.[date_instructions_received],date_claim_concluded) AS [TTR]
,dim_detail_health.[nhs_stage_of_settlement] AS [Stage of settlement]  


,ISNULL(fact_finance_summary.defence_costs_billed_composite,0) - ( ISNULL(fact_finance_summary.[recovery_defence_costs_from_claimant],0) +ISNULL( fact_finance_summary.[recovery_defence_costs_via_third_party_contribution],0))AS [own Profit costs billed]
,red_dw.dbo.fact_finance_summary.disbursements_billed AS [Disbursements Billed]
,dim_detail_health.[nhs_who_dealt_with_costs] AS [Who dealt with costs]
,fact_finance_summary.[tp_total_costs_claimed]  AS [Claimant Costs claimed]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant costs reserve]


,ISNULL(fact_finance_summary.[claimants_costs_paid],0) - ISNULL(recovery_claimants_costs_via_third_party_contribution,0)AS [Overall costs settlement]
,ISNULL(fact_finance_summary.[tp_total_costs_claimed],0) - ISNULL(fact_finance_summary.[claimants_costs_paid],0) AS [Savings]
,CASE WHEN ISNULL(fact_finance_summary.[tp_total_costs_claimed],0)>0 THEN ISNULL(fact_finance_summary.[tp_total_costs_claimed],0) - ISNULL(fact_finance_summary.[claimants_costs_paid],0) / fact_finance_summary.[tp_total_costs_claimed] ELSE NULL END  AS SavingsPercentage
,dim_detail_outcome.[date_costs_settled] AS [Date of settlement - Costs]
,dim_detail_health.nhs_recommended_to_proceed_to_da AS [Recommended to proceed to DA]
,red_dw.dbo.dim_detail_health.nhs_da_date  AS [DA date]
,dim_detail_health.[nhs_da_success] AS [DA success]
,CASE WHEN UPPER(dim_detail_core_details.referral_reason) LIKE '%DISPUTE%' THEN 1 ELSE 0 END  AS Dispute
,CASE WHEN dim_detail_health.[nhs_who_dealt_with_costs] IN ('Keoghs','Acumension') THEN 1 ELSE  0 END AS KeoghsAcumension
,dim_detail_core_details.referral_reason AS [Referal Reason]
,dim_detail_claim.[dst_claimant_solicitor_firm]
,dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] 
,CASE WHEN date_closed_case_management IS NULL THEN 'Live' ELSE 'Closed' END AS FileStatus
,dim_detail_outcome.[outcome_of_case]
,ISNULL(total_amount_bill_non_comp,0) AS [Total Billed To Date]
,interim_costs_payments AS [Interim Costs]
,red_dw.dbo.fact_finance_summary.wip AS [WIP]
,InterimGD
,InterimSD
,fact_finance_summary.tp_costs_reserve_net
,red_dw.dbo.fact_finance_summary.defence_costs_reserve_net
,dim_detail_core_details.[present_position]
,fact_finance_summary.[other_defendants_costs_reserve]
,dim_detail_outcome.[are_we_pursuing_a_recovery]
,fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution]
,fact_finance_summary.[recovery_defence_costs_via_third_party_contribution]
,fact_finance_summary.[recovery_defence_costs_from_claimant]
,fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution]
,date_closed_practice_management AS [Date Closed 3E]
,date_closed_case_management AS [Date Closed Mattersphere]
,ISNULL(total_amount_bill_non_comp,0)-ISNULL(vat_non_comp,0) [Total Amount Billed]
,ISNULL(defence_costs_vat,0) AS defence_costs_vat
,vat_non_comp AS [All Vat]
,defence_costs_billed_composite AS RevenueBilled
,disbursement_balance AS [Unbilled Disbursements]
-- case value changed #18962
,

CASE 
WHEN 
dim_detail_health.[nhs_is_this_a_ppo_matter] = 'Yes' THEN '£500,001 and above'

WHEN
 LOWER(dim_detail_outcome.outcome_of_case) LIKE '%discontinued%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%won%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%struck%' THEN '£0 to £50,000'



WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

  BETWEEN' 0'AND '50000' THEN '£0 to £50,000'
 
 
WHEN date_claim_concluded IS NOT NULL 
 AND (LOWER(dim_detail_outcome.outcome_of_case) LIKE '%assessment%' OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%lost%'  OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%settled%' )
 AND 
 (ISNULL(fact_detail_paid_detail.[sd_paid_nhs],0) - ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],0)) + fact_detail_paid_detail.[gd_paid_nhs]

BETWEEN   '50001' AND '100000' THEN '£50,000 to £100,000'


 
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
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN' 0'AND '50000' THEN '£0 to £50,000'

 WHEN 
 (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NULL 
 AND dim_detail_outcome.[outcome_of_case] IS NULL 
 AND (fact_detail_reserve_detail.[nhs_gd_reserve] + fact_detail_reserve_detail.[nhs_sd_reserve] )BETWEEN '50001' AND '100000' THEN '£50,000 to £100,000'

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
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) BETWEEN' 0'AND '50000' THEN '£0 to £50,000'

 WHEN 
 (dim_detail_health.[nhs_is_this_a_ppo_matter] = 'No' OR dim_detail_health.[nhs_is_this_a_ppo_matter] IS NULL )
 AND dim_detail_outcome.[date_claim_concluded] IS NOT  NULL 
 OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL 
 AND (ISNULL(fact_detail_paid_detail.[gd_paid_nhs],0) + ISNULL(fact_detail_paid_detail.[sd_paid_nhs] ,0) ) BETWEEN '50001' AND '100000' THEN '£50,000 to £100,000'

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


ELSE '-' END AS [case value ]

,YEAR(dim_detail_outcome.[date_claim_concluded]) AS [Year Concluded]
,MONTH(dim_detail_outcome.[date_claim_concluded]) AS [Month No Concluded]
,DATENAME(MONTH, dim_detail_outcome.[date_claim_concluded]) AS [Month Name Concluded] 
,CASE WHEN dim_detail_outcome.[date_claim_concluded] BETWEEN @GraphStart AND @GraphEnd AND  UPPER(dim_detail_core_details.referral_reason) LIKE '%DISPUTE%' 
THEN 1 ELSE 0 END AS ConcludedGraph

,YEAR([zurichnhs_date_final_bill_sent_to_client]) AS [Year Final Bill]
,MONTH([zurichnhs_date_final_bill_sent_to_client]) AS [Month No Final Bill]
,DATENAME(MONTH, [zurichnhs_date_final_bill_sent_to_client]) AS [Month Name Final Bill] 
,CASE WHEN [zurichnhs_date_final_bill_sent_to_client] BETWEEN @GraphStart AND @GraphEnd AND  UPPER(dim_detail_core_details.referral_reason) LIKE '%DISPUTE%' 
THEN 1 ELSE 0 END AS FinalBillGraph
,CASE WHEN UPPER(dim_detail_outcome.[outcome_of_case]) LIKE '%LOST%' OR UPPER(dim_detail_outcome.[outcome_of_case]) LIKE '%WON%' THEN 1 ELSE 0 END AS [NoWon]


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number

INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue   COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT

INNER JOIN #Referralreason AS Referralreason ON Referralreason.ListValue   COLLATE DATABASE_DEFAULT = (CASE WHEN ISNULL(referral_reason,'') ='' THEN 'Missing' ELSE ISNULL(referral_reason,'') END) COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.client_code = dim_matter_header_current.client_code
 AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
 ON fact_detail_client.client_code = dim_matter_header_current.client_code
 AND fact_detail_client.matter_number = dim_matter_header_current.matter_number   
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number   
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
 ON fact_detail_recovery_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_recovery_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

 
 LEFT OUTER JOIN 
 (
 SELECT fileID,SUM(curInDamPayPoA) AS InterimGD FROM ms_prod.dbo.udMIProcessIntDamsPayPostIns
WHERE cboInDamPayPoRe='GENERAL'
GROUP BY fileID
) AS InterimGD
  ON ms_fileid=InterimGD.fileID

   LEFT OUTER JOIN 
 (
  SELECT fileID,SUM(curInDamPayPoA) AS InterimSD FROM ms_prod.dbo.udMIProcessIntDamsPayPostIns
WHERE cboInDamPayPoRe='SPECIAL'
GROUP BY fileID




 ) AS InterimSD
  ON ms_fileid=InterimSD.fileID



 
  
 

WHERE master_client_code='N1001'
--AND dim_matter_header_current.matter_number IN('00000510','00016094','00017096','00017795')

AND ms_only=1
AND (date_closed_practice_management IS NULL OR date_closed_practice_management>='2019-04-01')
AND reporting_exclusions=0

and ((dim_detail_health.[zurichnhs_date_final_bill_sent_to_client]  >= @StartDate OR @StartDate is null) and  dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] <=  @EndDate  OR @EndDate is null) 
AND RTRIM(dim_matter_header_current.client_code)+'-'+RTRIM(dim_matter_header_current.matter_number)  NOT IN 
(
'N00001-PPD001','N00001-VOL001','09011060-00000998','N00002-PPD001'
,'N00002-VOL001','N00003-PPD001','N00003-VOL001','N00007-00000999'
,'N00012-00000999','N00014-00000999','N00017-00000999','N00022-00000999'
,'N00024-00000001','N00024-00000999','N00032-00000001','N1001-00017454'
,'N1001-00017966','N00009-00000001','N00027-00000001','N00031-00000001'
,'N00034-00000001','N00036-00000999','N00017-00000437','N00028-00000002'
,'N1001-00017081','N1001-00017433','N1001-00017768','N1001-00006655'
,'N1001-00007820','N1001-00006655','N1001-00010632','N1001-00014112'
,'N1001-00012555','N1001-00004446','N1001-00007378','N1001-00007819'
,'N1001-00007122','N1001-00001126','N1001-00000871','N1001-00008667'
,'N1001-00013286','N1001-00013746','N1001-00013752','N1001-00005401'
,'N1001-00007817','N1001-00007375','N1001-00001128','N1001-00011721'
,'N1001-00009879','N1001-00012467','N1001-00008030','N1001-00001328'
,'N1001-00012615','N1001-00014509','N1001-00014611','N1001-00017433'
,'N1001-00010542','N1001-00012608','N1001-00005930'

)
AND ISNULL(nhs_instruction_type,'') NOT IN 
(
'Breast screenings - group action'
,'C&W Group Action'
,'Derbyshire Healthcare Group Action'
,'East Sussex Group Action'
,'MTW Group Action'
,'RB - UHNS Group Action'
,'RG - UHNM GROUP Action'
,'Mid Staffs Group Action'
,'Worcester Group Action'
,'UHNS Group Action'                                     
,'UHNS Group Action'
,'RG - UHNM Group Action'


)
AND ([zurichnhs_date_final_bill_sent_to_client]  IS NULL  OR [zurichnhs_date_final_bill_sent_to_client] >='2019-04-01')
AND ISNULL(outcome_of_case,'') <>'Exclude from reports'
AND (dim_detail_outcome.date_claim_concluded >= '2020-04-01' OR dim_detail_outcome.date_claim_concluded IS NULL )
AND CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END NOT IN ('M17LT402/026')
AND (dim_detail_health.zurichnhs_date_final_bill_sent_to_client >= '2020-04-01' OR dim_detail_health.zurichnhs_date_final_bill_sent_to_client IS NULL )
END
GO
