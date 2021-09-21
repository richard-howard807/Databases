SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[ClientMINewClientOpening] 

AS

BEGIN

DECLARE @Year AS INT
DECLARE @Month AS INT

SET @Year=(SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)),103))
SET @Month=(SELECT DISTINCT fin_month_no FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)),103))

DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE 

SET @StartDate=(SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_year=@Year AND fin_month_no<=@Month)
SET @EndDate=(SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_year=@Year AND fin_month_no<=@Month)




SELECT dim_client.segment 
,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)) AS [Month]
,SUM(NewClientsCreatedPrevious) + SUM(ReopenPrev.ReopeningsPrev) AS [New/Linked/Re-opened Previous YTD]
,SUM(NewCreatedCurrent.NewClientsCreated) + SUM(ReopenCurrent.ReopeningsCurrent) AS [New/Linked/Re-opened YTD]
,SUM(PreviousYear.NewClientYTD) AS [New Clients Billed Previous YTD]
,SUM(CurrentYear.NewClientYTD)  AS [New Clients Billed YTD]
,SUM(PreviousYear.RevenueYTD) AS [New Clients Billing Previous YTD]
,SUM(CurrentYear.RevenueYTD) AS [New Clients Billing YTD]
FROM (SELECT DISTINCT segment FROM red_dw.dbo.dim_client) AS dim_client
LEFT OUTER JOIN (SELECT segment
,SUM(CASE WHEN dim_date.bill_fin_year=@Year THEN 1 ELSE 0 END) AS NewClientYTD
,SUM(RevenueYTD) AS RevenueYTD
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_bill_date AS dim_date WITH(NOLOCK)
 ON CONVERT(DATE,dim_client.open_date,103)=CONVERT(DATE,dim_date.bill_date,103)
INNER JOIN (SELECT client_code,SUM(CASE WHEN dim_bill_date.bill_fin_year=@Year THEN bill_amount ELSE 0 END) AS RevenueYTD 
			FROM red_dw.dbo.fact_bill_activity  WITH(NOLOCK) 
			INNER JOIN red_dw.dbo.dim_bill_date  WITH(NOLOCK) 
			 ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			 WHERE dim_bill_date.bill_fin_year=@Year
			 AND bill_fin_month_no<=@Month
			 		
			GROUP BY client_code
) AS fact_bill_activity_activity
 ON dim_client.client_code=fact_bill_activity_activity.client_code

WHERE dim_date.bill_fin_year=@Year
AND bill_fin_month_no<=@Month
AND sector IS NOT NULL

GROUP BY segment) CurrentYear
ON CurrentYear.segment = dim_client.segment
LEFT OUTER JOIN (SELECT segment
,SUM(CASE WHEN dim_date.bill_fin_year=@Year-1 THEN 1 ELSE 0 END) AS NewClientYTD
,SUM(RevenueYTD) AS RevenueYTD

FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_bill_date AS dim_date WITH(NOLOCK)
 ON CONVERT(DATE,dim_client.open_date,103)=CONVERT(DATE,dim_date.bill_date,103)
INNER JOIN (SELECT client_code,SUM(CASE WHEN dim_bill_date.bill_fin_year=@Year-1 THEN bill_amount ELSE 0 END) AS RevenueYTD 
			FROM red_dw.dbo.fact_bill_activity  WITH(NOLOCK) 
			INNER JOIN red_dw.dbo.dim_bill_date  WITH(NOLOCK) 
			 ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			 WHERE dim_bill_date.bill_fin_year=@Year-1
			 AND bill_fin_month_no<=@Month
			 		
			GROUP BY client_code
) AS fact_bill_activity_activity
 ON dim_client.client_code=fact_bill_activity_activity.client_code

WHERE dim_date.bill_fin_year=@Year-1
AND bill_fin_month_no<=@Month
AND sector IS NOT NULL

GROUP BY segment) AS PreviousYear ON PreviousYear.segment = dim_client.segment

LEFT OUTER JOIN
(
 SELECT segment,
 COUNT(1) AS NewClientsCreated 

FROM MS_Prod.config.dbClient 
INNER JOIN red_dw.dbo.dim_client
 ON clNo=client_code COLLATE DATABASE_DEFAULT
INNER JOIN MS_Prod.dbo.udExtClient udExtClient  ON udExtClient.clID = dbClient.clID
INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,calendar_date,103)=CONVERT(DATE,dbClient.Created,103)
WHERE 1=1
AND fin_year=@Year AND fin_month_no<=@Month
AND dbClient.clName NOT LIKE '%MS TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%ERROR%'
AND dbClient.clNo NOT LIKE 'EMP%'
GROUP BY segment
) AS NewCreatedCurrent
 ON NewCreatedCurrent.segment = dim_client.segment
