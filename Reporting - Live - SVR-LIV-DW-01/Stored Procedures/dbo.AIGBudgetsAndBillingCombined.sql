SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[AIGBudgetsAndBillingCombined]
(

@Team AS NVARCHAR(MAX)
,@FeeEarner AS NVARCHAR(MAX)
)

AS 

BEGIN

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)

IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)

SELECT dim_matter_header_current.client_code AS [client_code],
dim_matter_header_current.[ms_fileid],
dim_matter_header_current.[matter_number],
dim_matter_header_current.[matter_description],
dim_detail_client.[ascent_matter_number],
dim_detail_client.[aig_rates_assigned_in_ascent],
dim_detail_client.[aig_litigation_number], 
fed_code AS [matter_owner_fed_code],
name AS [matter_owner_name],
hierarchylevel3hist AS [Department],
hierarchylevel4hist AS [matter_owner_team],
CASE WHEN TRY_CAST(dim_matter_header_current.client_code AS INT) IS NULL THEN dim_matter_header_current.client_code ELSE CAST(TRY_CAST(dim_matter_header_current.client_code AS INT)  AS NVARCHAR(50)) END  AS[client_code_trimmed],
TRY_CAST(dim_matter_header_current.matter_number AS INT)[matter_number_trimmed],
dim_client_involvement.[insurerclient_reference],
dim_client_involvement.[insuredclient_name],
fact_finance_summary.[unpaid_bill_balance],
fact_finance_summary.[total_amount_billed],
fact_finance_summary.[defence_costs_reserve_initial],
fact_finance_summary.[defence_costs_billed],
fact_finance_summary.[defence_costs_reserve_net],
dim_matter_group.[matter_group_code],
dim_matter_group.[matter_group_name],
fact_finance_summary.[fixed_fee_amount],
dim_detail_core_details.[aig_current_fee_scale], 
dim_detail_core_details.[aig_instructing_office], 
dim_detail_core_details.[aig_reference], 
dim_detail_core_details.[clients_claims_handler_surname_forename], 
dim_detail_core_details.[date_instructions_received], 
dim_detail_core_details.[fixed_fee],  
dim_detail_core_details.[is_this_a_linked_file], 
dim_detail_core_details.[is_this_the_lead_file], 
date_opened_case_management AS [matter_opened_case_management_calendar_date],
date_closed_case_management AS [matter_closed_case_management_calendar_date],
fact_detail_cost_budgeting.[percentage_of_budget],
dim_detail_core_details.[present_position], 
dim_detail_core_details.[referral_reason], 
dim_detail_core_details.[suspicion_of_fraud], 
dim_detail_fraud.[fraud_current_fraud_type], 
dim_detail_fraud.[fraud_initial_fraud_type], 
dim_detail_outcome.[date_claim_concluded], 
dim_detail_outcome.[date_costs_settled], 
dim_detail_outcome.[outcome_of_case], 
fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget], 
fact_detail_cost_budgeting.[aig_fixed_fee_budget_expenses], 
fact_detail_cost_budgeting.[aig_fixed_fee_budget_fees], 
fact_detail_cost_budgeting.[aig_fixed_fee_budget_vat], 
fact_detail_cost_budgeting.[aigtotalbudgetfixedfee], 
fact_detail_cost_budgeting.[aigtotalbudgethourlyrate], 
fact_detail_cost_budgeting.[discoverydisclosure_fees_document_production], 
fact_detail_cost_budgeting.[discoverydisclosure_fees_court_mandated_conferences], 
fact_detail_cost_budgeting.[discoverydisclosure_fees_depositions], 
fact_detail_cost_budgeting.[discoverydisclosure_fees_expert_discovery], 
fact_detail_cost_budgeting.[discoverydisclosure_feesother_written_motionsubmission], 
fact_detail_cost_budgeting.[discoverydisclosure_feeswritten_discoveryinterrogatori], 
fact_detail_cost_budgeting.[evaluation_fees_analysisstrategy], 
fact_detail_cost_budgeting.[evaluation_fees_budgeting], 
fact_detail_cost_budgeting.[evaluation_fees_documentsfile_management], 
fact_detail_cost_budgeting.[evaluation_fees_expertsconsultants], 
fact_detail_cost_budgeting.[evaluation_fees_fact_investigationdevelopment], 
fact_detail_cost_budgeting.[evaluation_fees_pleadings], 
fact_detail_cost_budgeting.[evaluation_fees_prelim_injunctionsprovisional_remedies], 
fact_detail_cost_budgeting.[n_discoverydisclosure_fees_discovery_motions], 
fact_detail_cost_budgeting.[o_discoverydisclosure_fees_discovery_onsite_inspections], 
fact_detail_cost_budgeting.[p_adr_fees_settlementnonbinding_adr], 
fact_detail_cost_budgeting.[q_trial_fees_fact_witnesses], 
fact_detail_cost_budgeting.[r_trial_fees_expert_witnesses], 
fact_detail_cost_budgeting.[s_trial_fees_written_motionssubmissions], 
fact_detail_cost_budgeting.[t_trial_fees_trial_preparation_support], 
fact_detail_cost_budgeting.[u_trial_fees_trial_and_hearing_attendance], 
fact_detail_cost_budgeting.[v_trial_fees_post_trial_motionssubmissions], 
fact_detail_cost_budgeting.[w_trial_fees_enforcement], 
fact_detail_cost_budgeting.[x_appeal_fees_appellate_proceedingsmotions_practice], 
fact_detail_cost_budgeting.[y_appeal_fees_appellate_briefs], 
fact_detail_cost_budgeting.[yy_appeal_fees_oral_argument], 
fact_detail_cost_budgeting.[yz_overall_costs_budget_figure], 
fact_detail_cost_budgeting.[za_evaluation_expenses], 
fact_detail_cost_budgeting.[zb_discoverydisclosure_expenses], 
fact_detail_cost_budgeting.[zc_adr_expenses], 
fact_detail_cost_budgeting.[zd_trial_expenses], 
fact_detail_cost_budgeting.[ze_appeal_expenses], 
fact_detail_cost_budgeting.[zf_multiphase_expenses], 
fact_detail_cost_budgeting.[zg_overall_expenses_figure], 
fact_finance_summary.[defence_costs_reserve],
dim_detail_client.[date_budget_uploaded],
dim_detail_client.[has_budget_been_approved],
fact_finance_summary.[total_recovery],
fact_finance_summary.[unpaid_disbursements],
fact_detail_cost_budgeting.[total_budget_uploaded],
dim_instruction_type.[instruction_type],
dim_detail_client.[uksc]
,dim_matter_header_current.[billing_arrangement]
,dim_detail_client.[hide_flag]
,dim_detail_core_details.[associated_matter_numbers]
,fact_finance_summary.[disbursement_balance]
,dim_detail_client.[first_date_budget_uploaded]
,dim_matter_header_current.[master_matter_number]
,dim_matter_header_current.[master_client_code],fact_finance_summary.[vat_billed]
,ISNULL(total_amount_billed,0) - ISNULL(vat_billed,0) AS [Total Billed Net]
, ISNULL(vat_billed,0) AS TotalVat
,disbursement_balance AS [UnbilledDisbs]
,LastBillDate AS [Date of Last Non Revered/Non DisbOnly Bill]
,DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE()) AS [Elapsed from Last Bill]
,DATEDIFF(DAY,date_opened_case_management,GETDATE()) AS [Elapsed fromDate Opened]
,CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END  AS ElapsedDays
,DATEDIFF(DAY,date_opened_case_management,date_claim_concluded) AS ElapsedConcluded
,wip AS [WIP]
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,red_dw.dbo.dim_matter_header_current.fee_arrangement
,Proforma.[Proforma Status]
,Proforma.[Proforma Elapsed Days]
,[Proforma].[Proforma Date]
,dim_detail_core_details.[is_insured_vat_registered]
,LitLevel.LIT_date_budget_uploaded
,LitLevel.Lit_total_budget_uploaded
,LitLevel.Lit_disbursement_balance
,LitLevel.Lit_unpaid_bill_balance
,LitLevel.Lit_Wip
,LitLevel.Lit_defence_cost_billed
,LitLevel.Lit_total_amount_billed
,LitLevel.count AS [count]
,lead_file_matter_number_client_matter_number
,CASE WHEN LitLevel.Approved>=1 THEN 'Yes' ELSE 'No' END AS Approved
,         CONCAT_WS(',',
             CASE WHEN dim_detail_client.aig_litigation_number IS NULL
                       OR dim_detail_client.aig_litigation_number = '' THEN
                      'No LIT Number'
             END ,
			 CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent='LIT not in ASCENT' THEN 'LIT not in ASCENT' END,

CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent IN 
(
--'FRAUDC - Fraud Hourly'
--,'AUTOCO - Motor Hourly'
--,
'CASUAM - Casualty Major Loss'
--,'CASUAC - Casualty Hourly'
,'AUTOML - Motor Major Loss'
,'HLTHCR - Healthcare Hourly'
,'ENVIRC - Environmental Hourly'
,'ENVIRM - Environmental Hourly'
,'RECVCA - Recovery'
--,'AUTOEX - Motor Hourly'
) AND ISNULL(dim_matter_header_current.fixed_fee,'')<>'Hourly' 
AND ISNULL(referral_reason,'')<>'Costs dispute'
THEN 'Incorrect fee scale' END,

CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent IN 
(
'AUTOCA - Motor Fixed Fee'
--,'CASUCA - Casualty Fixed Fee'
,'CASUMA - Casualty Fixed Fee'
,'CASUCA - Casualty Fixed Fee'

) 
AND ISNULL(dim_matter_header_current.fixed_fee,'')<>'Fixed Fee' 
AND ISNULL(referral_reason,'')<>'Costs dispute'
THEN 'Incorrect fee scale' END,
             CASE WHEN dim_detail_client.aig_litigation_number LIKE 'LIT-%'
                       AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
                       AND ISNULL(fact_detail_cost_budgeting.[aig_fixed_fee_budget_fees],0) = 0 
                       AND ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0) =0 
                       AND ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) = 0 
					   AND ISNULL(lead_budget_details.budget_approved,'') = ''
					   AND ISNULL(lead_budget_details.total_budget_uploaded,0) = 0
                       AND ISNULL(lead_budget_details.date_budget_uploaded,'') ='' 
					  					   
					   THEN
                      'No budget figures'
             END,
             CASE WHEN ISNULL(dim_detail_client.has_budget_been_approved, '') = 'Rejected' THEN
                      'Rejected Budget'
             END--,
