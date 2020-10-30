SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Einstein].[PageHitsNewSummary] -- EXEC Einstein.PageHitsNew '2020-10-01','2020-10-28'
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS
BEGIN 

SELECT AllData.Username 
,[Name]
,AllData.Team AS [Team]
,AllData.PracticeArea AS [PracticeArea]
,AllData.Timestamp AS [TIMEStamp]
,SUM(AllData.NoHits) AS [Total Hits]
,ROW_NUMBER() OVER(ORDER BY SUM(AllData.NoHits) DESC) AS [RowID]
FROM (

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
       ,COUNT(*) AS [NoHits]

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


) AS AllData

GROUP BY AllData.Username 
,[Name]
,AllData.Team
,AllData.PracticeArea 
,AllData.Timestamp 


END 
GO
