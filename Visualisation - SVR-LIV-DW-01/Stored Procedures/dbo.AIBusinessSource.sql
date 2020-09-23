SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AIBusinessSource]
AS
BEGIN

--Business Source Data
SELECT DISTINCT dim_matter_header_current.client_code AS [Client Code]
	, segment AS [Segment]
	, sector AS [Sector]
	, client_partner_name AS [Client Partner]
	, hierarchylevel3hist AS [Department]
	, work_type_name AS [Matter Type]
	, referrer_type AS [Business Source]
	, business_source_name AS [Business Source Description]
	, defence_costs_billed_composite AS [Revenue]
	, date_opened_case_management AS [Date Opened]
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client 
ON dim_client.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON CAST(date_opened_case_management AS DATE)=calendar_date
WHERE reporting_exclusions=0
AND current_fin_year='Current'

END
GO
