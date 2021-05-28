SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[PaidRevenueDrilldown]
(
@Period AS NVARCHAR(20)
,@FedCode AS NVARCHAR(100)
,@Division AS NVARCHAR(MAX)
,@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)
AS 

BEGIN

--DECLARE @Period AS NVARCHAR(MAX)
--SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date
--WHERE bill_date =DATEADD(MONTH,0,CONVERT(DATE,GETDATE(),103)))

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)




SELECT fact_bill_receipts_detail.client_code
,client_name AS [Client Name]
,fact_bill_receipts_detail.matter_number AS [Matter Number]
,matter_description AS[Matter Description]
,name AS [Fee Earner]
,matter_partner_full_name
,bill_date
,bill_number
,revenue
,CASE WHEN receipt_fin_month_no=@FinMonth THEN 1  ELSE 0 END AS [MTD]

FROM red_dw.dbo.fact_bill_receipts_detail 
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_receipts_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_receipt_date
 ON dim_receipt_date.dim_receipt_date_key = fact_bill_receipts_detail.dim_receipt_date_key
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_receipts_detail.dim_fed_hierarchy_history_key
 WHERE receipt_fin_year=@FinYear
AND dim_fed_hierarchy_history.fed_code=@FedCode
AND hierarchylevel2hist=@Division
AND hierarchylevel3hist=@Department
AND hierarchylevel4hist=@Team
END
GO
