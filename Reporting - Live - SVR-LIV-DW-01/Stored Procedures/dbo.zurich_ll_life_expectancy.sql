SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-04-12
-- Description:	Ticket 143331 New report for Zurich Large loss matters showing life expectancy at (anticipated) settlement date 
-- =============================================
-- Ticket #144151 - columns added
-- =============================================

CREATE PROCEDURE [dbo].[zurich_ll_life_expectancy] --EXEC [dbo].[zurich_ll_life_expectancy]

AS

BEGIN


SET NOCOUNT ON;


SELECT 
	dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number		AS [Weightmans ref]
	, dim_fed_hierarchy_history.name			AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Matter Owner Team]
	, COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference)			AS [Zurich Ref]
	, dim_matter_worktype.work_type_name			AS [Matter Type]
	, RTRIM(dim_detail_core_details.injury_type_code) + '-' + RTRIM(dim_detail_core_details.injury_type)		AS [Injury Type]
	, dim_detail_outcome.outcome_of_case			AS [Settlement Type]
	, dim_detail_core_details.claimants_date_of_birth		AS [Claimant DOB]
	, CAST(dim_detail_core_details.ll05_capita_likely_settlement_date AS DATE)			AS [Anticipated Date of Settlement]
	, CAST(dim_detail_outcome.zurich_result_date AS DATE)			AS [Date of Settlement]
	, dim_detail_core_details.ll18_is_there_a_reduced_life_expectancy			AS [Is There a Reduced Life Expectancy]
	, fact_detail_client.claimants_life_expectancy_estimate			AS [Claimant's Life Expectancy Prior to Injury]
	, fact_detail_client.agreed_life_expectancy_estimate			AS [Agreed Life Expectancy After Injury]
	, fact_detail_client.claimants_life_expectancy_estimate - fact_detail_client.agreed_life_expectancy_estimate		AS [Reduction in Life Expectancy]
	, fact_detail_client.defendants_life_expectancy_estimate			AS [Defendant's Life Expectancy Estimate (Age)]
	, dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000			AS [Will Total Gross Damages Reserve Exceed £350,000]
	, dim_detail_claim.future_loss_claim			AS [Is There a Future Loss Claim?]
	, dim_detail_outcome.ll00_settlement_basis		AS [Settlement Basis]
	, dim_detail_outcome.global_settlement			AS [Global Settlement]
	, CASE
		WHEN RTRIM(dim_detail_core_details.zurich_line_of_business) = 'PUB' THEN
			'Public Liability'
		WHEN RTRIM(dim_detail_core_details.zurich_line_of_business) = 'EMP' THEN
			'Employers Liability'
		WHEN RTRIM(dim_detail_core_details.zurich_line_of_business) = 'MOT' THEN 
			'Motor'
	  END															AS zurich_line_of_business
	, DATEDIFF(YEAR, dim_detail_core_details.claimants_date_of_birth, dim_detail_core_details.ll05_capita_likely_settlement_date)- 
				CASE 
					WHEN (MONTH(dim_detail_core_details.claimants_date_of_birth) > MONTH(dim_detail_core_details.ll05_capita_likely_settlement_date)) OR (MONTH(dim_detail_core_details.claimants_date_of_birth) = MONTH(dim_detail_core_details.ll05_capita_likely_settlement_date) AND DAY(dim_detail_core_details.claimants_date_of_birth) > DAY(dim_detail_core_details.ll05_capita_likely_settlement_date)) THEN 
						1 
					ELSE 
						0 
				END				AS [Claimant's Age at Anticipated Settlement]
	, DATEDIFF(YEAR, dim_detail_core_details.claimants_date_of_birth, dim_detail_outcome.date_claim_concluded)- 
				CASE 
					WHEN (MONTH(dim_detail_core_details.claimants_date_of_birth) > MONTH(dim_detail_outcome.date_claim_concluded)) OR (MONTH(dim_detail_core_details.claimants_date_of_birth) = MONTH(dim_detail_outcome.date_claim_concluded) AND DAY(dim_detail_core_details.claimants_date_of_birth) > DAY(dim_detail_outcome.date_claim_concluded)) THEN 
						1 
					ELSE 
						0 
				END				AS [Claimant's Age at Settlement]
	, IIF(dim_detail_outcome.date_claim_concluded IS NULL, 'Live', 'Settled')			AS claim_status
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code	
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date = CAST(dim_detail_outcome.date_claim_concluded AS DATE)
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'Z1001'
	AND dim_detail_claim.cit_claim = 'Yes'
	AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Large Loss'
	AND ISNULL(dim_date.cal_year, 9999) >= 2019
	AND ISNULL(dim_detail_core_details.injury_type_code, '') <> 'A00'
	AND RTRIM(dim_detail_core_details.zurich_line_of_business) IN ('PUB', 'EMP', 'MOT')


END	
GO
