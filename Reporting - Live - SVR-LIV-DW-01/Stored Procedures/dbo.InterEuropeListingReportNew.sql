SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Jamie Bonner>
-- Create date: <2020-01-24>
-- Description:	<ticket #43507 new logic for InterEurope listing report>
-- =============================================

CREATE PROCEDURE [dbo].[InterEuropeListingReportNew]
AS
BEGIN

    SET NOCOUNT ON;
    SELECT 
		SUBSTRING(h_current.client_code, PATINDEX('%[^0]%', h_current.client_code), LEN(h_current.client_code))
			+ '.' +
			SUBSTRING(h_current.matter_number, PATINDEX('%[^0]%', h_current.matter_number), LEN(h_current.matter_number))	AS [Weightmans Reference]
		, LTRIM(RTRIM(client_involv.client_reference))																		AS [Insurer Client Reference]
		, LTRIM(RTRIM(client_involv.insuredclient_name))																	AS [Insurer Client]
		, CAST(core_details.date_instructions_received AS DATE)																AS [Date Instructions Received]
		, CASE
			WHEN core_details.referral_reason = 'Costs dispute' THEN
				'Costs Only'
			WHEN core_details.referral_reason = 'Infant approval' THEN
				'Infant Approval'
			WHEN core_details.referral_reason = 'Nomination only' THEN
				'Procedural Only'
			WHEN core_details.track = 'Small Claims' THEN
				'Small Claims'
			WHEN core_details.track = 'Fast Track' THEN
				'Fast Track'
			WHEN core_details.track = 'Multi Track' THEN 
				'Multi Track'
			ELSE 
				NULL
		  END																												AS [Claim Category]
		, CASE 
			WHEN outcome.outcome_of_case = 'Exclude from reports' THEN
				'Excluded'
			WHEN outcome.date_costs_settled IS NULL THEN
				'Open'
			ELSE 
				'Closed'	
		  END																												AS [Status]
		, CAST(core_details.incident_date AS DATE)																			AS [Date of Accident]
		, COALESCE(third_party.claimantsols_name, third_party.claimantrep_name)												AS [Claimant Solicitor]
		, core_details.proceedings_issued																					AS [Proceedings Issued]
		, CASE
			WHEN outcome.date_claim_concluded IS NOT NULL THEN 
				NULL
			ELSE 
				fin_sum.damages_reserve_net	
		  END																												AS [Damages Reserve]
		, 'TBC'																												AS [Quantified Damages claimed] 			
		, CASE
			WHEN outcome.date_claim_concluded IS NOT NULL THEN 
				NULL
			ELSE 
				fin_sum.tp_costs_reserve_net	
		  END																												AS [TP Costs Reserve]
		, 'TBC'																												AS [Quantified Costs claimed]
		, outcome.outcome_of_case																							AS [Outcome of Case]
		, CASE
			WHEN outcome.date_claim_concluded IS NOT NULL THEN
				NULL
			ELSE elapsed_days.elapsed_days_live_files
		  END																												AS [Live elapsed days]
		, elapsed_days.elapsed_days_conclusion																				AS [Number of days to settlement]
		, elapsed_days.elapsed_days_costs_to_settle																			AS [Damages to costs lifecycle]
		, paid_detail.total_damages_paid																					AS [Damages Paid]
		, 'TBC'																												AS [Damages Saving against Reserve]
		, fin_sum.total_tp_costs_paid_to_date																				AS [TP Costs Paid]
		, 'TBC'																												AS [Costs Saving against Claimed]		
		, CAST(h_current.date_closed_case_management AS DATE)																AS [Date closed in MS]
		, ISNULL(fin_sum.total_amount_billed, 0)																			AS [Total billed (inc disbs)]
		, LTRIM(RTRIM(core_details.clients_claims_handler_surname_forename))												AS [InterEurope Handler Name] 
		, core_details.track																								AS [Track]
		, core_details.referral_reason																						AS [Referral Reason]
		, CAST(core_details.date_initial_report_sent AS DATE)																AS [Date Initial Report Sent]
		, CAST(core_details.date_subsequent_sla_report_sent AS DATE)														AS [Date of Subsequent Report]
		, CAST(core_details.date_the_closure_report_sent AS DATE)															AS [Date Of Report Closure (internal)]
		, fin_sum.damages_reserve																							AS [Damages Reserve  (not NET)]
		, 'TBC'																												AS [Quantified Damages Reserve (Not NET)]
		, res_detail.claimant_costs_reserve_current																			AS [TP costs Reserve (Not NET)]
		, 'TBC'																												AS [Quantified Costs Reserve (Not NET)]
		, find_trial_date.trial_date																						AS [Trial date]
		, core_details.present_position																						AS [Present Position]
		, detail_fin.output_wip_fee_arrangement																				AS [Fee Arrangement]
		, h_current.matter_owner_full_name																					AS [Weightmans Handler Name]
		, h_current.matter_description																						AS [Matter Description]
		, fin_sum.defence_costs_reserve																						AS [Defence Cost Reserve]
		, CAST(outcome.date_claim_concluded AS DATE)																		AS [Date Claim Concluded]
		--required for dashboard
		, outcome.[date_costs_settled]																						AS [Date Costs Settled]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.date_instructions_received, core_details.date_initial_report_sent) AS [Working Days to Initial Report Sent]
		, outcome.[repudiation_outcome]																					AS [Repudiation - outcome]
		, core_details.[ll00_have_we_had_an_extension_for_the_initial_report]											AS [Have we had an Extension for the Initail Report?]
	--select *
	FROM red_dw.dbo.dim_matter_header_current h_current
		INNER JOIN red_dw.dbo.fact_dimension_main fact_dim_main
			ON fact_dim_main.dim_matter_header_curr_key = h_current.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.dim_client_involvement client_involv
			ON client_involv.dim_client_involvement_key = fact_dim_main.dim_client_involvement_key
		INNER JOIN red_dw.dbo.dim_detail_core_details core_details
			ON core_details.dim_detail_core_detail_key = fact_dim_main.dim_detail_core_detail_key
		INNER JOIN red_dw.dbo.dim_detail_outcome outcome
			ON outcome.dim_detail_outcome_key = fact_dim_main.dim_detail_outcome_key
		INNER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement third_party
			ON third_party.dim_claimant_thirdpart_key = fact_dim_main.dim_claimant_thirdpart_key
		INNER JOIN red_dw.dbo.fact_finance_summary fin_sum
			ON fin_sum.master_fact_key = fact_dim_main.master_fact_key
		INNER JOIN red_dw.dbo.fact_detail_elapsed_days elapsed_days
			ON elapsed_days.master_fact_key = fact_dim_main.master_fact_key
		INNER JOIN red_dw.dbo.fact_detail_paid_detail paid_detail
			ON paid_detail.master_fact_key = fact_dim_main.master_fact_key
		INNER JOIN red_dw.dbo.dim_detail_finance detail_fin
			ON detail_fin.dim_detail_finance_key = fact_dim_main.dim_detail_finance_key
		INNER JOIN red_dw.dbo.fact_detail_reserve_detail res_detail
			ON res_detail.master_fact_key = fact_dim_main.master_fact_key
		LEFT OUTER JOIN (SELECT 
						court.client_code
						, court.matter_number
						, tasks.task_code
						, tasks.task_desccription
						, COALESCE(CAST(court.date_of_trial AS DATE), CAST(due.calendar_date AS DATE)) AS trial_date
					FROM red_dw.dbo.dim_detail_court court 
						INNER JOIN red_dw.dbo.dim_tasks tasks
							ON tasks.client_code = court.client_code AND tasks.matter_number = court.matter_number
						INNER JOIN red_dw.dbo.fact_tasks fact 
							ON fact.dim_tasks_key = tasks.dim_tasks_key
						INNER JOIN red_dw.dbo.dim_task_due_date due 
							ON due.dim_task_due_date_key = fact.dim_task_due_date_key
					WHERE 
						tasks.client_code = '00351402'
						AND tasks.task_desccription LIKE '%rial date - today%') find_trial_date
				ON find_trial_date.client_code = h_current.client_code AND find_trial_date.matter_number = h_current.matter_number
	WHERE 
		h_current.client_code = '00351402'
		AND h_current.matter_number <> 'ML'
		AND h_current.reporting_exclusions = 0
		AND CAST(core_details.date_instructions_received AS DATE)>='2019-11-01'
	

END;
GO
