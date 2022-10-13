SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CapacityPlanningClaims_Hours_LinearForecast]
--EXEC [CapacityPlanningClaims_Hours_LinearForecast]
AS


DROP TABLE IF EXISTS #t1
DROP TABLE IF EXISTS #pers
SELECT 

DatePeriod = REPLACE(RIGHT(fin_period,9),')',''),
TimeLine = '01/' + CASE WHEN LEN(cal_month_no) = 1 THEN '0' + CAST(cal_month_no AS VARCHAR(2)) ELSE CAST(cal_month_no AS VARCHAR(2)) end  +  '/'+ CAST(cal_year AS VARCHAR(4)),
Month = fin_period,
Department =  hierarchylevel3hist, 
fin_month_display,
[Actual Chargeable Hours]  = 
SUM(
CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL 
     WHEN a.minutes_recorded/60  = 0 THEN NULL
ELSE a.minutes_recorded / 60 END) , 
[Chargeable Hours Target] =  SUM(a.team_level_budget_value_hours)

INTO #t1
FROM            red_dw.dbo.fact_agg_billable_time_monthly_rollup AS 

a LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS fed 
ON fed.dim_fed_hierarchy_history_key = a.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_date ON a.dim_gl_date_key = dim_date_key

WHERE 1 =1 --

AND fin_period >= '2020-12 (Apr-2020)' -- may need to update with financial year - 1 


AND fed.hierarchylevel2hist = 'Legal Ops - Claims'

AND fed.hierarchylevel3hist IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )


GROUP BY 
hierarchylevel3hist, 
fin_period,
fin_month_display,
fin_month_name,
fin_year
,fin_month_no,
fin_period,
fin_month_display
, '01/' + CASE WHEN LEN(cal_month_no) = 1 THEN '0' + CAST(cal_month_no AS VARCHAR(2)) ELSE CAST(cal_month_no AS VARCHAR(2)) end  +  '/'+ CAST(cal_year AS VARCHAR(4))
ORDER BY fin_year, fin_month_no

--SELECT * FROM #t1 


SELECT DISTINCT TOP 13  Month INTO #pers FROM #t1
ORDER BY Month DESC 

SELECT 
TimeLine= CONVERT(DATE, TimeLine, 103), 
Month, 
[Actual Chargeable Hours], 
Department, 
CAST(ROW_NUMBER()  OVER (PARTITION BY Department ORDER BY Month ) + 5 AS VARCHAR(20))AS RN 
--LEFT(DATENAME(MONTH,CAST(TimeLine AS DATE)),3) +'-'+ RIGHT(CAST(YEAR(CAST(TimeLine AS DATE)) AS varchar(4)), 2)


FROM #t1
WHERE Month

IN (SELECT Month FROM #pers)
ORDER BY Month
GO
