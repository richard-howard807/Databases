SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2023-11-03
-- Description:	#173482 LTA KPI measurements
-- =============================================
CREATE PROCEDURE [dbo].[LTA_KPI]
	(
	 @Month VARCHAR(6)
	)
AS
BEGIN

	SET NOCOUNT ON;
    
SELECT DISTINCT dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_date.fin_month AS [Month]
	, CASE WHEN dim_fed_hierarchy_history.hierarchylevel3hist ='Corp Comm & WT&E' THEN 86
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist ='EPI' THEN 88
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist ='Litigation' THEN 89
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist ='Real Estate' THEN 86
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist ='Regulatory' THEN 89
		END AS [Engagement]
	, SUM(fact_agg_billable_time_monthly_rollup.team_level_utilisation_target_percent) AS [Target Utilisation]
	, CASE WHEN SUM(fact_agg_billable_time_monthly_rollup.contracted_hours_in_month)>0 AND SUM(fact_agg_billable_time_monthly_rollup.minutes_recorded/60)>0
			THEN SUM(fact_agg_billable_time_monthly_rollup.minutes_recorded/60)/SUM(fact_agg_billable_time_monthly_rollup.contracted_hours_in_month)
			ELSE NULL END AS [Utilisation]
	, CASE WHEN SUM(fact_agg_billable_time_monthly_rollup.contracted_hours_in_month)>0 AND SUM(fact_agg_billable_time_monthly_rollup.minutes_recorded/60)>0
			THEN SUM(fact_agg_billable_time_monthly_rollup.minutes_recorded/60)/SUM(fact_agg_billable_time_monthly_rollup.contracted_hours_in_month)
			ELSE NULL END/SUM(fact_agg_billable_time_monthly_rollup.team_level_utilisation_target_percent) AS [Utilisation % of Target]
	, Debt.Debt AS [Debt over 90 days]
	, [PrevoiusFYDebt] AS [Debt over 90 days Last FY]
	, [PrevoiusFYDebt]-[PrevoiusFYDebt]*0.1 AS [Target Debt over 90 days]
	, ([PrevoiusFYDebt]-[PrevoiusFYDebt]*0.1)/Debt.Debt AS [Debt over 90 days % of Target]
	, Employees.[Employee Count]
	, Leavers.[Leaver Count]
	, CASE WHEN  Leavers.[Leaver Count]=0 OR Employees.[Employee Count]=0
			THEN null ELSE Leavers.[Leaver Count]/Employees.[Employee Count] END AS [Attrition Rate]

FROM red_dw.dbo.fact_agg_billable_time_monthly_rollup
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_billable_time_monthly_rollup.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date.dim_date_key=fact_agg_billable_time_monthly_rollup.dim_gl_date_key
LEFT OUTER JOIN (SELECT DISTINCT dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
				, fin_month AS [Month]
				, SUM(fact_debt_monthly.outstanding_total_bill) AS [Debt]
				FROM red_dw.dbo.fact_debt_monthly
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key=fact_debt_monthly.dim_fed_matter_owner_key
				LEFT OUTER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date=fact_debt_monthly.debt_date
				WHERE dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
				AND dim_date.fin_year>='2023'
				AND fact_debt_monthly.age_of_debt>90
				GROUP BY dim_fed_hierarchy_history.hierarchylevel4hist,
                         dim_date.fin_month
						 ) AS [Debt]
ON Debt.Team=dim_fed_hierarchy_history.hierarchylevel4hist
AND Debt.Month=dim_date.fin_month

LEFT OUTER JOIN (SELECT DISTINCT dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
				, fin_month AS [Month]
				, SUM(fact_debt_monthly.outstanding_total_bill) AS [PrevoiusFYDebt]
				FROM red_dw.dbo.fact_debt_monthly
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key=fact_debt_monthly.dim_fed_matter_owner_key
				LEFT OUTER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date=fact_debt_monthly.debt_date
				WHERE dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
				AND dim_date.current_fin_year='Previous'
				AND dim_date.fin_month_no=12
				AND fact_debt_monthly.age_of_debt>90
				GROUP BY dim_fed_hierarchy_history.hierarchylevel4hist,
                         dim_date.fin_month
						 ) AS [PreviousFYDebt]
