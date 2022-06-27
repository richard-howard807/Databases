SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[RevenueandHours_Revenue]

(
@fin_period AS NVARCHAR(60)
)


AS


SELECT   

[Business Line] = fed.hierarchylevel1hist,
[Practice Area] = fed.hierarchylevel2hist,
[Team] = fed.hierarchylevel3hist ,
[Display Name] = fed.hierarchylevel5hist,
b.dim_bill_date_key, 
b.dim_fed_hierarchy_history_key, 
b.billed_time, b.minutes_recorded, 
b.bill_amount, b.fed_level_budget_value, 
b.fed_level_minute_value, 
b.fed_level_tb_budget_value, 
b.team_level_budget_value, 
b.team_level_budget_value_balance, 
b.practice_area_level_budget_value, 
b.business_line_level_budget_value, 
b.firm_level_budget_value, 
b.dss_update_time, 
CASE WHEN fed.display_name = 'Budget Balance' 
THEN team_level_budget_value_balance ELSE fed_level_budget_value 
END AS 'Target Profit Costs (Budget Balanced)', 
b.team_level_budget_value_hours
FROM red_dw.dbo.agg_bill_activity_monthly_rollup AS b 
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history AS fed 
ON fed.dim_fed_hierarchy_history_key = b.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_date
ON b.dim_bill_date_key = dim_date_key
JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = fed.dim_employee_key
WHERE fin_period = @fin_period
GO
