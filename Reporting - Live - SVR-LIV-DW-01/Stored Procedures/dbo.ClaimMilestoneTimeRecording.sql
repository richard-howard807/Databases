SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ClaimMilestoneTimeRecording]
(
@StartDate AS DATE
,@EndDate AS DATE
,@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)

AS 

BEGIN

IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
SELECT ListValue  INTO #Department FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)


SELECT 
name
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,CONVERT(DATE,transaction_calendar_date,103) AS [Date]
,SUM(minutes_recorded) / 60 AS Hrs
,COUNT(DISTINCT dim_matter_header_curr_key) AS NoMatters
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_transaction_date
 ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

WHERE CONVERT(DATE,transaction_calendar_date,103) BETWEEN @StartDate AND @EndDate
AND hierarchylevel2hist='Legal Ops - Claims'
GROUP BY name
,hierarchylevel3hist
,hierarchylevel4hist
,CONVERT(DATE, transaction_calendar_date, 103)

ORDER BY name,hierarchylevel3hist,hierarchylevel4hist,CONVERT(DATE, transaction_calendar_date, 103)

END
GO