,CASE WHEN  ISNULL(is_insured_vat_registered,'Yes')='Yes' 
AND dim_detail_client.aig_litigation_number LIKE 'LIT-%'
AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
AND ISNULL(dim_detail_client.aig_litigation_number,'')<>'Recovery'
AND ISNULL(dim_matter_header_current.fee_arrangement,'')='Fixed Fee/Fee Quote/Capped Fee'
AND 
(ISNULL(fact_detail_cost_budgeting.[aigtotalbudgetfixedfee],0) + 
--ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) + 
ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0)
) < 
(ISNULL(total_amount_billed,0) - ISNULL(vat_billed,0)) + ISNULL(fact_detail_cost_budgeting.[aig_fixed_fee_budget_fees],0)+ISNULL(disbursement_balance,0)
THEN 'Insufficient budget' END 

,CASE WHEN  ISNULL(is_insured_vat_registered,'Yes')='No' 
AND dim_detail_client.aig_litigation_number LIKE 'LIT-%'
AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
AND ISNULL(dim_detail_client.aig_litigation_number,'')<>'Recovery'
AND ISNULL(dim_matter_header_current.fee_arrangement,'')='Fixed Fee/Fee Quote/Capped Fee'
AND 
(ISNULL(fact_detail_cost_budgeting.[aigtotalbudgetfixedfee],0) + 
--ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) + 
ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0)
) < 
ISNULL(total_amount_billed,0)  + ISNULL(fact_detail_cost_budgeting.[aig_fixed_fee_budget_fees] ,0)+ISNULL(disbursement_balance,0)
THEN 'Insufficient budget' END
-------------- Fixed Fee (Above) ------------------
,CASE WHEN  ISNULL(is_insured_vat_registered,'Yes')='Yes' 
AND dim_detail_client.aig_litigation_number LIKE 'LIT-%'
AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
AND ISNULL(dim_detail_client.aig_litigation_number,'')<>'Recovery'
AND ISNULL(dim_matter_header_current.fee_arrangement,'')<>'Fixed Fee/Fee Quote/Capped Fee'
AND 
(
--ISNULL(fact_detail_cost_budgeting.[aigtotalbudgetfixedfee],0) + 
ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) + 
ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0)
) < 
(ISNULL(total_amount_billed,0) - ISNULL(vat_billed,0))  + ISNULL(wip,0)+ISNULL(disbursement_balance,0)
THEN 'Insufficient budget' END 