ON [PreviousFYDebt].Team=dim_fed_hierarchy_history.hierarchylevel4hist

LEFT OUTER JOIN (SELECT DISTINCT dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
		, dim_date.fin_month AS [Month]
		, COUNT(DISTINCT dim_employee.employeeid) AS [Leaver Count]
		FROM red_dw.dbo.dim_employee
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
		AND dim_fed_hierarchy_history.activeud=1
		LEFT OUTER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date=dim_employee.leftdate
		WHERE dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
		AND main_reason_for_leaving = '1. Resignation'
		AND ISNULL(secondary_reason_for_leaving,'') <> '3.2 Retirement'
		AND dim_date.fin_year>=2023
		GROUP BY dim_fed_hierarchy_history.hierarchylevel4hist,
				 dim_date.fin_month) AS [Leavers]
ON Leavers.Month = dim_date.fin_month
AND Leavers.Team = dim_fed_hierarchy_history.hierarchylevel4hist

LEFT OUTER JOIN (SELECT dim_date.fin_month AS [Month]
			, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
			, SUM(IIF(ISNULL(dim_employee.leftdate , '29990101') > dim_date.calendar_date, 1, 0) ) AS [Employee Count]
			FROM red_dw.dbo.dim_fed_hierarchy_history
			INNER JOIN red_dw.dbo.dim_employee ON dim_employee.employeeid = dim_fed_hierarchy_history.employeeid
			INNER JOIN red_dw.dbo.dim_date ON dim_date.calendar_date BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
			INNER JOIN (SELECT MAX(dim_date_key) maxdate, fin_year, fin_month_no 
						FROM red_dw.dbo.dim_date 
						GROUP BY dim_date.fin_year, dim_date.fin_month_no) maxdate ON maxdate.maxdate = dim_date.dim_date_key
			WHERE dim_fed_hierarchy_history.activeud = 1
			AND dim_date.fin_year>=2023
			AND calendar_date < DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
			AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
			GROUP BY dim_date.dim_date_key,
					dim_date.fin_month,
					dim_fed_hierarchy_history.hierarchylevel4hist
			) AS [Employees]
ON Employees.Month = dim_date.fin_month
AND Employees.Team = dim_fed_hierarchy_history.hierarchylevel4hist

WHERE dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
AND dim_fed_hierarchy_history.hierarchylevel4hist <>'LTA Management'
AND dim_fed_hierarchy_history.hierarchylevel4hist IS NOT NULL 
AND dim_date.fin_year>=2023
AND dim_date.calendar_date<DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
AND dim_date.fin_month=@Month

GROUP BY CASE
         WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Corp Comm & WT&E' THEN
         86
         WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'EPI' THEN
         88
         WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Litigation' THEN
         89
         WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Real Estate' THEN
         86
         WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Regulatory' THEN
         89
         END,
         [PrevoiusFYDebt] - [PrevoiusFYDebt] * 0.1,
         ([PrevoiusFYDebt] - [PrevoiusFYDebt] * 0.1) / Debt.Debt,
         CASE
         WHEN Leavers.[Leaver Count] = 0
         OR Employees.[Employee Count] = 0 THEN
         NULL
         ELSE
         Leavers.[Leaver Count] / Employees.[Employee Count]
         END,
		 dim_fed_hierarchy_history.hierarchylevel3hist,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         dim_date.fin_month,
		 Debt.Debt, 
         PreviousFYDebt.PrevoiusFYDebt,
         Employees.[Employee Count],
		 Leavers.[Leaver Count]
ORDER BY dim_fed_hierarchy_history.hierarchylevel4hist, fin_month

END
GO
