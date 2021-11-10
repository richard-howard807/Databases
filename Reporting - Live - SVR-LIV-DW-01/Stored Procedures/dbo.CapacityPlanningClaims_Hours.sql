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
DROP TABLE IF EXISTS #matters

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


SELECT 
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''), 
Department =  hierarchylevel3hist,
NewMatters = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.open_practice_management_month end),
ClosedMatters = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.closed_case_management_month end), 
Active = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.open_case_management end)
INTO #matters
FROM red_dw.dbo.fact_matter_summary
join red_dw.dbo.fact_dimension_main on fact_dimension_main.master_fact_key = fact_matter_summary.master_fact_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key_original_matter_owner_dopm 
JOIN red_dw.dbo.dim_matter_header_history
ON dim_matter_header_history_key = dim_mat_head_history_key
JOIN  red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.client_code = dim_matter_header_history.client_code AND dim_matter_header_current.matter_number = dim_matter_header_history.matter_number
JOIN red_dw.dbo.dim_date 
ON dim_date.dim_date_key = fact_matter_summary.dim_date_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
WHERE 1 = 1 
AND fin_period >= '2020-12 (Apr-2020)'
AND ISNULL(hierarchylevel3hist,'') IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )
AND ISNULL(dim_matter_header_current.reporting_exclusions, 0)  = 0

/*Test */
--AND ISNULL(hierarchylevel3hist,'') IN ('Casualty' )
--AND fin_period = '2021-12 (Apr-2021)'

GROUP BY 

fin_period,
  hierarchylevel3hist, fact_matter_summary.fin_month

  ORDER BY  hierarchylevel3hist, fin_period





SELECT #t1.DatePeriod,
       #t1.Month,
       #t1.Department,
       #t1.fin_month_display,
       #t1.[Actual Chargeable Hours],
       #t1.[Chargeable Hours Target]	

,
LinearForecast = CASE WHEN [Actual Chargeable Hours] IS NULL  then 

'''=' + #t1.Department + '_Linear!$E' +CAST(
ROW_NUMBER() OVER (PARTITION BY #t1.Department  ORDER BY  Month) - 7 AS VARCHAR(3)) END
,#matters.NewMatters
,#matters.ClosedMatters
,#matters.Active
FROM #t1
LEFT JOIN #matters
ON #matters.DatePeriod = #t1.DatePeriod AND #matters.Department = #t1.Department

WHERE MONTH IN (SELECT DISTINCT Month FROM #pers)
GO
