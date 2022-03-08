SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-03-07
-- Description:	New report for CRU enquries
-- =============================================

CREATE PROCEDURE [motor].[CRU]

		 @REF AS VARCHAR(17)
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Reference]
	, RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number [FED Reference]
	, dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_claimant_thirdparty_involvement.claimant_name AS [Claimant Name]
	, CAST(dim_detail_core_details.claimants_date_of_birth AS DATE) AS [Claimant's Date of Birth]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE) AS [Date Claim Concluded]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE) AS [Date Closed]
	, dim_detail_outcome.outcome_of_case AS [Outcome]
	, ISNULL(fact_detail_client.[nhs_charges_paid_by_all_parties], fact_detail_paid_detail.[nhs_charges_paid_by_client]) AS [NHS Charges]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key

WHERE reporting_exclusions=0
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number = (@Ref)

END
GO
