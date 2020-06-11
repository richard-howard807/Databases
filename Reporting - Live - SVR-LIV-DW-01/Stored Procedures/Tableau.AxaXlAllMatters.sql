SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2020-02-17
Description:		Data for all AXA XL matters for Tableau
Ticket:				47664
Current Version:	Initial Create
====================================================
-- ES 2020-06-11 amended where clause to match the where clause in the report [axa].[axa_matter_listing_report], requested by HF
====================================================
*/

CREATE PROCEDURE [Tableau].[AxaXlAllMatters]
AS
	BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SET NOCOUNT ON
	
	
	DROP TABLE IF EXISTS #claimant_address
	DROP TABLE IF EXISTS #time_recording
	DROP TABLE IF EXISTS #revenue
	
	
--====================================================================================================================================================================================
-- Temp table to access the claimants address and postcode
--====================================================================================================================================================================================
	
	
	SELECT fact_dimension_main.master_fact_key										AS [fact_key],
	       dim_client.contact_salutation											AS [claimant1_contact_salutation],
	       dim_client.addresse														AS [claimant1_addresse],
	       dim_client.address_line_1												AS [claimant1_address_line_1],
	       dim_client.address_line_2												AS [claimant1_address_line_2],
	       dim_client.address_line_3												AS [claimant1_address_line_3],
	       dim_client.address_line_4												AS [claimant1_address_line_4],
	       dim_client.postcode														AS [claimant1_postcode]
	INTO #claimant_address
	FROM red_dw.dbo.dim_claimant_thirdparty_involvement
	    INNER JOIN red_dw.dbo.fact_dimension_main
	        ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
	    INNER JOIN red_dw.dbo.dim_involvement_full
	        ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
	    INNER JOIN red_dw.dbo.dim_client
	        ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
	WHERE dim_client.dim_client_key <> 0
	
	
	
	
--====================================================================================================================================================================================
-- Temp Table to gather up all time recordings on AXA XL matters split by handler role
--====================================================================================================================================================================================
	
	SELECT 
		all_time.client_code
	    , all_time.matter_number
	    , all_time.master_fact_key
	    , ISNULL(SUM(all_time.partner_consultant_time), 0) / 60																		AS [partner_consultant_hours]
	    , ISNULL(SUM(all_time.associate_time), 0) / 60																				AS [associate_hours]
	    , ISNULL(SUM(all_time.solicitor_legal_exec_time), 0) / 60																	AS [solicitor_legal_exec_time_hours]
	    , ISNULL(SUM(all_time.paralegal_time), 0) / 60																				AS [paralegal_hours]
	    , ISNULL(SUM(all_time.trainee_time), 0) / 60																				AS [trainee_hours]
	    , ISNULL(SUM(all_time.other_time), 0) / 60																					AS [other_hours]
	INTO #time_recording
	FROM (
			SELECT 
				dim_matter_header_current.client_code
			    , dim_matter_header_current.matter_number
			    , fact_chargeable_time_activity.master_fact_key
			    , CASE
			         WHEN partners.jobtitle LIKE '%Partner%'
			              OR partners.jobtitle LIKE '%Consultant%' THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [partner_consultant_time]
			    , CASE
			         WHEN partners.jobtitle LIKE '%Associate%' THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [associate_time]
			    , CASE
			         WHEN partners.jobtitle LIKE 'Solicitor%' OR partners.jobtitle LIKE '%Legal Executive%' THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [solicitor_legal_exec_time]
			    , CASE
			         WHEN partners.jobtitle LIKE '%Paralegal%' THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [paralegal_time]
			    , CASE
			         WHEN partners.jobtitle LIKE '%Trainee Solicitor%' THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [trainee_time]
			    , CASE
			         WHEN partners.jobtitle NOT LIKE '%Partner%' AND partners.jobtitle NOT LIKE '%Consultant%'
							AND partners.jobtitle NOT LIKE '%Associate%' AND partners.jobtitle NOT LIKE '%Solicitor%'
							AND partners.jobtitle NOT LIKE '%Legal Executive%' AND partners.jobtitle NOT LIKE '%Paralegal%'
							AND partners.jobtitle NOT LIKE '%Trainee%' OR partners.jobtitle IS NULL THEN
			             SUM(fact_chargeable_time_activity.minutes_recorded)
			         ELSE
			             0
			      END																												AS [other_time]
			FROM red_dw.dbo.fact_chargeable_time_activity
				LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
					ON fact_dimension_main.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
			    LEFT OUTER JOIN (
									SELECT DISTINCT
										dim_fed_hierarchy_history_key
										, jobtitle
										, name
									FROM red_dw.dbo.dim_fed_hierarchy_history
								)																									AS partners
					ON Partners.dim_fed_hierarchy_history_key = fact_chargeable_time_activity.dim_fed_hierarchy_history_key
			    LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
				LEFT OUTER JOIN red_dw.dbo.dim_client
					ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
			WHERE 
				dim_client.client_group_name = 'AXA XL'
				AND minutes_recorded <> 0
			GROUP BY 
				dim_matter_header_current.client_code
			    , dim_matter_header_current.matter_number
			    , fact_chargeable_time_activity.master_fact_key
			    , partners.jobtitle
		 ) AS all_time
	GROUP BY 
		all_time.client_code
	    , all_time.matter_number
	    , all_time.master_fact_key
	
	
	
	
