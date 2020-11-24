SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-11-24
-- Description:	#80100, new report request
-- =============================================

-- ==============================================

CREATE PROCEDURE [royalmail].[RMG_High_Profile]

AS
BEGIN
	
	SET NOCOUNT ON;
	SELECT dim_matter_header_current.master_client_code AS [MS Client Code]
		, dim_matter_header_current.master_matter_number AS [MS Matter Code]
		, dim_matter_header_current.matter_description AS [Name]
		, dim_detail_client.[emp_claimants_place_of_work] AS [Workplace/ Geography]
		, dim_detail_claim.[rmg_high_profile_matter_type] AS [Matter Type]
		, dim_detail_claim.[rmg_high_profile_summary] AS [Summary]
		, dim_detail_claim.[rmg_high_profile_present_position] AS [Present Position]
		, fact_detail_reserve_detail.[potential_compensation] AS [Realistic Valuation]
		, dim_detail_claim.[rmg_high_profile_rag_rating] AS [R-A-G Rating]
		, ISNULL(dim_detail_claim.[rmg_high_profile_reason_for_sensitivity],'')+' '+ISNULL(dim_detail_claim.[rmg_high_profile_merits_of_claim],'') AS [Reason for Sensitivity / Merits of Claim / Value of Claim (if possible)]
		, dim_detail_claim.[rmg_high_profile_merits_of_claim] AS [Merits of Claim]
		, dim_detail_claim.[rmg_high_profile_stakeholders_aware] AS [Stakeholders Aware]
		, dim_detail_claim.[rmg_high_profile_next_steps] AS [Next Steps]
		, dim_detail_claim.[rmg_high_profile_next_key_date] AS [Key Dates]
		, dim_detail_claim.[rmg_is_this_a_high_profile_matter] AS [Is this a High Profile Matter?]

	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
	ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
	ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

	WHERE dim_matter_header_current.client_group_code='00000006'
	AND dim_matter_header_current.reporting_exclusions=0
	AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
	AND dim_detail_claim.[rmg_high_profile_matter_type] IS NOT NULL 

END
GO
