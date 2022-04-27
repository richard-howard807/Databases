SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 24/08/2021
-- Description:	Ticket #110181 listing report for client Hastings. Covers data for Hastings Direct ADR and Trial Report 
--				Added KPI & SLA columns. Changed proc to create table so can run multiple reports off it.
-- =============================================

CREATE PROCEDURE [dbo].[hastings_listing]	--EXEC Reporting.dbo.hastings_listing

AS

BEGIN


IF OBJECT_ID('Reporting.dbo.hastings_listing_table') IS NOT NULL DROP TABLE  Reporting.dbo.hastings_listing_table

IF OBJECT_ID('tempdb..#hastings_financials') IS NOT NULL DROP TABLE #hastings_financials
IF OBJECT_ID('tempdb..#next_trial_date') IS NOT NULL DROP TABLE #next_trial_date


--======================================================================================================================
-- financial data 
--======================================================================================================================
SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, fact_detail_recovery_detail.amount_recovery_sought
	, fact_finance_summary.damages_reserve
	, fact_detail_cost_budgeting.hastings_claimant_schedule_value
	, fact_detail_cost_budgeting.hastings_counter_schedule_of_loss_value
	, (fact_finance_summary.damages_paid - fact_detail_paid_detail.nhs_charges_paid_by_client)	AS damages_paid	
	, fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat
	, fact_detail_paid_detail.claimants_disbursements_claimed
	, fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat
	, fact_finance_summary.claimants_solicitors_disbursements_paid
	, fact_finance_summary.tp_total_costs_claimed
	, fact_finance_summary.claimants_costs_paid
	, fact_finance_summary.total_amount_billed
	, fact_finance_summary.defence_costs_billed
	, fact_finance_summary.disbursements_billed
	, fact_finance_summary.vat_billed
	, paid_bills.bill_amount_paid
	, paid_bills.vat_paid
	, paid_bills.disbs_paid	AS paid_disbursements
	, fact_finance_summary.wip
	, fact_finance_summary.disbursement_balance
	, fact_finance_summary.unpaid_bill_balance
	, fact_detail_client.recovery_amout
	, fact_detail_reserve_detail.hastings_predict_damages_meta_model_value
	, fact_detail_reserve_detail.predict_rec_damages_reserve_current
	, fact_detail_reserve_detail.hastings_predict_claimant_costs_meta_model_value
	, fact_detail_reserve_detail.predict_rec_claimant_costs_reserve_current	
	, fact_detail_reserve_detail.hastings_predict_lifecycle_meta_model_value
	, fact_detail_reserve_detail.predict_rec_settlement_time
	, CASE
		WHEN fact_detail_cost_budgeting.hastings_claimant_schedule_value IS NOT NULL THEN
			fact_detail_cost_budgeting.hastings_claimant_schedule_value - (fact_finance_summary.damages_paid - fact_detail_paid_detail.nhs_charges_paid_by_client)
		ELSE
			NULL
	  END												AS damages_savings_currency
	, CASE
		WHEN fact_detail_cost_budgeting.hastings_claimant_schedule_value IS NOT NULL THEN
			CASE
				WHEN fact_detail_cost_budgeting.hastings_claimant_schedule_value = 0 AND fact_finance_summary.damages_paid = 0 THEN
					0
				WHEN fact_detail_cost_budgeting.hastings_claimant_schedule_value > 0 AND fact_finance_summary.damages_paid = 0 THEN
					1
				ELSE 
					(fact_detail_cost_budgeting.hastings_claimant_schedule_value - (fact_finance_summary.damages_paid - fact_detail_paid_detail.nhs_charges_paid_by_client))/fact_detail_cost_budgeting.hastings_claimant_schedule_value
			END 
		ELSE
			NULL
	  END												AS damages_savings_percent
	, ISNULL(fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat, 0) + ISNULL(fact_detail_paid_detail.claimants_disbursements_claimed, 0)		AS costs_claimed_sum_check
	, ISNULL(fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat, 0) + ISNULL(fact_detail_paid_detail.claimants_solicitors_disbursements_paid, 0)	AS costs_paid_sum_check
	, CASE
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			NULL
		ELSE
			(fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat + fact_detail_paid_detail.claimants_disbursements_claimed) - (fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat + fact_finance_summary.claimants_solicitors_disbursements_paid)	
	  END															AS costs_savings_currency
	, CASE
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			NULL
		WHEN (fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat + fact_detail_paid_detail.claimants_disbursements_claimed) = 0 AND (fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat + fact_finance_summary.claimants_solicitors_disbursements_paid) = 0 THEN
			0
		WHEN (fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat + fact_detail_paid_detail.claimants_disbursements_claimed) > 0 AND (fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat + fact_finance_summary.claimants_solicitors_disbursements_paid) = 0 THEN
			1
		ELSE 
			((fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat + fact_detail_paid_detail.claimants_disbursements_claimed) - (fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat + fact_finance_summary.claimants_solicitors_disbursements_paid))/(fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat + fact_detail_paid_detail.claimants_disbursements_claimed)
	  END																AS costs_savings_percent
	, COALESCE(NULLIF(fact_detail_cost_budgeting.hastings_claimant_schedule_value, 0), fact_finance_summary.damages_reserve, 0) + ISNULL(fact_finance_summary.tp_total_costs_claimed, 0)		AS total_claimed
	, ISNULL(fact_finance_summary.damages_paid, 0) + ISNULL(fact_finance_summary.claimants_costs_paid, 0)			AS total_paid
	, ISNULL(fact_finance_summary.damages_paid, 0) + ISNULL(fact_finance_summary.claimants_costs_paid, 0) 
		+ ISNULL(fact_finance_summary.total_amount_billed, 0)					AS total_claim_cost
