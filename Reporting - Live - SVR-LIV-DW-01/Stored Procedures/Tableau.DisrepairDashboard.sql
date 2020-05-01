SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2020-05-01
Description:		New stored procedure for disrepair dashboard
Ticket:				55732
Current Version:	Initial Create
====================================================
====================================================
*/

CREATE PROCEDURE [Tableau].[DisrepairDashboard]
AS
	BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

--========================================================================================================================
--  Table to extract the postcode from property address
--========================================================================================================================

	DROP TABLE IF EXISTS #property_postcode
	SELECT 
		dim_matter_header_current.dim_matter_header_curr_key										AS [header_key]
		, CASE	
			WHEN CHARINDEX(',', dim_detail_property.property_address) = 0 THEN 
				NULL
			ELSE
				REVERSE(LEFT(REVERSE(dim_detail_property.property_address), 
					CHARINDEX(',', REVERSE(dim_detail_property.property_address))-1))	
		   END																						AS [postcode]
	INTO #property_postcode
	FROM red_dw.dbo.dim_detail_property
		INNER JOIN red_dw.dbo.fact_dimension_main
			ON fact_dimension_main.dim_detail_property_key = dim_detail_property.dim_detail_property_key
		INNER JOIN red_dw.dbo.dim_matter_header_current
			ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.dim_matter_worktype
			ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	WHERE 
		dim_matter_worktype.work_type_code = '1150'



--========================================================================================================================
--  Main query
--========================================================================================================================

	SELECT 
		dim_matter_header_current.master_client_code												AS [MS Client Code]
		, dim_matter_header_current.master_matter_number											AS [MS Matter Number]
		, dim_matter_header_current.master_client_code + '/' 
			+ dim_matter_header_current.master_matter_number										AS [Client/Matter Number]
		, dim_matter_header_current.client_name														AS [Client Name]
		, dim_matter_header_current.matter_description												AS [Matter Description]
		, dim_matter_header_current.matter_owner_full_name											AS [Case Manager]
		, dim_matter_header_current.matter_partner_full_name										AS [Matter Partner]
		, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)					AS [Date Opened]
		, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)					AS [Date Closed]
		, COALESCE(dim_detail_claim.dst_claimant_solicitor_firm, 
			dim_claimant_thirdparty_involvement.claimantsols_name,
				dim_claimant_thirdparty_involvement.claimantrep_name,
					dim_claimant_thirdparty_involvement.othersidesols_name)							AS [Claimant Solicitors]
		, dim_detail_property.landlord																AS [Landlord]
		, dim_detail_property.property_address														AS [Property Address]
		, LTRIM(RTRIM(#property_postcode.postcode))													AS [Postcode]
		, Doogal.Latitude																			AS [Latitude]
		, Doogal.Longitude																			AS [Longitude]
		, dim_detail_property.tenant_name															AS [Tenant Name]
		, dim_detail_property.disrepair_is_there_a_section_82_claim									AS [Is There a Section 82 Claim?]
		, dim_detail_property.disrepair_does_fitness_act_apply										AS [Does Fitness Act Apply?]
		, fact_detail_property.amount_claimed_tenant												AS [Amount Claimed by Tenant (Damages)]
		, fact_detail_property.damages_tenant														AS [Damages Paid to Tenant]
		, fact_finance_summary.tp_total_costs_claimed												AS [Tenant's Solicitors Costs Claimed]
		, fact_detail_property.tenants_solicitors_costs												AS [Tenant's Solicitors Costs]
		, CASE
			WHEN fact_finance_summary.commercial_costs_estimate IS NULL THEN
				fact_finance_summary.fixed_fee_amount
			ELSE
				fact_finance_summary.commercial_costs_estimate
		  END																						AS [Cost Estimate (Excl. VAT & Disbs]
		, fact_finance_summary.total_amount_bill_non_comp											AS [Weightmans Costs Billed to Date]
		, fact_finance_summary.vat_non_comp															AS [VAT Billed to Date]
		, fact_finance_summary.disbursements_billed													AS [Disbursements Billed to Date]
		, CAST(dim_detail_property.court_hearing_date AS DATE)										AS [Hearing Date]
		, CAST(dim_detail_property.other_key_dates AS DATE)											AS [Other Key Dates]
		, dim_detail_property.status_comment														AS [Current Status]
		, CASE	
			WHEN dim_detail_property.disrepair_outcome IS NULL THEN
				'Ongoing'
			ELSE dim_detail_property.disrepair_outcome
		  END																						AS [Outcome]
		, CAST(dim_detail_property.disrepair_date_application_submitted AS DATE)					AS [Date Application Submitted]
	FROM red_dw.dbo.fact_dimension_main
		INNER JOIN red_dw.dbo.dim_matter_header_current
			ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.dim_matter_worktype
			ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_property
			ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_property
			ON fact_detail_property.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
			ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
			ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
			ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
		LEFT OUTER JOIN #property_postcode
			ON #property_postcode.header_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.Doogal
			ON Doogal.Postcode = LTRIM(RTRIM(#property_postcode.postcode))
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
			ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	WHERE
		dim_matter_worktype.work_type_code = '1150'
		AND dim_matter_header_current.reporting_exclusions <> 1

END
GO
