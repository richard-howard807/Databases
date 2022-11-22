SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [marketing].[client_mi_previous_year_summary]
(
	  @current_fin_from INT
	, @client_group_name VARCHAR(200)
	, @client_name VARCHAR(200)
)	
AS


--DECLARE @current_fin_from AS INT = 202301
--DECLARE @client_group_name VARCHAR(200) = 'AIG' 
--DECLARE @client_name VARCHAR(200) = NULL 
DECLARE @previous_fin_year AS INT = (SELECT DISTINCT dim_date.fin_year - 1 FROM red_dw.dbo.dim_date WHERE dim_date.fin_month = @current_fin_from)
DECLARE @previous_fin_end AS INT = (SELECT MAX(dim_date.fin_month) FROM red_dw.dbo.dim_date WHERE dim_date.fin_year = @previous_fin_year)



IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#ClientCodes')) DROP TABLE #ClientCodes

SELECT DISTINCT
	dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.client_code
	, dim_matter_header_current.matter_number
	, dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_client.client_name
	, CASE 
		WHEN (@client_group_name = 'Tesco' AND (RTRIM(dim_client.client_code) = 'T3003' 
			OR (ISNULL(dim_detail_claim.name_of_instructing_insurer, '') = 'Tesco Underwriting (TU)' AND dim_client.client_group_name = 'Ageas'))) THEN 
			'Tesco'
		WHEN @client_group_name = 'Ageas' THEN 
			CASE 
				WHEN RTRIM(dim_client.client_code) <> 'T3003' AND ISNULL(dim_detail_claim.name_of_instructing_insurer, '') <> 'Tesco Underwriting (TU)' 
					AND dim_client.client_group_name = 'Ageas' THEN 
					'Ageas'
			END 
		ELSE 
			dim_client.client_group_name
		END			AS client_group_name
	--, dim_client.client_group_name
INTO #ClientCodes
FROM red_dw.dbo.dim_client
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.client_code = dim_client.client_code
	LEFT OUTER JOIN red_dw.dbo.fact_bill_activity
		ON fact_bill_activity.client_code = dim_matter_header_current.client_code
			AND fact_bill_activity.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.client_code = dim_matter_header_current.client_code
			AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
WHERE 
-- Logic added re Ageas client group due to Tesco splitting away from Ageas. Logic to get Tesco matters matches Tesco DAX queries in SSRS Tesco reports project
CASE WHEN (@client_group_name = 'Tesco' AND (RTRIM(dim_client.client_code) = 'T3003' OR (ISNULL(dim_detail_claim.name_of_instructing_insurer, '') = 'Tesco Underwriting (TU)' AND dim_client.client_group_name = 'Ageas'))) THEN 1
	WHEN @client_group_name = 'Ageas' THEN 
		CASE 
			WHEN RTRIM(dim_client.client_code) <> 'T3003' AND ISNULL(dim_detail_claim.name_of_instructing_insurer, '') <> 'Tesco Underwriting (TU)' AND dim_client.client_group_name = 'Ageas' THEN 1
			ELSE 0
		END 
	WHEN (@client_group_name IS NOT NULL AND dim_client.client_group_name = @client_group_name) THEN 1
	WHEN @client_name IS NOT NULL AND dim_client.client_name = @client_name THEN 1
	ELSE 0 END = 1	

--=========================================================================================================================================================


SELECT 
	SUM(financials.previous_bill_amount)			AS previous_bill_amount
	, SUM(financials.previous_hours_billed)/60		AS previous_hours_billed
	, SUM(financials.previous_wip_value)		AS previous_wip_value
	, SUM(financials.previous_debt_value)		AS previous_debt_value
FROM (
	--Revenue
	SELECT
		SUM(fact_bill_activity.bill_amount)			AS previous_bill_amount
		, 0			AS previous_hours_billed
		, 0		AS previous_wip_value
		, 0		AS previous_debt_value
	FROM red_dw.dbo.fact_bill_activity 
		INNER JOIN red_dw.dbo.dim_date 
			ON fact_bill_activity.dim_bill_date_key = dim_date.dim_date_key
		INNER JOIN #ClientCodes 
			ON #ClientCodes.client_code = fact_bill_activity.client_code AND #ClientCodes.matter_number = fact_bill_activity.matter_number
	WHERE dim_date.fin_year = @previous_fin_year

	UNION ALL 
		
	--Hours Billed
	SELECT		
		0		AS previous_bill_amount
		, SUM(fact_bill_billed_time_activity.minutes_recorded)	AS previous_hours_billed
		, 0		AS previous_wip_value
		, 0		AS previous_debt_value
	FROM red_dw.dbo.fact_bill_billed_time_activity
		INNER JOIN red_dw.dbo.dim_date 
			ON fact_bill_billed_time_activity.dim_bill_date_key  = dim_date.dim_date_key
		INNER JOIN #ClientCodes 
			ON #ClientCodes.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
	WHERE
		dim_date.fin_year = @previous_fin_year

	UNION ALL 

	--WIP
	SELECT 
		0			AS previous_bill_amount
		, 0			AS previous_hours_billed
		,SUM([wip_value]) AS previous_wip_value
		, 0			AS previous_debt_value
	FROM red_dw.dbo.fact_wip_monthly
		INNER JOIN #ClientCodes
			ON #ClientCodes.client_code = fact_wip_monthly.client
				AND #ClientCodes.matter_number = fact_wip_monthly.matter
	WHERE 
		fact_wip_monthly.wip_month = @previous_fin_end

	UNION ALL

	--Debt
	SELECT 
		0				AS previous_bill_amount
		, 0			AS previous_hours_billed
		, 0		AS previous_wip_value
		, SUM(fact_debt_monthly.outstanding_total_bill) AS previous_debt_value
	FROM red_dw.dbo.fact_debt_monthly 
		INNER JOIN #ClientCodes
			ON #ClientCodes.dim_matter_header_curr_key = fact_debt_monthly.dim_matter_header_curr_key
	WHERE 
		fact_debt_monthly.debt_month = @previous_fin_end
) AS financials





GO
