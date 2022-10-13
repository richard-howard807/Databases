SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 02/07/2018
-- Description:	Ticket 318801:  New report for Andy Cooper (Profit Costs by Client Group for a Department/team
--				NOTE:  I have done this in sql because I can do it quickly.  Should probably be written
--						against the profit costs cube in MDX.  On my todo list!
-- =============================================
-- ES 2021-12-14 added segment and sector removed team parameter requested by BH 


CREATE PROCEDURE [kpi].[client_profit_costs_per_department]
(
	@current_fin_from INT
	,@current_fin_to INT
	,@division VARCHAR(MAX)
	,@department VARCHAR(MAX)
	--,@team VARCHAR(MAX)
)
AS

	
	/*For testing purposes*/
	--DECLARE @current_fin_from INT = '201801'
	--DECLARE @current_fin_to INT = '201812'
	

	SELECT val 
	INTO #division
	FROM dbo.split_delimited_to_rows(@division,',')
	
	SELECT val 
	INTO #department
	FROM dbo.split_delimited_to_rows(@department,',')
	 
	 --SELECT val 
	 --INTO #team
	 --FROM dbo.split_delimited_to_rows(@team,',')


	
	
	DECLARE @DateFrom DATE 
	DECLARE @DateTo DATE 
	SELECT  @DateFrom = MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @current_fin_from
	SELECT  @DateTo = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @current_fin_to
	-- used for previous profit costs
	DECLARE @PreviousDateFrom DATE = DATEADD(YEAR,-1,@DateFrom)
	DECLARE @PreviousDateTo DATE = DATEADD(YEAR,-1,@DateTo)





	SELECT 
		fee_earner.hierarchylevel2hist  [division]
		,fee_earner.hierarchylevel3hist [department]
		,fee_earner.hierarchylevel4hist [team]
		,COALESCE(NULLIF(client.client_group_code,''),client.client_code) client_or_group
		,COALESCE(NULLIF(client.client_group_name,''),client.client_name) client_or_group_name
		,client.segment
		,client.sector
		-- financials
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN bills.bill_amount ELSE 0 END)  previous_pc_ytd
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bills.bill_amount ELSE 0 END  ) [current_pc_ytd]
		,SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bills.bill_amount ELSE 0 END  )- SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN bills.bill_amount ELSE 0 END) AS [Movement from last period (Department)]
		, CASE WHEN SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bills.bill_amount ELSE 0 END  )- SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN bills.bill_amount ELSE 0 END) <0.00 THEN 'Red'
		  WHEN SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bills.bill_amount ELSE 0 END  )- SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN bills.bill_amount ELSE 0 END) =0.00 THEN 'Yellow'
		  WHEN SUM(CASE WHEN bill_date.calendar_date BETWEEN @DateFrom AND @DateTo THEN bills.bill_amount ELSE 0 END  )- SUM(CASE WHEN bill_date.calendar_date BETWEEN @PreviousDateFrom AND @PreviousDateTo THEN bills.bill_amount ELSE 0 END) > 0.00 THEN 'Light Green'
		  END AS BackColor
			

	FROM red_dw.dbo.fact_bill_activity bills 
	INNER JOIN red_dw.dbo.dim_date bill_date ON bills.dim_bill_date_key = bill_date.dim_date_key	
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON fee_earner.dim_fed_hierarchy_history_key = bills.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = bills.dim_client_key
	--INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = bills.dim_matter_header_curr_key
	WHERE bill_date.calendar_date >= @PreviousDateFrom 
	--AND fee_earner.hierarchylevel3hist = @department
	AND fee_earner.hierarchylevel2hist COLLATE DATABASE_DEFAULT IN (SELECT val FROM #division)
	AND fee_earner.hierarchylevel3hist COLLATE DATABASE_DEFAULT IN (SELECT val FROM #department)
	--AND fee_earner.hierarchylevel4hist COLLATE DATABASE_DEFAULT IN (SELECT val FROM #team)
	
	AND bills.client_code NOT IN ('00030645','95000C')
	GROUP BY 	fee_earner.hierarchylevel2hist 
			,fee_earner.hierarchylevel3hist 
			,fee_earner.hierarchylevel4hist 
		,COALESCE(NULLIF(client.client_group_code,''),client.client_code) 
		,COALESCE(NULLIF(client.client_group_name,''),client.client_name) 
		,client.segment
		,client.sector
	
	ORDER BY division,department,team,current_pc_ytd DESC

GO
