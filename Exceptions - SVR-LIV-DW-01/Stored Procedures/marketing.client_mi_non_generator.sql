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
-- Create date: 05/06/2018
-- Description:	Client MI Report - Non-Generator Client Version
--				Profit Costs by fee earner (includes profit costs for matters that do not exist in matter header table)	
-- =============================================
-- Issues to code around:	fin_month_display where calendar date = '01/05/2017'
-- 20180621 fix related to recovery rate
-- ==============================================

CREATE PROCEDURE [marketing].[client_mi_non_generator]
(
	  @current_fin_from INT
	, @current_fin_to INT
	, @client_group_name VARCHAR(12)
	, @client_code VARCHAR(MAX)
	
)
AS

/*
	For testing purposes
*/

	--DECLARE @current_fin_from INT = '202001'
	--DECLARE @current_fin_to INT = '202009'
	--DECLARE @client_group_name VARCHAR(200) =  '00000131'
	--DECLARE @client_code VARCHAR(200) = NULL --'T15036,W15693,00798758'


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

	CASE WHEN @client_group_name IS NOT NULL AND client_group_code = @client_group_name THEN 1
		WHEN @client_code IS NOT NULL AND client_code IN  (SELECT val COLLATE DATABASE_DEFAULT FROM  [dbo].[split_delimited_to_rows](@client_code,','))   THEN 1
		ELSE 0 END = 1	



		

	SELECT
			client_group_name
			,Data.division
			,Data.department
			,Data.team
			,Data.fin_month_display
			,SUM(ISNULL(Data.previous_bill_amount,0)) previous_bill_amount
			,SUM(ISNULL(Data.bill_amount,0)) bill_amount
			,SUM(Data.billed_time/60) billed_time
		INTO #results
			 
	FROM
	(
	-- financials
	SELECT	
		client_group_name
		,fee_earner.hierarchylevel2hist [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bill_date.fin_period ELSE ' Profit Costs - Previous Period'  END fin_month_display
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN finance.bill_amount ELSE 0 END)  previous_bill_amount
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN ISNULL(finance.bill_amount,0) ELSE 0 END  ) [bill_amount]
		,0 [billed_time]
	FROM red_dw.dbo.fact_bill_activity finance
	INNER JOIN red_dw.dbo.dim_date bill_date ON finance.dim_bill_date_key = bill_date.dim_date_key
	INNER JOIN #ClientCodes ON #ClientCodes.client_code = finance.client_code
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = finance.dim_fed_hierarchy_history_key --finance.fed_code_fee_earner = fee_earner.fed_code AND fee_earner.dss_current_flag = 'Y'

	WHERE bill_date.calendar_date >= @PreviousDateFrom
	--AND fee_earner.hierarchylevel4hist = 'Large Loss Manchester and Leeds'
	--AND finance.bill_amount <> 0
	GROUP BY
		 client_group_name
		,fee_earner.hierarchylevel2hist 
		,fee_earner.hierarchylevel3hist 
		,fee_earner.hierarchylevel4hist
	--	,CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN ISNULL([hours_billed],0) ELSE 0 END  
	--	,pc_previous.previous_bill_amount
		,CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bill_date.fin_period ELSE ' Profit Costs - Previous Period' END
		
	UNION ALL 
		
	SELECT		#ClientCodes.client_group_name
							,fee_earner.hierarchylevel2hist [division]
							,fee_earner.hierarchylevel3hist [department]
							,fee_earner.hierarchylevel4hist [team]
							,' Profit Costs - Previous Period' [fin_month_display]
							,0 previous_bill_amount
							,0 bill_amount
							,SUM(isnull(minutes_recorded, 0)) [hours_billed]
				FROM red_dw.dbo.fact_bill_billed_time_activity minutes_recorded
				INNER JOIN red_dw.dbo.dim_date bill_date ON minutes_recorded.dim_bill_date_key  = bill_date.dim_date_key
				INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = minutes_recorded.dim_client_key
				INNER JOIN #ClientCodes ON #ClientCodes.client_code = client.client_code
				INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = minutes_recorded.dim_fed_hierarchy_history_key
				WHERE bill_date.calendar_date BETWEEN @DateFrom AND @DateTo
				GROUP BY  
						#ClientCodes.client_group_name
							,fee_earner.hierarchylevel2hist 
							,fee_earner.hierarchylevel3hist 
							,fee_earner.hierarchylevel4hist
					
	
	) Data



	
	
	GROUP BY client_group_name
			,Data.division
			,Data.department
			,Data.team
			,Data.fin_month_display





	SELECT *
	FROM #results

	UNION all


	SELECT DISTINCT client_group_name,
           division,
           department,
           team,
           missing_fin_periods.fin_period,
           0,
           0,
           0
	FROM #results
	CROSS APPLY (
		SELECT DISTINCT fin_period
		FROM red_dw..dim_date
		WHERE fin_period NOT IN (
				SELECT fin_month_display
				FROM #results)
		AND calendar_date BETWEEN @DateFrom AND @DateTo
		--anD calendar_date BETWEEN '20190501' AND '20200131'
	) missing_fin_periods

		
GO
