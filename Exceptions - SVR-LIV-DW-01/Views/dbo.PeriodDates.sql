SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE  VIEW [dbo].[PeriodDates]
AS  
                 
      WITH    DatesTable
              AS (SELECT CONVERT(date,DATEADD(dd,-N,GETDATE()+1)) AS [Date] FROM dbo.Tally)
              
    SELECT  [Date]
          , (
              SELECT    Period
              FROM      [dbo].[CalculatePeriod](YEAR([Date]), MONTH([Date]))
            ) AS YearPeriod
          , CASE WHEN DATENAME(WEEKDAY, [Date]) = 'Sunday'
                      OR DATENAME(WEEKDAY, [Date]) = 'Saturday' THEN 0
                 ELSE 1
            END AS WorkingDay
    FROM    DatesTable

--SELECT  Date ,
--        YearPeriod ,
--        WorkingDay FROM VP01SVR.VisiblePracticeV4.dbo.PeriodDates 

GO
