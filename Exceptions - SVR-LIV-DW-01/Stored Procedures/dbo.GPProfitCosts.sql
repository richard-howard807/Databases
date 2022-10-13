SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2017-11-06
-- Description:	New marketing report requested by Andrea Bridson for GP clients, webby 265461
-- =============================================
CREATE PROCEDURE [dbo].[GPProfitCosts] 

	@StartDate  AS datetime
	,@EndDate AS datetime

AS
BEGIN
	--DECLARE @StartDate  AS DATETIME = '2011-01-01'
	--DECLARE @EndDate AS DATETIME = '2017-11-01'

	
	SET NOCOUNT ON;

    
SELECT 
	contBusActivity AS [Business Activity]
	, clName AS [Client Name]
	, clNo AS [Client Code]
	, client_partner_name AS [Partner]
	, finance.[profitcosts] AS [Total Profit Costs]
	, CASE WHEN bill_current_cal_year='Current' THEN years.profitcosts ELSE NULL END AS [Current FY Profit Costs]
	, CASE WHEN bill_current_cal_year='Previous' THEN years.profitcosts ELSE NULL END AS [Previous FY Profit Costs]
	, [matters] AS [Number of Maters]
	, dim_client.open_date AS [Date Client Opened]
	
	
FROM MS_Prod.dbo.dbContactCompany AS Company
INNER JOIN MS_Prod.config.dbClient ON Company.contid=dbClient.clDefaultContact
INNER JOIN red_dw.dbo.dim_client ON dim_client.client_code=dbClient.clno COLLATE DATABASE_DEFAULT
INNER JOIN (SELECT client_code, SUM(defence_costs_billed) AS [profitcosts] 
			FROM red_dw.dbo.fact_finance_summary 
			GROUP BY client_code) AS [finance] ON [finance].client_code = dim_client.client_code
LEFT OUTER JOIN (SELECT client_code, COUNT(1) AS [matters] 
				FROM red_dw.dbo.dim_matter_header_current
				GROUP BY client_code) AS [matters] ON [matters].client_code = dbClient.clNo COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT client_code, SUM(fees_total) AS profitcosts, bill_fin_year, bill_current_cal_year
			FROM red_dw.dbo.fact_bill_matter_detail
			INNER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill_matter_detail.dim_bill_date_key
			WHERE bill_current_cal_year<>'No'
			GROUP BY client_code, bill_fin_year, bill_current_cal_year) AS years ON years.client_code = dim_client.client_code

WHERE LOWER(contBusActivity) LIKE '%86210%'
AND dim_client.open_date BETWEEN @StartDate AND @EndDate


END
GO
