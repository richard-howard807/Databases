SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [ss].[build_FinanceDataFile] as

drop table ss.FinanceDataFile

SELECT   
		RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
        , fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_client.client_name AS [Client Name]
		, fact_detail_paid_detail.admin_charges_total AS [Admin Charges Total]
		, fact_finance_summary.[defence_costs_billed] AS [Defence Costs Billed]
		, fact_finance_summary.[total_paid] AS [Total Paid]
		, fact_finance_summary.[disbursements_billed] AS [Disbursements Billed]
		, fact_finance_summary.disbursement_balance AS [Disbursements Balance]
		, fact_finance_summary.[unpaid_disbursements] AS [Unpaid Disbursements]
		, fact_finance_summary.opponents_disbursements_paid AS [Opponents Disbursements Paid]
		, fact_finance_summary.[vat_billed] AS [VAT Billed]
		, fact_finance_summary.unpaid_bill_balance AS [Unpaid Bill Balance] 
		, fact_finance_summary.[recovery_defence_costs_from_claimant] AS [Recovery Defence Costs from Claimant]
		, fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution] AS [Recovery Claimants Costs via Third Party Contribution]
		, fact_finance_summary.[recovery_defence_costs_via_third_party_contribution] AS [Recovery Defence Costs via Third Party Contribution]
		, fact_finance_summary.recovery_claimants_damages_via_third_party_contribution AS [Recovery Claimants Damages via Third Party Contribution]
		, fact_finance_summary.[total_recovery] AS [Total Recovery (sum of NMI112+NMI135+NMI136+NMI137)]
		, fact_detail_recovery_detail.monies_recovered_if_applicable AS [Monies Recovered if Applicable]
		, fact_detail_recovery_detail.monies_received AS [Monies Received]
		, fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		, fact_detail_cost_budgeting.total_budget_uploaded AS [Total Budget Uploaded]
		, dim_detail_client.date_budget_uploaded AS [Date Budget Uploaded]
		, dim_detail_client.has_budget_been_approved AS [Budget Approved]
		, fact_detail_paid_detail.personal_injury_paid AS [Personal Injury Paid]
		, fact_detail_client.client_balance AS [Client Balance]
		, fact_finance_summary.wip AS WIP
		, fact_detail_paid_detail.value_of_instruction AS [Value of Instruction]
		, fact_detail_cost_budgeting.initial_costs_estimate AS [Initial Costs Estimate]
		, fact_finance_summary.commercial_costs_estimate AS [Current Costs Estimate]
		, fact_finance_summary.damages_interims AS [Damage Interims]
		, fact_detail_paid_detail.interim_costs_payments AS [Interim Costs Payments]
		, fact_finance_summary.special_damages_miscellaneous_paid AS [Special Damages Miscellaneous Paid]
		, fact_detail_paid_detail.cru_paid_by_all_parties AS [CRU Paid by all Parties]
		, fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties AS [Total Settlement Value of the Claim Paid by all the Parties]
		, fact_finance_summary.detailed_assessment_costs_paid AS [Detailed Assessment Costs Paid]
		, fact_finance_summary.interlocutory_costs_paid_to_claimant AS [Interlocutory Costs Paid to Claimant]
		, fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction AS [Interim Costs Payments by Client Pre-Instruction]
		, fact_finance_summary.[other_defendants_costs_paid] AS [Other Defendants Costs Paid]
		, fact_finance_summary.other_defendants_costs_reserve_initial AS [Other Defendants Costs Reserve Initial]
		, fact_finance_summary.other_defendants_costs_reserve AS [Other Defendants Costs Reserve]
		, fact_finance_summary.[costs_claimed_by_another_defendant] AS [Costs Claimed by another Defendant]
		, fact_finance_summary.[detailed_assessment_costs_claimed_by_claimant] AS [Detailed Assessment Costs Claimed by Claimant]
		, fact_detail_future_care.[interlocutory_costs_claimed_by_claimant] AS [Interlocutory Costs Claimed by Claimant]
		, fact_finance_summary.claimants_total_costs_paid_by_all_parties AS [Claimants Total Costs Paid by all Parties]
		, fact_finance_summary.damages_paid AS [Damages Paid] 
		, fact_finance_summary.claimants_costs_paid AS [Claimants Costs Paid]
		, fact_finance_summary.tp_total_costs_claimed As [TP Total Costs Claimed]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]
		, fact_finance_summary.[damages_reserve_initial] AS [Damages Reserve Initial]
		, fact_detail_reserve_detail.[initial_damages_reserve] AS [Damages Reserve Initial (based on detail TRA077)]
		, fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		, fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Costs Reserve Initial]
		, fact_finance_summary.tp_costs_reserve AS [TP  Costs Reserve]
		, fact_finance_summary.[tp_costs_reserve_initial] AS [TP Costs Reserve Initial]
		, fact_finance_summary.total_reserve AS [Total Reserve]
		, fact_finance_summary.[total_reserve_initial] AS [Total Reserve Initial]
		, fact_detail_paid_detail.general_damages_paid AS [General Damages Paid]
		, fact_detail_paid_detail.special_damages_paid AS [Special Damages Paid]
		, fact_detail_paid_detail.cru_paid AS [CRU Paid]
		, dim_detail_claim.our_proportion_percent_of_costs AS [Our Proportion % of Costs]
		, fact_detail_paid_detail.our_proportion_costs AS [Our Proportion Costs]
		, fact_detail_client.[costs_paid] AS [Costs Paid]
		, fact_detail_client.[costs_reserve] AS [Costs Reserve]
		, fact_detail_client.[primary_cover_value] AS [Primary Cover Value]
		, fact_detail_cost_budgeting.[costs_written_off_compliance] AS [Costs Written off Compliance]
		, fact_detail_cost_budgeting.fees_estimate AS [Fees Estimate]
		, fact_finance_summary.commercial_costs_estimate_net AS [Outstanding Costs]
		, dim_detail_outcome.[final_bill_date_grp] AS  [Final Bill Date - Ageas]
		, fact_detail_client.defence_costs AS [Defence Costs]
		, fact_detail_paid_detail.[fee_estimate] AS [Fee Estimates]
		, fact_finance_summary.costs_to_date AS [Costs to Date]
		, ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.[claimants_costs_paid],0)AS [Trust Spend]
		, fact_detail_client.[nhsla_spend] AS [NHSLA Spend]
		, fact_finance_summary.damages_paid_to_date AS [Damages Paid to Date]
		, fact_detail_paid_detail.[total_paid] AS [Total Paid - Zurich]
		, dim_detail_finance.[damages_banding] AS [Damages Banding]
		, dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
		, dim_detail_finance.[output_wip_percentage_complete] AS [Percentage Completion]
		, fact_detail_cost_budgeting.[costs_paid_to_another_defendant] AS [Costs Paid to Another Defendant]
		, fact_detail_client.[nhs_charges_paid_by_all_parties] AS [NHS Charges Paid by all Parties]
		, fact_detail_future_care.[disease_total_estimated_settlement_value] AS [Disease Total Estimated Settlement Value]
		, fact_detail_paid_detail.[claimants_costs] AS [Claimant's Costs Paid]
		, fact_detail_paid_detail.[total_nil_settlements] AS [Outsource Damages Paid (WPS278+WPS279+WPS281)]
		, fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Total third party costs claimed (the sum of TRA094+NMI599+NMI600)]
		, fact_finance_summary.[total_tp_costs_paid] AS [Total third party costs paid (sum of TRA072+NMI143+NMI379)]
		, fact_finance_summary.[total_reserve_net] AS [Total Reserve (Net)]
		, fact_finance_summary.[damages_reserve_net] AS [Damages Reserve (Net)]
		, fact_finance_summary.[tp_costs_reserve_net] AS [Claimant's Costs Reserve (Net)]
		, fact_finance_summary.[defence_costs_reserve_net] AS [Defence Costs Reserve (Net)]
		, fact_detail_reserve_detail.[solicitor_total_current_reserve] AS [Solicitor Total Reserve Current]
		, fact_detail_paid_detail.[interim_payments] AS [Interim Payments]
		, fact_detail_reserve_detail.[personal_injury_reserve_initial] AS [PI Reserve Initial]
		, fact_detail_cost_budgeting.[personal_injury_reserve_current] AS [PI Reserve Current]
		, dim_detail_outcome.[percent_success_fee_claimed] AS [% Success Fee Claimed]
		, fact_detail_reserve_detail.[amount_of_success_fee_claimed] AS [Amount of Success Fee Claimed]
		, fact_finance_summary.[ate_premium_claimed] AS [ATE Premium Claimed]
		, fact_detail_reserve_detail.[claimant_s_solicitor_s_base_costs_claimed_vat] AS [Claimant's solicitor's base costs claimed + VAT]
		, fact_detail_paid_detail.[claimants_disbursements_claimed] AS [Claimant's disbursements claimed]
		, fact_detail_paid_detail.[percent_success_fee_paid] AS [% Success Fee Paid]
		, fact_detail_paid_detail.[amount_of_success_fee_paid] AS [Amount of Success Fee Paid]
		, fact_finance_summary.[ate_premium_paid] AS [ATE Premium Paid]
		, fact_detail_paid_detail.[claimant_s_solicitor_s_base_costs_paid_vat] AS [Claimant's solicitor's base costs paid + VAT]
		, fact_finance_summary.[claimants_solicitors_disbursements_paid] AS [Claimant's solicitor's disbursements paid]
		, fact_detail_paid_detail.[general_damages_misc_paid] AS [General Damages Misc Paid]
		, fact_detail_paid_detail.[past_care_paid] AS [Past Care Paid]
		, fact_detail_paid_detail.[past_loss_of_earnings_paid] AS [Past Loss of Earnings Paid]
		, fact_detail_paid_detail.[cru_costs_paid] AS [CRU Costs Paid]
		, fact_detail_paid_detail.[cru_offset] AS [CRU Offset against Damages]
		, fact_detail_paid_detail.[future_care_paid] AS [Future Care Paid]
		, fact_detail_paid_detail.[future_loss_of_earnings_paid] AS [Future Loss of Earnings Paid]
		, fact_detail_paid_detail.[future_loss_misc_paid] AS [Future Loss Misc Paid]
		, fact_detail_paid_detail.[nhs_charges_paid_by_client] AS [NHS Charges Paid by Client]
		, fact_finance_summary.[other_defendants_costs_reserve] AS [Other defendants costs - reserve (current)] --NMI519
		, fact_detail_reserve_detail.[general_damages_non_pi_misc_reserve_current] AS [General damages (non-PI) - misc reserve (current)] --NMI514
		, ISNULL(dim_detail_health.[nhs_billing_status],'Final') AS [NHS) Billing Status]
		, fact_detail_reserve_detail.claimant_costs_reserve_current   --TRA080
		, CASE WHEN dim_matter_header_current.final_bill_flag=0 OR dim_matter_header_current.final_bill_flag IS NULL THEN 'N' ELSE 'Y' END AS [Final Bill Flag]
		, CASE WHEN dim_detail_critical_mi.claim_status IN ('Open', 'Re-opened') THEN ''
			   WHEN dim_detail_critical_mi.claim_status  IN ('Closed') AND (ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant,0)+ISNULL(fact_finance_summary.detailed_assessment_costs_paid,0))=0 THEN 'Nil Settlement'
               WHEN dim_detail_critical_mi.claim_status  IN ('Closed') AND (ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant,0)+ISNULL(fact_finance_summary.detailed_assessment_costs_paid,0))>0 THEN 'Payment Made'
               END [Nill Settlement]
		, CASE WHEN dim_matter_header_current.final_bill_flag=1 THEN '0'
				WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN '0'
				ELSE fact_finance_summary.commercial_costs_estimate_net
		  END AS [Outstanding Costs Estimate]
		, CASE WHEN fact_finance_summary.[damages_paid] + fact_finance_summary.[claimants_costs_paid] > 0 THEN 'Payment made' 
				WHEN fact_finance_summary.[damages_paid] + fact_finance_summary.[claimants_costs_paid] = 0 THEN 'Repudiated' end as [Repudiated/Payment Made (lees)]
		, dim_detail_claim.[date_final_bill] AS [Claim Status]
		, fact_finance_summary.[total_amount_billed] AS [Total Amount Billed]
		, ISNULL(fact_finance_summary.[total_amount_billed],0)-ISNULL(fact_finance_summary.vat_billed,0) [Total Amount Billed (exc VAT)]
		, ISNULL(fact_finance_summary.commercial_costs_estimate,0)-(ISNULL(fact_finance_summary.[total_amount_billed],0)-ISNULL(fact_finance_summary.vat_billed,0)) [Total Outstanding Costs]
		, ISNULL(fact_detail_future_care.[interlocutory_costs_claimed_by_claimant],0) + ISNULL(fact_finance_summary.[claimants_costs_paid],0) + ISNULL(fact_finance_summary.[detailed_assessment_costs_paid],0) + ISNULL(fact_finance_summary.[other_defendants_costs_paid],0) AS [Opponents Cost Spend]
		, ISNULL(fact_finance_summary.[tp_costs_reserve_initial], 0) + ISNULL(fact_finance_summary.[other_defendants_costs_reserve_initial], 0) AS [Initial claimant's costs reserve / estimation] 
		, fact_bill_detail_summary.bill_total AS [Total Bill Amount - Composite (IncVAT )]
		, fact_bill_detail_summary.bill_total_excl_vat AS [Total Bill Amount - Composite (excVAT)] 
		, fact_bill_detail_summary.disbursements_billed_exc_vat
		, ISNULL(fact_finance_summary.commercial_costs_estimate,0)-(ISNULL(fact_bill_detail_summary.bill_total_excl_vat,0)) [Total Outstanding Costs - Composite]
		, CASE WHEN fact_finance_summary.[damages_paid] IS NULL  AND fact_detail_paid_detail.[general_damages_paid] IS NULL AND fact_detail_paid_detail.[special_damages_paid] IS NULL AND fact_detail_paid_detail.[cru_paid] IS NULL THEN NULL
			ELSE  (CASE WHEN fact_finance_summary.[damages_paid] IS NULL THEN (ISNULL(fact_detail_paid_detail.[general_damages_paid],0)+ISNULL(fact_detail_paid_detail.[special_damages_paid],0)+ ISNULL(fact_detail_paid_detail.[cru_paid],0)) ELSE fact_finance_summary.[damages_paid] END) END AS [Damages Paid by Client - Disease]
		, CASE WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL  AND fact_detail_paid_detail.[total_nil_settlements] IS NULL THEN NULL
				ELSE (CASE WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL THEN (CASE WHEN ISNULL(dim_detail_claim.[our_proportion_percent_of_damages],0)=0 THEN NULL ELSE (ISNULL(fact_detail_paid_detail.[general_damages_paid],0)+ISNULL(fact_detail_paid_detail.[special_damages_paid],0)+ ISNULL(fact_detail_paid_detail.[cru_paid],0))/dim_detail_claim.[our_proportion_percent_of_damages] END) 
				ELSE fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] END) END AS [Damages Paid (all parties) - Disease]
		, CASE WHEN fact_finance_summary.[claimants_costs_paid] IS NULL AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN NULL ELSE COALESCE(fact_finance_summary.[claimants_costs_paid],fact_detail_paid_detail.[claimants_costs]) END AS [Claimant's Costs Paid by Client - Disease]
		, CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN NULL
				ELSE (CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL THEN 
			(CASE WHEN ISNULL(fact_detail_paid_detail.[our_proportion_costs ],0)=0 THEN NULL ELSE ISNULL(fact_detail_paid_detail.[claimants_costs],0)/fact_detail_paid_detail.[our_proportion_costs ] END) 
				ELSE fact_finance_summary.[claimants_total_costs_paid_by_all_parties] END)  END AS [Claimant's Total Costs Paid (all parties) - Disease]
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL AND dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 0 ELSE fact_finance_summary.[other_defendants_costs_reserve] END AS [Other Defendant's Costs Reserve (Net)]
		, fact_finance_summary.[claimants_total_costs_paid_by_all_parties]
		, fact_detail_paid_detail.tp_total_costs_claimed_all_parties
		, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction
		, fact_finance_summary.damages_interims
		, fact_finance_summary.indemnity_spend
	

into ss.FinanceDataFile
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care ON fact_detail_future_care.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key=fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key=fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key=fact_dimension_main.master_fact_key --added in for Composite Billing JL
LEFT OUTER JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key


WHERE 
ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
GO