INTO #hastings_financials
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
			AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
		ON fact_detail_recovery_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.client_code = dim_matter_header_current.client_code
			AND fact_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN (
						SELECT 
							TE_3E_Prod.dbo.Matter.Number																						
							, SUM(InvMaster.OrgFee) - SUM(InvMaster.BalFee)	AS bill_amount_paid
							, (SUM(InvMaster.OrgHCo) + SUM(InvMaster.OrgSCo)) - (SUM(InvMaster.BalHCo) + SUM(InvMaster.BalSCo))	AS disbs_paid
							, SUM(InvMaster.OrgTax) - SUM(InvMaster.BalTax)		AS vat_paid
						--SELECT InvMaster.* 
						FROM TE_3E_Prod.dbo.InvMaster 
							INNER JOIN TE_3E_Prod.dbo.Matter 
								ON Matter.MattIndex = InvMaster.LeadMatter
							INNER JOIN TE_3E_Prod.dbo.Client 
								ON Client.ClientIndex = Matter.Client
						WHERE 1 = 1
							AND Client.Number = '4908'
							--AND Matter.Number = '4908-16'
							AND InvMaster.TaxInvNumber <> 'PURGE'
							AND InvMaster.IsReversed = 0
						GROUP BY
							Matter.Number
					) AS paid_bills
		ON paid_bills.Number COLLATE DATABASE_DEFAULT = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number 
WHERE
	dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.reporting_exclusions = 0


	
--======================================================================================================================
-- Next active trial date on matters for Hastings Direct ADR and Trial Report 
--======================================================================================================================

SELECT DISTINCT
	dim_matter_header_current.dim_matter_header_curr_key
	, CAST(MIN(trial.key_date) AS DATE)	 			AS date_of_trial
	, CAST(MIN(trial_window.key_date) AS DATE)			AS date_of_trial_window
	, CAST(MIN(mediation.key_date) AS DATE)			AS date_of_mediation
	, CAST(MIN(infant.key_date) AS DATE)				AS date_of_infant_approval_hearing
	, CAST(MIN(disposal.key_date) AS DATE)				AS date_of_disposal_hearing
	, COUNT(1)			AS has_trial
INTO #next_trial_date
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates AS disposal
		ON disposal.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND disposal.type = 'DISHEARING'
				AND disposal.key_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 100, CAST(GETDATE() AS DATE))
					AND disposal.is_active = 1
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates AS infant
		ON infant.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND infant.type = 'INFAPP'
				AND infant.key_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 100, CAST(GETDATE() AS DATE))
					AND infant.is_active = 1
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates AS mediation
		ON mediation.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND mediation.type = 'MEDIATION'
				AND mediation.key_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 100, CAST(GETDATE() AS DATE))
					AND mediation.is_active = 1
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates AS trial_window
		ON trial_window.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND trial_window.type = 'TRIALWINDOW'
				AND trial_window.key_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 100, CAST(GETDATE() AS DATE))
					AND trial_window.is_active = 1
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates AS trial
		ON trial.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND trial.type IN ('KDTRIALDATELIT', 'TRIAL')
				AND trial.key_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 100, CAST(GETDATE() AS DATE))
					AND trial.is_active = 1
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.date_closed_practice_management IS NULL
	AND dim_detail_outcome.date_claim_concluded IS NULL
	AND COALESCE(trial.key_date, trial_window.key_date, mediation.key_date, infant.key_date, disposal.key_date) IS NOT NULL
GROUP BY
	dim_matter_header_current.dim_matter_header_curr_key


