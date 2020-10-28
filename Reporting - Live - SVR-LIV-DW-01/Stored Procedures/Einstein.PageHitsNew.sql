SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Einstein].[PageHitsNew] -- EXEC Einstein.PageHitsNew '2020-10-01','2020-10-28'
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS
BEGIN 

--DECLARE @StartDate AS DATE;
--DECLARE @EndDate AS DATE;
--SET @StartDate = '2020-10-01';
--SET @EndDate = '2020-10-28';
IF OBJECT_ID(N'tempdb..#MainData') IS NOT NULL
BEGIN DROP TABLE #MainData END

SELECT SiteURL AS SiteURL
       ,SUBSTRING(WebURL, 1, 15) AS URL
       ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
	   ,'Einstein' AS Website
       ,WebURL AS WebURL
       ,windowsusername AS Username
       ,name AS [Name]
       ,hierarchylevel3hist AS PracticeArea
       ,hierarchylevel4hist AS Team
       ,[TimeStamp] AS [Timestamp]
       ,COUNT(*) AS [No litigation in person]
INTO #MainData
FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
    INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON REPLACE(WSSUsageLog.UserName, 'sbc\', '') = windowsusername COLLATE DATABASE_DEFAULT
           AND dss_current_flag = 'Y'

WHERE CONVERT(DATE, WSSUsageLog.TimeStamp, 103) >= '2020-01-01'
      AND CONVERT(DATE, WSSUsageLog.TimeStamp, 103)
      BETWEEN @StartDate AND @EndDate
	  AND WebURL <> ''
GROUP BY SiteURL,
         SiteURL,
         WebURL,
         DocUrl,
         WebURL,
         windowsusername,
         name,
         hierarchylevel3hist,
         hierarchylevel4hist,
         [Timestamp]



SELECT SiteURL
       ,URL
       ,FullURL
       ,Website
       ,WebURL
       ,Timestamp
       ,[No litigation in person] 
	   ,NULL AS Section
       ,NULL AS Category
       ,NULL AS SubCategory 
	   FROM #MainData


END 
GO
