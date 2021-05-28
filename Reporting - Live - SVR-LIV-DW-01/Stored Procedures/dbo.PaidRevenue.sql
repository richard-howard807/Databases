SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[PaidRevenue]
(
--@Division AS NVARCHAR(MAX)
--,@Department AS NVARCHAR(MAX)
--,@Team AS NVARCHAR(MAX)
--,@FeeEarner AS NVARCHAR(MAX)
@Period AS NVARCHAR(20)
,@FEDCode  AS NVARCHAR(MAX)
,@Level AS NVARCHAR(MAX)
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

	DROP TABLE  IF EXISTS #FedCodeList
    	CREATE TABLE #FedCodeList  (
ListValue  NVARCHAR(MAX)
)
IF @level  <> 'Individual'
	BEGIN
	PRINT ('not Individual')
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
use red_dw;
DECLARE @nDate AS DATE = GETDATE()

SELECT DISTINCT
dim_fed_hierarchy_history_key
FROM red_Dw.dbo.dim_fed_hierarchy_history 
WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

INSERT into #FedCodeList 
exec sp_executesql @sql
	end
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT into #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END 

SELECT hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]
,display_name AS [Display Name]
,dim_fed_hierarchy_history.fed_code
,receipt_fin_year AS FinYear
,SUM(CASE WHEN receipt_fin_month_no=@FinMonth THEN revenue ELSE 0 END) AS [MTDRevenue]
,SUM(revenue) AS YTDRevene
FROM red_dw.dbo.fact_bill_receipts_detail 
INNER JOIN red_dw.dbo.dim_receipt_date
 ON dim_receipt_date.dim_receipt_date_key = fact_bill_receipts_detail.dim_receipt_date_key
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_receipts_detail.dim_fed_hierarchy_history_key

 WHERE receipt_fin_year=@FinYear
     AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
              (
                  SELECT (CASE
                              WHEN @Level = 'Firm' THEN
                                  dim_fed_hierarchy_history_key
                              ELSE
                                  0
                          END
                         )
                  FROM red_dw.dbo.dim_fed_hierarchy_history
                  UNION
                  SELECT  (CASE
                              WHEN @Level IN ( 'Individual' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
                  UNION
                  SELECT (CASE
                              WHEN @Level IN ( 'Area Managed' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
              ) 
GROUP BY hierarchylevel2hist 
,hierarchylevel3hist 
,hierarchylevel4hist 
,display_name
,dim_fed_hierarchy_history.fed_code
,receipt_fin_year
END
GO
