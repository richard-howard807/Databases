SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =========================================================================================
-- Author:		Max Taylor
-- Create date: 08/11/2021
-- Ticket:		119900
-- Description:	Initial Create SQL Hours
--=========================================================================================

-- =========================================================================================
CREATE PROCEDURE [dbo].[CapacityPlanningClaims_Hours]

AS

DROP TABLE IF EXISTS #t1
DROP TABLE IF EXISTS #pers

SELECT 

DatePeriod = REPLACE(RIGHT(fin_period,9),')',''),
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

--AND fin_year >= YEAR(GETDATE())

AND fed.hierarchylevel2hist = 'Legal Ops - Claims'

AND fed.hierarchylevel3hist IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )

GROUP BY fin_period,
hierarchylevel3hist, 
fin_period,
fin_month_display,
fin_month_name,
fin_year
,fin_month_no,
fin_period,
fin_month_display

ORDER BY fin_year, fin_month_no


SELECT DISTINCT TOP 25  Month INTO #pers FROM #t1
ORDER BY Month DESC 



SELECT #t1.* 

,
LinearForecast = CASE WHEN [Actual Chargeable Hours] IS NULL  then 

'''=' + Department + '_Linear!$E' +CAST(
ROW_NUMBER() OVER (PARTITION BY Department ORDER BY  Month) - 7 AS VARCHAR(3)) END
FROM #t1

WHERE MONTH IN (SELECT DISTINCT Month FROM #pers)
GO
