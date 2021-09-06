SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 03/09/2021
-- Description:	Ticket #110181 KPI and SLA Compliance report for client Hastings. 
-- =============================================

CREATE PROCEDURE [dbo].[hastings_kpi_sla_compliance]

AS

BEGIN

SELECT 
	dim_client_involvement.insurerclient_reference			AS [Hastings Claim Reference]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Supplier Reference]
	, dim_matter_header_current.matter_description			AS [Case Description]
	, dim_matter_header_current.matter_owner_full_name			AS [Case Manager]
	, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_instruction_type.instruction_type			AS [Hastings Instruction Type]
	, dim_detail_core_details.present_position			AS [Present Position]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened on MS]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date Instructions Received]
	, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers		AS [Date Full File of Papers Received]
	, dim_detail_core_details.do_clients_require_an_initial_report		AS [Initial Report Required?]
	, dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report			AS [Extension for Initial Report Agreed]
	, CAST(dim_detail_core_details.date_initial_report_due AS DATE)					AS [Date Initial Report Due]
	, CAST(dim_detail_core_details.date_initial_report_sent AS DATE)				AS [Date Initial Report Sent]
	, fact_detail_elapsed_days.days_to_first_report_lifecycle			AS [Number of Business Days to Initial Report Sent]
	, CAST(dim_detail_core_details.date_subsequent_sla_report_sent AS DATE)		AS [Date of Last SLA Report]
	, dim_detail_core_details.proceedings_issued					AS [Proceedings Issued?]
	, CAST(dim_detail_core_details.date_proceedings_issued AS DATE)			AS [Date Proceedings Issued]
	, defence_due_key_date.defence_due_date					AS [Date Defence Due - Key Date]
	, CAST(dim_detail_court.defence_due_date AS DATE)			AS [Date Defence Due - MI Field]	
	, CAST(dim_detail_core_details.date_defence_served AS DATE)		AS [Date Defence Filed]
	, dim_detail_core_details.suspicion_of_fraud			AS [Suspicion of Fraud?]
	, dim_detail_claim.hastings_fundamental_dishonesty		AS [Fundamental Dishonesty]
	, dim_detail_outcome.hastings_type_of_settlement			AS [Type of Settlement]
	, dim_detail_outcome.hastings_stage_of_settlement			AS [Stage of Settlement]
	, dim_detail_outcome.outcome_of_case					AS [Outcome of Case]
	, dim_detail_claim.hastings_offers_made_with_the_intention_to_rely_on_at_trial			AS [Offers Made with Intention to Rely on at Trial?]
	, CAST(dim_detail_core_details.target_settlement_date AS DATE)				AS [Target Settlement Date]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)				AS [Date Claim Concluded]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)				AS [Date Costs Settled]
	, dim_detail_claim.hastings_is_indemnity_an_issue				AS [Is Indemnity an Issue?]
	, dim_detail_claim.hastings_contribution_proceedings_issued			AS [Contribution Proceedings Issued?]
	, dim_detail_outcome.are_we_pursuing_a_recovery				AS [Are we Pursuing a Recovery]
	, dim_detail_client.hastings_recovery_from					AS [Recovery from]
	, CAST(dim_detail_claim.date_recovery_concluded AS DATE)			AS [Date Recovery Concluded]
	, fact_detail_client.recovery_amout					AS [Amount Recovered]
	, dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000		AS [Gross Damages Reserve Exceed £350,000?]
	, dim_detail_core_details.does_claimant_have_personal_injury_claim			AS [Does the Claimant have a PI Claim?]
	, dim_detail_core_details.injury_type				AS [Injury Type]
	, fact_detail_reserve_detail.hastings_predict_damages_meta_model_value		AS [PREDICT Damages Meta-model Value]
	, fact_detail_reserve_detail.predict_rec_damages_reserve_current			AS [PREDICT Recommended Damages Reserve (Current)]
	, 'TBC'					AS [Damages Paid 100%]
	, fact_detail_reserve_detail.hastings_predict_claimant_costs_meta_model_value		AS [PREDICT Claimant Costs Meta-model Value]
	, fact_detail_reserve_detail.predict_rec_claimant_costs_reserve_current			AS [PREDICT Recommended Claimant COsts Reserve (Current)]
	, fact_finance_summary.claimants_costs_paid				AS [Claimant Costs Paid]
	, fact_detail_reserve_detail.hastings_predict_lifecycle_meta_model_value			AS [PREDICT Lifecycle Meta-model Value]
	, fact_detail_reserve_detail.predict_rec_settlement_time				AS [PREDICT Recommended Settlement Time]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)			AS [Damages Lifecycle]
	, CAST(dim_detail_client.hastings_closure_date AS DATE)				AS [Hastings Closure Date]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)			AS [Date Closed on MS]
	, dim_detail_compliance.hastings_instructions_acknowledged_within_a_day			AS [SLA.A1 Instructions Acknowledged]
	, dim_detail_compliance.hastings_instructions_allocated_within_two_days			AS [SLA.A2 File Allocated]
	, dim_detail_compliance.hastings_file_set_up_on_collaborate			AS [SLA.A2 on Collaborate]
	, dim_detail_compliance.hastings_references_sent_to_ph_within_two_business_days		AS [SLA.A2 Refs Sent to Policyholder]
	, dim_detail_compliance.hastings_initial_contact_with_claimant_solicitors			AS [SLA.A2 Initial Contact with Claimant Sols]
	, dim_detail_compliance.hastings_initial_report_sent_within_ten_days				AS [SLA.A3 Initial Report 10 Days]
	, dim_detail_compliance.hastings_defences_submitted_to_hastings					AS [SLA.A4 Defencese Submitted 7 Days]
	, dim_detail_compliance.hastings_court_directions_provided_to_hastings			AS [SLA.A5 Court Directions Provided to Hastings 2 Days]
	, dim_detail_compliance.hastings_defence_submitted_to_court_within_direction_timetable		AS [SLA.A6 Defence Submitted to Court]
	, dim_detail_compliance.hastings_compliance_with_all_other_court_dates				AS [SLA.A7 Compliance with Court Dates]
	, dim_detail_compliance.hastings_brought_other_parties_into_litigation				AS [SLA.A8 Identified Other Parties]
	, dim_detail_compliance.hastings_urgent_developments_reported_two_days				AS [SLA.A9 Urgent Developments Reported]
	, dim_detail_compliance.hastings_update_reports_submitted_every_three_months		AS [SLA.A9 Update Reports Submitted]
	, dim_detail_compliance.hastings_significant_developments_reported_five_days		AS [SLA.A10 Significant Developments Reported]
	, dim_detail_compliance.hastings_provided_written_responses_in_a_timely_manner		AS [SLA.A11 Non-urgent Written Responses]
	, dim_detail_compliance.hastings_provided_written_responses_to_urgent_correspondence	AS [SLA.A12 Urgent Written Responses]
	, dim_detail_compliance.hastings_supplier_recognises_new_information_indicates_change		AS [SLA.A12 Supplier Written Responses]
	, dim_detail_compliance.hastings_responded_to_phone_calls_within_two_business_days			AS [SLA.A13 Responded to Phone Calls 2 Days]
	, dim_detail_compliance.hastings_outcome_reports_submitted_within_two_days			AS [SLA.A14 Outcome Reports Submitted 2 days]
	, dim_detail_compliance.hastings_trials_referred_to_and_signed_off_by_large_loss			AS [SLA.A15 Trials Referred to Large Loss]
	, dim_detail_compliance.hastings_advice_to_be_directed_to_the_hastings_handler			AS [SLA.A15 Trial Advice Directed to Hastings]
	, dim_detail_compliance.hastings_report_on_tactics_submitted_to_hastings				AS [SLA.A15 Full Report Tactics 2 Weeks]
	, dim_detail_compliance.hastings_any_trial_dates_missed					AS [SLA.A16 Trial Dates Missed]
	, dim_detail_compliance.hastings_reports_and_advice_to_be_provided_to_hastings			AS [SLA.A17 Experts Reports Provided to Hastings]
	, dim_detail_compliance.hastings_instructions_and_reports_agreed_with_hastings			AS [SLA.A17 Expoerts Reports Agreed with Hastings]
	, dim_detail_compliance.hastings_accurate_reserves_held_on_file_at_all_times			AS [SLA.A19 Accurate Reserves Held]
	, CASE 
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'Justified complaint made' THEN 
			'Yes'
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'No complaints made' THEN
			'No'
		ELSE 
			NULL
	  END																	AS [SLA.A20 Justified Complaints Made]
	, CASE 
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'Non-justified complaint made' THEN 
			'Yes'
		WHEN dim_detail_compliance.hastings_any_complaints_made = 'No complaints made' THEN
			'No'
		ELSE 
			NULL
	  END																	AS [SLA.A20 Non-Justified Complaints Made]
	, dim_detail_compliance.hastings_any_leakage_identified				AS [SLA.A21 Any Leakage Identified]
	, CAST(dim_detail_compliance.hastings_date_of_sla_review AS DATE)				AS [Date of Last Review]
	, CASE
		WHEN ISNULL(dim_detail_core_details.do_clients_require_an_initial_report, '') = 'No' THEN	
				'N/A'
			WHEN ISNULL(dim_detail_core_details.referral_reason, '') = 'Nomination only' AND dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NULL THEN
				'N/A'
			WHEN date_initial_report_sent IS NULL THEN	
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
	  END													AS [KPI A.1 Initial Advice]
	, CASE
		WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN	
			'Achieved'
		WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified but do not intend to plead' THEN
			'Not Achieved'
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR dim_detail_claim.hastings_fundamental_dishonesty = 'No fundamental dishonesty' THEN
			'N/A'
		ELSE
			NULL
	  END 											AS [KPI A.2 Fundamental Dishonesty Pleaded]
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_core_details.suspicion_of_fraud = 'Yes'
		AND dim_detail_claim.hastings_fundamental_dishonesty = 'Fundamental dishonesty identified and pleaded' THEN 
			CASE 
				WHEN dim_detail_outcome.hastings_type_of_settlement = 'Withdrawn' THEN
					'Achieved Withdrawn'
				WHEN dim_detail_outcome.hastings_type_of_settlement IN ('Calderbank', 'P36', 'Time limited') THEN
					'Achieved compromised'
				WHEN dim_detail_outcome.hastings_type_of_settlement IN ('Fundamental dishonesty defence', 'Other successful full defence') THEN
					'Achieved failed'
			END
		WHEN dim_detail_core_details.suspicion_of_fraud = 'No' OR (dim_detail_outcome.hastings_type_of_settlement = 'No fundamental dishonesty' AND dim_detail_outcome.date_claim_concluded IS NULL) THEN
			'N/A'
	  END										AS [KPI A.2 Fundamental Dishonesty Success]
	, CASE
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'Yes' AND dim_detail_claim.date_recovery_concluded IS NOT NULL 
		AND fact_detail_client.recovery_amout >= 1 THEN
			'Achieved'
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'Yes' AND dim_detail_claim.date_recovery_concluded IS NOT NULL 
		AND fact_detail_client.recovery_amout < 1 THEN
			'Not Achieved'
		WHEN dim_detail_claim.hastings_contribution_proceedings_issued = 'No' OR dim_detail_claim.date_recovery_concluded IS NULL THEN
			'N/A'
	  END															AS [KPI A.2 Contribution Proceedings]
	, CASE
		WHEN dim_detail_core_details.referral_reason LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_claim.hastings_is_indemnity_an_issue = 'Yes'
		AND dim_detail_claim.date_recovery_concluded IS NOT NULL AND LOWER(dim_detail_client.hastings_recovery_from) IN ('policyholder', 'policy holder') THEN
			CASE
				WHEN fact_detail_client.recovery_amout > 0 THEN
					'Achieved'
				ELSE
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' OR dim_detail_outcome.date_claim_concluded IS NULL OR dim_detail_claim.hastings_is_indemnity_an_issue = 'No'
		OR dim_detail_claim.date_recovery_concluded IS NULL THEN
			'N/A'
	  END									AS [KPI A.3 Indemnity Recoveries]
	, CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL
		AND dim_detail_claim.hastings_offers_made_with_the_intention_to_rely_on_at_trial = 'Yes' AND dim_detail_outcome.hastings_stage_of_settlement = 'Trial' THEN
			CASE
				WHEN dim_detail_outcome.outcome_of_case IN ('Won at trial', 'Assessment of damages (claimant fails to beat P36 offer)') THEN 
					'Achieved'
				WHEN dim_detail_outcome.outcome_of_case = 'Lost at trial' THEN 
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NULL THEN
			'N/A'
	  END									AS [KPI A.4 Offers and Outcomes]
	, CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' AND dim_detail_outcome.date_claim_concluded IS NOT NULL THEN
			CASE	
				WHEN dim_detail_core_details.target_settlement_date >= dim_detail_outcome.date_claim_concluded THEN
					'Achieved'
				WHEN dim_detail_core_details.target_settlement_date <= dim_detail_outcome.date_claim_concluded THEN 
					'Not Achieved'
			END
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%'AND dim_detail_outcome.date_claim_concluded IS NULL THEN
			'N/A'
	  END											AS [KPI A.5 Lifecycle]
	, CASE
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' OR dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000 = 'No'
		OR dim_detail_core_details.does_claimant_have_personal_injury_claim = 'No' OR dim_detail_core_details.injury_type = 'Fatal injury' 
		OR dim_matter_worktype.work_type_code = '1597' THEN
			'N/A'
		--logic to be added for Achieved/Not Achieved 
	 END									AS [KPI A.6 PREDICT]
	, 'TBC'			AS [KPI A.7 Internal Monthly Audits]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.client_code = dim_matter_header_current.client_code
			AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
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
	LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance
		ON dim_detail_compliance.client_code = dim_matter_header_current.client_code
			AND dim_detail_compliance.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
			AND fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.client_code = dim_matter_header_current.client_code
			AND fact_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
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
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.master_matter_number > 1

	
END 

GO
