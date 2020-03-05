SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*
		So we can't use a cte because the teams may not be fee earning any more
		need a way to include all teams in both queries, so may need to use a hierarchy query 
		as the base and the add in the financials!!  Super annoying.

		Note:  Can't link red_dw.dbo.fact_bill_activity to red_dw.dbo.fact_bill_billed_time_activity minutes_recorded just as is
				because the fed hierarchy can change. did a subquery join using fed code.  Lets see what the result is


*/




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 27/03/2018
-- Description:	Client MI Report - New version
--				Profit Costs by fee earner (includes profit costs for matters that do not exist in matter header table)	
-- =============================================
-- Issues to code around:	fin_month_display where calendar date = '01/05/2017'
--
-- ==============================================

CREATE PROCEDURE [marketing].[client_mi]
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
	--DECLARE @current_fin_to INT = '201812'
	--DECLARE @client_group_name VARCHAR(200) = 'Ageas'
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



	SELECT	
		client_group_name
		,fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		-- LD 17/5/2018 The line below is using the case to limit the billed time to one row ... a fudge but I have tried every which way to get recorded minutes in 
		-- for recovery rate with no avail... why this field is not in the fact_bill_activity table is a mystery to me!!! the billed time doesn't appear
		-- to return the correct result
		, CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN ISNULL([hours_billed],0) ELSE 0 END  [billed_time] 
	
		
		,CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bill_date.fin_period ELSE ' Profit Costs - Previous Period'  END fin_month_display
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN finance.bill_amount ELSE 0 END)  previous_bill_amount
		--,SUM(finance.bill_amount) [bill_amount]
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN finance.bill_amount ELSE 0 END  ) [bill_amount]
		
	FROM red_dw.dbo.fact_bill_activity finance
	INNER JOIN red_dw.dbo.dim_date bill_date ON finance.dim_bill_date_key = bill_date.dim_date_key
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = finance.client_code
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = finance.dim_fed_hierarchy_history_key --finance.fed_code_fee_earner = fee_earner.fed_code AND fee_earner.dss_current_flag = 'Y'
	LEFT JOIN (SELECT		fee_earner.hierarchylevel4hist
							--,fee_earner.fed_code
							--,bill_date.fin_period
							
							,SUM(minutes_recorded)/60 [hours_billed]
				FROM red_dw.dbo.fact_bill_billed_time_activity minutes_recorded
				INNER JOIN red_dw.dbo.dim_date bill_date ON minutes_recorded.dim_bill_date_key  = bill_date.dim_date_key
				INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = minutes_recorded.dim_client_key
				INNER JOIN #ClientCodes ON #ClientCodes.client_code = client.client_code
				INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = minutes_recorded.dim_fed_hierarchy_history_key
				WHERE bill_date.calendar_date BETWEEN @DateFrom AND @DateTo
				GROUP BY  
						fee_earner.hierarchylevel4hist
						--	,fee_earner.fed_code
							--,bill_date.fin_period
							
							) billed_time ON  billed_time.hierarchylevel4hist = fee_earner.hierarchylevel4hist
							--AND billed_time.fed_code = fee_earner.fed_code
							--AND billed_time.fin_period = bill_date.fin_period
							

	WHERE bill_date.calendar_date >= @PreviousDateFrom
	--AND fee_earner.hierarchylevel4hist = 'Large Loss Manchester and Leeds'
	--AND finance.bill_amount <> 0
	GROUP BY
		 client_group_name
		,fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist
		,CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN ISNULL([hours_billed],0) ELSE 0 END  
	--	,pc_previous.previous_bill_amount
		,CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bill_date.fin_period ELSE ' Profit Costs - Previous Period' END
		
	ORDER BY division,department,team











GO
