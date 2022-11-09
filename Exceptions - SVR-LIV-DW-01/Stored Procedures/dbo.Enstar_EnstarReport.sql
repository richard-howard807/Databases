SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Enstar_EnstarReport]

AS


SELECT 
		
			dim_client.[client_name],
			dim_client.[client_group_name],
			WeightmansRef = dim_matter_header_current.master_client_code +'-'+ master_matter_number,
			dim_matter_header_current.[matter_description],
			name AS [matter_owner_name],
			dim_detail_core_details.[delegated],
			dim_detail_core_details.[present_position],
			dim_matter_header_current.date_opened_case_management,
			work_type_name,
			fact_finance_summary.wip AS [WIP]	,
		    fact_finance_summary.defence_costs_billed AS [Revenue Billed]	,
			fact_finance_summary.disbursements_billed
            


FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
WHERE 
		dim_matter_header_current.[master_client_code] = 'W26065'
GO
