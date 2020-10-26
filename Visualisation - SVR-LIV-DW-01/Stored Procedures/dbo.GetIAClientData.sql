SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GetIAClientData]

AS 

BEGIN


DECLARE @Period AS NVARCHAR(MAX)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date
WHERE bill_date =DATEADD(MONTH,-1,CONVERT(DATE,GETDATE(),103)))

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

SELECT [Opportunity Number]
	,dim_client_key
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
FROM (SELECT MS_Prod.dbo.udSegment.description AS [segmentname],
       MS_Prod.dbo.udSubSegment.description AS [sectorname] 
FROM MS_Prod.dbo.udSubSegment
INNER JOIN MS_Prod.dbo.udSegment
 ON segment=udsegment.code
where udSegment.active=1
and udSubSegment.active=1
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
