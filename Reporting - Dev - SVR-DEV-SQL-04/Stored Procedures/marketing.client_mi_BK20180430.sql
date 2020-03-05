SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 27/03/2018
-- Description:	Client MI Report - New version
--				Profit Costs by fee earner (includes profit costs for matters that do not exist in matter header table)	
-- =============================================
-- Issues to code around:	fin_month_display where calendar date = '01/05/2017'
--
-- ==============================================

CREATE PROCEDURE [marketing].[client_mi_BK20180430]
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
	--DECLARE @current_fin_to INT = '201811'
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
	--used for previous period
	DECLARE @fin_month_display VARCHAR(7) 
	SELECT @fin_month_display = fin_month_display FROM red_dw.dbo.dim_date WHERE calendar_date = @DateFrom
	IF @fin_month_display = '201801' 
		BEGIN
		SET @fin_month_display = '2018-01' -- weird anomaly in dim_date on calendar date 01/05/2017
		END

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


	-- query to return current and previous profit costs
	
; WITH pc_previous AS
(
	SELECT	
		
		fee_earner.hierarchylevel4hist [team]
		,@fin_month_display [fin_month_display]
		,SUM(finance.bill_amount) [previous_bill_amount]
		
	FROM red_dw.dbo.fact_bill_activity finance
	INNER JOIN red_dw.dbo.dim_date bill_date ON finance.dim_bill_date_key = bill_date.dim_date_key
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = finance.client_code
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = finance.dim_fed_hierarchy_history_key  --finance.fed_code_fee_earner = fee_earner.fed_code AND fee_earner.dss_current_flag = 'Y'
	WHERE bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo
	GROUP BY
		fee_earner.hierarchylevel4hist 
		--,@fin_month_display
)


	SELECT	
		client_group_name
		,fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,ISNULL(pc_previous.previous_bill_amount,0) previous_bill_amount
		,bill_date.fin_period fin_month_display
		,SUM(finance.bill_amount) [bill_amount]
		,SUM(finance.billed_time) [billed_time]
		
	FROM red_dw.dbo.fact_bill_activity finance
	INNER JOIN red_dw.dbo.dim_date bill_date ON finance.dim_bill_date_key = bill_date.dim_date_key
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = finance.client_code
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = finance.dim_fed_hierarchy_history_key --finance.fed_code_fee_earner = fee_earner.fed_code AND fee_earner.dss_current_flag = 'Y'
	LEFT JOIN pc_previous ON fee_earner.hierarchylevel4  = pc_previous.team AND pc_previous.fin_month_display = bill_date.fin_month_display
	WHERE bill_date.calendar_date BETWEEN @DateFrom AND @DateTo
	AND finance.bill_amount <> 0
	GROUP BY
		 client_group_name
		,fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist 
		,pc_previous.previous_bill_amount
		,bill_date.fin_period
	ORDER BY division,department,team







GO
