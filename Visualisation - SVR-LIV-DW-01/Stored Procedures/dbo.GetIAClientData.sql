SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[GetIAClientData]

AS 

BEGIN


DECLARE @Period AS NVARCHAR(MAX)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date
WHERE bill_date =DATEADD(MONTH,0,CONVERT(DATE,GETDATE(),103)))

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

DECLARE @MinDate AS DATE
SET @MinDate=(SELECT MIN(bill_date) AS MinDate FROM red_dw.dbo.dim_bill_date WHERE bill_fin_period=@Period)


PRINT @FinYear
PRINT @FinMonth

DECLARE @PreFinYear AS INT
SET @PreFinYear=@FinYear-1

PRINT @PreFinYear

SELECT [Opportunity Number]
	,IA_Client_Data.dim_client_key
	,[Client Name]
	,[Client Category]
	,[Opportunity Name]
	,[Opportunity Type]
	,[Revenue Type]
	,Segments.segmentname AS [Segment]
	,Segments.sectorname  AS [Sector]
	,[CRP]
	,[Open Date]
	,[Days Open]
	,[Last Contacted Date]
	,[Days Since Last Contacted]
	,[Next Engagement Date]
	,[Expected Close Date]
	,[Stage]
	,[Sales Stage]
	,[Opportunity Source]
	,[Campaigns]
	,[Probability %]
	,[Opportunity Value]
	,[Referrer Name]
	,[Referrer Company]
	,[Division]
	,[BD]
	,TargetstaRevenue.TargetRevenue AS [Target Revenue]
	,[Last YR Annual]
	,[MTD Actual]
	,TargetstaRevenue.RevenueYTD AS [YTD Actual]
	,[Outcome]
	,[Outcome Reason]
	,ActualClosedDate
	,CASE WHEN IA_Client_Data.dim_client_key=0 THEN NULL ELSE ClientRevenueYTD END AS ClientRevenueYTD
	,CASE WHEN IA_Client_Data.dim_client_key=0 THEN NULL ELSE ClientPrevRevenueYTD END AS ClientPrevRevenueYTD
	,CASE WHEN IA_Client_Data.dim_client_key=0 THEN NULL ELSE ClientPrevYear END ClientPrevYear
	,AnnualTartget.AnnualTargetRevenue
	,SegmentSectorWIP.SegmentSectorWip
FROM (SELECT MS_Prod.dbo.udSegment.description AS [segmentname],
       MS_Prod.dbo.udSubSegment.description AS [sectorname] 
FROM MS_Prod.dbo.udSubSegment
INNER JOIN MS_Prod.dbo.udSegment
 ON segment=udsegment.code
WHERE udSegment.active=1
AND udSubSegment.active=1
) AS Segments
LEFT OUTER JOIN dbo.IA_Client_Data
 ON UPPER(Segment)=UPPER(Segments.segmentname) COLLATE DATABASE_DEFAULT
 AND UPPER(Sector)=UPPER(Segments.sectorname) COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT Targets.segmentname,
       Targets.sectorname,
       Targets.TargetRevenue,
	   CurrentYear.RevenueYTD

FROM (SELECT segmentname,sectorname,SUM(target_value) AS TargetRevenue
FROM red_dw.dbo.fact_segment_target_upload
WHERE [year]=@FinYear
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
GROUP BY  segment,sector) AS CurrentYear
 ON Targets.segmentname=CurrentYear.segment
 AND Targets.sectorname=CurrentYear.sector
) AS TargetstaRevenue
 ON UPPER(TargetstaRevenue.segmentname)=UPPER(Segments.segmentname) COLLATE DATABASE_DEFAULT
 AND UPPER(TargetstaRevenue.sectorname)=UPPER(Segments.sectorname) COLLATE DATABASE_DEFAULT
---------------------Client Revenue for Bids Tab
LEFT OUTER JOIN 
(
SELECT dim_client.dim_client_key,SUM(bill_amount) AS ClientRevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
--WHERE 
--dim_bill_date.bill_date BETWEEN DATEADD(MONTH,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)) AND 
--CAST(EOMONTH(GETDATE()) AS DATETIME)
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY  dim_client.dim_client_key
) AS ClientRevenueYTD
 ON ClientRevenueYTD.dim_client_key = IA_Client_Data.dim_client_key
 --------------------------------------------------------------------
 LEFT OUTER JOIN 
