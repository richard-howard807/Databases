SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 16/02/2018
-- Ticket Number: 294178 & 294219
-- Description:	New datasource for the new AXA Listing report and accompanying Dashboard
-- =============================================
CREATE PROCEDURE [axa].[axa_matter_listing_report]
	
AS
BEGIN
	
	
	SELECT  
		
			[Date instructions received] = dim_detail_core_details.date_instructions_received
			,[Line of Business] = dim_matter_worktype.work_type_name
			--,[Work Type Group] = CASE WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN 'NHSLA'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN 'PL All'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN 'PL Pol'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN 'PL OL'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN 'Prof Risk'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN 'EL'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN 'Motor'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Disease'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN 'OI'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN 'LMT'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN 'Recovery'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN 'Insurance Costs'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN 'Education'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN 'Healthcare'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN 'Claims Handling'
			--		WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN 'Health and Safety'
			--		ELSE 'Other'
			--		END
			,[Weightmans FE] = fee_earner.name
			,[Weightmans Reference ] = RTRIM(fact_dimension_main.client_code)+'-'+fact_dimension_main.matter_number 
			,[AXA CS Handler] = dim_detail_core_details.clients_claims_handler_surname_forename
			,[AXA CS Reference] = client_ref.insurerclient_reference
			,[Date of Accident] = dim_detail_core_details.incident_date
			,[Claimant Solicitors] = tp_ref.claimantsols_name
			,[Injury Type ] = dim_detail_core_details.brief_description_of_injury
			,[Matter Description] = dim_matter_header_current.matter_description
			,[Present Position] =dim_detail_core_details.present_position
			,[Referral reason] = dim_detail_core_details.referral_reason
			,[Track] = dim_detail_core_details.track
			,[Proceedings issued] = dim_detail_core_details.proceedings_issued
			,[Suspicion of Fraud] = dim_detail_core_details.suspicion_of_fraud
			,[Damages Reserve Current] = fact_finance_summary.damages_reserve
			,[TP Costs Reserve Current]=fact_finance_summary.tp_costs_reserve
			,[Defence Costs Reserve Current]=fact_finance_summary.defence_costs_reserve
			,[Date Claim Concluded] = dim_detail_outcome.date_claim_concluded
			,[Outcome] = dim_detail_outcome.outcome_of_case
			,[Damages Paid]= fact_finance_summary.damages_paid
			,[Total Settlement value]=fact_finance_summary.total_settlement_value_of_the_claim_paid_by_all_the_parties
			,[TP Costs Paid] = fact_finance_summary.total_tp_costs_paid
			,[Profit Costs Billed]= fact_finance_summary.defence_costs_billed
			,[Disbs Billed]=fact_finance_summary.disbursements_billed
			,[WIP]=fact_finance_summary.wip
			,[Date Case Closed]=dim_matter_header_current.date_closed_case_management
			,[Date Case Opened]=dim_matter_header_current.date_opened_case_management
			,[Work Type Group]= CASE WHEN dim_matter_worktype.work_type_name LIKE 'EL%' THEN 'EL'
									 WHEN dim_matter_worktype.work_type_name LIKE 'PL%' THEN 'PL'
									 WHEN dim_matter_worktype.work_type_name LIKE 'Motor%' THEN 'Motor'
									 WHEN dim_matter_worktype.work_type_name LIKE 'Disease%' THEN 'Disease'
									 ELSE 'Other'
			
								END		
			-- Extra fields for the dashboard
			,[Date initial report sent] = dim_detail_core_details.date_initial_report_sent
			,[Indemnity Saving] = ISNULL(fact_finance_summary.total_reserve,0) - ISNULL(fact_detail_paid_detail.damages_paid,0) + ISNULL(fact_finance_summary.total_tp_costs_paid,0) + ISNULL(fact_finance_summary.defence_costs_billed,0)
			,[Status] = CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END
			,[Total Reserve] = fact_detail_reserve.total_reserve
			,[Repudiated] = [dim_detail_outcome].[repudiated] 
			,[AXA Reason For Referal]=axa_reason_for_instruction
			,dim_matter_worktype.work_type_name
	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	INNER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_client ON fact_client.master_fact_key=fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_detail_reserve ON fact_detail_reserve.master_fact_key=fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement client_ref ON client_ref.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement tp_ref ON tp_ref.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	
	
	WHERE 
	ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
	AND dim_matter_header_current.matter_number<>'ML'
	AND dim_matter_header_current.master_client_code = 'A1001'
	AND dim_matter_header_current.reporting_exclusions=0
	AND dim_matter_header_current.date_opened_case_management >= '20170101'
	--AND dim_detail_core_details.date_instructions_received IS NOT NULL 
	--AND dim_detail_core_details.date_instructions_received >= '20170101'

	ORDER BY dim_matter_header_current.date_opened_case_management
	
END



GO
