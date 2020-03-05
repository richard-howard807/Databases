SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [marketing].[client_mi_wip_and_debt_BK20180430]
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

	--DECLARE @current_fin_from INT = '201801'
	--DECLARE @current_fin_to INT = '201810'
	--DECLARE @client_group_name VARCHAR(200) = 'Zurich'
	--DECLARE @client_name VARCHAR(200) =  NULL --'GreenAcres Groups Limited'
	

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
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#ClientCodes')) 
				DROP TABLE #ClientCodes
	SELECT client_code,client_name,client_group_name
	INTO #ClientCodes
	FROM red_dw.dbo.dim_client
	WHERE 
	CASE WHEN @client_group_name IS NOT NULL AND client_group_name = @client_group_name THEN 1
		WHEN @client_name IS NOT NULL AND client_name = @client_name THEN 1
		ELSE 0 END = 1	


/*
	Profit Costs
*/

; WITH 	wip_previous AS

( 
	
	SELECT 
		fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,SUM([wip_value]) previous_wip_value
     
	FROM [red_dw].[dbo].[fact_wip_monthly] wip
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = wip.client
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
INNER JOIN #ClientCodes ON #ClientCodes.client_code = debt.client_code
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
INNER JOIN #ClientCodes ON #ClientCodes.client_code = debt.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = debt.dim_fed_matter_owner_key
WHERE debt.debt_month = @previous_fin_to
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
		,SUM([wip_value]) current_wip_value

	FROM [red_dw].[dbo].[fact_wip_monthly] wip
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = wip.client
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON  fee_earner.dim_fed_hierarchy_history_key = wip.dim_fed_matter_owner_key
	LEFT JOIN wip_previous ON fee_earner.hierarchylevel4hist = wip_previous.Team
	LEFT JOIN debt_current ON fee_earner.hierarchylevel4hist  = debt_current.team
	LEFT JOIN debt_previous ON fee_earner.hierarchylevel4hist  = debt_previous.team
	WHERE wip.wip_month = @current_fin_to
	GROUP BY fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist
		,fee_earner.hierarchylevel4hist
		,wip_previous.previous_wip_value
		,debt_current.current_debt
		,debt_previous.previous_debt

	

GO
