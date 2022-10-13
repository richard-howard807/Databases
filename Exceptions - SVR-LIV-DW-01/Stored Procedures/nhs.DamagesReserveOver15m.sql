SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-10-06
-- Description:	#171714, new report for NHSR cases where damages reserve >=£15m
-- =============================================
CREATE PROCEDURE [nhs].[DamagesReserveOver15m]

AS
BEGIN
	
	SET NOCOUNT ON;

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
	, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	, dim_client_involvement.insurerclient_reference AS [Insurer Client Reference]
	, dim_detail_core_details.[present_position] AS [Present Position]
	, dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued]
	, dim_detail_court.[date_proceedings_issued] AS [Date Proceeding Issued]
	, dim_detail_health.[claimant_name] AS [Claimant Name]
	, fact_finance_summary.[damages_reserve] AS [Damages Reserve Current]
	, dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.master_client_code='N1001'
AND fact_finance_summary.[damages_reserve]>=15000000
AND dim_detail_outcome.date_claim_concluded IS NULL 


END
GO
