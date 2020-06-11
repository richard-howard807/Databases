SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-06-11
-- Description:	Coronavirus Instructions Report for Marketing folder, #61051
-- =============================================
CREATE PROCEDURE [dbo].[Coronavirus_Instructions]

AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


SELECT 
	dim_matter_header_current.master_client_code + '/'
		+ dim_matter_header_current.master_matter_number															AS [Mattersphere Weightmans Reference]
	, dim_matter_header_current.matter_description																	AS [Matter Description]
	, dim_detail_core_details.is_this_part_of_a_campaign															AS [Is This Part of a Campaign?]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)										AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)										AS [Date Closed]
	, dim_matter_header_current.matter_owner_full_name																AS [Case Manager]
	, dim_fed_hierarchy_history.hierarchylevel4hist																	AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist																	AS [Department]
	, dim_matter_worktype.work_type_name																			AS [Work Type]
	, dim_client.client_name																						AS [Client Name]
	, dim_client.sector																								AS [Client Sector]
	, dim_client.segment																							AS [Client Segment]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)															AS [Revenue Billed Excl VAT]
	, ISNULL(fact_finance_summary.disbursements_billed, 0)															AS [Disbursments Excl VAT]
	, ISNULL(fact_finance_summary.defence_costs_vat, 0) 
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)											AS [Total VAT Billed]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0)
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)
			+ ISNULL(fact_finance_summary.defence_costs_vat, 0)														AS [Total Amount Billed]
	, fact_finance_summary.wip																						AS [WIP]
	, fact_finance_summary.disbursement_balance																		AS [Unbilled Disbursements]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
WHERE
	LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
	OR (
		CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
		AND (
				LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
				LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
			)
		)
END 
GO
