SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Julie Loughlin
-- Create date: 23/07/2020
-- Description:	New report for Midland Heart see ticket 65197
-- =============================================
CREATE PROCEDURE [dbo].[Midland_Heart_WIP_Billing]
AS
BEGIN

	SET NOCOUNT ON;
SELECT 
	RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
	,dim_matter_header_current.[matter_description] AS [Matter Description]
	, dim_matter_worktype.[work_type_name] AS [Work Type]
	, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
	, clientcontact_name AS [Instructing Officer]
	, dim_fed_hierarchy_history.[name] AS [Case Manager]
	, dim_fed_hierarchy_history.jobtitle
	, CASE WHEN CAST(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) AS VARCHAR(100)) = ''
	   OR  CAST(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) AS VARCHAR(100))  IS NULL 
	   THEN CAST(fact_finance_summary.fixed_fee_amount AS VARCHAR(100)) 
	   ELSE CAST(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) AS VARCHAR(100))
	   END AS [Estimated total gross fee OR fixed fee - £]
	, fact_finance_summary.total_amount_billed AS [Total gross bills since the file was opened (inc. disbs & VAT) - £]




FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date

WHERE 

dim_matter_header_current.matter_number <> 'ML'
AND dim_matter_header_current.reporting_exclusions=0
AND fact_dimension_main.client_code = 'W23552'



END
GO
