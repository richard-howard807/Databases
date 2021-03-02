SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[VariousEateries]

AS
BEGIN 

SELECT 
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [MS Client/Matter Reference]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)				AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)				AS [Date Closed]
	, dim_matter_header_current.matter_owner_full_name				AS [Case Manager]
	, dim_matter_header_current.matter_category
	, dim_matter_worktype.work_type_name			AS [Matter Type (Work Type)]
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
	, fact_finance_summary.defence_costs_billed				AS [Revenue]
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
	,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus
	, Doogal.Latitude
	, Doogal.Longitude
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
WHERE 1 =1 
	AND dim_matter_header_current.master_client_code IN ('774963','W23644')
	AND dim_matter_header_current.reporting_exclusions = 0
	AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case, '')) <> 'exclude from reports'

END 
GO
