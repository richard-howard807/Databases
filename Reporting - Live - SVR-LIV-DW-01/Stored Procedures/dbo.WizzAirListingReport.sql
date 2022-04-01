SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-03-30
-- Description:	#141365 Wizz Air EC261 report and Wizz Air Listing report
-- =============================================
CREATE PROCEDURE [dbo].[WizzAirListingReport]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT dim_matter_header_current.client_name AS [Client name]
	, dim_matter_header_current.master_client_code +'-'+ dim_matter_header_current.master_matter_number AS [Client and Matter number]
	, dim_matter_header_current.matter_description AS [Matter description]
	, dim_matter_header_current.date_opened_case_management AS [Date opened]
	, dim_matter_header_current.date_closed_case_management AS [Date closed]
	, dim_matter_header_current.matter_owner_full_name AS [Matter owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	, dim_matter_worktype.work_type_name AS [Matter type]
	, NULL AS [Instruction type]
	, dim_detail_finance.output_wip_fee_arrangement AS [Fee arrangement]
	, fact_finance_summary.fixed_fee_amount AS [Fixed fee amount]
	, dim_matter_header_current.billing_arrangement_description AS [Rate arrangement]
	, fact_finance_summary.wip AS [WIP]
	, fact_finance_summary.disbursement_balance AS [Unbilled disbursement]
	, fact_finance_summary.defence_costs_billed AS [Revenue billed (net of VAT)]
	, fact_finance_summary.disbursements_billed AS [Disbursements Billed (net of VAT)]
	, fact_finance_summary.total_amount_billed AS [Total billed]
	, fact_matter_summary_current.last_time_transaction_date AS [Date of last time posting]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='W21757'

END
GO
