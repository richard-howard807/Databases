SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vis_view_fact_dimension_main]
AS 
SELECT 
fact_dimension_main.master_fact_key, 
fact_dimension_main.source_system_id, 
fact_dimension_main.client_code, 
fact_dimension_main.matter_number, 
fact_dimension_main.master_client_code, 
fact_dimension_main.dim_matter_header_curr_key, 
fact_dimension_main.dim_client_key, 
fact_dimension_main.dim_detail_audit_key, 
fact_dimension_main.dim_detail_claim_key, 
fact_dimension_main.dim_detail_client_key, 
fact_dimension_main.dim_detail_core_detail_key, 
fact_dimension_main.dim_detail_court_key, 
fact_dimension_main.dim_detail_critical_mi_key, 
fact_dimension_main.dim_detail_flight_dela_key, 
fact_dimension_main.dim_detail_fraud_key, 
fact_dimension_main.dim_detail_future_care_key, 
fact_dimension_main.dim_detail_health_key, 
fact_dimension_main.dim_detail_hire_detail_key, 
fact_dimension_main.dim_detail_litigation_key, 
fact_dimension_main.dim_detail_outcome_key, 
fact_dimension_main.dim_detail_plot_detail_key, 
fact_dimension_main.dim_detail_practice_ar_key, 
fact_dimension_main.dim_detail_property_key, 
fact_dimension_main.dim_detail_incident_key, 
fact_dimension_main.dim_agents_involvement_key, 
fact_dimension_main.dim_claimant_thirdpart_key, 
fact_dimension_main.dim_client_involvement_key, 
fact_dimension_main.dim_court_involvement_key, 
fact_dimension_main.dim_defendant_involvem_key, 
fact_dimension_main.dim_experts_involvemen_key, 
fact_dimension_main.dim_insurance_involvem_key, 
fact_dimension_main.dim_involvement_full_bridge_key, 
fact_dimension_main.dim_witness_involvemen_key, 
fact_dimension_main.dim_detail_advice_key, 
fact_dimension_main.dim_open_practice_management_date_key, 
fact_dimension_main.dim_closed_practice_management_date_key, 
fact_dimension_main.dim_detail_rsu_key, 
fact_dimension_main.dim_detail_previous_details_key, 
fact_dimension_main.dim_detail_compliance_key, 
fact_dimension_main.dim_detail_finance_key, 
fact_dimension_main.dim_fed_hierarchy_history_key, 
fact_dimension_main.dim_open_case_management_date_key, 
fact_dimension_main.dim_file_notes_key, 
fact_dimension_main.dim_branch_key, 
fact_dimension_main.dim_closed_case_management_date_key, 
fact_dimension_main.dss_create_time, 
fact_dimension_main.dss_update_time 
FROM red_dw.dbo.fact_dimension_main WITH (NOLOCK)

INNER JOIN red_dw.dbo.dim_closed_case_management_date ON dim_closed_case_management_date.dim_closed_case_management_date_key = fact_dimension_main.dim_closed_case_management_date_key
WHERE client_code NOT IN ('00030645','95000C','00453737')
AND matter_number<>'ML'
AND (calendar_date >= DATEADD(YEAR,-3,GETDATE()) OR calendar_date IS NULL)
GO