(
SELECT dim_client.dim_client_key,SUM(bill_amount) AS ClientPrevRevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
--WHERE dim_bill_date.bill_date BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))) AND 
--DATEADD(YEAR, -1,CAST(EOMONTH(GETDATE()) AS DATETIME))
WHERE bill_fin_year= @PreFinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY  dim_client.dim_client_key
) AS ClientPrevRevenueYTD
 ON ClientPrevRevenueYTD.dim_client_key = IA_Client_Data.dim_client_key
--------------------
 LEFT OUTER JOIN 
(
SELECT dim_client.dim_client_key,SUM(bill_amount) AS ClientPrevYear
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
--WHERE dim_bill_date.bill_date BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))) AND 
--DATEADD(YEAR, -1,CAST(EOMONTH(GETDATE()) AS DATETIME))
WHERE bill_fin_year= @PreFinYear
--AND bill_fin_month_no<=@FinMonth
GROUP BY  dim_client.dim_client_key
) AS ClientPrevRevenueYear
 ON ClientPrevRevenueYear.dim_client_key = IA_Client_Data.dim_client_key

LEFT OUTER JOIN 
(
SELECT segmentname,sectorname,SUM(target_value) AS AnnualTargetRevenue
FROM red_dw.dbo.fact_segment_target_upload
WHERE [year]=@FinYear
GROUP BY segmentname,sectorname
) AS AnnualTartget
 ON AnnualTartget.sectorname = Segments.sectorname COLLATE DATABASE_DEFAULT
 AND AnnualTartget.segmentname = Segments.segmentname COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT segment,sector,SUM(wip_value) AS SegmentSectorWip
FROM  red_dw.dbo.fact_wip
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_wip.dim_client_key
GROUP BY segment,sector
) AS SegmentSectorWIP
 ON SegmentSectorWIP.sector = Segments.sectorname COLLATE DATABASE_DEFAULT
 AND SegmentSectorWIP.segment = Segments.segmentname COLLATE DATABASE_DEFAULT

--SELECT [Opportunity Number]
--	,dim_client_key
--	,[Client Name]
--	,[Client Category]
--	,[Opportunity Name]
--	,[Opportunity Type]
--	,TargetsRevenue.segmentname AS [Segment]
--	,TargetsRevenue.sectorname  AS [Sector]
--	,[CRP]
--	,[Open Date]
--	,[Days Open]
--	,[Last Contacted Date]
--	,[Days Since Last Contacted]
--	,[Next Engagement Date]
--	,[Expected Close Date]
--	,[Stage]
--	,[Sales Stage]
--	,[Opportunity Source]
--	,[Campaigns]
--	,[Probability %]
--	,[Opportunity Value]
--	,[Referrer Name]
--	,[Referrer Company]
--	,[Division]
--	,[BD]
--	,TargetsRevenue.TargetRevenue AS [Target Revenue]
--	,[Last YR Annual]
--	,[MTD Actual]
--	,TargetsRevenue.RevenueYTD AS [YTD Actual]
--	,[Outcome]
--	,[Outcome Reason]
--	,ActualClosedDate
--FROM 
--(
--SELECT Targets.segmentname,
--       Targets.sectorname,
--       Targets.TargetRevenue,
--	   CurrentYear.RevenueYTD

--FROM (SELECT segmentname,sectorname,SUM(target_value) AS TargetRevenue
--FROM red_dw.dbo.fact_segment_target_upload
--WHERE [year]=@FinYear
--AND financial_month<=@FinMonth
--GROUP BY segmentname,sectorname
--) AS Targets
--LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS RevenueYTD
--FROM red_dw.dbo.fact_bill_activity
--INNER JOIN red_dw.dbo.dim_bill_date
-- ON dim_bill_date.bill_date = fact_bill_activity.bill_date
--INNER JOIN red_dw.dbo.dim_client
-- ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
--WHERE bill_fin_year= @FinYear
--AND bill_fin_month_no<=@FinMonth
--GROUP BY  segment,sector) AS CurrentYear
-- ON Targets.segmentname=CurrentYear.segment
-- AND Targets.sectorname=CurrentYear.sector
--) AS TargetsRevenue
--LEFT OUTER JOIN dbo.IA_Client_Data
-- ON UPPER(Segment)=UPPER(TargetsRevenue.segmentname)
-- AND UPPER(Sector)=UPPER(TargetsRevenue.sectorname)

END
GO
