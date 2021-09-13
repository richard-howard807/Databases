SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClientMINewClientOpening] 

AS

BEGIN

DECLARE @Year AS INT
DECLARE @Month AS INT

SET @Year=(SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,GETDATE(),103))
SET @Month=(SELECT DISTINCT fin_month_no FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,GETDATE(),103))

PRINT @Month

SELECT dim_client.segment  
,NULL AS [New/Linked/Re-opened Previous YTD]
,NULL AS [New/Linked/Re-opened YTD]
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
WHERE dim_client.segment IS NOT NULL
GROUP BY dim_client.segment 

ORDER BY dim_client.segment


END 
GO
