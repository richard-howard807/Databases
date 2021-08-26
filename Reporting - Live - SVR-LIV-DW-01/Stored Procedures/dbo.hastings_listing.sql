SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 24/08/2021
-- Description:	Ticket #110181 listing report for client Hastings. Covers data for Hastings Direct ADR and Trial Report 
-- =============================================

CREATE PROCEDURE [dbo].[hastings_listing]

AS

BEGIN

DROP TABLE IF EXISTS #hastings_financials
DROP TABLE IF EXISTS #next_trial_date


--======================================================================================================================
-- financial data 
--======================================================================================================================
SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, fact_detail_recovery_detail.amount_recovery_sought
	, fact_finance_summary.damages_reserve
	, fact_detail_cost_budgeting.hastings_claimant_schedule_value
	, fact_detail_cost_budgeting.hastings_counter_schedule_of_loss_value
	, fact_finance_summary.damages_paid	
	, fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat
	, fact_detail_paid_detail.claimants_disbursements_claimed
	, fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat
	, fact_finance_summary.claimants_solicitors_disbursements_paid
	, fact_finance_summary.tp_total_costs_claimed
	, fact_finance_summary.claimants_costs_paid
	, fact_finance_summary.total_amount_billed
	, paid_bills.bill_amount_paid
	, paid_bills.vat_paid
	, fact_detail_paid_detail.paid_disbursements
	, fact_finance_summary.wip
	, fact_finance_summary.disbursement_balance
	, fact_finance_summary.unpaid_bill_balance
	, CASE
		WHEN fact_detail_cost_budgeting.hastings_claimant_schedule_value IS NOT NULL THEN
			fact_detail_cost_budgeting.hastings_claimant_schedule_value - fact_finance_summary.damages_paid
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
					(fact_detail_cost_budgeting.hastings_claimant_schedule_value - fact_finance_summary.damages_paid)/fact_detail_cost_budgeting.hastings_claimant_schedule_value
			END 
		ELSE
			NULL
	  END												AS damages_savings_percent
	, ISNULL(fact_detail_reserve_detail.claimant_s_solicitor_s_base_costs_claimed_vat, 0) + ISNULL(fact_detail_paid_detail.claimants_disbursements_claimed, 0)		AS costs_claimed_sum_check
	, ISNULL(fact_detail_paid_detail.claimant_s_solicitor_s_base_costs_paid_vat, 0) + ISNULL(fact_detail_paid_detail.claimants_solicitors_disbursements_paid, 0)	AS costs_paid_sum_check
	, fact_detail_paid_detail.tp_total_costs_claimed - fact_finance_summary.claimants_costs_paid		AS costs_savings_currency
	, CASE
		WHEN fact_detail_paid_detail.tp_total_costs_claimed = 0 AND fact_finance_summary.claimants_costs_paid = 0 THEN
			0
		WHEN fact_detail_paid_detail.tp_total_costs_claimed > 0 AND fact_finance_summary.claimants_costs_paid = 0 THEN
			1
		ELSE 
			(fact_detail_paid_detail.tp_total_costs_claimed - fact_finance_summary.claimants_costs_paid)/fact_detail_paid_detail.tp_total_costs_claimed
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
	LEFT OUTER JOIN (
						SELECT 
							TE_3E_Prod.dbo.Matter.Number																						
							, (SUM(InvMaster.OrgAmt) - SUM(InvMaster.OrgTax)) - (SUM(InvMaster.BalAmt) - SUM(InvMaster.BalTax))		AS bill_amount_paid
							, SUM(InvMaster.OrgTax) - SUM(InvMaster.BalTax)		AS vat_paid
						FROM TE_3E_Prod.dbo.InvMaster 
							INNER JOIN TE_3E_Prod.dbo.Matter 
								ON Matter.MattIndex = InvMaster.LeadMatter
							INNER JOIN TE_3E_Prod.dbo.Client 
								ON Client.ClientIndex = Matter.Client
						WHERE 1 = 1
							AND Client.Number = '4908'
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
	, dim_client_involvement.insurerclient_reference		AS [Claim Reference]
	, dim_instruction_type.instruction_type					AS [Instruction Type]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [Hastings Handler]
	, dim_matter_header_current.matter_owner_full_name			AS [Supplier Handler]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Supplier Reference]
	, dim_matter_header_current.matter_description		AS [Case Description - DELETE BEFORE SENDING]
	, dim_detail_core_details.present_position			AS [Present Position - DELETED BEFORE SENDING]
	, dim_detail_core_details.referral_reason		AS [Referral Reason - DELETE BEFORE SENDING]
	, dim_matter_header_current.branch_name			AS [Supplier Branch]
	, claimant_names.claimant_forenames			AS [Claimant First Name]
	, claimant_names.claimant_surnames			AS [Claimant Surname]
	, claimant_names.claimant_postcode			AS [Claimant Postcode]
	, dim_detail_claim.hastings_claimant_adult_or_minor			AS [Adult or Minor]
	, dim_detail_core_details.ll01_sex				AS [Male or Female]
	, dim_detail_claim.hastings_injury_type				AS [Injury Type]
	, dim_detail_core_details.injury_type				AS [Firm Injury Type - DELETE BEFORE SENDING]
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
	, COALESCE(dim_detail_claim.dst_claimant_solicitor_firm, dim_claimant_thirdparty_involvement.claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name)		AS [Claimant Solicitor Firm]
	, dim_detail_core_details.name_of_claimants_solicitor_surname_forename			AS [Claimant Solicitor Handler]
	, clm_sols_town.town				AS [Claimant Solicitor Branch]
	, dim_detail_claim.hastings_fundamental_dishonesty			AS [Fundamental Dishonesty]
	, dim_detail_core_details.proceedings_issued				AS [Litigated]
	, CAST(dim_detail_core_details.date_proceedings_issued AS DATE)		AS [Date Litigated]
	, dim_detail_claim.hastings_claim_status				AS [Claim Status]
	, allocated_courts.court_names				AS [Allocated Courts]
	, dim_detail_core_details.zurich_grp_rmg_was_litigation_avoidable			AS [Was Litigation Avoidable?]
	, dim_detail_claim.hastings_reason_for_litigation			AS [Reason for Litigation]
	, #hastings_financials.amount_recovery_sought		AS [Recovery to be Made?]
	, dim_detail_client.hastings_recovery_from				AS [Recovery from]
	, #hastings_financials.damages_reserve				AS [Current Damages Reserve - DELETE BEFORE SENDING]
	, #hastings_financials.hastings_claimant_schedule_value				AS [Claimant Schedule of Loss Value]
	, dim_detail_claim.hastings_ppo_claimed					AS [PPO Claimed]
	, dim_detail_claim.hastings_provisional_damages_claimed			AS [Provisional Damages Claimed]
	, #hastings_financials.hastings_counter_schedule_of_loss_value			AS [Counter Schedule of Loss Value]
	, dim_detail_outcome.hastings_settlement_achieved			AS [Settlement Achieved]
	, #hastings_financials.damages_paid						AS [Total Settlement]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date of Settlement]
	--, #hastings_financials.damages_savings_currency											AS [Damages Settlement Saving (money)]
	--, #hastings_financials.damages_savings_percent										AS [Damages Settlement Saving (percent)]
	, 'TBC'			AS [Damages Settlement Saving (money)]
	, 'TBC'			AS [Damages Settlement Saving (percent)]
	, #hastings_financials.claimant_s_solicitor_s_base_costs_claimed_vat			AS [Claimant Costs Claimed]
	, #hastings_financials.claimants_disbursements_claimed			AS [Claimant Disbursements Claimed]
	, #hastings_financials.claimant_s_solicitor_s_base_costs_paid_vat			AS [Claimant Costs Paid]
	, #hastings_financials.claimants_solicitors_disbursements_paid		AS [Claimant Disbursements Paid]
	, CAST(dim_detail_outcome.hastings_date_costs_paid AS DATE)					AS [Date Costs Paid]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)					AS [Date Costs Settled - DELETED BEFORE SENDING]
	, #hastings_financials.tp_total_costs_claimed					AS [Total Costs Claimed - DELETE BEFORE SENDING]
	, CASE
		WHEN #hastings_financials.costs_claimed_sum_check <> ISNULL(#hastings_financials.tp_total_costs_claimed, 0) THEN
			'Red'
		ELSE
			'Transparent'
	  END							AS [total_costs_claimed_rag_status]
	, #hastings_financials.claimants_costs_paid			AS [Total Costs Paid - DELETE BEFORE SENDING]
	, CASE	
		WHEN #hastings_financials.costs_paid_sum_check <> ISNULL(#hastings_financials.claimants_costs_paid, 0) THEN
			'Red'
		ELSE
			'Transparent'
	  END								AS [total_costs_paid_rag_status]
	--, #hastings_financials.costs_savings_currency			AS [Total Costs Savings (money)]
	--, #hastings_financials.costs_savings_percent							AS [Total Costs Savings (percent)]
	, 'TBC'		AS [Total Costs Savings (money)]
	, 'TBC'		AS [Total Costs Savings (percent)]
	, #hastings_financials.total_claimed											AS [Total Costs of Claim Presented]
	--, #hastings_financials.total_claimed - #hastings_financials.total_paid			AS [Total Claim Costs Savings (money)]
	--, CASE
	--	WHEN #hastings_financials.total_claimed = 0 AND #hastings_financials.total_paid = 0 THEN
	--		0
	--	WHEN #hastings_financials.total_claimed > 0 AND #hastings_financials.total_paid = 0 THEN
	--		1
	--	ELSE 
	--		ROUND((#hastings_financials.total_claimed - #hastings_financials.total_paid)/#hastings_financials.total_claimed, 2)
	--  END																			AS [Total Claim Costs Savings (percent)]
	, 'TBC'		AS [Total Claim Costs Savings (money)]
	, 'TBC'		AS [Total Claim Costs Savings (percent)]
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
						GROUP BY
							dbFile.fileID
					) AS claimant_names
		ON claimant_names.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN (
						SELECT 
							dbFile.fileID
							, dbAddress.addLine4		AS town	
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
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_matter_number >= 6 --excludes ML matter and earlier matters opened in 1990s
ORDER BY
	dim_matter_header_current.master_matter_number


END	

GO
