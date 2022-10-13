SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ZurichPaidBills] --EXEC dbo.ZurichPaidBills '2020-01-01','2020-08-06'
(
@StartDate AS DATE
,@EndDate AS DATE
,@FedCode AS NVARCHAR(MAX)
)
AS 

BEGIN

IF OBJECT_ID('tempdb..#FeeEarnerList') IS NOT NULL   DROP TABLE #FeeEarnerList
SELECT ListValue  INTO #FeeEarnerList FROM 	dbo.udt_TallySplit(',', @FedCode)


SELECT 
dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Fee Earner Name]
,fee_earner_code
,work_type_name AS [Work Type]
,dim_bill.bill_number AS [Bill Number]
,Payor AS [Payor Name]
,amount_paid AS [Amount Paid]
,bill_total AS [Bill Total]
,last_pay_calendar_date AS [Bill Last Payment Date]
,CASE WHEN dim_bill.bill_flag='i' THEN 'Interim' 
WHEN dim_bill.bill_flag='f' THEN 'Final' ELSE dim_bill.bill_flag END AS [Bill Final or Interim]
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN #FeeEarnerList AS FedCode ON FedCode.ListValue COLLATE DATABASE_DEFAULT = fee_earner_code COLLATE DATABASE_DEFAULT

INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_last_pay_date
 ON dim_last_pay_date.dim_last_pay_date_key = fact_bill.dim_last_pay_date_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN 
(
SELECT Payor.InvNumber,STRING_AGG(Payor,', ') AS Payor FROM 
(
SELECT DISTINCT InvNumber,Payor.DisplayName AS Payor FROM  TE_3E_Prod.dbo.ARDetail WITH (NOLOCK)
INNER JOIN TE_3E_Prod.dbo.InvMaster  WITH (NOLOCK) 
 ON ARDetail.InvMaster=InvMaster.InvIndex
INNER JOIN TE_3E_Prod.dbo.Matter WITH (NOLOCK) 
 ON ARDetail.Matter=Matter.MattIndex
INNER JOIN TE_3E_Prod.dbo.Client  WITH (NOLOCK) 
 ON Matter.Client=Client.ClientIndex
LEFT OUTER JOIN TE_3E_Prod.dbo.Payor ON ARDetail.Payor=Payor.PayorIndex
WHERE (Client.Number='Z1001' OR  Client.AltNumber='Z1001') 
AND IsReversed=0
) AS Payor
GROUP BY Payor.InvNumber
) AS Payor
 ON dim_bill.bill_number=Payor.InvNumber COLLATE DATABASE_DEFAULT
WHERE
master_client_code='Z1001'
AND bill_reversed=0
AND fact_bill.bill_number <>'PURGE'
AND bill_total=amount_paid
AND last_pay_calendar_date BETWEEN @StartDate AND @EndDate
AND work_type_name ='Disease - Industrial Deafness'
AND UPPER(Payor) LIKE '%ZURICH%'

END
GO
