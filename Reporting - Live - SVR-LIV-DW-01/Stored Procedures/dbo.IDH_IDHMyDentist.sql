SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Max Taylor>
-- Create date: <20210514,>
-- Description:	<initial create  >
-- =============================================
CREATE PROCEDURE [dbo].[IDH_IDHMyDentist]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT 
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [MS Client/Matter Reference]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)				AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)				AS [Date Closed]
	, dim_matter_header_current.matter_owner_full_name				AS [Case Manager]
	, dim_matter_header_current.matter_category
	, dim_matter_worktype.work_type_name						AS [Matter Type (Work Type)]
	, dim_detail_property.case_classification_code				AS [Case Classification Code]
	, dim_detail_property.case_classification					AS [Case Classification]
	, dim_detail_property.property_address						AS [Property Address]
	, dim_detail_property.property_address_1					AS [Property Address 1]
	, dim_detail_property.property_address_2					AS [Property Address 2]
	, dim_detail_property.postcode								AS [Postcode]
	, dim_detail_property.postcode_2							AS [Postcode 2]
	, dim_detail_property.property_contact						AS [Property Contact]
	, dim_detail_property.property_client_contact				AS [Property Client Contact]
	, dim_detail_property.property_type_1						AS [Property Type 1]
	, dim_detail_property.property_type_2						AS [Property Type 2]
	, dim_detail_property.property_type_3						AS [Property Type 3]
	, CAST(dim_detail_property.date_landlord_solicitor_documents_received AS DATE)		AS [Lease received/sent out]
	, CAST(dim_detail_property.date_lease_returned_to_landlords_solicitor AS DATE)			AS [Lease Returned] 
	, CAST(dim_detail_property.date_lease_agreed AS DATE)	 							AS [Date Lease Agreed]
	, CAST(dim_detail_property.completion_date AS DATE)						AS [Completion Date]
	, fact_finance_summary.fixed_fee_amount					AS [Fees Estimate - FF Amount]
	, ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate)	AS [Fees Estimate - Commercial Costs Estimate]
	, fact_detail_cost_budgeting.fees_estimate				AS [Fees Estimate - Fees Estimate]
	, fact_finance_summary.total_amount_billed				AS [Total Billed]
	, ISNULL(fact_finance_summary.defence_costs_billed, '.00')				AS [Revenue]
	, fact_finance_summary.disbursements_billed				AS [Disburesments]
	, fact_finance_summary.vat_billed						AS [VAT]
	, fact_finance_summary.wip								AS [WIP]

	, CASE
		WHEN dim_detail_property.completion_date IS NOT NULL THEN 
			'Completed'
		WHEN dim_detail_property.date_lease_agreed IS NOT NULL THEN
			'Lease Agreed'
		WHEN dim_detail_property.date_lease_returned_to_landlords_solicitor IS NOT NULL THEN
			'Lease Returned'
		WHEN dim_detail_property.date_landlord_solicitor_documents_received IS NOT NULL THEN
			'Lease Received/Sent'
		ELSE
			'Awaiting Lease'
	  END														AS [Present Position]
	, dim_detail_property.site_number			AS [Site Number]
	, dim_detail_property.site_name			AS [Site Name]	
	, dim_file_notes.external_file_notes	
	, Doogal.Latitude
	, Doogal.Longitude
	--, CASE
 --       WHEN ISNULL(fact_matter_summary_current.last_bill_date, '1753-01-01') = '1753-01-01' THEN 'Not yet billed'

 --       ELSE
 --           CAST(FORMAT(fact_matter_summary_current.last_bill_date, 'd', 'en-gb') AS VARCHAR(10))
 --   END AS [Last Bill Date]
	, CAST(fact_matter_summary_current.last_bill_date AS DATE)		AS [Last Bill Date v2]
	,dim_employee.locationidud AS [Office]

	,[Tab Filter] = CASE WHEN dim_employee.locationidud = 'Glasgow' THEN 'Scotland'
	                     WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] =  'Property Litigation' THEN 'Property Litigation' 
	                      ELSE 'Property' END,
	 
    dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team],
    dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department],
    dim_fed_hierarchy_history.[hierarchylevel2hist] [Division]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property
		ON dim_detail_property.client_code = dim_matter_header_current.client_code
			AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
			AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.Doogal
		ON Doogal.Postcode = dim_detail_property.postcode
	LEFT OUTER JOIN red_dw.dbo.dim_file_notes
		ON dim_file_notes.client_code = dim_matter_header_current.client_code
			AND dim_file_notes.matter_number = dim_matter_header_current.matter_number

	LEFT JOIN red_dw.dbo.fact_matter_summary_current
	ON fact_matter_summary_current.master_fact_key = fact_finance_summary.master_fact_key

	LEFT JOIN red_dw.dbo.fact_dimension_main
	ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary_current.dim_fed_hierarchy_history_key
	LEFT JOIN  red_dw.dbo.dim_employee
	ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key



WHERE 1 =1 
	AND dim_matter_header_current.master_client_code = 'W19702'
	AND dim_matter_header_current.matter_category = 'Real Estate'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case, '')) <> 'exclude from reports'



END
--GO
GO
