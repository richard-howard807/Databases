SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[ClientMIFinancials]

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

SELECT Targets.segmentname,
       Targets.sectorname,
       Targets.TargetRevenue,
	   CurrentYear.RevenueYTD,
	   Previous.PreviousRevenue
	   ,LastYearFull
	   ,CurrentMonth.RevenueMTD
	   ,TargetMonth
	   ,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)) AS ReportingPeriod
	   
FROM (
 SELECT Segments.segmentname,Segments.sectorname,SUM(target_value) AS TargetRevenue
FROM 
(
SELECT MS_Prod.dbo.udSegment.description AS [segmentname],
       MS_Prod.dbo.udSubSegment.description AS [sectorname] 
FROM MS_Prod.dbo.udSubSegment
INNER JOIN MS_Prod.dbo.udSegment
 ON segment=udsegment.code
WHERE  udSegment.active=1
AND udSubSegment.active=1
 ) AS Segments
LEFT OUTER JOIN red_dw.dbo.fact_segment_target_upload
 ON fact_segment_target_upload.sectorname = Segments.sectorname COLLATE DATABASE_DEFAULT
 AND fact_segment_target_upload.segmentname = Segments.segmentname COLLATE DATABASE_DEFAULT
AND financial_month<=@FinMonth
AND  [year]=@FinYear
GROUP BY Segments.segmentname,Segments.sectorname
--SELECT segmentname,sectorname,SUM(target_value) AS TargetRevenue
--FROM red_dw.dbo.fact_segment_target_upload
--WHERE [year]=@FinYear
--AND segmentname=@SegmentName
--AND financial_month<=@FinMonth
--GROUP BY segmentname,sectorname
) AS Targets
LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS RevenueYTD
,SUM(CASE WHEN hierarchylevel3hist='Newcastle' AND segment IS NOT NULL THEN bill_amount ELSE 0 END) AS NewcastleRevenue
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY  segment,sector) AS CurrentYear
 ON Targets.segmentname=CurrentYear.segment COLLATE DATABASE_DEFAULT 
 AND Targets.sectorname=CurrentYear.sector COLLATE DATABASE_DEFAULT

 LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS RevenueMTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no=@FinMonth
GROUP BY  segment,sector) AS CurrentMonth
 ON Targets.segmentname=CurrentMonth.segment COLLATE DATABASE_DEFAULT 
 AND Targets.sectorname=CurrentMonth.sector COLLATE DATABASE_DEFAULT


LEFT OUTER JOIN 
(
SELECT Segments.segmentname,Segments.sectorname,SUM(target_value) AS TargetMonth
FROM 
(
SELECT MS_Prod.dbo.udSegment.description AS [segmentname],
       MS_Prod.dbo.udSubSegment.description AS [sectorname] 
FROM MS_Prod.dbo.udSubSegment
INNER JOIN MS_Prod.dbo.udSegment
 ON segment=udsegment.code
WHERE  udSegment.active=1
AND udSubSegment.active=1
 ) AS Segments
LEFT OUTER JOIN red_dw.dbo.fact_segment_target_upload
 ON fact_segment_target_upload.sectorname = Segments.sectorname COLLATE DATABASE_DEFAULT
 AND fact_segment_target_upload.segmentname = Segments.segmentname COLLATE DATABASE_DEFAULT
AND financial_month=@FinMonth
AND  [year]=@FinYear
GROUP BY Segments.segmentname,Segments.sectorname
) AS TargetMonth
  ON Targets.segmentname=TargetMonth.segmentname COLLATE DATABASE_DEFAULT 
 AND Targets.sectorname=TargetMonth.sectorname COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS PreviousRevenue
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year=@FinYear-1
AND bill_fin_month_no<=@FinMonth

GROUP BY  segment,sector) AS Previous
 ON Targets.segmentname=Previous.segment COLLATE DATABASE_DEFAULT
 AND Targets.sectorname=Previous.sector  COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT segment,sector,SUM(bill_amount) AS LastYearFull
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year=@FinYear-1


GROUP BY  segment,sector
) AS LastYearFull

 ON Targets.segmentname=LastYearFull.segment COLLATE DATABASE_DEFAULT
 AND Targets.sectorname=LastYearFull.sector  COLLATE DATABASE_DEFAULT


ORDER BY Targets.sectorname



END 
GO
