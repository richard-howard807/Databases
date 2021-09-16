SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClientMIWIP]

AS 

BEGIN

DECLARE @Period AS NVARCHAR(500)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)),103))

PRINT @Period

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

DECLARE @MinDate AS DATE
SET @MinDate=(SELECT MIN(bill_date) AS MinDate FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)


PRINT @FinYear
PRINT @FinMonth


SELECT Segments.segmentname AS Segment
,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)) AS ReportingPeriod
,CurrentMonth.WIPCurrent AS [WIP]
,PreviousMonth.WIPPrevious AS [Prior Year WIP]
,CurrentMonth.WIPCurrent - PreviousMonth.WIPPrevious AS [WIP Difference]
,CurrentMonth.Over90Current AS [WIP >90 Days]
,PreviousMonth.Over90Previous AS [Prior Year WIP >90 Days]
,CurrentMonth.Over90Current - PreviousMonth.Over90Previous AS [>90 Days Difference]
FROM 
(
SELECT DISTINCT MS_Prod.dbo.udSegment.description AS [segmentname]
       --MS_Prod.dbo.udSubSegment.description AS [sectorname] 
FROM MS_Prod.dbo.udSubSegment
INNER JOIN MS_Prod.dbo.udSegment
 ON segment=udsegment.code
WHERE  udSegment.active=1
AND udSubSegment.active=1
 ) AS Segments 
LEFT OUTER JOIN ( 
SELECT segment,SUM(wip_value) AS WIPCurrent,SUM(wip_over_90_days) AS [Over90Current] 
FROM red_dw.dbo.fact_wip_monthly
 INNER JOIN red_dw.dbo.dim_client
  ON dim_client.dim_client_key = fact_wip_monthly.dim_client_key
 INNER JOIN red_dw.dbo.dim_transaction_date
  ON dim_transaction_date.dim_transaction_date_key = fact_wip_monthly.dim_transaction_date_key
WHERE transaction_fin_year= @FinYear
AND transaction_fin_month_no=@FinMonth
GROUP BY segment) AS CurrentMonth
ON Segments.segmentname=CurrentMonth.segment COLLATE DATABASE_DEFAULT 
LEFT OUTER JOIN ( 
SELECT segment,SUM(wip_value) AS WIPPrevious,SUM(wip_over_90_days) AS [Over90Previous] 
FROM red_dw.dbo.fact_wip_monthly
 INNER JOIN red_dw.dbo.dim_client
  ON dim_client.dim_client_key = fact_wip_monthly.dim_client_key
 INNER JOIN red_dw.dbo.dim_transaction_date
  ON dim_transaction_date.dim_transaction_date_key = fact_wip_monthly.dim_transaction_date_key
WHERE transaction_fin_year= @FinYear-1
AND transaction_fin_month_no=@FinMonth
GROUP BY segment) AS PreviousMonth
ON Segments.segmentname=PreviousMonth.segment COLLATE DATABASE_DEFAULT 

ORDER BY 1 ASC



END
GO