--====================================================================================================================================================================================
-- Temp table providing all revenue, hours and disbs billed on AXA XL matters
--====================================================================================================================================================================================
	
	
	SELECT 
		fact_bill_detail.client_code
		, fact_bill_detail.matter_number
		, SUM(fact_bill_detail.bill_total_excl_vat)									AS [revenue]
		, SUM(fact_bill_detail.workhrs)												AS [hours_billed]
		, disbs_billed.disbursements_billed											AS [disbursements_billed]
		, total_billed.total_billed													AS [total_billed]
		, DATEPART(YEAR, dim_bill_date.bill_date)									AS [year_billed]
	
	INTO #revenue
	FROM red_dw.dbo.fact_bill_detail
		INNER JOIN red_dw.dbo.dim_bill_date
			ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
		INNER JOIN red_dw.dbo.dim_client
			ON dim_client.dim_client_key = fact_bill_detail.dim_client_key
		LEFT OUTER JOIN (
							SELECT 
								fact_bill_detail.client_code
								, fact_bill_detail.matter_number
								, SUM(fact_bill_detail.bill_total_excl_vat)									AS [disbursements_billed]
								, DATEPART(YEAR, dim_bill_date.bill_date)									AS [year_billed]
							FROM red_dw.dbo.fact_bill_detail
								INNER JOIN red_dw.dbo.dim_bill_date
									ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
								INNER JOIN red_dw.dbo.dim_client
									ON dim_client.dim_client_key = fact_bill_detail.dim_client_key
							WHERE 
								charge_type='disbursements'
								AND client_group_name = 'AXA XL'
								AND bill_number <> 'PURGE'
							GROUP BY 
								fact_bill_detail.client_code
								, fact_bill_detail.matter_number
								, DATEPART(YEAR, dim_bill_date.bill_date)
						)																					AS disbs_billed
							ON disbs_billed.client_code = fact_bill_detail.client_code AND disbs_billed.matter_number = fact_bill_detail.matter_number 
								AND disbs_billed.year_billed = DATEPART(YEAR, dim_bill_date.bill_date)
		LEFT OUTER JOIN (
							SELECT 
								fact_bill_detail.client_code
								, fact_bill_detail.matter_number
								, SUM(bill_total)															AS [total_billed]
								, DATEPART(YEAR, dim_bill_date.bill_date)									AS [year_billed]
							FROM red_dw.dbo.fact_bill_detail
								INNER JOIN red_dw.dbo.dim_bill_date
									ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
								INNER JOIN red_dw.dbo.dim_client
									ON dim_client.dim_client_key = fact_bill_detail.dim_client_key
							WHERE 
								client_group_name = 'AXA XL'
								AND bill_number <> 'PURGE'
							GROUP BY 
								fact_bill_detail.client_code
								, fact_bill_detail.matter_number
								, DATEPART(YEAR, dim_bill_date.bill_date)
						)																					AS total_billed
							ON total_billed.client_code = fact_bill_detail.client_code AND total_billed.matter_number = fact_bill_detail.matter_number 
								AND total_billed.year_billed = DATEPART(YEAR, dim_bill_date.bill_date)
	WHERE 
		charge_type IN ('charge', 'time')
		AND client_group_name = 'AXA XL'
		AND bill_number <> 'PURGE'
	GROUP BY 
		fact_bill_detail.client_code
		, fact_bill_detail.matter_number
		, disbs_billed.disbursements_billed
		, total_billed.total_billed
		, DATEPART(YEAR, dim_bill_date.bill_date)
	ORDER BY 
		fact_bill_detail.client_code
		, fact_bill_detail.matter_number
		, DATEPART(YEAR, dim_bill_date.bill_date)
	
	
	
	
