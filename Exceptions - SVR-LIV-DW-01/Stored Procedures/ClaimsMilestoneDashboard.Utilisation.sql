SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [ClaimsMilestoneDashboard].[Utilisation] 
AS
BEGIN
SELECT gl_calendar_date AS [Date chargeable hours posted]
,CAST(SUM(minutes_recorded / 60) AS DECIMAL(10, 1)) AS ChargeableHrs
,SUM(fact_budget_activity.contracted_hours_in_month)  AS ContractedHrs
,dim_fed_hierarchy_history.name AS [Fee earner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel2hist AS Division
FROM red_dw.dbo.fact_agg_billable_time_monthly_rollup
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_billable_time_monthly_rollup.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_gl_date 
  ON dim_gl_date.dim_gl_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
LEFT OUTER JOIN red_dw.dbo.fact_budget_activity 
  ON fact_budget_activity.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
  AND fact_budget_activity.dim_budget_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key 
WHERE gl_calendar_date >='2019-05-01'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
GROUP BY gl_calendar_date,dim_fed_hierarchy_history.name 
,dim_fed_hierarchy_history.hierarchylevel4hist
,dim_fed_hierarchy_history.hierarchylevel3hist 
,dim_fed_hierarchy_history.hierarchylevel2hist 

END 
GO