,CASE WHEN  ISNULL(is_insured_vat_registered,'Yes')='No' 
AND dim_detail_client.aig_litigation_number LIKE 'LIT-%'
AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
AND ISNULL(dim_detail_client.aig_litigation_number,'')<>'Recovery'
AND ISNULL(dim_matter_header_current.fee_arrangement,'')<>'Fixed Fee/Fee Quote/Capped Fee'
AND 
(--ISNULL(fact_detail_cost_budgeting.[aigtotalbudgetfixedfee],0) + 
ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) + 
ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0)
) < 
ISNULL(total_amount_billed,0)  + ISNULL(wip,0)+ISNULL(disbursement_balance,0)
THEN 'Insufficient budget' END
-------------- Hourly (Above) ------------------
--CASE WHEN ISNULL(dim_detail_client.has_budget_been_approved, '') = 'No' THEN
             --         'Awaiting budget approval'
             --END
			 --,
    --         CASE WHEN ISNULL(dim_detail_client.aig_litigation_number, '') LIKE '%[*]LIT-%' THEN
    --                  'Incorrect fee scale'
    --         END,
    --         CASE WHEN ISNULL(dim_detail_client.aig_litigation_number, '') LIKE '%[#]LIT-%' THEN
    --                  'LIT not on Collaborati'
    --         END
	) 
			 
			 [exception]