--==============================================================================================================================================
-- Main query
--==============================================================================================================================================
SELECT
	NULL		AS [Exposure Number]
	, CAST(COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference) AS NVARCHAR(2000))	COLLATE Latin1_General_BIN	AS [Claim Reference]
	, CAST(dim_instruction_type.instruction_type AS NVARCHAR(60)) COLLATE Latin1_General_BIN					AS [Instruction Type]
	, CAST(dim_detail_core_details.clients_claims_handler_surname_forename AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Hastings Handler]
	, dim_matter_header_current.matter_owner_full_name			AS [Supplier Handler]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Supplier Reference]
	, CAST(dim_matter_header_current.matter_description AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Case Description - DELETE BEFORE SENDING]
	, CAST(dim_detail_core_details.present_position AS NVARCHAR(255)) COLLATE Latin1_General_BIN			AS [Present Position - DELETED BEFORE SENDING]
	, CAST(dim_detail_core_details.referral_reason AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Referral Reason - DELETE BEFORE SENDING]
	, CAST(dim_matter_worktype.work_type_name AS NVARCHAR(50)) COLLATE Latin1_General_BIN AS work_type_name	
	, CAST(dim_matter_header_current.branch_name AS NVARCHAR(50)) COLLATE Latin1_General_BIN			AS [Supplier Branch]
	, CAST(claimant_names.claimant_forenames AS NVARCHAR(MAX)) COLLATE Latin1_General_BIN			AS [Claimant First Name]
	, CAST(claimant_names.claimant_surnames AS NVARCHAR(MAX)) COLLATE Latin1_General_BIN			AS [Claimant Surname]
	, CAST(claimant_names.claimant_postcode AS NVARCHAR(MAX)) COLLATE Latin1_General_BIN			AS [Claimant Postcode]
	, dim_detail_claim.hastings_claimant_adult_or_minor			AS [Adult or Minor]
	, CAST(dim_detail_core_details.ll01_sex	AS NVARCHAR(15)) COLLATE Latin1_General_BIN			AS [Male or Female]
	, dim_detail_claim.hastings_injury_type				AS [Injury Type]
	, CAST(dim_detail_core_details.injury_type AS NVARCHAR(255)) COLLATE Latin1_General_BIN				AS [Firm Injury Type - DELETE BEFORE SENDING]
	, dim_detail_client.hastings_policyholder_first_name		AS [Policyholder First Name]
	, dim_detail_client.hastings_policyholder_last_name			AS [Policyholder Last Name]
	, dim_detail_client.hastings_policyholder_postcode			AS [Policyholder Postcode]
	, dim_detail_claim.hastings_indemnity_position				AS [Indemnity Position]
	, CAST(dim_detail_core_details.incident_date AS	DATE)		AS [Date of Accident]
	, CAST(dim_detail_client.mib_instruction_date AS DATE)		AS [Date of Instruction]
	, CASE 
		WHEN ISNULL(dim_detail_core_details.date_instructions_received, '1900-01-01') > ISNULL(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, '1900-01-01') THEN
			CAST(dim_detail_core_details.date_instructions_received AS DATE) 
		ELSE
			CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE)
	  END										AS [Date Full File Received]
	, dim_detail_claim.hastings_accident_type			AS [Accident Type]
	, dim_detail_claim.hastings_jurisdiction			AS [Jurisdiction]
	, dim_detail_claim.hastings_fault_rating			AS [Fault Rating]
	, dim_detail_core_details.hastings_fault_liability_percent		AS [Fault Liability %]
	, CAST(COALESCE(dim_detail_claim.dst_claimant_solicitor_firm, dim_claimant_thirdparty_involvement.claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name) AS NVARCHAR(2000)) COLLATE Latin1_General_BIN		AS [Claimant Solicitor Firm]
	, CAST(dim_detail_core_details.name_of_claimants_solicitor_surname_forename	AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Claimant Solicitor Handler]
	, CAST(clm_sols_town.town AS NVARCHAR(50)) COLLATE Latin1_General_BIN				AS [Claimant Solicitor Branch]
	, CAST(CASE
		WHEN dim_detail_claim.hastings_fundamental_dishonesty IN ('Fundamental dishonesty identified and intend to plead', 'Fundamental dishonesty identified and pleaded') THEN
			'Y'
		WHEN dim_detail_claim.hastings_fundamental_dishonesty IN ('Fundamental dishonesty identified but do not intend to plead', 'No fundamental dishonesty') THEN
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN									AS [Fundamental Dishonesty]
	, CAST(CASE	
		WHEN RTRIM(LOWER(dim_detail_core_details.proceedings_issued)) = 'yes' THEN
			'Y'
		WHEN RTRIM(LOWER(proceedings_issued)) = 'no' THEN
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN													AS [Litigated]
	, CAST(dim_detail_core_details.date_proceedings_issued AS DATE)		AS [Date Litigated]
	, dim_detail_claim.hastings_claim_status				AS [Claim Status]
	, CAST(allocated_courts.court_names AS NVARCHAR(MAX)) COLLATE Latin1_General_BIN				AS [Allocated Courts]
	, CAST(CASE
		WHEN RTRIM(LOWER(dim_detail_core_details.zurich_grp_rmg_was_litigation_avoidable)) = 'yes' THEN
			'Y'
		WHEN RTRIM(LOWER(dim_detail_core_details.zurich_grp_rmg_was_litigation_avoidable)) = 'no' THEN 
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN														AS [Was Litigation Avoidable?]
	, dim_detail_claim.hastings_reason_for_litigation			AS [Reason for Litigation]
	, #hastings_financials.amount_recovery_sought		AS [Recovery to be Made?]
	, dim_detail_client.hastings_recovery_from				AS [Recovery from]
	, #hastings_financials.damages_reserve				AS [Current Damages Reserve - DELETE BEFORE SENDING]
	, #hastings_financials.hastings_claimant_schedule_value				AS [Claimant Schedule of Loss Value]
	, CAST(CASE
		WHEN dim_detail_claim.hastings_ppo_claimed = 'Yes' THEN
			'Y'
		WHEN dim_detail_claim.hastings_ppo_claimed = 'No' THEN 
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN						AS [PPO Claimed]
	, CAST(CASE	
		WHEN dim_detail_claim.hastings_provisional_damages_claimed = 'Yes' THEN
			'Y'
		WHEN dim_detail_claim.hastings_provisional_damages_claimed = 'No' THEN
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN								AS [Provisional Damages Claimed]
	, #hastings_financials.hastings_counter_schedule_of_loss_value			AS [Counter Schedule of Loss Value]
	, CAST(CASE
		WHEN dim_detail_outcome.hastings_settlement_achieved = 'Yes' THEN
			'Y' 
		WHEN dim_detail_outcome.hastings_settlement_achieved = 'No' THEN
			'N'
	  END AS NVARCHAR(1)) COLLATE Latin1_General_BIN										AS [Settlement Achieved]
	, #hastings_financials.damages_paid						AS [Total Settlement]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date of Settlement]
	, #hastings_financials.damages_savings_currency											AS [Damages Settlement Saving (money)]
	, #hastings_financials.damages_savings_percent										AS [Damages Settlement Saving (percent)]
	--, 'TBC'			AS [Damages Settlement Saving (money)]
	--, 'TBC'			AS [Damages Settlement Saving (percent)]
	, #hastings_financials.claimant_s_solicitor_s_base_costs_claimed_vat			AS [Claimant Costs Claimed]
	, #hastings_financials.claimants_disbursements_claimed			AS [Claimant Disbursements Claimed]
	, #hastings_financials.claimant_s_solicitor_s_base_costs_paid_vat			AS [Claimant Costs Paid]
	, #hastings_financials.claimants_solicitors_disbursements_paid		AS [Claimant Disbursements Paid]
	, CAST(dim_detail_outcome.hastings_date_costs_paid AS DATE)					AS [Date Costs Paid]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)					AS [Date Costs Settled - DELETED BEFORE SENDING]
	, #hastings_financials.tp_total_costs_claimed					AS [Total Costs Claimed - DELETE BEFORE SENDING]
	, CAST(CASE
		WHEN #hastings_financials.costs_claimed_sum_check <> ISNULL(#hastings_financials.tp_total_costs_claimed, 0) THEN
			'Red'
		ELSE
			'Transparent'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN							AS [total_costs_claimed_rag_status]
	, #hastings_financials.claimants_costs_paid			AS [Total Costs Paid - DELETE BEFORE SENDING]
	, CAST(CASE	
		WHEN #hastings_financials.costs_paid_sum_check <> ISNULL(#hastings_financials.claimants_costs_paid, 0) THEN
			'Red'
		ELSE
			'Transparent'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN								AS [total_costs_paid_rag_status]
	, #hastings_financials.costs_savings_currency						AS [Total Costs Savings (money)]
	, #hastings_financials.costs_savings_percent						 AS [Total Costs Savings (percent)]
	--, 'TBC'		AS [Total Costs Savings (money)]
	--, 'TBC'		AS [Total Costs Savings (percent)]
	, #hastings_financials.total_claimed											AS [Total Costs of Claim Presented]
	, 'TBC'		AS [Total Claim Costs Savings (money)]
	, 'TBC'		AS [Total Claim Costs Savings (percent)]
	, #hastings_financials.defence_costs_billed
	, #hastings_financials.disbursements_billed
	, #hastings_financials.vat_billed
	, #hastings_financials.total_amount_billed						AS [Suppliers Billing to Date]
	, final_bill.final_bill_date								AS [Date of Final Invoice]
	, #hastings_financials.bill_amount_paid			AS [Suppliers Billing Paid]
	, #hastings_financials.vat_paid					AS [VAT on Suppliers Billing Paid]
	, #hastings_financials.paid_disbursements		AS [Suppliers Disbursements Paid]
	, #hastings_financials.total_claim_cost			AS [Total Claim Cost]
	, 'TBC'			AS [Total Claim Saving £]
	, 'TBC'			AS [Total Claim Saving (percent)]
	, CAST(dim_detail_client.hastings_closure_date AS DATE)			AS [Date Supplier Closed File]
	, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_proceedings_issued)							AS [Lifecycle Accident - Litigation]
	, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_outcome.date_claim_concluded)							AS [Lifecycle Accident - Settlement]
	, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_client.hastings_closure_date)							AS [Lifecycle Accident - Panel File Closure]
	, DATEDIFF(DAY, dim_detail_client.mib_instruction_date, dim_detail_outcome.date_claim_concluded)						AS [Lifecycle Instruction - Damages Settlement]
	, DATEDIFF(DAY, dim_detail_client.mib_instruction_date, dim_detail_client.hastings_closure_date)					AS [Lifecycle Instruction - Panel File Closure]
	, DATEDIFF(DAY, dim_detail_core_details.date_proceedings_issued, dim_detail_outcome.date_claim_concluded)			AS [Lifecycle Litigation - Damages Settlement]
	, DATEDIFF(DAY, dim_detail_outcome.date_claim_concluded, dim_detail_outcome.hastings_date_costs_paid)				AS [Lifecycle Damages Settlement - Costs Settlement]
	, DATEDIFF(DAY, dim_detail_outcome.hastings_date_costs_paid, dim_detail_client.hastings_closure_date)				AS [Lifecycle Costs Settlement - Panel File Closure]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)					AS [Date Closed on Mattersphere - DELETE BEFORE SENDING]
	, #hastings_financials.wip					AS [Unbilled WIP - DELETE BEFORE SENDING]
	, #hastings_financials.disbursement_balance			AS [Unbilled Disbs - DELETE BEFORE SENDING]
	, #hastings_financials.unpaid_bill_balance			AS [Unpaid Bill Balance - DELETE BEFORE SENDING]
	, #next_trial_date.date_of_trial			AS [Date of Trial]
	, #next_trial_date.date_of_trial_window		AS [Date of Trial Window]
	, #next_trial_date.date_of_mediation			AS [Date of Mediation]
	, #next_trial_date.date_of_infant_approval_hearing		AS [Date of Infant Approval Hearing]
	, #next_trial_date.date_of_disposal_hearing 			AS [Date of Disposal Hearing]
	, ISNULL(#next_trial_date.has_trial, 0)			AS has_trial
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened on MS]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date Instructions Received]
	, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers		AS [Date Full File of Papers Received]
	, CAST(dim_detail_core_details.do_clients_require_an_initial_report AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Initial Report Required?]
	, CAST(dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report AS NVARCHAR(255)) COLLATE Latin1_General_BIN			AS [Extension for Initial Report Agreed]
	, CAST(dim_detail_core_details.date_initial_report_due AS DATE)					AS [Date Initial Report Due]
	, CAST(dim_detail_core_details.date_initial_report_sent AS DATE)				AS [Date Initial Report Sent]
	, fact_detail_elapsed_days.days_to_first_report_lifecycle			AS [Number of Business Days to Initial Report Sent]
	, CAST(dim_detail_core_details.date_subsequent_sla_report_sent AS DATE)		AS [Date of Last SLA Report]
	, defence_due_key_date.defence_due_date					AS [Date Defence Due - Key Date]
	, CAST(dim_detail_court.defence_due_date AS DATE)			AS [Date Defence Due - MI Field]
	, CAST(dim_detail_core_details.date_defence_served AS DATE)			AS [Date Defence Filed]
	, CAST(dim_detail_core_details.suspicion_of_fraud AS NVARCHAR(255)) COLLATE Latin1_General_BIN			AS [Suspicion of Fraud?]
	, dim_detail_outcome.hastings_type_of_settlement			AS [Type of Settlement]
	, dim_detail_outcome.hastings_stage_of_settlement			AS [Stage of Settlement]
	, CAST(dim_detail_outcome.outcome_of_case AS NVARCHAR(255)) COLLATE Latin1_General_BIN					AS [Outcome of Case]
	, dim_detail_claim.hastings_offers_made_with_the_intention_to_rely_on_at_trial			AS [Offers Made with Intention to Rely on at Trial?]
	, CAST(dim_detail_core_details.target_settlement_date AS DATE)				AS [Target Settlement Date]
	, dim_detail_claim.hastings_is_indemnity_an_issue				AS [Is Indemnity an Issue?]
	, dim_detail_claim.hastings_contribution_proceedings_issued			AS [Contribution Proceedings Issued?]
	, CAST(dim_detail_outcome.are_we_pursuing_a_recovery AS NVARCHAR(255)) COLLATE Latin1_General_BIN				AS [Are we Pursuing a Recovery]
	, CAST(dim_detail_claim.date_recovery_concluded AS DATE)			AS [Date Recovery Concluded]
	, #hastings_financials.recovery_amout			AS [Amount Recovered]
	, CAST(dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000 AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Gross Damages Reserve Exceed £350,000?]
	, CAST(dim_detail_core_details.does_claimant_have_personal_injury_claim	AS NVARCHAR(255)) COLLATE Latin1_General_BIN		AS [Does the Claimant have a PI Claim?]
	, #hastings_financials.hastings_predict_damages_meta_model_value		AS [PREDICT Damages Meta-model Value]
	, #hastings_financials.predict_rec_damages_reserve_current				AS [PREDICT Recommended Damages Reserve (Current)]
	, 'TBC'			AS [Damages Paid 100%]
	, #hastings_financials.hastings_predict_claimant_costs_meta_model_value		AS [PREDICT Claimant Costs Meta-model Value]
	, #hastings_financials.predict_rec_claimant_costs_reserve_current			AS [PREDICT Recommended Claimant Costs Reserve (Current)]
	, #hastings_financials.hastings_predict_lifecycle_meta_model_value			AS [PREDICT Lifecycle Meta-model Value]
	, #hastings_financials.predict_rec_settlement_time						AS [PREDICT Recommended Settlement Time]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)			AS [Damages Lifecycle]
	, dim_detail_compliance.hastings_instructions_acknowledged_within_a_day					AS [SLA.A1 Instructions Acknowledged]
	, dim_detail_compliance.hastings_instructions_allocated_within_two_days					AS [SLA.A2 File Allocated]
	, IIF(ISNULL(dim_detail_compliance.hastings_file_set_up_on_collaborate, '')='Not applicable', 'N/A', dim_detail_compliance.hastings_file_set_up_on_collaborate)		AS [SLA.A2 on Collaborate]
	, IIF(ISNULL(dim_detail_compliance.hastings_references_sent_to_ph_within_two_business_days, '')='Not applicable', 'N/A', hastings_references_sent_to_ph_within_two_business_days)			AS [SLA.A2 Refs Sent to Policyholder]
	, IIF(ISNULL(dim_detail_compliance.hastings_initial_contact_with_claimant_solicitors, '')='Not applicable', 'N/A', hastings_initial_contact_with_claimant_solicitors)				AS [SLA.A2 Initial Contact with Claimant Sols]
	, IIF(ISNULL(dim_detail_compliance.hastings_initial_report_sent_within_ten_days, '')='Not applicable', 'N/A', hastings_initial_report_sent_within_ten_days)					AS [SLA.A3 Initial Report 10 Days]
	, IIF(ISNULL(dim_detail_compliance.hastings_defences_submitted_to_hastings, '')='Not applicable', 'N/A', hastings_defences_submitted_to_hastings) 							AS [SLA.A4 Defencese Submitted 7 Days]
	, CAST(IIF(ISNULL(dim_detail_compliance.hastings_court_directions_provided_to_hastings, '')='Not applicable', 'N/A', hastings_court_directions_provided_to_hastings) AS NVARCHAR(255)) COLLATE Latin1_General_BIN					AS [SLA.A5 Court Directions Provided to Hastings 2 Days]
	, IIF(ISNULL(dim_detail_compliance.hastings_defence_submitted_to_court_within_direction_timetable, '')='Not applicable', 'N/A', hastings_defence_submitted_to_court_within_direction_timetable)		AS [SLA.A6 Defence Submitted to Court]
	, CAST(IIF(ISNULL(dim_detail_compliance.hastings_compliance_with_all_other_court_dates, '')='Not applicable', 'N/A', hastings_compliance_with_all_other_court_dates) AS NVARCHAR(255)) COLLATE Latin1_General_BIN					AS [SLA.A7 Compliance with Court Dates]
	, IIF(ISNULL(dim_detail_compliance.hastings_brought_other_parties_into_litigation, '')='Not applicable', 'N/A', hastings_brought_other_parties_into_litigation)					AS [SLA.A8 Identified Other Parties]
	, IIF(ISNULL(dim_detail_compliance.hastings_urgent_developments_reported_two_days, '')='Not applicable', 'N/A', hastings_urgent_developments_reported_two_days)					AS [SLA.A9 Urgent Developments Reported]
	, IIF(ISNULL(dim_detail_compliance.hastings_update_reports_submitted_every_three_months, '')='Not applicable', 'N/A', hastings_update_reports_submitted_every_three_months)			AS [SLA.A9 Update Reports Submitted]
	, IIF(ISNULL(dim_detail_compliance.hastings_significant_developments_reported_five_days, '')='Not applicable', 'N/A', hastings_significant_developments_reported_five_days)			AS [SLA.A10 Significant Developments Reported]
	, IIF(ISNULL(dim_detail_compliance.hastings_provided_written_responses_in_a_timely_manner, '')='Not applicable', 'N/A', hastings_provided_written_responses_in_a_timely_manner)			AS [SLA.A11 Non-urgent Written Responses]
	, IIF(ISNULL(dim_detail_compliance.hastings_provided_written_responses_to_urgent_correspondence, '')='Not applicable', 'N/A', hastings_provided_written_responses_to_urgent_correspondence)	AS [SLA.A12 Urgent Written Responses]
	, IIF(ISNULL(dim_detail_compliance.hastings_supplier_recognises_new_information_indicates_change, '')='Not applicable', 'N/A', hastings_supplier_recognises_new_information_indicates_change)		AS [SLA.A12 Supplier Written Responses]
	, IIF(ISNULL(dim_detail_compliance.hastings_responded_to_phone_calls_within_two_business_days, '')='Not applicable', 'N/A', hastings_responded_to_phone_calls_within_two_business_days)			AS [SLA.A13 Responded to Phone Calls 2 Days]
	, IIF(ISNULL(dim_detail_compliance.hastings_outcome_reports_submitted_within_two_days, '')='Not applicable', 'N/A', hastings_outcome_reports_submitted_within_two_days)				AS [SLA.A14 Outcome Reports Submitted 2 days]
	, IIF(ISNULL(dim_detail_compliance.hastings_trials_referred_to_and_signed_off_by_large_loss, '')='Not applicable', 'N/A', hastings_trials_referred_to_and_signed_off_by_large_loss)			AS [SLA.A15 Trials Referred to Large Loss]
	, IIF(ISNULL(dim_detail_compliance.hastings_advice_to_be_directed_to_the_hastings_handler, '')='Not applicable', 'N/A', hastings_advice_to_be_directed_to_the_hastings_handler)			AS [SLA.A15 Trial Advice Directed to Hastings]
	, IIF(ISNULL(dim_detail_compliance.hastings_report_on_tactics_submitted_to_hastings, '')='Not applicable', 'N/A', hastings_report_on_tactics_submitted_to_hastings)				AS [SLA.A15 Full Report Tactics 2 Weeks]
	, IIF(ISNULL(dim_detail_compliance.hastings_any_trial_dates_missed, '')='Not applicable', 'N/A', hastings_any_trial_dates_missed)							AS [SLA.A16 Trial Dates Missed]
	, IIF(ISNULL(dim_detail_compliance.hastings_reports_and_advice_to_be_provided_to_hastings, '')='Not applicable', 'N/A', hastings_reports_and_advice_to_be_provided_to_hastings)			AS [SLA.A17 Experts Reports Provided to Hastings]
	, IIF(ISNULL(dim_detail_compliance.hastings_instructions_and_reports_agreed_with_hastings, '')='Not applicable', 'N/A', hastings_instructions_and_reports_agreed_with_hastings)			AS [SLA.A17 Experts Reports Agreed with Hastings]
	, IIF(ISNULL(dim_detail_compliance.hastings_accurate_reserves_held_on_file_at_all_times, '')='Not applicable', 'N/A', hastings_accurate_reserves_held_on_file_at_all_times)			AS [SLA.A19 Accurate Reserves Held]
	, CAST(CASE 
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'Justified complaint made' THEN 
			'Yes'
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'No complaints made' THEN
			'No'
		ELSE 
			NULL
	  END AS NVARCHAR(255)) COLLATE Latin1_General_BIN																	AS [SLA.A20 Justified Complaints Made]
	, CAST(CASE 
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'Non-justified complaint made' THEN 
			'Yes'
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'No complaints made' THEN
			'No'
		ELSE 
			NULL
	  END AS NVARCHAR(255)) COLLATE Latin1_General_BIN																	AS [SLA.A20 Non-Justified Complaints Made]
	, IIF(ISNULL(dim_detail_compliance.hastings_any_leakage_identified, '')='Not applicable', 'N/A', hastings_any_leakage_identified)				AS [SLA.A21 Any Leakage Identified]
	, CAST(dim_detail_compliance.hastings_date_of_sla_review AS DATE)				AS [Date of Last Review]
	, CAST(CASE
		WHEN ISNULL(dim_detail_core_details.do_clients_require_an_initial_report, '') = 'No' THEN	
			'N/A'
		WHEN ISNULL(dim_detail_core_details.referral_reason, '') = 'Nomination only' AND dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NULL THEN
			'N/A'
		WHEN ISNULL(dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report, '') = 'Yes' THEN
			'N/A'
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN	
			CASE	
				WHEN (fact_detail_elapsed_days.days_to_first_report_lifecycle) > 10 THEN 
					'Not Achieved'
				WHEN CAST(GETDATE() AS DATE) < dim_detail_core_details.date_initial_report_due THEN
					'N/A'
			END 
		WHEN fact_detail_elapsed_days.days_to_first_report_lifecycle < 0 THEN 
			'N/A'
		WHEN (fact_detail_elapsed_days.days_to_first_report_lifecycle) <= 10 THEN 
			'Achieved'
		WHEN (fact_detail_elapsed_days.days_to_first_report_lifecycle) > 10 THEN 
			'Not Achieved'
		ELSE 
			'N/A' 
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN													AS [KPI A.1 Initial Advice]
	, CAST(CASE
		WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN	
			'Achieved'
		WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified but do not intend to plead' THEN
			'Not Achieved'
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR dim_detail_claim.hastings_fundamental_dishonesty = 'No fundamental dishonesty' THEN
			'N/A'
		ELSE
			NULL
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN 											AS [KPI A.2 Fundamental Dishonesty Pleaded]
	, CAST(CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_core_details.suspicion_of_fraud = 'Yes'
		AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN 
			CASE 
				WHEN dim_detail_outcome.hastings_type_of_settlement = 'Withdrawn' THEN
					'Achieved'
			END
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR (dim_detail_outcome.hastings_type_of_settlement = 'No fundamental dishonesty' AND dim_detail_outcome.date_claim_concluded IS NULL) THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN										AS [KPI A.2 Fundamental Dishonesty Success - Withdrawn]
	, CAST(CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_core_details.suspicion_of_fraud = 'Yes'
		AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN 
			CASE 
				WHEN dim_detail_outcome.hastings_type_of_settlement IN ('Calderbank', 'P36', 'Time limited') THEN
					'Achieved'
			END
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR (dim_detail_outcome.hastings_type_of_settlement = 'No fundamental dishonesty' AND dim_detail_outcome.date_claim_concluded IS NULL) THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN										AS [KPI A.2 Fundamental Dishonesty Success - Compromised]
	, CAST(CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_core_details.suspicion_of_fraud = 'Yes'
		AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN 
			CASE
				WHEN dim_detail_outcome.hastings_type_of_settlement IN ('Fundamental dishonesty defence', 'Other successful full defence') THEN
					'Achieved'
			END
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR (dim_detail_outcome.hastings_type_of_settlement = 'No fundamental dishonesty' AND dim_detail_outcome.date_claim_concluded IS NULL) THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN										AS [KPI A.2 Fundamental Dishonesty Success - Failed]
	, CAST(CASE
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'Yes' AND dim_detail_claim.date_recovery_concluded IS NOT NULL 
		AND #hastings_financials.recovery_amout >= 1 THEN
			'Achieved'
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'Yes' AND dim_detail_claim.date_recovery_concluded IS NOT NULL 
		AND #hastings_financials.recovery_amout < 1 THEN
			'Not Achieved'
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'No' OR dim_detail_claim.date_recovery_concluded IS NULL THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN															AS [KPI A.2 Contribution Proceedings]
	, CAST(CASE
		WHEN dim_detail_core_details.referral_reason LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_claim.hastings_is_indemnity_an_issue = 'Yes'
		AND dim_detail_claim.date_recovery_concluded IS NOT NULL AND LOWER(dim_detail_client.hastings_recovery_from) IN ('policyholder', 'policy holder') THEN
			CASE
				WHEN #hastings_financials.recovery_amout > 0 THEN
					'Achieved'
				ELSE
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' OR dim_detail_outcome.date_claim_concluded IS NULL OR dim_detail_claim.hastings_is_indemnity_an_issue = 'No'
		OR dim_detail_claim.date_recovery_concluded IS NULL THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN									AS [KPI A.3 Indemnity Recoveries]
	, CAST(CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL
		AND dim_detail_claim.hastings_offers_made_with_the_intention_to_rely_on_at_trial = 'Yes' AND dim_detail_outcome.hastings_stage_of_settlement = 'Trial' THEN
			CASE
				WHEN dim_detail_outcome.outcome_of_case IN ('Won at trial', 'Assessment of damages (claimant fails to beat P36 offer)') THEN 
					'Achieved'
				WHEN dim_detail_outcome.outcome_of_case = 'Lost at trial' THEN 
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' OR dim_detail_outcome.date_claim_concluded IS NULL THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN									AS [KPI A.4 Offers and Outcomes]
	, CAST(CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL THEN
			CASE	
				WHEN dim_detail_core_details.target_settlement_date >= dim_detail_outcome.date_claim_concluded THEN
					'Achieved'
				WHEN dim_detail_core_details.target_settlement_date <= dim_detail_outcome.date_claim_concluded THEN 
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%'OR dim_detail_outcome.date_claim_concluded IS NULL THEN
			'N/A'
	  END AS NVARCHAR(15)) COLLATE Latin1_General_BIN											AS [KPI A.5 Lifecycle]
	, CAST(CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' OR dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000 = 'No'
		OR dim_detail_core_details.does_claimant_have_personal_injury_claim = 'No' OR dim_detail_core_details.injury_type = 'Fatal injury' 
		OR dim_matter_worktype.work_type_code = '1597' THEN
			'N/A'
		--logic to be added for Achieved/Not Achieved 
	 END AS NVARCHAR(15)) COLLATE Latin1_General_BIN									AS [KPI A.6 PREDICT]
	, CAST('TBC' AS NVARCHAR(15)) COLLATE Latin1_General_BIN			AS [KPI A.7 Internal Monthly Audits]	--logic to be confirmed
INTO Reporting.dbo.hastings_listing_table
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
		--ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.client_code = dim_matter_header_current.client_code
			AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
		--ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
		--ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance
		ON dim_detail_compliance.client_code = dim_matter_header_current.client_code
			AND dim_detail_compliance.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
			AND fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #hastings_financials
		ON #hastings_financials.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #next_trial_date
		ON #next_trial_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
						SELECT 
							dbFile.fileID
							, STRING_AGG(CAST(RTRIM(dbContactIndividual.contChristianNames) AS NVARCHAR(MAX)), ', ')			AS claimant_forenames
							, STRING_AGG(CAST(RTRIM(dbContactIndividual.contSurname) AS NVARCHAR(MAX)), ', ')				AS claimant_surnames
							, STRING_AGG(CAST(RTRIM(dbAddress.addPostcode) AS NVARCHAR(MAX)), ', ')							AS claimant_postcode
						FROM MS_Prod.config.dbFile
							INNER JOIN MS_Prod.config.dbClient
								ON dbClient.clID = dbFile.clID
							INNER JOIN MS_Prod.config.dbAssociates
								ON dbAssociates.fileID = dbFile.fileID
							INNER JOIN MS_Prod..dbContactIndividual
								ON dbContactIndividual.contID = dbAssociates.contID
							INNER JOIN MS_Prod.config.dbContact
								ON dbContact.contID = dbAssociates.contID
							INNER JOIN MS_Prod..dbAddress
								ON dbContact.contDefaultAddress = dbAddress.addID
						WHERE
							dbClient.clNo = '4908'
							AND dbAssociates.assocType = 'CLAIMANT'
							AND dbAssociates.assocActive = 1
						GROUP BY
							dbFile.fileID
					) AS claimant_names
		ON claimant_names.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN (
						SELECT 
							dbFile.fileID
							, COALESCE(dbAddress.addLine4, dbAddress.addLine3, dbAddress.addLine2)		AS town	
						FROM MS_Prod.config.dbAssociates
							INNER JOIN MS_Prod.config.dbFile
								ON dbFile.fileID = dbAssociates.fileID
							INNER JOIN MS_Prod.config.dbClient
								ON dbClient.clID = dbFile.clID
							INNER JOIN MS_Prod.config.dbContact
								ON dbContact.contID = dbAssociates.contID
							INNER JOIN MS_Prod..dbAddress
								ON dbContact.contDefaultAddress = dbAddress.addID
						WHERE
							dbClient.clNo = '4908'
							AND dbAssociates.assocType = 'CLAIMANTSOLS'
							AND dbAssociates.assocActive = 1
							--AND dbFile.fileNo = '12'
					) AS clm_sols_town
		ON clm_sols_town.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN (
						SELECT 
							dbFile.fileID
							, STRING_AGG(CAST(dbContact.contName AS NVARCHAR(MAX)), ', ')		AS court_names
						FROM MS_Prod.config.dbAssociates
							INNER JOIN MS_Prod.config.dbFile
								ON dbFile.fileID = dbAssociates.fileID
							INNER JOIN MS_Prod.config.dbClient
								ON dbClient.clID = dbFile.clID
							INNER JOIN MS_Prod.config.dbContact
								ON dbContact.contID = dbAssociates.contID
						WHERE 1 = 1
							AND dbClient.clNo = '4908'
							AND dbAssociates.assocType IN (
								'COUNTYCRT',
								'COURT',
								'CROWNCRT',
								'HIGHCRT',
								'MAGSCOURT'
								)
						GROUP BY
							dbFile.fileID
					) AS allocated_courts
		ON allocated_courts.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN (
						SELECT
							 dim_matter_header_current.dim_matter_header_curr_key
							 , CAST(MAX(dim_date.calendar_date) AS DATE)			AS final_bill_date
						FROM red_dw.dbo.dim_matter_header_current
							INNER JOIN red_dw.dbo.fact_bill
								ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
							INNER JOIN red_dw.dbo.dim_date
								ON dim_date.dim_date_key = fact_bill.dim_bill_date_key
							INNER JOIN red_dw.dbo.dim_detail_core_details
								ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
									AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
						WHERE
							dim_matter_header_current.master_client_code = '4908'
							AND RTRIM(dim_detail_core_details.present_position) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear')
						GROUP BY
							dim_matter_header_current.dim_matter_header_curr_key
				) AS final_bill
		ON final_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
						SELECT 
							dim_key_dates.dim_matter_header_curr_key
							, MAX(CAST(dim_key_dates.key_date AS DATE)) AS defence_due_date
						FROM red_dw.dbo.dim_key_dates
						WHERE 1 = 1
							AND dim_key_dates.client_code = '00004908'
							AND dim_key_dates.type = 'DEFENCE'
							AND dim_key_dates.is_active = 1
						GROUP BY
							dim_key_dates.dim_matter_header_curr_key
					) AS defence_due_key_date
		ON defence_due_key_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_matter_number >= 6 --excludes ML matter and earlier matters opened in 1990s
ORDER BY
	dim_matter_header_current.master_matter_number


END	

GO