LEFT OUTER JOIN
(
 SELECT segment,
 COUNT(1) AS NewClientsCreatedPrevious 

FROM MS_Prod.config.dbClient 
INNER JOIN red_dw.dbo.dim_client
 ON clNo=client_code COLLATE DATABASE_DEFAULT
INNER JOIN MS_Prod.dbo.udExtClient udExtClient  ON udExtClient.clID = dbClient.clID
INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,calendar_date,103)=CONVERT(DATE,dbClient.Created,103)
WHERE 1=1
AND fin_year=@Year-1 AND fin_month_no<=@Month
AND dbClient.clName NOT LIKE '%MS TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%ERROR%'
AND dbClient.clNo NOT LIKE 'EMP%'
GROUP BY segment
) AS NewCreatedPrevious
 ON NewCreatedPrevious.segment = dim_client.segment

LEFT OUTER JOIN 
(
SELECT segment,COUNT(1) AS ReopeningsCurrent
FROM 
(
SELECT	MostRecent.mg_client	AS Client
	--,	caclient.cl_clname		AS ClientName
	,	MostRecent.mg_matter	AS Matter
	,	MostRecent.mg_feearn	AS FeeEarner
	,	MostRecent.mg_datopn	AS DateMatterOpened
	,	Previous.mg_feearn		AS	PreviousFeeEarner
	,	Previous.mg_datopn		AS	PreviousDateMatterOpened
	,	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) AS NoYears
FROM
	(
	SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	MostRecent

INNER JOIN 
	(
			SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	Previous
	
	ON	MostRecent.mg_client = Previous.mg_client
INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,MostRecent.mg_datopn,103)=CONVERT(DATE,calendar_date,103)

WHERE	MostRecent.OrderID = 1
	AND Previous.OrderID = 2
	AND	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) >= 3
	AND fin_year=@Year AND fin_month_no<=@Month

) AS AllData
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON AllData.Client=client_code
LEFT OUTER JOIN (
SELECT dim_client.client_code,COUNT(1) AS TotalMatters ,SUM(defence_costs_billed) AS Revenue
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_client.client_code
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
GROUP BY dim_client.client_code) AS TotalMatters
 ON TotalMatters.client_code = dim_client.client_code
WHERE DATEDIFF(MONTH,PreviousDateMatterOpened,DateMatterOpened)/12>=3
GROUP BY segment
) AS ReopenCurrent
 ON ReopenCurrent.segment = dim_client.segment
LEFT OUTER JOIN 
(
SELECT segment,COUNT(1) AS ReopeningsPrev
FROM 
(
SELECT	MostRecent.mg_client	AS Client
	--,	caclient.cl_clname		AS ClientName
	,	MostRecent.mg_matter	AS Matter
	,	MostRecent.mg_feearn	AS FeeEarner
	,	MostRecent.mg_datopn	AS DateMatterOpened
	,	Previous.mg_feearn		AS	PreviousFeeEarner
	,	Previous.mg_datopn		AS	PreviousDateMatterOpened
	,	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) AS NoYears
FROM
	(
	SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	MostRecent

INNER JOIN 
	(
			SELECT	client_code AS mg_client
			,matter_number AS mg_matter
			,matter_owner_full_name AS 	mg_feearn
			,date_opened_practice_management AS 	mg_datopn
			,ROW_NUMBER() OVER (PARTITION BY client_code ORDER BY date_opened_practice_management DESC ) AS OrderID 
			FROM red_dw.dbo.dim_matter_header_current
			WHERE matter_number <>'ML'
	)	Previous
	
	ON	MostRecent.mg_client = Previous.mg_client
INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,MostRecent.mg_datopn,103)=CONVERT(DATE,calendar_date,103)

WHERE	MostRecent.OrderID = 1
	AND Previous.OrderID = 2
	AND	DATEDIFF(YEAR,Previous.mg_datopn,MostRecent.mg_datopn) >= 3
	AND fin_year=@Year-1 AND fin_month_no<=@Month

) AS AllData
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON AllData.Client=client_code
LEFT OUTER JOIN (
SELECT dim_client.client_code,COUNT(1) AS TotalMatters ,SUM(defence_costs_billed) AS Revenue
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_client.client_code
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
GROUP BY dim_client.client_code) AS TotalMatters
 ON TotalMatters.client_code = dim_client.client_code
WHERE DATEDIFF(MONTH,PreviousDateMatterOpened,DateMatterOpened)/12>=3
GROUP BY segment
) AS ReopenPrev
 ON ReopenPrev.segment = dim_client.segment
  


WHERE dim_client.segment IS NOT NULL
GROUP BY dim_client.segment 

ORDER BY dim_client.segment


END 
GO