,CASE WHEN
master_client_code='A2002'
AND ISNULL(dim_detail_client.aig_litigation_number,'')<>'Recovery'
AND date_opened_case_management>='2019-02-01'
AND date_closed_practice_management IS NULL
AND 
(
ISNULL(dim_matter_header_current.fee_arrangement,'') <>'Fixed Fee/Fee Quote/Capped Fee'
OR (dim_matter_header_current.fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' AND ISNULL(red_dw.dbo.dim_detail_core_details.present_position,'')='Final bill due - claim and costs concluded')
)                                                 
AND wip>=500
AND (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)>=90 THEN 'Yes' ELSE 'No' END AS ReadyToBill

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT  AND dss_current_flag='Y'
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
 ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
 AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
 ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
 ON dim_detail_fraud.client_code = dim_matter_header_current.client_code
 AND dim_detail_fraud.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_group
 ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  (
				SELECT dim_detail_client.aig_litigation_number
					,MAX(dim_detail_client.date_budget_uploaded) date_budget_uploaded
					,MAX(cost_budgeting.total_budget_uploaded) total_budget_uploaded
					,MAX(dim_detail_client.has_budget_been_approved) budget_approved
				FROM red_dw.dbo.fact_dimension_main main
				INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
				INNER JOIN red_dw.dbo.dim_detail_client dim_detail_client ON dim_detail_client.dim_detail_client_key = main.dim_detail_client_key
				INNER JOIN red_dw.dbo.fact_detail_cost_budgeting cost_budgeting ON cost_budgeting.master_fact_key = main.master_fact_key

				WHERE 1=1
					--AND dim_detail_client.aig_litigation_number = 'LIT-21253'
					AND header.client_group_code = '00000013'
					AND header.reporting_exclusions <> 1
					AND UPPER(dim_detail_client.aig_litigation_number) LIKE '%LIT%'
					AND dim_detail_client.aig_litigation_number <> 'No LIT'
					AND dim_detail_client.aig_litigation_number IS NOT NULL 
				GROUP BY dim_detail_client.aig_litigation_number
						) lead_budget_details ON lead_budget_details.aig_litigation_number = dim_detail_client.aig_litigation_number
 
LEFT OUTER  JOIN 
(
SELECT fileID AS ms_fileid
,profstatus.[description]  AS  [Proforma Status]
,DATEDIFF(DAY,prof.ProfDate,GETDATE()) AS [Proforma Elapsed Days]
,prof.ProfDate AS [Proforma Date]
FROM   [TE_3E_Prod].[dbo].TRE_WfHistoryHdr AS WfHistoryHdr
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfHistory AS WfHistory ON WfHistoryHdr.WfID  =  WfHistory.TRE_WfHistoryHdr 
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfRuleSet AS WFRuleSet ON WfHistory.TRE_WfRuleSet = WFRuleSet.Code
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfAction AS WfAction   ON WFRuleSet.TRE_WfAction =  WfAction.Code
       
	   INNER JOIN [TE_3E_Prod].[dbo].[ProfMaster] prof ON WfHistory.joinid = prof.profmasterid  
          LEFT JOIN [TE_3E_Prod].[dbo].[ProfStatus] profstatus ON profstatus.code = prof.profstatus
          LEFT JOIN [TE_3E_Prod].[dbo].[Matter] matter ON matter.mattindex = prof.leadmatter
          LEFT JOIN [TE_3E_Prod].[dbo].[Client] client ON matter.client = client.clientindex
		  LEFT JOIN MS_Prod.config.dbFile ON matter.MattIndex=fileExtLinkID

	
WHERE WfHistory.CompletedDate IS NULL  
              AND WfHistory.IsHide  =  0
              AND prof.InvMaster IS NULL
) AS Proforma
 ON Proforma.ms_fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (SELECT fact_bill.client_code,fact_bill.matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
WHERE master_client_code='A2002'
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY fact_bill.client_code,fact_bill.matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
 
LEFT OUTER JOIN 
(
SELECT dim_detail_client.[aig_litigation_number]
,MAX(date_budget_uploaded) AS [LIT_date_budget_uploaded]
,SUM(CASE WHEN has_budget_been_approved='Yes' THEN 1 ELSE 0 END)  AS Approved
,MAX(fact_detail_cost_budgeting.[total_budget_uploaded]) AS [Lit_total_budget_uploaded]
,SUM(fact_finance_summary.[disbursement_balance]) AS [Lit_disbursement_balance]
,SUM(fact_finance_summary.[unpaid_bill_balance]) AS [Lit_unpaid_bill_balance]
,SUM(fact_finance_summary.[wip]) AS Lit_Wip
,SUM(fact_finance_summary.[defence_costs_billed]) AS [Lit_defence_cost_billed]
,SUM(fact_finance_summary.[total_amount_billed]) AS [Lit_total_amount_billed]
,COUNT(1) AS [count]
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
 ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
 AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number
 
WHERE client_group_name='AIG'
AND ISNULL(dim_detail_client.[aig_litigation_number],'') LIKE '%LIT%' 
AND reporting_exclusions <>1
AND dim_detail_client.[aig_litigation_number] <> 'No LIT'
GROUP BY dim_detail_client.[aig_litigation_number]

) AS LitLevel
 ON LitLevel.aig_litigation_number = dim_detail_client.aig_litigation_number
WHERE date_closed_case_management IS NULL
AND ISNULL(red_dw.dbo.dim_detail_core_details.present_position,'') NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid')
AND client_group_name='AIG'
AND reporting_exclusions <>1
AND ISNULL(dim_detail_client.[zurich_data_admin_exclude_from_reports],'No')<>'Yes'
AND red_dw.dbo.dim_matter_header_current.ms_fileid <>4344242

END
GO
