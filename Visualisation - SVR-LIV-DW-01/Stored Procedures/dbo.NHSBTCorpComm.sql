SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-11-04
-- Description:	#77708, NHSBT Stored Procedure for dashboard
-- =============================================

-- =============================================

CREATE PROCEDURE [dbo].[NHSBTCorpComm]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Weightmans Ref]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, dim_matter_header_current.date_closed_case_management AS [Date Closed]
	, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, fact_finance_summary.fixed_fee_amount AS [Fixed Fee Amount]
	, dim_detail_core_details.ntsbt_purchase_order AS [NHSBT) Purchase Order]
	, fact_finance_summary.defence_costs_billed AS [Revenue]
	, fact_finance_summary.disbursements_billed AS [Disbursements Billed]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

WHERE dim_matter_header_current.master_client_code='707938'
AND dim_fed_hierarchy_history.hierarchylevel3hist='Corp-Comm'

END
GO
