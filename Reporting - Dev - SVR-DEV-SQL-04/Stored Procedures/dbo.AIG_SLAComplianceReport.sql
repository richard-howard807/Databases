SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2017-08-16
Description:		AIG - SLA Compliance Report
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [dbo].[AIG_SLAComplianceReport]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 


 RTRIM(dimmain.client_code)+'/'+dimmain.matter_number AS [Weightmans Reference]
,dimmain.client_code AS [Client Code]
,dimmain.matter_number AS [Matter Number]
,dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
,dim_instruction_type.instruction_type AS [Instruction Type]
,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
,CASE WHEN core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] IS NULL AND
	[dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received], GETDATE())<=2 THEN 'Not yet due'
	WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) <=2 THEN 'Within 2 days'
	WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) >2 THEN 'More than 2 days'
	ELSE NULL END AS [Acknowledgement]
,CASE WHEN core_details.[date_initial_report_sent] IS NULL AND
	[dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received], GETDATE())<=10 THEN 'Not yet due'
	WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[date_initial_report_sent]) <=10 THEN 'Within 10 days'
	WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[date_initial_report_sent]) >10 THEN 'More than 10 days'
	ELSE NULL END AS [Initial Report Sent]
,CASE WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=3 THEN 'Qtr1'
	WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=6 THEN 'Qtr2'
	WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=9 THEN 'Qtr3'
	WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=12 THEN 'Qtr4'
	ELSE NULL END AS [Calendar Quarter Received]
,CAST(dim_open_case_management_date.open_case_management_fin_year - 1 as varchar) + '/' + CAST(dim_open_case_management_date.open_case_management_fin_year as varchar) AS [Financial Year Opened] 
,dim_detail_client.hide_flag AS [AIG Hide Flag]

FROM 
		red_dw.dbo.fact_dimension_main AS dimmain
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details AS core_details ON core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_client_involvement AS Client_Involv ON Client_Involv.dim_client_involvement_key = dimmain.dim_client_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud AS detail_fraud ON detail_fraud.dim_detail_fraud_key=dimmain.dim_detail_fraud_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details AS detail_hire_details ON detail_hire_details.dim_detail_hire_detail_key= dimmain.dim_detail_hire_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=dimmain.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_client ON fact_client.master_fact_key= dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care AS fact_future_care ON fact_future_care.master_fact_key=dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_reserve_detail ON fact_reserve_detail.master_fact_key=dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_claim AS dim_detail_claim ON dim_detail_claim.dim_detail_claim_key=dimmain.dim_detail_claim_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=dimmain.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = dimmain.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_client AS dim_detail_client ON dim_detail_client.dim_detail_client_key = dimmain.dim_detail_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation AS dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = dimmain.dim_detail_litigation_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_health AS dim_detail_health ON dim_detail_health.dim_detail_health_key = dimmain.dim_detail_health_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area AS dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = dimmain.dim_detail_practice_ar_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 
		LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.dim_agents_involvement_key = dimmain.dim_agents_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = dimmain.dim_claimant_thirdpart_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_future_care ON dim_detail_future_care.dim_detail_future_care_key=dimmain.dim_detail_future_care_key
		--LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = dimmain.master_fact_key
		--LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = dimmain.dim_detail_critical_mi_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = dimmain.dim_detail_advice_key
		LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type] ON [dim_instruction_type].[dim_instruction_type_key]=dim_matter_header_current.dim_instruction_type_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_open_case_management_date  ON dim_open_case_management_date.calendar_date = dim_matter_header_current.date_opened_case_management
		WHERE 
		ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_client.client_code IN ('00006864','00006865','00006868','00006876','00006866','00364317','00006861','A2002') --NOT IN ('00030645','95000C','00453737')
		AND dim_matter_header_current.reporting_exclusions=0
		AND (dim_matter_header_current.date_closed_case_management >= '20140101' OR dim_matter_header_current.date_closed_case_management IS NULL)
		AND dim_detail_client.hide_flag is null

		END
GO
