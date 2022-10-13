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
	   ,hierarchylevel2hist AS [Section]
       ,hierarchylevel3hist AS Category
       ,hierarchylevel4hist AS SubCategory
	   ,COUNT(*) AS [NoHits]


FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
    INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON REPLACE(WSSUsageLog.UserName, 'sbc\', '') = windowsusername COLLATE DATABASE_DEFAULT
           AND dss_current_flag = 'Y' AND activeud=1

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
		 hierarchylevel2hist,
         hierarchylevel3hist,
         hierarchylevel4hist,
         [Timestamp]





END 
GO
