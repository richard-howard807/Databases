SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[MonthSegmentTemplateFinancials]
(
@Period AS NVARCHAR(MAX)
,@SegmentName AS NVARCHAR(MAX)
)
AS

BEGIN

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
	   Previous.PreviousRevenue,
	   NextMonth AS NextMonthTarget,
	   @Period AS [Period],
	   @MinDate,
	   DATEADD(MONTH,1,(@MinDate)) AS NextMonth
	   
FROM (SELECT segmentname,sectorname,SUM(target_value) AS TargetRevenue
FROM red_dw.dbo.fact_segment_target_upload
WHERE [year]=@FinYear
AND segmentname=@SegmentName
AND financial_month<=@FinMonth
GROUP BY segmentname,sectorname
) AS Targets
LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS RevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
AND segment=@SegmentName
GROUP BY  segment,sector) AS CurrentYear
 ON Targets.segmentname=CurrentYear.segment
 AND Targets.sectorname=CurrentYear.sector
LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS PreviousRevenue
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year=@FinYear-1
AND bill_fin_month_no<=@FinMonth
AND segment=@SegmentName

GROUP BY  segment,sector) AS Previous
 ON Targets.segmentname=Previous.segment
 AND Targets.sectorname=Previous.sector

LEFT OUTER JOIN 
(
SELECT Segment,
Sector,SUM([Opportunity Value]) AS NextMonth
FROM Visualisation.dbo.IA_Client_Data
WHERE 
[Expected Close Date] BETWEEN  DATEADD(MONTH,1,(@MinDate)) AND DATEADD(DAY,-1,DATEADD(MONTH,2,(@MinDate)))

GROUP BY Segment,Sector
) AS NextMonth
 ON UPPER(Targets.segmentname)=UPPER(NextMonth.Segment)
 AND UPPER(Targets.sectorname)=UPPER(NextMonth.Sector)

ORDER BY Targets.sectorname



END 
GO