--====================================================================================================================================================================================
--	Main Procedure
--====================================================================================================================================================================================
	
	SELECT --TOP 100 
		SUBSTRING(dim_matter_header_current.client_code,PATINDEX('%[^0]%', dim_matter_header_current.client_code)
			, LEN(dim_matter_header_current.client_code)) 
			+ '-' + 
			SUBSTRING(dim_matter_header_current.matter_number,PATINDEX('%[^0]%', dim_matter_header_current.matter_number)
			, LEN(dim_matter_header_current.matter_number))																	AS [Weightmans Reference]
		, dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number				AS [Mattersphere Weightmans Reference]
		, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number				AS [3E Reference]
		, dim_matter_header_current.matter_description																		AS [Matter Description]
		, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)											AS [Date Opened]
		, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)											AS [Date Closed]
		, dim_matter_header_current.matter_owner_full_name																	AS [Case Manager]
		, dim_fed_hierarchy_history.hierarchylevel4hist																		AS [Team]
		, dim_fed_hierarchy_history.hierarchylevel3hist																		AS [Department]
		, dim_matter_worktype.work_type_name																				AS [Work Type]
		, dim_matter_worktype.work_type_group																				AS [Work Type Group]
		, dim_client.client_name																							AS [Client Name]
		, dim_client.client_group_name																						AS [Client Group]
		, dim_instruction_type.instruction_type																				AS [Instruction Type] 
		, dim_client_involvement.insurerclient_reference																	AS [Insurer Client Reference]
		, dim_detail_core_details.clients_claims_handler_surname_forename													AS [Clients Claims Handler]
		, dim_client_involvement.insuredclient_reference																	AS [Insured Client Reference]
		, dim_detail_claim.dst_insured_client_name																			AS [Insured Client Name (Data Services)]
		, dim_detail_core_details.insured_sector																			AS [Insured Sector]
		, dim_detail_core_details.insured_departmentdepot																	AS [Insured Department]
		, dim_detail_core_details.insured_departmentdepot_postcode															AS [insured Department Postcode]
		, LTRIM(RTRIM(dim_detail_core_details.present_position))															AS [Present Position]
		, dim_detail_core_details.referral_reason																			AS [Referral Reason]
		, LTRIM(RTRIM(dim_detail_core_details.proceedings_issued))															AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued																			AS [Date Proceedings Issued]
		, dim_court_involvement.court_reference																				AS [Court Reference]
		, dim_court_involvement.court_name																					AS [Court Name]
		, dim_detail_core_details.track																						AS [Track]
		, dim_detail_core_details.suspicion_of_fraud																		AS [Suspicion of Fraud?]
		, dim_detail_fraud.fraud_type																						AS [Fraud Type]
		, dim_detail_core_details.credit_hire																				AS [Credit Hire]
		, dim_detail_hire_details.credit_hire_organisation																	AS [Credit Hire Organisation]
		, dim_detail_core_details.brief_details_of_claim																	AS [Brief Details of Claim]
		, dim_detail_core_details.injury_type																				AS [Description of Injury]
		, dim_detail_core_details.is_there_an_issue_on_liability															AS [Liability Issue]
		, dim_matter_header_current.fee_arrangement																			AS [Fee Arrangement]
		, CAST(dim_detail_core_details.incident_date AS DATE)																AS [Incident Date]
		, dim_detail_core_details.incident_location																			AS [Incident Location]
		, dim_detail_core_details.incident_location_postcode																AS [Incident Location Postcode]
		, dim_detail_core_details.has_the_claimant_got_a_cfa																AS [Has the Claimant got a CFA]
		, dim_detail_claim.cfa_entered_into_before_1_april_2013																AS [CFA entered into before 1 April 2013]
		, dim_detail_claim.dst_claimant_solicitor_firm																		AS [Claimant's Solicitor (Data Service)]
		, claimants_address.claimant1_postcode																				AS [Claimant Postcode]
		, fact_finance_summary.damages_reserve																				AS [Damages Reserve Current]
		, fact_finance_summary.damages_reserve_net																			AS [Damages Reserve Current (Net)]
		, dim_detail_hire_details.claim_for_hire_combined																	AS [Hire Claimed]
		, fact_detail_reserve_detail.claimant_costs_reserve_current															AS [Claimant Costs Reserve Current]
		, fact_detail_reserve_detail.current_claimant_solicitors_costs_reserve_net											AS [Claimant Costs Reserve Current (Net)]
		, fact_finance_summary.defence_costs_reserve																		AS [Defence Costs Reserve Current]
		, fact_finance_summary.defence_costs_reserve_net																	AS [Defence Costs Reserve Current (Net)]
		, dim_detail_outcome.outcome_of_case																				AS [Outcome of Case]
		, dim_detail_court.date_of_trial																					AS [Date of Trial] 
		, CAST(dim_detail_outcome.date_claim_concluded AS DATE)																AS [Date Claim Concluded]
		, fact_finance_summary.damages_interims																				AS [Interim Damages]
		, CASE
			WHEN fact_finance_summary.damages_paid IS NULL AND fact_detail_paid_detail.general_damages_paid IS NULL
			AND fact_detail_paid_detail.special_damages_paid IS NULL AND fact_detail_paid_detail.cru_paid IS NULL THEN	
				NULL
			ELSE 
				CASE	
					WHEN fact_finance_summary.damages_paid IS NULL THEN
						ISNULL(fact_detail_paid_detail.general_damages_paid, 0)
						+ ISNULL(fact_detail_paid_detail.special_damages_paid, 0) 
						+ ISNULL(fact_detail_paid_detail.cru_paid, 0)
					ELSE
						fact_finance_summary.damages_paid
				END
		  END																												AS [Damages Paid by Client]
		, fact_detail_paid_detail.personal_injury_paid																		AS [Personal Injury Paid]
		, fact_detail_paid_detail.amount_hire_paid																			AS [Hire Paid]
		, fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties								AS [Damages Paid (All Parties)]
		, dim_detail_outcome.date_claimants_costs_received																	AS [Date Claimant's Costs Received]
		, dim_detail_outcome.date_costs_settled																				AS [Date Costs Settled]
		, fact_detail_paid_detail.interim_costs_payments																	AS [Interim Costs Payments]
		, fact_finance_summary.tp_total_costs_claimed																		AS [Claimant's Total Costs Claimed against Client]
		, fact_finance_summary.claimants_costs_paid																			AS [Claimant's Costs Paid by Client]
		, fact_finance_summary.detailed_assessment_costs_claimed_by_claimant												AS [Detailed Assessment Costs Claimed by Claimant]
		, fact_finance_summary.detailed_assessment_costs_paid																AS [Detailed Assessment Costs Paid]
		, fact_finance_summary.costs_claimed_by_another_defendant															AS [Costs Claimed by Another Defendant]
		, fact_detail_paid_detail.costs_paid_to_another_defendant															AS [Costs Paid to Another Defendant]
		, fact_finance_summary.claimants_total_costs_paid_by_all_parties													AS [Claimants Total Costs Paid by All Parties]
		, fact_finance_summary.total_recovery																				AS [Total Recovery (NMI112,NMI135,NMI136,NMI137)]
		, fact_bill_detail_summary.bill_total																				AS [Total Bill Amount - Composite (Inc VAT)]
		, fact_finance_summary.defence_costs_billed																			AS [Revenue Costs Billed]
		, fact_bill_detail_summary.disbursements_billed_exc_vat																AS [Disbursements Billed]
		, fact_bill_detail_summary.vat_amount																				AS [VAT Billed]
		, fact_finance_summary.wip																							AS [WIP]
		, fact_finance_summary.disbursement_balance																			AS [Unbilled Disbursements]
		, CAST(fact_matter_summary_current.last_bill_date AS DATE)															AS [Last Bill Date Composite]
		, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE)												AS [Date of Last Time Posting]
		, ISNULL(time_recording.partner_consultant_hours, 0)																AS [Total Partner/Consultant Hours Recorded]
		, ISNULL(time_recording.associate_hours, 0)																			AS [Total Associate Hours Recorded]
		, ISNULL(time_recording.solicitor_legal_exec_time_hours, 0)															AS [Total Solicitor/LegalExec Hours Recorded]
		, ISNULL(time_recording.paralegal_hours, 0)																			AS [Total Paralegal Hours Recorded]
		, ISNULL(time_recording.trainee_hours, 0)																			AS [Total Trainee Hours Recorded]
		, ISNULL(time_recording.other_hours, 0)																				AS [Total Other Hours Recorded]
		, ISNULL(revenue_2017.total_billed, 0)																				AS [Total Billed 1 Jan - 31 Dec 2017]
		, ISNULL(revenue_2018.total_billed, 0)																				AS [Total Billed 1 Jan - 31 Dec 2018]
		, ISNULL(revenue_2019.total_billed, 0)																				AS [Total Billed 1 Jan - 31 Dec 2019]
		, ISNULL(revenue_2020.total_billed, 0)																				AS [Total Billed 1 Jan - 31 Dec 2020]
		, ISNULL(revenue_2017.revenue, 0)																					AS [Revenue 1 Jan - 31 Dec 2017]
		, ISNULL(revenue_2018.revenue, 0)																					AS [Revenue 1 Jan - 31 Dec 2018]
		, ISNULL(revenue_2019.revenue, 0)																					AS [Revenue 1 Jan - 31 Dec 2019]
		, ISNULL(revenue_2020.revenue, 0)																					AS [Revenue 1 Jan - 31 Dec 2020]
		, ISNULL(revenue_2017.disbursements_billed, 0)																		AS [Disbursements Billed 1 Jan - 31 Dec 2017]
		, ISNULL(revenue_2018.disbursements_billed, 0)																		AS [Disbursements Billed 1 Jan - 31 Dec 2018]
		, ISNULL(revenue_2019.disbursements_billed, 0)																		AS [Disbursements Billed 1 Jan - 31 Dec 2019]
		, ISNULL(revenue_2020.disbursements_billed, 0)																		AS [Disbursements Billed 1 Jan - 31 Dec 2020]
		, ISNULL(revenue_2017.hours_billed, 0)																				AS [Hours Billed 1 Jan - 31 Dec 2017]
		, ISNULL(revenue_2018.hours_billed, 0)																				AS [Hours Billed 1 Jan - 31 Dec 2018]
		, ISNULL(revenue_2019.hours_billed, 0)																				AS [Hours Billed 1 Jan - 31 Dec 2019]
		, ISNULL(revenue_2020.hours_billed, 0)																				AS [Hours Billed 1 Jan - 31 Dec 2020]
	--select *
	FROM red_dw.dbo.dim_matter_header_current
	    INNER JOIN red_dw.dbo.fact_dimension_main
	        ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
	        ON red_dw.dbo.dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
			ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
		LEFT OUTER JOIN red_dw.dbo.dim_client
			ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
			ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
		LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
			ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
			ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
			ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_court
			ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
		LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
			ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
			ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
			ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
		LEFT OUTER JOIN	#claimant_address																														AS claimants_address
			ON claimants_address.fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
			ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
			ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
			ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN	red_dw.dbo.dim_detail_outcome
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary
			ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN #time_recording																															AS time_recording
			ON time_recording.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN #revenue																																AS revenue_2017
			ON revenue_2017.client_code = dim_matter_header_current.client_code AND revenue_2017.matter_number = dim_matter_header_current.matter_number
				AND revenue_2017.year_billed = '2017'
		LEFT OUTER JOIN #revenue																																AS revenue_2018
			ON revenue_2018.client_code = dim_matter_header_current.client_code AND revenue_2018.matter_number = dim_matter_header_current.matter_number
				AND revenue_2018.year_billed = '2018'
		LEFT OUTER JOIN #revenue																																AS revenue_2019
			ON revenue_2019.client_code = dim_matter_header_current.client_code AND revenue_2019.matter_number = dim_matter_header_current.matter_number
				AND revenue_2019.year_billed = '2019'
		LEFT OUTER JOIN #revenue																																AS revenue_2020
			ON revenue_2020.client_code = dim_matter_header_current.client_code AND revenue_2020.matter_number = dim_matter_header_current.matter_number
				AND revenue_2020.year_billed = '2020'
	WHERE 
		--red_dw.dbo.dim_client.client_group_name = 'AXA XL'
		--AND red_dw.dbo.dim_matter_header_current.matter_number <> 'ML'
		--AND reporting_exclusions <> 1
		  ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_opened_case_management >= '20170101'
	ORDER BY dim_matter_header_current.date_opened_practice_management

END
GO
