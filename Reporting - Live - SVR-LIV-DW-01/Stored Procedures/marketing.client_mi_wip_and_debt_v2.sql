SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [marketing].[client_mi_wip_and_debt_v2]
(
	  @current_fin_from INT
	, @current_fin_to INT
	, @client_group_name VARCHAR(200)
	, @client_name VARCHAR(200)
)	
AS

/*
	For testing purposes
*/

	--DECLARE @current_fin_from INT = '202201'
	--DECLARE @current_fin_to INT = '202201'
	--DECLARE @client_group_name VARCHAR(200) = 'AIG'
	--DECLARE @client_name VARCHAR(200) = NULL --'Clarion Housing Group Limited'
	

/*
	Set the variables
*/

	
-- used for current profit costs
DECLARE @DateFrom DATE 
DECLARE @DateTo DATE 
SELECT  @DateFrom = MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @current_fin_from
SELECT  @DateTo = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @current_fin_to
-- used for previous profit costs
DECLARE @PreviousDateFrom DATE = DATEADD(YEAR,-1,@DateFrom)
DECLARE @PreviousDateTo DATE = DATEADD(YEAR,-1,@DateTo)
--used for previous wip and debt
DECLARE @previous_fin_to INT = @current_fin_to - 100
DECLARE @PreviousYearTo DATE = DATEADD(YEAR,-1,@DateTo)
	

-- used to get the client numbers
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#ClientCodes')) DROP TABLE #ClientCodes

SELECT DISTINCT
	dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.client_code
	, dim_matter_header_current.matter_number
	, dim_client.client_name
	, CASE 
		WHEN (@client_group_name = 'Tesco' AND (RTRIM(dim_client.client_code) = 'T3003' 
			OR ISNULL(dim_detail_claim.name_of_instructing_insurer, '') = 'Tesco Underwriting (TU)')) AND dim_client.client_group_name = 'Ageas' THEN 
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
CASE WHEN (@client_group_name = 'Tesco' AND (RTRIM(dim_client.client_code) = 'T3003' OR ISNULL(dim_detail_claim.name_of_instructing_insurer, '') = 'Tesco Underwriting (TU)')) AND dim_client.client_group_name = 'Ageas' THEN 1
	WHEN @client_group_name = 'Ageas' THEN 
		CASE 
			WHEN RTRIM(dim_client.client_code) <> 'T3003' AND ISNULL(dim_detail_claim.name_of_instructing_insurer, '') <> 'Tesco Underwriting (TU)' AND dim_client.client_group_name = 'Ageas' THEN 1
			ELSE 0
		END 
	WHEN (@client_group_name IS NOT NULL AND dim_client.client_group_name = @client_group_name) THEN 1
	WHEN @client_name IS NOT NULL AND dim_client.client_name = @client_name THEN 1
	ELSE 0 END = 1	



--==============================================================================================================================================

/*
	Profit Costs
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

; WITH 	wip_previous AS

( 
	
	SELECT DISTINCT
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,SUM([wip_value]) previous_wip_value
     
	FROM [red_dw].[dbo].[fact_wip_monthly] wip
	INNER JOIN #ClientCodes
		ON #ClientCodes.client_code = wip.client
			AND #ClientCodes.matter_number = wip.matter
	--INNER JOIN #ClientCodes ON #ClientCodes.client_code = wip.client
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = wip.dim_fed_matter_owner_key
	WHERE wip.wip_month = @previous_fin_to
	GROUP BY fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist 
), debt_current AS

(
SELECT 
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,SUM(debt.outstanding_total_bill) [current_debt]


FROM red_dw.dbo.fact_debt_monthly debt
INNER JOIN #ClientCodes
	ON #ClientCodes.dim_matter_header_curr_key = debt.dim_matter_header_curr_key
--INNER JOIN #ClientCodes ON #ClientCodes.client_code = debt.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = debt.dim_fed_matter_owner_key
WHERE debt.debt_month = @current_fin_to
GROUP BY fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist 

), debt_previous AS
(



SELECT 
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,SUM(debt.outstanding_total_bill) [previous_debt]


FROM red_dw.dbo.fact_debt_monthly debt
INNER JOIN #ClientCodes
	ON #ClientCodes.dim_matter_header_curr_key = debt.dim_matter_header_curr_key
--INNER JOIN #ClientCodes ON #ClientCodes.client_code = debt.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = debt.dim_fed_matter_owner_key
WHERE debt.debt_month = @previous_fin_to
GROUP BY fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist 

),
	wip_current AS

( 
	
	SELECT 
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,SUM([wip_value]) current_wip_value
     
	FROM [red_dw].[dbo].[fact_wip_monthly] wip
	INNER JOIN #ClientCodes
		ON #ClientCodes.client_code = wip.client
			AND #ClientCodes.matter_number = wip.matter
	--INNER JOIN #ClientCodes ON #ClientCodes.client_code = wip.client
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = wip.dim_fed_matter_owner_key
	WHERE wip.wip_month = @current_fin_to
	GROUP BY fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist 
)




	SELECT 
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,ISNULL(debt_current.current_debt,0) current_debt
		,ISNULL(debt_previous.previous_debt,0) previous_debt
		,ISNULL(wip_previous.previous_wip_value,0) previous_wip_value
		,ISNULL(wip_current.[current_wip_value],0) current_wip_value

	FROM  
	(SELECT DISTINCT hierarchylevel2hist,hierarchylevel3hist,hierarchylevel4hist FROM red_dw.dbo.dim_fed_hierarchy_history WHERE hierarchylevel2hist <> 'Unknown'
	UNION ALL
    SELECT DISTINCT hierarchylevel2hist,hierarchylevel3hist,hierarchylevel4hist FROM red_dw.dbo.dim_fed_hierarchy_history WHERE dim_fed_hierarchy_history_key = 0
) fee_earner 
	LEFT JOIN wip_current ON fee_earner.hierarchylevel4hist = wip_current.team AND fee_earner.hierarchylevel2hist = wip_current.division
	LEFT JOIN wip_previous ON fee_earner.hierarchylevel4hist = wip_previous.team AND fee_earner.hierarchylevel2hist = wip_previous.division
	LEFT JOIN debt_current ON fee_earner.hierarchylevel4hist  = debt_current.team AND fee_earner.hierarchylevel2hist = debt_current.division
	LEFT JOIN debt_previous ON fee_earner.hierarchylevel4hist  = debt_previous.team AND fee_earner.hierarchylevel2hist = debt_previous.division

	WHERE (ISNULL(debt_current.current_debt,0) + ISNULL(debt_previous.previous_debt,0) + ISNULL(wip_previous.previous_wip_value,0) + ISNULL(wip_current.[current_wip_value],0)) <> 0
	
	

GO
